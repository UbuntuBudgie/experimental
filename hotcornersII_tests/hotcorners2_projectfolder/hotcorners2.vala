using Gtk;
using Gdk;
using Math;
using Gee;

/* 
* HotCornersII
* Author: Jacob Vlijm
* Copyright © 2017-2018 Ubuntu Budgie Developers
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


namespace SharedFunctions {

    /*
    * Here we keep the (possibly) shared stuff 
    */

    public string[] getcommands() {
        
        /* 
        * reads the commands from the commands file
        * if it does not exist, fall back to defaults
        */

        string[] commands = {};
        var pathdata = new HashMap<string, string>();
        pathdata = get_path ("hotcorners", "hotc_commands");
        string path = pathdata.get ("file");
        var file = File.new_for_path(path);
        //string output = "";
        try {
            var content = new DataInputStream(file.read());
            string line;
            int i = 0;
            while (i < 4) {
                line = content.read_line();
                print(line + "\n");
                commands += line;
                i += 1;
            } 
        }
        /* in case the file is not found, fall back to default */
        catch (GLib.IOError err) {
            commands = {
                "false",
                "false",
                "false",
                "false",
            };
        }
        foreach (string add in commands) {
            print("here we go " + add + "\n");
        }
        return commands;
    }

    public HashMap get_path (string applet_name, string ? filename = null) {

        /*
        * given the applet settingsfolder name, tell the full path
        * also, if optional filename is used as second arg, tell the
        * full path to the file
        */
        
        var map = new HashMap<string, string> ();
        string home = Environment.get_home_dir();
        string extras = Path.build_filename(
            home, ".config/budgie-extras", applet_name
        );

        map.set("appsettings", extras);

        if (filename != null) {
            string filepath = Path.build_filename(
                extras, filename
            );
            map.set("file", filepath);
        }
        else {
            map.set("file", "");
        }
        return map;
    }
}

public class WatchCorners : Gtk.Window {

    /* process stuff */
    private int action_area;
    private int[] x_arr;
    private int[] y_arr;
    private int pressure;
    private int time_steps;
    private string[] commands;
    private bool runloop;
    /* GUI stuff */
    private Grid maingrid;
    private Entry[] entries;
    private ToggleButton[] buttons;
    private CheckButton[] cbuttons;
    //private Array[,] defaults;

    public void button_action() {
        this.runloop = false;
        GLib.Timeout.add (200, () => {
            print("restarting HotCorners...");
            return false;
        });
        this.runloop = true;
        testmain();
    }

    /* below is the actual applet popup section */
    public void managewindow(string[] ? args = null) {
        this.title = "HotCorners Settings";
        maingrid = new Grid();
        maingrid.set_row_spacing(7);
        maingrid.set_column_spacing(7);
        this.add(maingrid);

        string[] namelist = {
            "Top-left", "Top-right", "Bottom-left", "Bottom-right"
        };

        /* now we have a default list */
        int y_pos = 0;

        foreach (string name in namelist) {
            print(name + "\n");
            ToggleButton latest = new ToggleButton.with_label(name);
            buttons += latest;
            maingrid.attach(latest, 0, y_pos, 1, 1);
            latest.toggled.connect(toggle_corner);
            Entry latest_entry = new Entry();
            entries += latest_entry;
            maingrid.attach(latest_entry, 1, y_pos, 1, 1);
            var spacer = new Label(" ");
            maingrid.attach(spacer, 2, y_pos, 1, 1);
            var spacer2 = new Label(" ");
            maingrid.attach(spacer2, 4, y_pos, 1, 1);
            CheckButton latest_check = new CheckButton();
            cbuttons += latest_check;
            maingrid.attach(latest_check, 3, y_pos, 1, 1);
            y_pos += 1;
            print(@"$y_pos\n");
        }
        this.show_all();
        this.runloop = true;
        testmain();
        Gtk.main();
    }

