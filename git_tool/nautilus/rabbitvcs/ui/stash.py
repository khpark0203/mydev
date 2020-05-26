#
# This is an extension to the Nautilus file manager to allow better
# integration with the Subversion source control system.
#
# Copyright (C) 2006-2008 by Jason Field <jason@jasonfield.com>
# Copyright (C) 2007-2008 by Bruce van der Kooij <brucevdkooij@gmail.com>
# Copyright (C) 2008-2010 by Adam Plumb <adamplumb@gmail.com>
#
# RabbitVCS is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# RabbitVCS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with RabbitVCS;  If not, see <http://www.gnu.org/licenses/>.
#

from __future__ import division
from __future__ import absolute_import
import six
import threading
from locale import strxfrm

import os.path

from rabbitvcs.util import helper

import gi
gi.require_version("Gtk", "3.0")
sa = helper.SanitizeArgv()
from gi.repository import Gtk, GObject, Gdk
sa.restore()

from rabbitvcs.ui import InterfaceView
from rabbitvcs.ui.action import SVNAction, GitAction, vcs_action_factory
from rabbitvcs.ui.dialog import MessageBox
import rabbitvcs.ui.widget
from rabbitvcs.util.contextmenu import GtkContextMenu
from rabbitvcs.util.contextmenuitems import *
from rabbitvcs.util.decorators import gtk_unsafe
from rabbitvcs.util.strings import S
import rabbitvcs.util.settings
import rabbitvcs.vcs

from rabbitvcs import gettext
_ = gettext.gettext

from six.moves import range


REVISION_LABEL = _("Revision")
DATE_LABEL = _("Date")
AUTHOR_LABEL = _("Author")


def revision_grapher(history):
    """
    Expects a list of revision items like so:
    [
        item.commit = "..."
        item.parents = ["...", "..."]
    ]

    Output can be put directly into the CellRendererGraph
    """
    items = []
    revisions = []
    last_lines = []
    color = "#d3b9d3"
    for item in history:
        commit = S(item.revision)
        parents = []
        for parent in item.parents:
            parents.append(S(parent))

        if commit not in revisions:
            revisions.append(commit)

        index = revisions.index(commit)
        next_revisions = revisions[:]

        parents_to_add = []
        for parent in parents:
            if parent not in next_revisions:
                parents_to_add.append(parent)

        next_revisions[index:index+1] = parents_to_add

        lines = []
        for i, revision in enumerate(revisions):
            if revision in next_revisions:
                lines.append((i, next_revisions.index(revision), color))
            elif revision == commit:
                for parent in parents:
                    lines.append((i, next_revisions.index(parent), color))

        node = (index, "#a9f9d2")

        items.append((item, node, last_lines, lines))
        revisions = next_revisions
        last_lines = lines

    return items

