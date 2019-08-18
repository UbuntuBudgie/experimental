using Gtk;

/*
Budgie WindowPreviews
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

namespace PreviewsControls {

    GLib.Settings prvsettings;

    class ControlsWindow : Gtk.Window {

        Grid maingrid;

        public ControlsWindow () {
            this.title = "Previews Controls";
            maingrid = new Gtk.Grid();
            this.add(maingrid);
            set_margins();
            var toggle_previews = new Gtk.CheckButton.with_label(
                "Run Previews"
            );
            toggle_previews.set_relief(Gtk.ReliefStyle.NONE);
            var toggle_allworkspaces = new Gtk.CheckButton.with_label(
                "Show windows of all workspaces"
            );
            var ok_button = new Button.with_label("Close");
            ok_button.clicked.connect(Gtk.main_quit);

            maingrid.attach(toggle_previews, 1, 1, 1, 1);
            maingrid.attach(toggle_allworkspaces, 1, 2, 1, 1);
            toggle_previews.set_active(get_currsetting("enable-previews"));
            toggle_allworkspaces.set_active(get_currsetting("allworkspaces"));
            toggle_previews.toggled.connect ( () => {
                update_settings(toggle_previews, "enable-previews");
            });
            toggle_allworkspaces.toggled.connect ( () => {
                update_settings(toggle_allworkspaces, "allworkspaces");
            });

            maingrid.attach(ok_button, 99, 99, 1, 1);
            this.destroy.connect(Gtk.main_quit);
        }

        private bool get_currsetting (string key) {
            return prvsettings.get_boolean(key);
        }

        private void update_settings (ToggleButton button, string key) {
            prvsettings.set_boolean(key, button.get_active());
        }

        private void set_margins () {
            // I admit, lazy layout
            int[,] corners = {
                {0, 0}, {100, 0}, {2, 0}, {0, 100}, {100, 100}
            };
            int lencorners = corners.length[0];
            for (int i=0; i < lencorners; i++) {
                var spacelabel = new Label("\t");
                //spacelabel.set_text("");
                maingrid.attach(
                    spacelabel, corners[i, 0], corners[i, 1], 1, 1
                );
            }
        }
    }

    public static void main (string[] args) {
        Gtk.init(ref args);
        prvsettings = new GLib.Settings(
            "org.ubuntubudgie.plugins.budgie-wpreviews"
        );
        var controls = new ControlsWindow();
        controls.show_all();
        Gtk.main();
    }
}