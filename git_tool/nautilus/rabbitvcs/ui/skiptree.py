from __future__ import absolute_import
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

import os
import glob
import copy
import six.moves._thread
from time import sleep
from rabbitvcs.util import helper

import gi
gi.require_version("Gtk", "3.0")
sa = helper.SanitizeArgv()
from gi.repository import Gtk, GObject, Gdk
sa.restore()

from rabbitvcs.ui import InterfaceView
from rabbitvcs.util.contextmenu import GtkFilesContextMenu, GtkContextMenuCaller
import rabbitvcs.ui.widget
import rabbitvcs.ui.dialog
import rabbitvcs.ui.action
from rabbitvcs.util import helper
from rabbitvcs.util.strings import S
import rabbitvcs.vcs
from rabbitvcs.util.log import Log
from rabbitvcs.vcs.status import Status

log = Log("rabbitvcs.ui.skiptree")

from rabbitvcs import gettext
_ = gettext.gettext

helper.gobject_threads_init()

class Skiptree(InterfaceView, GtkContextMenuCaller):
    """
    Provides an interface for the user to add unversioned files to a
    repository.  Also, provides a context menu with some extra functionality.

    Send a list of paths to be added

    """

    TOGGLE_ALL = True

    def __init__(self, paths, base_dir=None):
        InterfaceView.__init__(self, "skiptree", "Skiptree")
        # InterfaceView.__init__(self, "skiptree", "Skiptree")

        self.paths = paths
        self.base_dir = base_dir
        self.last_row_clicked = None
        self.vcs = rabbitvcs.vcs.VCS()
        self.items = []
        self.show_ignored = False
        self.file_remove = False
        self.is_git = True
        self.show_skipped = False
        self.statuses = ["normal", "modified", "missing"]
        
        # TODO Remove this when there is svn support
        if rabbitvcs.vcs.guess(self.paths[0])['vcs'] == rabbitvcs.vcs.VCS_SVN:
            self.is_git = False
        elif rabbitvcs.vcs.guess(self.paths[0])['vcs'] == rabbitvcs.vcs.VCS_GIT:
            self.is_git = True
        else:
            return

        columns = [[GObject.TYPE_BOOLEAN,
                    rabbitvcs.ui.widget.TYPE_HIDDEN_OBJECT,
                    rabbitvcs.ui.widget.TYPE_PATH,
                    GObject.TYPE_STRING],
                   [rabbitvcs.ui.widget.TOGGLE_BUTTON, "", _("Path"),
                    _("Extension")]]


        self.files_table = rabbitvcs.ui.widget.Table(
            self.get_widget("files_table"),
            columns[0],
            columns[1],
            filters=[{
                "callback": rabbitvcs.ui.widget.path_filter,
                "user_data": {
                    "base_dir": base_dir,
                    "column": 2
                }
            }],
            callbacks={
                "row-activated":  self.on_files_table_row_activated,
                "mouse-event":   self.on_files_table_mouse_event,
                "key-event":     self.on_files_table_key_event
            }
        )

        self.initialize_items()

    #
    # Helpers
    #

    def load(self):
        status = self.get_widget("status")
        helper.run_in_main_thread(status.set_text, _("Loading..."))
        self.items = self.vcs.get_items_skiptree(self.paths, self.statuses)
        if self.is_git:
           self.show_skiptree_file(self.items)
        if self.show_ignored:
            for path in self.paths:
                # TODO Refactor
                # TODO SVN support
                # TODO Further fix ignore patterns
                if rabbitvcs.vcs.guess(path)['vcs'] == rabbitvcs.vcs.VCS_GIT:
                    git = self.vcs.git(path)
                    for ignored_path in git.client.get_all_ignore_file_paths(path):
                        should_add = True
                        for item in self.items:
                            if item.path == os.path.realpath(ignored_path):
                                should_add = False

                        if should_add:
                            self.items.append(Status(os.path.realpath(ignored_path), 'unversioned'))



        self.populate_files_table()
        helper.run_in_main_thread(status.set_text, _("Found %d item(s)") % len(self.items))

    def populate_files_table(self):
        self.files_table.clear()
        for item in self.items:
            self.files_table.append([
                True,
                S(item.path),
                item.path,
                helper.get_file_extension(item.path)
            ])

    def toggle_ignored(self):
        self.show_ignored = not self.show_ignored
        self.initialize_items()

    # Overrides the GtkContextMenuCaller method
    def on_context_menu_command_finished(self):
        self.initialize_items()

    def initialize_items(self):
        """
        Initializes the activated cache and loads the file items in a new thread
        """

        try:
            six.moves._thread.start_new_thread(self.load, ())
        except Exception as e:
            log.exception(e)

    def delete_items(self, widget, event):
        paths = self.files_table.get_selected_row_items(1)
        if len(paths) > 0:
            proc = helper.launch_ui_window("delete", paths)
            self.rescan_after_process_exit(proc, paths)

    #
    # UI Signal Callbacks
    #

    def on_select_all_toggled(self, widget):
        self.TOGGLE_ALL = not self.TOGGLE_ALL
        for row in self.files_table.get_items():
            row[0] = self.TOGGLE_ALL

    def on_file_remove_toggled(self, widget):
        self.file_remove = widget.get_active()

    def on_show_ignored_toggled(self, widget):
        self.toggle_ignored()
        
    def on_show_skipped_toggled(self, widget):
        self.show_skipped = widget.get_active()
        self.initialize_items()

    def on_files_table_row_activated(self, treeview, event, col):
        paths = self.files_table.get_selected_row_items(1)
        helper.launch_diff_tool(*paths)

    def on_files_table_key_event(self, treeview, event, *args):
        if Gdk.keyval_name(event.keyval) == "Delete":
            self.delete_items(treeview, event)

    def on_files_table_mouse_event(self, treeview, event, *args):
        if event.button == 3 and event.type == Gdk.EventType.BUTTON_RELEASE:
            self.show_files_table_popup_menu(treeview, event)

    def show_files_table_popup_menu(self, treeview, event):
        paths = self.files_table.get_selected_row_items(1)
        GtkFilesContextMenu(self, event, self.base_dir, paths).show()


