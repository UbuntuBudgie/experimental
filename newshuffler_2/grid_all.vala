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

// simplify variant-get:
//  Variant got_data = wins[k];
//  string yay = (string)got_data.get_child_value(2);


namespace GridAll {

    ShufflerInfoClient client;
    //  string[] id_array;

    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    interface ShufflerInfoClient : Object {
        public abstract GLib.HashTable<string, Variant> get_winsdata () throws Error;
        public abstract int getactivewin () throws Error;
        public abstract HashTable<string, Variant> get_tiles (string mon, int cols, int rows) throws Error;
        public abstract void move_window (int wid, int x, int y, int width, int height) throws Error;
        public abstract int get_yshift (int w_id) throws Error;
        public abstract string getactivemon_name () throws Error;
        //  public abstract void grid_allwindows (
        //      int cols, int rows, int left, int right, int top, int bottom
        //  ) throws Error;
    }

    private int get_stringindex (string s, string[] arr) {
        // get index of a string in an array
        for (int i=0; i < arr.length; i++) {
            if(s == arr[i]) return i;
        } return -1;
    }





    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

    private string[] make_tilekeys (int cols, int rows) {
        /*
        / we receieve the hastable keys in an unordered manner
        / so we need to reconstruc an ardered one to work with
        */
        string[] key_arr = {};

        for (int r=0; r< rows; r++) {
            for (int c=0; c < cols; c++) {
                key_arr += @"$c*$r";
                // print( @"key: $c*$r\n");
            }
        }
        return key_arr;
    }

    private string[] remove_arritem (string s, string[] arr) {
        string[] newarr = {};
        foreach (string item in arr) {
            if (item != s) {
                newarr += item;
            }
        }
        return newarr;
    }

    private void grid_allwindows (int[] geo_args) {
        // split args for readability please

        /* make array of window ids. then:
        / - create sorted key list from args ***************************************************
        / - per tile, see what window is closest (lookup distance -from- id-array -in- hashtable)
        / - move window, remove id from array
        / - repeat until out of windows (id array is empty, cycle through tiles if needed)
        / - N.B. change order in creating tiles! row per row. not col for col...
        */
        HashTable<string, Variant>? tiles = null;
        HashTable<string, Variant>? wins = null;
        string[] id_array = {};
        string[] ordered_keyarray = make_tilekeys(geo_args[0], geo_args[1]);
        // get active monitorname by active window ("" if null)
        try {
            string mon_name = client.getactivemon_name();
            tiles = client.get_tiles(
                mon_name, geo_args[0], geo_args[1]
            );
            print(@"$mon_name\n");
        }
        catch (Error e) {
        }




        //  print("args:\n");
        //  foreach (int n in geo_args) {
        //      print(@"$n\n");
        //  }


        /////////////////////////////////////////////////////////////////////
        // 1. get windows, populate id_array
        /********************* select only valid ones!!! (monitor/workspace)************ */
        try {
            print("here we are\n");
            wins = client.get_winsdata();
            foreach (string k in wins.get_keys()) {
                Variant got_data = wins[k];
                string yay = (string)got_data.get_child_value(2);

                id_array += k;
                print(@"$k, $yay\n");
            }
        }
        catch (Error e) {
        }

        /////////////////////////////////////////////////////////////////////

        if (tiles != null) {
            string s1 = "";
            string s2 = "";
            string s3 = "";
            int x = 0;
            int y = 0;
            int width;
            int height;

            foreach (string k in tiles.get_keys()) {
                //print(@"$k\n");
                Variant var1 = tiles[k];
                VariantIter iter = var1.iterator ();
                iter.next("i", &x);
                iter.next("i", &y);
                iter.next("i", &width);
                iter.next("i", &height);
            }
        }



    }
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    public static void main(string[] args) {
        print("id please\n");

        try {
            client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon")
            );
            //  int cols = 2;
            //  int rows = 2;
            //  int left = 0;
            //  int right = 0;
            //  int top = 0;
            //  int bottom = 0;
            string[] arglist = {
                "--cols", "--rows", "--left", "--right", "--top", "--bottom"
            };
            int[] passedargs = {0, 0, 0, 0, 0, 0};
            int i = 0;
            foreach (string s in args) {
                int argindex = get_stringindex(s, arglist);
                if (argindex != -1 ) {
                    int fetch_arg = i+1;
                    if (fetch_arg < args.length) {
                        int val = int.parse(args[fetch_arg]);
                        passedargs[argindex] = val;
                    }
                    else {
                        print(@"missing value of: $s\n");
                    }
                }
                i += 1;
            }

            grid_allwindows({
                passedargs[0],
                passedargs[1],
                passedargs[2],
                passedargs[3],
                passedargs[4],
                passedargs[5]
            });
        }

        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

}