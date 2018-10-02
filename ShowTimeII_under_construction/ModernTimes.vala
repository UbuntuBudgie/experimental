using Gtk;

/* 
* ShowTimeII
* Author: Jacob Vlijm
* Copyright ©2017-2018 Ubuntu Budgie Developers
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


public class ModernTimes : Gtk.Window {

    private Label datelabel;
    private Label timelabel;
    bool twelve_hrs;
    private bool showtime;
    private bool showdate;
    private string css_template;
    private bool custom_pos;
    Thread<bool> test;



    public ModernTimes () {
        twelve_hrs = true;
        showtime = true;
        showdate = true;
        custom_pos = false;

        //data
        css_template = """
        .timelabel {
            font-size: bigfontpx;
            color: xxx-xxx-xxx;

        }
        .datelabel {
            font-size: smallfontpx;
            color: xxx-xxx-xxx;
        }
        """;

        // window 
        this.title = "Charlie Chaplin";
        this.destroy.connect(Gtk.main_quit);
        var maingrid = new Grid();
        timelabel = new Label("");
        timelabel.xalign = 1;
        datelabel = new Label("");
        datelabel.xalign = 1;
        maingrid.attach(timelabel, 0, 0, 1, 1);
        maingrid.attach(datelabel, 0, 1, 1, 1);
        //check environment
        check_res();
        this.add(maingrid);
        this.show_all();
        test = new Thread<bool>.try ("oldtimer", get_time);
    }

    private GLib.Settings get_settings(string path) {
        var settings = new GLib.Settings(path);
        return settings;
    }

    private void set_labelsize (int scale) {
        string[] color = {"0", "0", "0"};
        string temp_css = css_template.replace(
            "xxx-xxx-xxx", "rgb(".concat(string.joinv(", ", color), ")")
        );
        string bigfont = "20"; string smallfont = "15";
        switch(scale) {
            case(1): bigfont = "25"; smallfont = "17"; break;
            case(2): bigfont = "37"; smallfont = "22"; break;
            case(3): bigfont = "50"; smallfont = "32"; break;
        }
        string css = temp_css.replace(
            "bigfont", bigfont).replace("smallfont", smallfont
        ); 
        print(@"scale: $scale, css: $css\n");
    }
        

    private string get_months(int month) {
        string[] months = {
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        };
        return months[month - 1];
    }

    private void check_res() {
        /* see what is the resolution on the primary monitor */

        var prim = Gdk.Display.get_default().get_primary_monitor();
        var geo = prim.get_geometry();
        int height = geo.height;
        int width = geo.width;
        if (!custom_pos) {
            this.move(width - 400, height- 300);
        }
        int currscale;
        if (height < 1100) {currscale = 1;}
        else if (height < 1600) {currscale = 2;}
        else {currscale = 3;}

        set_labelsize(currscale);

        print(@"$width $height\n");
    }


    private string get_days(int day) {
        string[] days = {
            "Monday", "Tuesday", "Wednesday", 
            "Thursday", "Friday", "Saturday", "Sunday", 
        };
        return days[day - 1];
    }

    private string fix_mins(int minutes) {
        string minsdisplay = minutes.to_string();
        if (minsdisplay.length == 1) {
            return "0".concat(minsdisplay);
        }
        return minsdisplay;
    }

    private void set_timelabel(DateTime obj) {

        // timedisplay
        if (showtime) {
            int hrs = obj.get_hour();
            int mins = obj.get_minute();
            if (twelve_hrs) {
                convert_totwelve(hrs, mins);
            }
            else {
                string minsdisplay = fix_mins(mins);
                timelabel.set_text(@"$hrs:$minsdisplay");
            }
        }
        else {
            timelabel.set_text("");
        }
        // datedisplay
        if (showdate) {
            string month = get_months(obj.get_month());
            int monthday = obj.get_day_of_month();
            string day = get_days(obj.get_day_of_week());
            int year = obj.get_year();
            datelabel.set_text(@"$day, $monthday $month $year");
        }
    }

    private void convert_totwelve(int hrs, int mins) {
        string showmins = fix_mins(mins);
        int newhrs = hrs;
        string add = " ".concat("AM");
        if (twelve_hrs == true) {
            if (hrs > 12) {
                newhrs = hrs - 12;
            }
            else if (hrs < 1) {
                newhrs = hrs + 12;
            }
            if (12 <= hrs < 24) {
                add = " ".concat("PM");
            }
        }
        timelabel.set_text(@"$newhrs:$showmins $add");
    }

    public bool get_time() {
        while (true) {
            // get time obj
            var now = new DateTime.now_local();
            // get/set new time
            Idle.add ( () => {
                set_timelabel(now);
                return false;
            });
            // get time until next check
            int sec = now.get_second();
            int break_tonext = 61 - sec;
            print(@"$break_tonext\n");
            Thread.usleep(break_tonext * 1000000);
            // exit on removing applet
            /*if (<condition>) {
                print("exit\n");
                test.exit(true);
            }*/
        }
        
    }
}


public static void main(string[] args) {
    Gtk.init(ref args);
    new ModernTimes();
    Gtk.main();
}