class SVNSkiptree(Skiptree):
    def __init__(self, paths, base_dir=None):
        Skiptree.__init__(self, paths, base_dir)

        self.svn = self.vcs.svn()
        self.get_widget("show_skipped").hide()
        self.get_widget("file_remove").hide()

    def on_ok_clicked(self, widget):
        items = self.files_table.get_activated_rows(1)
        if not items:
            self.close()
            return

        self.action = rabbitvcs.ui.action.SVNAction(
            self.svn,
            register_gtk_quit=self.gtk_quit_is_set()
        )
        self.action.append(self.action.set_header, _("Exclude"))
        self.action.append(self.action.set_status, _("Running Exclude Command..."))
        self.action.append(self.svn.exclude, self.base_dir, items)
        self.action.append(self.action.set_status, _("Completed Exclude"))
        self.action.append(self.action.finish)
        self.action.schedule()
        
    def show_skiptree_file(self, items):
        pass

class GitSkiptree(Skiptree):
    def __init__(self, paths, base_dir=None):
        Skiptree.__init__(self, paths, base_dir)

        self.git = self.vcs.git(paths[0])

    def on_ok_clicked(self, widget):
        items = self.files_table.get_activated_rows(1)
        
        if not items:
            self.close()
            return
        self.hide()
        
        self.action = rabbitvcs.ui.action.GitAction(
            self.git,
            register_gtk_quit=self.gtk_quit_is_set()
        )
        self.action.append(self.action.set_header, _("Skiptree"))
        self.action.append(self.action.set_status, _("Running Skiptree Command..."))
        self.action.append(self.git.skiptree, items, self.file_remove)
        self.action.append(self.action.set_status, _("Completed Skiptree"))
        self.action.append(self.action.finish)
        self.action.schedule()
        
    def show_skiptree_file(self, items):
        remove_list = []
        for item in items:
            if self.show_skipped:
                if self.git.already_skiptree(item.path) == False:
                    remove_list.append(item)
            else:
                if self.git.already_skiptree(item.path):
                    remove_list.append(item)
        for remove_item in remove_list:
            items.remove(remove_item)

classes_map = {
    rabbitvcs.vcs.VCS_SVN: SVNSkiptree,
    rabbitvcs.vcs.VCS_GIT: GitSkiptree
}

def add_factory(paths, base_dir):
    guess = rabbitvcs.vcs.guess (paths[0])
    return classes_map[guess["vcs"]](paths,base_dir)

class AddQuiet(object):
    def __init__(self, paths):
        self.vcs = rabbitvcs.vcs.VCS()
        self.svn = self.vcs.svn()
        self.action = rabbitvcs.ui.action.SVNAction(
            self.svn
        )

        self.action.append(self.svn.add, paths)
        self.action.schedule()


if __name__ == "__main__":
    from rabbitvcs.ui import main, BASEDIR_OPT, QUIET_OPT
    (options, paths) = main(
        [BASEDIR_OPT, QUIET_OPT],
        usage="Usage: rabbitvcs add [path1] [path2] ..."
    )

    if options.quiet:
        AddQuiet(paths)
    else:
        window = add_factory(paths,options.base_dir)#Add(paths, options.base_dir)
        window.register_gtk_quit()
        Gtk.main()
