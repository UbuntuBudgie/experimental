using Gtk;
/*
Budgie Screenshot
Author: Jacob Vlijm
Copyright © 2022 Ubuntu Budgie Developers
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

// valac --pkg gtk+-3.0

namespace Budgie {

    [DBus (name = "org.buddiesofbudgie.ScreenshotControl")]
    interface ScreenshotControl : GLib.Object {
        public signal void received_im_msg (int account, string sender, string msg,
                                            int conv, uint flags);

        public abstract void StartMainWindow() throws GLib.Error;
        public abstract void StartAreaSelect() throws GLib.Error;
        public abstract void StartWindowScreenshot() throws GLib.Error;
        public abstract void StartFullScreenshot() throws GLib.Error;
    }

    static bool interactive = false;
    static bool window = false;
    static bool area = false;

    const OptionEntry[] options = {
        { "interactive", 'i', 0, OptionArg.NONE, ref interactive, "Interactively set options" },
        { "window", 'w', 0, OptionArg.NONE, ref window, "Grab a window instead of the entire display" },
        { "area", 'a', 0, OptionArg.NONE, ref area, "Grab an area of the display instead of the entire display" },
        { null }
    };

    public static int main(string[] args) {
        ScreenshotControl control;
        OptionContext ctx;
        ctx = new OptionContext("- Budgie Screenshot");
        ctx.set_help_enabled(true);
        ctx.add_main_entries(options, null);

        try {
            ctx.parse(ref args);
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
            return 0;
        }
        try {
            control = GLib.Bus.get_proxy_sync (
                BusType.SESSION, "org.buddiesofbudgie.ScreenshotControl",
                ("/org/buddiesofbudgie/ScreenshotControl")
            );

            if (interactive) {
                control.StartMainWindow();
                return 0;
            }
            if (area) {
                control.StartAreaSelect();
                return 0;
            }
            if (window){
                control.StartWindowScreenshot();
                return 0;
            }

            control.StartFullScreenshot();
            return 0;
        }
        catch (Error e) {
            stderr.printf ("%s\n", e.message);
            return 1;
        }

        return 0;
    }
}
