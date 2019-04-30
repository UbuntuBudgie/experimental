using Wnck;
using Gdk;
using Gtk;

/*
LaunchToWorkspace
Author: Jacob Vlijm
Copyright © 2017-2019 Ubuntu Budgie Developers
Website=https://ubuntubudgie.org
This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or any later version. This
program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
should have received a copy of the GNU General Public License along with this
program.  If not, see <https://www.gnu.org/licenses/>.
*/

// compile:
// valac --pkg gtk+-3.0 --pkg gio-2.0 --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE" 'file.vala'

namespace move_newwins {

    string[] classes;
    int[] targeted_workspaces;
    Wnck.Workspace[] workspaces;

    private Wnck.Screen getscreen () {
        unowned Wnck.Screen scr = Wnck.Screen.get_default();
        scr.force_update();
        return scr;
    }

    private void getstarted() {
        Wnck.Screen screen = getscreen();
        update_workspaces(screen);
        screen.window_opened.connect(newwin);
        screen.workspace_created.connect(() => {
            update_workspaces(screen);
        });
        screen.workspace_destroyed.connect(() => {
            update_workspaces(screen);
        });
    }

    private void update_workspaces (Wnck.Screen screen) {
        workspaces = {};
        foreach (Wnck.Workspace ws in screen.get_workspaces()) {
            workspaces += ws;
        }
    }

    private void newwin (Wnck.Window neww) {
        string wm_class = neww.get_class_group_name();
        int n = 0;
        foreach (string s in classes) {
            if (wm_class == s) {
                int newspace = targeted_workspaces[n];
                int n_spaces = workspaces.length;
                if (n_spaces > newspace) {
                    neww.move_to_workspace(
                        workspaces[
                            targeted_workspaces[n]
                        ]);
                    break;
                }
            }
            n += 1;
        }
    }

    public static void main (string[] args) {
        string[] redirs = args[1:args.length];
        foreach (unowned string arg in redirs) {
            string[] wmclass_data = arg.split("*");
            classes += wmclass_data[0];
            targeted_workspaces += int.parse(wmclass_data[1]);
        }
        Gtk.init(ref args);
        getstarted();
        Gtk.main();
    }

}
