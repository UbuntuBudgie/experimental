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
/ right / left / up / down
/ optional:
/ --grid 2 3
/ without --grid, dconf val is used
*/

namespace JumpActive {

    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]


    interface ShufflerInfoClient : Object {
        public abstract GLib.HashTable<string, Variant> get_winsdata () throws Error;
        public abstract int getactivewin () throws Error;
        public abstract HashTable<string, Variant> get_tiles (string mon, int cols, int rows) throws Error;
        public abstract void move_window (int wid, int x, int y, int width, int height) throws Error;
        public abstract int get_yshift (int w_id) throws Error;
        public abstract string getactivemon_name () throws Error;
    }

    private int find_next (string[] arr, int anchor) {
        foreach (string s in arr) {
            int curr_anchor = int.parse(s);
            if (curr_anchor > anchor) {
                return curr_anchor;
            }
        }
        return int.parse(arr[arr.length - 1]);
    }

    private int find_previous (string[] arr, int anchor) {
        int previous_anchor = 0;
        foreach (string s in arr) {
            int curr_anchor = int.parse(s);
            if (curr_anchor < anchor) {
                previous_anchor = curr_anchor;
            }
            else {
                return previous_anchor;
            }
        }
        return previous_anchor;
    }

    private int find_closest (string[] arr, int current) {
        int distance = 100000;
        int closest = 0;
        foreach (string s in arr) {
            int d = int.parse(s);
            int check_current = (current - d).abs();
            if (check_current < distance) {
                distance = check_current;
                closest = d;
            }
        }
        return closest;
    }

    public static void main(string[] args) {
        try {
            ShufflerInfoClient client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon")
            );

            // cols/rows is read from dconf, or overruled by args:
            int cols = 3; // from dconf
            int rows = 3; // from dconf
            if (args.length == 4) {
                cols = int.parse(args[2]);
                rows = int.parse(args[3]);
            }
            string activemon_name = client.getactivemon_name();
            HashTable<string, Variant> anchordata = client.get_tiles(activemon_name, cols, rows);

            // get active win
            int activewin = client.getactivewin();

            if (activewin != -1) {
                string xs = (string)anchordata["x_anchors"];
                string ys = (string)anchordata["y_anchors"];
                int tilewidth = (int)anchordata["tilewidth"];
                int tileheight = (int)anchordata["tileheight"];
                //  (string) lists
                string[] x_anchors = xs.split(" ");
                string[] y_anchors = ys.split(" ");
                print("go on, go on\n");
                HashTable<string, Variant> wins = client.get_winsdata();
                Variant activewin_data = wins[@"$activewin"];
                int winx = (int)activewin_data.get_child_value(3);
                int winy = (int)activewin_data.get_child_value(4);
                print(@"$xs\n$ys\n$tilewidth\n$activewin\n$winx $winy\n\n");

                int nextx = 0;
                int nexty = 0;

                string direction = args[1];

                switch(direction) {

                    case "right":
                        nextx = find_next(x_anchors, winx);
                        nexty = find_closest(y_anchors, winy);
                        break;

                    case "left":
                        nextx = find_previous(x_anchors, winx);
                        nexty = find_closest(y_anchors, winy);
                        break;
                    case "up":
                        nextx = find_closest(x_anchors, winx);
                        nexty = find_previous(y_anchors, winy);
                        break;

                    case "down":
                        nextx = find_closest(x_anchors, winx);
                        nexty = find_next(y_anchors, winy);
                        break;
                }
                int yshift = client.get_yshift(activewin);

                client.move_window(
                    activewin, nextx, nexty - yshift, tilewidth, tileheight
                );
            }
        }
        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }
}