class Stash(InterfaceView):
    """
    Provides an interface to the Log UI

    """
    
    SETTINGS = rabbitvcs.util.settings.SettingsManager()

    selected_rows = []
    selected_row = []
    paths_selected_rows = []
    limit = 100

    def __init__(self, path):
        """
        @type   path: string
        @param  path: A path for which to get log items

        """

        InterfaceView.__init__(self, "stash", "Stash")

        self.get_widget("Stash").set_title(_("Stash"))
        self.vcs = rabbitvcs.vcs.VCS()

        sm = rabbitvcs.util.settings.SettingsManager()
        # self.datetime_format = sm.get("general", "datetime_format")
        self.datetime_format = "%y.%m.%d (%a) %p %I:%M"

        self.filter_text = None
        self.path = path
        self.cache = StashCache()

        self.rev_first = None
        self.rev_start = None
        self.rev_end = None
        self.rev_max = 1
        self.previous_starts = []
        self.revision_number_column = 0
        self.head_row = 0

        self.message = rabbitvcs.ui.widget.TextView(
            self.get_widget("message")
        )

        self.stop_on_copy = False
        self.show_only_commit = False
        self.revision_clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)

    #
    # UI Signal Callback Methods
    #

    def on_destroy(self, widget, data=None):
        self.destroy()

    def on_close_clicked(self, widget, data=None):
        if self.is_loading:
            self.action.set_cancel(True)
            self.action.stop()
            self.set_loading(False)

        self.close()

    def on_key_pressed(self, widget, event, *args):
        InterfaceView.on_key_pressed(self, widget, event)
        if (event.state & Gdk.ModifierType.MOD1_MASK and
            Gdk.keyval_name(event.keyval).lower() == "l"):
                self.get_widget("limit").grab_focus()
        
    def on_stop_on_copy_toggled(self, widget):
        self.stop_on_copy = self.get_widget("stop_on_copy").get_active()
        if not self.is_loading:
            self.refresh()
            
    def on_refresh_clicked(self, widget):
        self.cache.empty()
        self.load()

    #
    # Revisions table callbacks
    #

    # In this UI, we have an ability to filter and display only certain items.
    def get_displayed_row_items(self, col):
        items = []
        for row in self.selected_rows:
            items.append(self.display_items[row][col])

        return items

    def on_revisions_table_row_activated(self, treeview, event, col):
        paths = self.revisions_table.get_displayed_row_items(1)

        helper.launch_diff_tool(*paths)

    def on_revisions_table_mouse_event(self, treeview, event, *args):
        if event.button == 3 and event.type == Gdk.EventType.BUTTON_RELEASE:
            self.show_revisions_table_popup_menu(treeview, event)

    #
    # Paths table callbacks
    #

    def on_paths_table_row_activated(self, treeview, data=None, col=None):
        try:
            revision1 = S(self.display_items[self.revisions_table.get_selected_rows()[0]].revision)
            revision2 = S(self.display_items[self.revisions_table.get_selected_rows()[0]+1].revision)
            path_item = self.paths_table.get_row(self.paths_table.get_selected_rows()[0])[1]
            url = self.root_url + path_item
            self.view_diff_for_path(url, S(revision1), S(revision2), sidebyside=True)
        except IndexError:
            pass

    def on_paths_table_mouse_event(self, treeview, event, *args):
        if event.button == 3 and event.type == Gdk.EventType.BUTTON_RELEASE:
            self.show_paths_table_popup_menu(treeview, event)

    #
    # Helper methods
    #

    def load_or_refresh(self):
        if self.cache.has(self.rev_start):
            self.refresh()
        else:
            self.load()

    def get_selected_revision_numbers(self):
        if len(self.revisions_table.get_selected_rows()) == 0:
            return ""

        revisions = []
        for row in self.revisions_table.get_selected_rows():
            revisions.append(int(self.revisions_table.get_row(row)[self.revision_number_column]))

        revisions.sort()
        helper.encode_revisions(revisions)

    def get_selected_revision_number(self):
        if len(self.revisions_table.get_selected_rows()):
            return self.revisions_table.get_row(self.revisions_table.get_selected_rows()[0])[self.revision_number_column]
        else:
            return ""

    def set_loading(self, loading):
        self.is_loading = loading

    def show_revisions_table_popup_menu(self, treeview, data):
        revisions = []
        for row in self.revisions_table.get_selected_rows():
            revisions.append(self.display_items[row])

        StashTopContextMenu(self, data, self.path, revisions).show()

    def get_vcs_name(self):
        vcs = rabbitvcs.vcs.VCS_DUMMY
        if hasattr(self, "svn"):
            vcs = rabbitvcs.vcs.VCS_SVN
        elif hasattr(self, "git"):
            vcs = rabbitvcs.vcs.VCS_GIT

        return vcs

class GitStash(Stash):
    def __init__(self, path):
        Stash.__init__(self, path)

        self.git = self.vcs.git(path)

        self.git_svn = self.git.client.git_svn

        self.limit = 100
        self.revision_number_column = 1

        self.revisions_table = rabbitvcs.ui.widget.Table(
            self.get_widget("revisions_table"),
            [GObject.TYPE_STRING, GObject.TYPE_STRING, GObject.TYPE_STRING],
            [_("Number"), _("Revision"), _("Message")],
            filters=[{
                "callback": rabbitvcs.ui.widget.git_revision_filter,
                "user_data": {
                    "column": 0
                }
            }],
            callbacks={
                "mouse-event":   self.on_revisions_table_mouse_event,
            }
        )
        
        self.message = rabbitvcs.ui.widget.TextView(
            self.get_widget("message"),
            self.SETTINGS.get_multiline("general", "default_commit_message")
        )
	
        self.start_point = 0
        self.initialize_root_url()
        self.load_or_refresh()
        self.show = False
        self.selected_row = None
        
    #
    # Log-loading callback methods
    #

    def refresh(self):
        self.revisions_table.clear()
        stash_list = self.git.get_stash_list()
        
        self.display_items = []
        
        for org_msg in stash_list:
            start_idx = org_msg.find("stash@{")
            end_idx = org_msg.find("}: ")
            revision = org_msg[:start_idx]
            num = org_msg[start_idx + len("stash@{"):end_idx]
            msg = org_msg[end_idx + len("}: "):]
            
            self.display_items.append(num)
            
            self.revisions_table.append([
                num,
                revision,
                msg
            ])

        self.set_loading(False)

    def load(self):
        self.set_loading(True)

        # Load log.
        self.action = GitAction(
            self.git,
            notification=False,
            run_in_thread=True
        )
        
        self.action.append(self.refresh)
        self.action.schedule()

    def initialize_root_url(self):
        self.root_url = self.git.get_repository() + "/"
        
    def stash(self):
        msg = self.message.get_text()
        if self.message.get_text() == "":
            msg = None
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        
        self.action.append(
            self.git.stash,
            cmd="save",
            msg=msg
        )
        
        if self.show:
            self.action.append(self.action.finish)
        self.action.append(self.refresh)
        self.action.schedule()
        
        self.message.set_text("")

    def drop(self):
        if len(self.revisions_table.get_selected_rows()):
            selected_row = self.revisions_table.get_selected_rows()[0]
            selected_num = int(self.display_items[selected_row])
            self.selected_row = selected_row
        else:
            selected_num = None
            self.selected_row = None
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        self.action.append(
            self.git.stash,
            cmd="drop",
            num=selected_num
        )
        if self.show:
            self.action.append(self.action.finish)
        self.action.append(self.refresh)
        self.action.schedule()
        
    def apply(self):
        if len(self.revisions_table.get_selected_rows()):
            selected_row = self.revisions_table.get_selected_rows()[0]
            selected_num = int(self.display_items[selected_row])
        else:
            selected_num = None
            
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        self.action.append(
            self.git.stash,
            cmd="apply",
            num=selected_num
        )
        if self.show:
            self.action.append(self.action.finish)
        self.action.append(self.refresh)
        self.action.schedule()
        
    def pop(self):
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        self.action.append(
            self.git.stash,
            cmd="pop",
            num=None
        )
        if self.show:
            self.action.append(self.action.finish)
        self.action.append(self.refresh)
        self.action.schedule()
        
    def on_stash_clicked(self, widget, data=None):
        self.stash()
        
    def on_drop_clicked(self, widget, data=None):
        self.drop()
        if self.selected_row:
            self.revisions_table.focus(self.selected_row, 0)
            if len(self.revisions_table.get_selected_rows()) == 0:
                self.revisions_table.focus(self.selected_row-1, 0)
    def on_apply_clicked(self, widget, data=None):
        self.apply()
        
    def on_pop_clicked(self, widget, data=None):
        self.pop()
        
    def on_toggle_notify(self, widget, data=None):
        self.show = widget.get_active()
        
