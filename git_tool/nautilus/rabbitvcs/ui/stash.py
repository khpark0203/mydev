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

        self.filter_text = None
        self.path = path

        self.message = rabbitvcs.ui.widget.TextView(
            self.get_widget("message")
        )

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

    def on_refresh_clicked(self, widget):
        self.load()

    def on_revisions_table_mouse_event(self, treeview, event, *args):
        if event.button == 3 and event.type == Gdk.EventType.BUTTON_RELEASE:
            self.show_revisions_table_popup_menu(treeview, event)
            
    def show_revisions_table_popup_menu(self, treeview, data):
        StashTopContextMenu(self, data, self.path, [1]).show()

    def set_loading(self, loading):
        self.is_loading = loading

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
        self.path = self.git.find_repository_path(path)

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
        
        self.path_table = rabbitvcs.ui.widget.Table(
            self.get_widget("path_table"),
            [GObject.TYPE_STRING, GObject.TYPE_STRING],
            [_("Number"), _("File")],
            filters=[{
                "callback": rabbitvcs.ui.widget.git_revision_filter,
                "user_data": {
                    "column": 0
                }
            }]
        )
        self.get_widget("root").set_markup("<i>Root : {}</i>".format(self.path))
        
        self.message = rabbitvcs.ui.widget.TextView(
            self.get_widget("message"),
            self.SETTINGS.get_multiline("general", "default_commit_message")
        )
        
        self.items = []
        self.load()
        self.show = False
        self.selected_row = None
        self.total_row = 0
        
    def set_item(self):
        self.path_table.clear()
        self.items = []
        for item in self.vcs.get_items([self.path], self.vcs.statuses_for_commit([self.path])):
            self.items.append(item.path)
        
        i = 1
        for item in self.items:
            idx = item.find(self.path) + len(self.path)
            self.path_table.append([
                i,
                item[idx+1:]
            ])
            i += 1
        
        if i > 2:
            self.get_widget("scrolledwindow2").set_property("vexpand", True)
        else:
            self.get_widget("scrolledwindow2").set_property("vexpand", False)
            
    
    def refresh(self):
        self.revisions_table.clear()
        stash_list = self.git.get_stash_list()
        
        self.total_row = 0
        for org_msg in stash_list:
            start_idx = org_msg.find("stash@{")
            end_idx = org_msg.find("}: ")
            revision = org_msg[:start_idx]
            num = org_msg[start_idx + len("stash@{"):end_idx]
            msg = org_msg[end_idx + len("}: "):]
            
            self.revisions_table.append([
                num,
                revision,
                msg
            ])
            self.total_row += 1
            
        self.set_item()
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
            self.selected_row = selected_row
        else:
            selected_row = 0
            self.selected_row = None
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        self.action.append(
            self.git.stash,
            cmd="drop",
            num=selected_row
        )
        if self.show:
            self.action.append(self.action.finish)
        self.action.append(self.refresh)
        self.action.schedule()
        
    def clear(self):
        self.selected_row = None
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        self.action.append(
            self.git.stash,
            cmd="clear",
            num=None
        )
        if self.show:
            self.action.append(self.action.finish)
        self.action.append(self.refresh)
        self.action.schedule()
        
    def apply(self):
        if len(self.revisions_table.get_selected_rows()):
            selected_row = self.revisions_table.get_selected_rows()[0]
            self.selected_row = selected_row
        else:
            selected_row = None
            
        self.action = GitAction(
            self.git,
            notification=self.show,
            run_in_thread=False
        )
        self.action.append(
            self.git.stash,
            cmd="apply",
            num=selected_row
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
        if len(self.revisions_table.get_selected_rows()) == self.total_row:
            self.clear()
        else:
            self.drop()
            if self.selected_row:
                self.revisions_table.focus(self.selected_row, 0)
                if len(self.revisions_table.get_selected_rows()) == 0:
                    self.revisions_table.focus(self.selected_row-1, 0)
    def on_apply_clicked(self, widget, data=None):
        self.apply()
        if self.selected_row:
            self.revisions_table.focus(self.selected_row, 0)
        
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
        if len(self.caller.revisions_table.get_selected_rows()) == 1:
            return True
        elif len(self.caller.revisions_table.get_selected_rows()) == self.caller.total_row:
            return True
        return False
    def stash_apply(self, data=None):
        if len(self.caller.revisions_table.get_selected_rows()) == 1:
            return True
        return False
        
class StashTopContextMenuCallbacks(object):
    def __init__(self, caller, vcs, path, revisions):
        self.caller = caller
        self.vcs = vcs
        self.path = path
        self.revisions = revisions

        self.vcs_name = self.caller.get_vcs_name()

    def stash_drop(self, widget, data=None):
        if len(self.caller.revisions_table.get_selected_rows()) == self.caller.total_row:
            self.caller.clear()
        else:
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
