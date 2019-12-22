/*
* ShufflerII
* Author: Jacob Vlijm
* Copyright © 2017-2019 Ubuntu Budgie Developers
* Website=https://ubuntubudgie.org
* This program is free software: you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the Free
* Software Foundation, either version 3 of the License, or any later version.
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details. You should have received a copy of the GNU General Public
* License along with this program.  If not, see
* <https://www.gnu.org/licenses/>.
*/

// valac --pkg gio-2.0 --pkg gtk+-3.0

/*
/ args:
/ |--x/y--| |--cols/rows--|
/  int int      int int
/ or:
/ |--x/y--| |--cols/rows--| |--xspan/yspan--|
/  int int      int int          int int
/ or:
/ maximize
*/

namespace TileActive {

    ShufflerInfoClient? client;
    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    interface ShufflerInfoClient : Object {
        public abstract GLib.HashTable<string, Variant> get_winsdata () throws Error;
        public abstract int getactivewin () throws Error;
        public abstract HashTable<string, Variant> get_tiles (string mon, int cols, int rows) throws Error;
        public abstract void move_window (int wid, int x, int y, int width, int height) throws Error;
        public abstract int get_yshift (int w_id) throws Error;
        public abstract int toggle_maximize (int w_id) throws Error;
    }

    void main (string[] args) {
        try {
            client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon")
            );
            if (args.length == 2) {
                string arg = (args[1]);
                if (arg == "maximize") {
                    // ok, for the sake of simplicity, let's allow one internal action
                    int win_id = client.getactivewin();
                    client.toggle_maximize(win_id);
                }
                else {
                    print(@"Unknown argument: $arg\n");
                }
            }
            if (args.length == 5) {
                if (
                    int.parse(args[1]) < int.parse(args[3]) &&
                    int.parse(args[2]) < int.parse(args[4])
                ) {
                    grid_window(args, 1, 1);
                }
                else {
                    print("position is outside monitor\n");
                }
            }
            else if (args.length == 7) {
                int ntiles_x = int.parse(args[5]);
                int ntiles_y = int.parse(args[6]);
                if (
                    int.parse(args[1]) + ntiles_x <= int.parse(args[3])  &&
                    int.parse(args[2]) + ntiles_y <= int.parse(args[4])
                ) {
                    grid_window(args, ntiles_x, ntiles_y);
                }
                else {
                    print("size exceeds monitor size\n");
                }
            }
        }
        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    void grid_window (string[] args, int ntiles_x, int ntiles_y) {
        // fetch info from daemon, do the job with it
        try {
            int activewin = client.getactivewin();
            // get data, geo on windows
            GLib.HashTable<string, Variant> windata = client.get_winsdata();
            GLib.List<unowned string> windata_keys = windata.get_keys();
            // vars
            int yshift = 0;
            string winsmonitor = "";
            foreach (string s in windata_keys) {
                if (int.parse(s) == activewin) {
                    yshift = client.get_yshift(activewin);
                    Variant currwindata = windata[s];
                    winsmonitor = (string)currwindata.get_child_value(2);
                }
            }
            // get tiles -> matching tile
            HashTable<string, Variant> tiles = client.get_tiles(
                winsmonitor, int.parse(args[3]), int.parse(args[4])
            );
            GLib.List<unowned string> tilekeys = tiles.get_keys();
            int orig_width = (int)tiles["tilewidth"];
            int orig_height = (int)tiles["tileheight"];
            foreach (string tilename in tilekeys) {
                // if key matches -> get tile pos & size -> move
                if (args[1].concat("*", args[2]) == tilename) {
                    Variant currtile = tiles[tilename];
                    int tile_x = (int)currtile.get_child_value(0);
                    int tile_y = (int)currtile.get_child_value(1);
                    int tile_wdth = orig_width * ntiles_x;
                    int tile_hght = orig_height * ntiles_y;
                    client.move_window(
                        activewin, tile_x, tile_y - yshift, tile_wdth, tile_hght
                    );
                }
            }
        }
        catch (Error e) {
                stderr.printf ("%s\n", e.message);
        }
    }
}