    void toggle_corner(ToggleButton button) {
        bool active = button.get_active();
        if (active) { 
            stdout.printf("Set active" + "\n"); 
        }
        else { 
            stdout.printf("Set inactive" + "\n"); 
        }            
        int buttonindex = array_search(button, this.buttons);
        Entry corr_entry = this.entries[buttonindex];
        string corr_entrytext = corr_entry.get_text();
        stdout.printf("Entrytext: " + corr_entrytext + "\n");
        string showindex = buttonindex.to_string();
        stdout.printf("button / entry index: " + showindex + "\n\n");
    }

    int array_search(ToggleButton currbutton, ToggleButton[] array) {
        int result = -1;
        for (int i=0; i < array.length; i++) {
            if(currbutton == array[i]) return i;
        }
        return result;
    }

    /* see what is the resolution on the primary monitor */
    public int[] check_res() {
        var prim = Gdk.Display.get_default().get_primary_monitor();
        var geo = prim.get_geometry();
        int width = geo.width;
        int height = geo.height;
        return {width, height};
    }

    /* the last <lastn> positions will be kept in mind, to decide on pressure */
    public int[] keepsection(int[] arr_in, int lastn) {
        /* equivalent to list[index:] */
        int[] temparr = {};
        int currlen = arr_in.length;
        if (currlen > lastn) {
            int remove = currlen - lastn;
            temparr = arr_in[remove:currlen];
            return temparr;
        }
        return arr_in;    
    }

    /* see if we are in a corner, if so, which one */
    public int check_corner(int xres, int yres, Seat seat) {
        int x;
        int y;
        seat.get_pointer().get_position(null, out x, out y);
        /* add coords to array, edit array */
        this.x_arr += x;
        this.x_arr = keepsection(this.x_arr, this.time_steps);
        this.y_arr += y;
        this.y_arr = keepsection(this.y_arr, this.time_steps);
        int n = -1;
        bool[] tests = {
            (x < this.action_area && y < this.action_area),
            (x > xres - this.action_area && y < this.action_area),
            (x < this.action_area && y > yres - this.action_area),
            (x > xres - this.action_area && y > yres - this.action_area),
        };
        foreach (bool test in tests) {
            n += 1;
            if (test == true) {
                return n;
            }
        }
        return -1;
    }

    /* decide if the pressure is enough */
    private bool decide_onpressure () {
        double x_travel = Math.pow(
            this.x_arr[0] - this.x_arr[this.time_steps - 1], 2
        );
        double y_travel = Math.pow(
            this.y_arr[0] - this.y_arr[this.time_steps - 1], 2
        );
        double travel = Math.pow(x_travel + y_travel, 0.5);
        if (travel > this.pressure) {
            return true;
        }
        else {
            return false;
        }
    }

    /* execute the command */
    public void run_command (int corner) {
        string cmd = this.commands[corner];
        if (cmd != "false") {
            // print("this is 2" + this.commands[corner]+ "\n");
            try {
                Process.spawn_command_line_async(cmd);
            }
            catch (GLib.SpawnError err) {
                /* 
                * in case an error occurs, the command most likely is
                * incorrect not much use for any action
                */
            }
        }
    }
  
    public int testmain(string[] ? args = null) {
        print("running\n");

        this.commands = SharedFunctions.getcommands();
        /* print(found_commands + "\n"); */
        Gdk.init(ref args);
        Gdk.Seat seat = Gdk.Display.get_default().get_default_seat();
        int[] res = check_res();
        /* here we set the size of the array (20 = 1 sec.) */
        this.action_area = 5;
        /* here we set the min distance in last <time_steps> steps */
        this.pressure = 150;
        /* here we set the time steps (size of array, 20 = last 1 second) */
        this.time_steps = 3;
        this.x_arr = {0};
        this.y_arr = {0};
        int xres = res[0];
        int yres = res[1];
        bool reported = false;

        GLib.Timeout.add (50, () => {
            //stdout.printf(show + "\n");
            int corner = check_corner(xres, yres, seat);
            if (corner != -1 && reported == false) {
                if (decide_onpressure() == true) {
                    run_command(corner);
                    reported = true;
                }
            }
            else if (corner == -1) {
                reported = false;
            }
            return this.runloop;
        });
        return 0;
    }
}

public static int main(string[] args) {
    Gtk.init(ref args);
    var instance = new WatchCorners();
    instance.managewindow();
    return 0;
}