class StashTopContextMenuConditions(object):
    def __init__(self, caller, vcs, path, revisions):
        self.caller = caller
        self.vcs = vcs
        self.path = path
        self.revisions = revisions

        self.vcs_name = caller.get_vcs_name()

    def stash_drop(self, data=None):
        return True
    def stash_apply(self, data=None):
        return True

class StashTopContextMenuCallbacks(object):
    def __init__(self, caller, vcs, path, revisions):
        self.caller = caller
        self.vcs = vcs
        self.path = path
        self.revisions = revisions

        self.vcs_name = self.caller.get_vcs_name()

    def stash_drop(self, widget, data=None):
        self.caller.drop()
        
    def stash_apply(self, widget, data=None):
        self.caller.apply()

        
class StashTopContextMenu(object):
    """
    Defines context menu items for a table with files

    """
    def __init__(self, caller, event, path, revisions=[]):
        """
        @param  caller: The calling object
        @type   caller: object

        @param  base_dir: The curent working directory
        @type   base_dir: string

        @param  path: The loaded path
        @type   path: string

        @param  revisions: The selected revisions
        @type   revisions: list of rabbitvcs.vcs.Revision object

        """
        self.caller = caller
        self.event = event
        self.path = path
        self.revisions = revisions
        self.vcs = rabbitvcs.vcs.VCS()

        self.conditions = StashTopContextMenuConditions(
            self.caller,
            self.vcs,
            self.path,
            self.revisions
        )

        self.callbacks = StashTopContextMenuCallbacks(
            self.caller,
            self.vcs,
            self.path,
            self.revisions
        )

        # The first element of each tuple is a key that matches a
        # ContextMenuItems item.  The second element is either None when there
        # is no submenu, or a recursive list of tuples for desired submenus.
        self.structure = [
            (MenuDrop, None),
            (MenuApply, None),
        ]

    def show(self):
        if len(self.revisions) == 0:
            return

        context_menu = GtkContextMenu(self.structure, self.conditions, self.callbacks)
        context_menu.show(self.event)
        
class StashCache(object):
    def __init__(self, cache={}):
        self.cache = cache

    def set(self, key, val):
        self.cache[key] = val

    def get(self, key):
        return self.cache[key]

    def has(self, key):
        return (key in self.cache)

    def empty(self):
        self.cache = {}
        
class MenuDrop(MenuItem):
    identifier = "RabbitVCS::Stash_Drop"
    label = _("Drop")
    
class MenuApply(MenuItem):
    identifier = "RabbitVCS::Stash_Apply"
    label = _("Apply")
    
classes_map = {
    rabbitvcs.vcs.VCS_GIT: GitStash
}

def log_factory(path, vcs):
    # vcs option is allowed for URL only
    if os.path.exists(path):
        vcs = None

    if not vcs:
        guess = rabbitvcs.vcs.guess(path)
        vcs = guess["vcs"]
        if not vcs in classes_map:
            from rabbitvcs.ui import VCS_OPT_ERROR
            raise SystemExit(VCS_OPT_ERROR)

    return classes_map[vcs](path)

if __name__ == "__main__":
    from rabbitvcs.ui import main, VCS_OPT
    (options, paths) = main(
        [VCS_OPT],
        usage="Usage: rabbitvcs stash"
    )

    window = log_factory(paths[0], vcs=options.vcs)
    window.register_gtk_quit()
    Gtk.main()
