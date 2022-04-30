
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

using Gtk;

public static int main(string[] args) {
    Gtk.init(ref args);
    try {
        Budgie.client = GLib.Bus.get_proxy_sync (
            BusType.SESSION, "org.buddiesofbudgie.Screenshot",
            ("/org/buddiesofbudgie/Screenshot")
        );
    }
    catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
    try {
        Budgie.ScreenshotServer server = new Budgie.ScreenshotServer();
        server.setup_dbus();
    }
    catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
    Gtk.main();
    return 0;
}
