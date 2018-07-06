using Gtk;
using Gdk;
using Math;
using BudgieExtrasLib;

public class WatchCorners {

    /* corner size */
    int action_area;
    int[] x_arr;
    int[] y_arr;
    int pressure;
    int time_steps;
    string[] commands;

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

        this.commands = getcommands();
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
        /* get commands from file */
        /* this.commands = {
            "gedit monkey", "toggle raven", "tilix", "false",
        }; */
        while (true) {
            /* 1000000 = 1 sec */
            Thread.usleep(50000);
            int corner = check_corner(xres, yres, seat);
            if (corner != -1 && reported == false) {
                if (decide_onpressure() == true) {
                    run_command(corner);
                    // print(@"$corner\n");
                    reported = true;
                }
            }
            else if (corner == -1) {
                reported = false;
            }
        }
    }
}

public static int main(string[] args) {
    var instance = new WatchCorners();
    instance.testmain();
    return 0;
}

