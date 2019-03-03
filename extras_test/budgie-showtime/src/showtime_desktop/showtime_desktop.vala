using Gtk;
using Math;
using Cairo;

namespace ShowTimeLog {
        ///////////////////////////////////////////////////////////////////////////////////////
    /////

    public string create_dirs_file (string subpath, string filename) {
        // if needed, creates directory for logfile
        string homedir = Environment.get_home_dir();
        string fullpath = GLib.Path.build_path(
            GLib.Path.DIR_SEPARATOR_S, homedir, subpath, filename
        );
        GLib.File file = GLib.File.new_for_path(fullpath);
        try {
            file.make_directory_with_parents();
        }
        catch (Error e) {
            /* the directory exists, nothing to be done */
        }
        return GLib.Path.build_filename(fullpath, filename);
    }

    private string currtime() {
        // creates the timestamp for the log file
        var logtime = new DateTime.now_local();
        int hrs = logtime.get_hour();
        int mins = logtime.get_minute();
        string pre = "";
        if (mins < 10) {
            pre = "0";
        }
        return @"$hrs:$pre$mins";
    }


    private void update_log (
        string wtype, string output

        ) {
        // update log file
        string loglocation = create_dirs_file(".config/budgie-extras", "showtimelog");
        var logfile = File.new_for_path (loglocation);
        if (!logfile.query_exists ()) {
            var file_stream = logfile.create (FileCreateFlags.NONE);
        }
        var logtime = currtime();
        // read history
        string glue = "\n=\n";
        string file_contents;
        FileUtils.get_contents(loglocation, out file_contents);
        string[] records = file_contents.split(glue);
        int length = records.length;
        string[] keeprecords;
        if (length > 40) {
            keeprecords = records[length - 40:length];
        }
        else {keeprecords = records;}
        // add new record
        string log_output = "time: ".concat(
            logtime, "\n", wtype, " ", output, glue
        );
        keeprecords += log_output;
        string newlog = string.joinv(glue, keeprecords);
        // delete previous version
        if (logfile.query_exists ()) {
            logfile.delete ();
        }
        var file_stream = logfile.create (FileCreateFlags.NONE);
        var data_stream = new DataOutputStream (file_stream);
        data_stream.put_string (newlog);
    }

    /////
    ///////////////////////////////////////////////////////////////////////////////////////


}


namespace  ShowTime {

    private string timefontcolor;
    private string datefontcolor;
    private int linespacing;
    private Label timelabel;
    private Label datelabel;
    GLib.Settings showtime_settings;

    private class ShowTimeappearance {

        public void get_appearance (Gdk.Screen screen) {
            // get font properties: color
            timefontcolor = showtime_settings.get_string("timefontcolor");
            datefontcolor = showtime_settings.get_string("datefontcolor");
            // get font properties: font & size
            string timeprops = showtime_settings.get_string("timefont");
            string dateprops = showtime_settings.get_string("datefont");
            // set fonts
            var timefont = new Pango.FontDescription().from_string(timeprops);
            var datefont = new Pango.FontDescription().from_string(dateprops);
            Pango.Context t = timelabel.get_pango_context();
            Pango.Context d = datelabel.get_pango_context();
            t.set_font_description(timefont);
            d.set_font_description(datefont);
            timelabel.set_margin_end (10);
            get_spacing(screen);
        }

        public void get_spacing (Gdk.Screen screen) {
            string linespacing_css = """
            .linespacing {
              margin-bottom: <bspac>px;
            }
            """.replace( "<bspac>", linespacing.to_string());
            // set / update time label
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            timelabel.get_style_context().remove_class("linespacing");

            try {
                css_provider.load_from_data(linespacing_css);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
                timelabel.get_style_context().add_class("linespacing");
            }
            catch (Error e) {
                // not much to be done
                print("Error loading css data\n");
            }
        }

        public void get_hexcolor(
            string currtime, string currdate
        ) {
            timelabel.set_markup (
                "<span foreground=\"" +
                timefontcolor + "\">" + currtime +
                "</span>"
            );
            datelabel.set_markup (
                "<span foreground=\"" +
                datefontcolor + "\">" + currdate +
                "</span>"
            );
        }
    }

    public class TimeWindow : Gtk.Window {
        int next_time;
        bool twelvehrs;
        bool showdate;
        string dateformat;
        ShowTimeappearance appearance;
        bool skip_update;
        int root_x;
        int root_y;
        bool bypass;

        public TimeWindow () {
            // define stuff
            check_res();
            bypass = false;
            showtime_settings = new GLib.Settings(
                "org.ubuntubudgie.plugins.budgie-showtime"
            );
            dateformat = get_dateformat();
            appearance = new ShowTimeappearance();
            // window
            this.title = "Showtime";
            this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
            this.resizable = false;
            this.destroy.connect(Gtk.main_quit);
            this.set_decorated(false);
            screen = this.get_screen();
            var maingrid = new Grid();
            timelabel = new Label("");
            datelabel = new Label("");
            // position
            maingrid.attach(timelabel, 0, 0, 1, 1);
            maingrid.attach(datelabel, 0, 1, 1, 1);
            this.add(maingrid);
            string[] bind = {
                "leftalign", "showdate", "twelvehrs", "xposition",
                "yposition", "linespacing", "timefontcolor", "linespacing",
                "datefontcolor", "timefont", "datefont"
            };
            foreach (string s in bind) {
                showtime_settings.changed[s].connect(update_appearance);
            }
            showtime_settings.changed["draggable"].connect(update_positionsettings);
            update_appearance();
            appearance.get_appearance(screen);
            // surpass on initiation
            skip_update = true;
            update_positionsettings ();
            skip_update = false;
            // transparency
            this.set_app_paintable(true);
            var visual = screen.get_rgba_visual();
            this.set_visual(visual);
            this.draw.connect(on_draw);
            this.show_all();
            // set new x pos in gsettings if not anchor = se or sw
            showtime_settings.changed["leftalign"].connect(act_onalignment);
            // set signal on windowsize change
            this.configure_event.connect(setcondition);
            new_setwindowposition();
            update_interface();
            new Thread<bool> ("oldtimer", run_time);
        }

        private bool setcondition () {
            // act on window event
            bypass = !bypass;
            // -but not if the window is draggable...
            bool drag = showtime_settings.get_boolean("draggable");
            if (!bypass && !drag) {
                new_setwindowposition();
            }
            return false;
        }

        private bool get_leftalign () {
            return showtime_settings.get_boolean("leftalign");
        }

        private string get_anchor () {
            // check what should be the anchor, given cuurent settings
            int xpos = showtime_settings.get_int("xposition");
            int ypos = showtime_settings.get_int("yposition");
            if (ypos == -1) {
                if (xpos == 1) {
                    return "sw";
                }
                else if (xpos == 2) {
                    return "se";
                }
            }
            else {
                bool left = get_leftalign();
                if (left) {
                    return "nw";
                }
                else {
                    return "ne";
                }
            }
            return "";
        }

        private void act_onalignment () {
            // edit gsettings on xposition if ne or nw
            // no need for reposition, windowsize remains the same
            string newanchor = get_anchor();
            int currx = showtime_settings.get_int("xposition");
            if (newanchor == "ne") {
                currx = currx + get_windowsize()[0];
            }
            else if (newanchor == "nw") {
                currx = currx - get_windowsize()[0];
            }
            showtime_settings.set_int("xposition", currx);
        }

        private int[] get_windowsize () {
            int? width = null;
            int? height = null;
            while (width == null || height == null) {
                this.get_size (out width, out height);
            }
            return {width, height};
        }

        private void new_setwindowposition (int x = 0, int y = 0) {

            ShowTimeLog.update_log("walking in\n", "no data yet");

            int newx = 0;
            int newy = 0;
            string anchor = get_anchor();
            ShowTimeLog.update_log("anchor:", anchor);
            if (anchor != "nw") {
                // make sure the width / height are available
                if (x == 0 || y == 0) {
                    int[] winsize = get_windowsize();
                    x = winsize[0];
                    y = winsize[1];
                }
                if (anchor == "se") {
                    // get right/bottom
                    int [] scrdata = check_res();
                    int rightside = scrdata[0] + scrdata[2];
                    int downside = scrdata[1] + scrdata[3];
                    ShowTimeLog.update_log("screendata: ", @"$rightside, $downside");
                    //
                    newx = rightside - 150 - x;
                    newy = downside - 150 - y;
                }
                else if (anchor == "sw") {
                    int [] scrdata = check_res();
                    newx = scrdata[2] + 150;
                    int downside = scrdata[1] + scrdata[3];
                    newy = downside - 150 - y;
                }
                else if (anchor == "nw") {
                    newx = showtime_settings.get_int("xposition");
                    newy = showtime_settings.get_int("yposition");
                }
                else if (anchor == "ne") {
                    newx = showtime_settings.get_int("xposition") - x;
                    newy = showtime_settings.get_int("yposition");
                }
                ShowTimeLog.update_log("new position:", @"$newx, $newy");
                this.move(newx, newy);
            }
        }

        private int[] check_res() {
            // see what is the resolution on the primary monitor
            var prim = Gdk.Display.get_default().get_primary_monitor();
            var geo = prim.get_geometry();
            int width = geo.width;
            int height = geo.height;
            int screen_xpos = geo.x;
            int screen_ypos = geo.y;
            return {width, height, screen_xpos, screen_ypos};
        }

        private bool on_draw (Widget da, Context ctx) {
            // needs to be connected to transparency settings change
            ctx.set_source_rgba(0, 0, 0, 0);
            ctx.set_operator(Cairo.Operator.SOURCE);
            ctx.paint();
            ctx.set_operator(Cairo.Operator.OVER);
            return false;
        }

        private int get_stringindex (string[] arr, string lookfor) {
            // get index of string in list
            for (int i=0; i < arr.length; i++) {
                if(lookfor == arr[i]) return i;
            }
            return -1;
        }

        /* private string capitalize (string s) {
            string header = s.substring(0, 1).up();
            string remaining = s.substring(1, s.length - 1);
            return header.concat(remaining);
        } */

        private string fix_mins(int minutes) {
            // make sure the minutes are displayed in double digits
            string minsdisplay = minutes.to_string();
            if (minsdisplay.length == 1) {
                return "0".concat(minsdisplay);
            }
            return minsdisplay;
        }

        private string get_localtime (DateTime newtime) {
            int mins = newtime.get_minute();
            int hrs = newtime.get_hour();
            int newhrs = hrs;
            string add = "";
            string showmins = fix_mins(mins);
            // hrs to double digits
            if (twelvehrs) {
                add = " ".concat(_("AM"));
                if (hrs > 12) {newhrs = hrs - 12;}
                else if (hrs < 1) {newhrs = hrs + 12;}
                if (12 <= hrs < 24) {add = " ".concat(_("PM"));}
                return @"$newhrs:$showmins$add";
            }
            string hrs_display = fix_mins(newhrs);
            return @"$hrs_display:$showmins$add";
        }

        private string get_dateformat () {
            string date_fmt = showtime_settings.get_string("dateformat");
            if (date_fmt == "") {return read_dateformat();}
            return date_fmt;
        }

        private string read_dateformat () {
            string[] date_data = {
                "%a", "%A", "%-a", "%-A", "%_a", "%_A",
                "%e", "%-e", "%_e", "%d", "%-d", "%_d",
                "%b", "%-b", "%_b", "%h", "%-h", "%_h"
            };
            string[] full_data = {"%A", "%e", "%B"};
            string cmd = "locale date_fmt";
            string output = "";
            string match = "";
            try {
                StringBuilder builder = new StringBuilder ();
                GLib.Process.spawn_command_line_sync(cmd, out output);
                string[] output_data = output.split(" ");
                foreach (string s in output_data) {
                    int index = get_stringindex(date_data, s.replace(",", ""));
                    if (index != -1) {
                        int corr = (int)(index/6);
                        match = full_data[corr];
                        builder.append (match).append (" ");
                    }
                }
                return builder.str;
            }
            catch (Error e) {
                return "";
            }
        }

        private void update_positionsettings () {
            int add = 0;
            bool draggable = showtime_settings.get_boolean("draggable");
            if (draggable) {
                this.set_type_hint(Gdk.WindowTypeHint.NORMAL);
            }
            else if (!skip_update) {
                this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
                if (!get_leftalign()) {
                    add = get_windowsize()[0];
                }
                int newroot_x;
                int newroot_y;
                this.get_position (out newroot_x, out newroot_y);
                root_x = newroot_x + add;
                root_y = newroot_y;
                showtime_settings.set_int("xposition", root_x);
                showtime_settings.set_int("yposition", root_y);
            }
        }

        private void update_appearance () {
            // text align
            int al = 1;
            if (get_leftalign()) {al = 0;}
            timelabel.xalign = al;
            datelabel.xalign = al;
            // showdate
            linespacing = showtime_settings.get_int("linespacing");
            showdate = showtime_settings.get_boolean("showdate");
            twelvehrs = showtime_settings.get_boolean("twelvehrs");
            appearance.get_appearance(screen);
            update_interface();
        }

        private void update_interface () {
            var now = new DateTime.now_local();
            string datestring = now.format(dateformat);
            if (!showdate) {datestring = "";}
            appearance.get_hexcolor(get_localtime(now), datestring);
        }

        private bool check_onapplet () {
            // check if the applet still runs
            string cmd = "dconf dump /com/solus-project/budgie-panel/applets/";
            string output;
            try {
                GLib.Process.spawn_command_line_sync(cmd, out output);
            }
            // on an occasional exception, don't break the loop
            catch (SpawnError e) {
                return true;
            }
            bool check = output.contains("ShowTime");
            return check;
        }

        private int convert_remainder_topositive (double subj, double rem) {
            // Math.remainder possibly gives a negative output, seems silly
            if (rem < 0) {return (int)(subj + rem);}
            return (int)rem;
        }

        private int[] calibrate_time () {
            /*
            the cycle is double-layered: once per 6 seconds, there is a
            dconf check to see if the applet is still on the panel
            (kill the thread & window if not), once per minute fine-
            tune the minute-sync. On startup, we need to synchroonize
            the cycle so that time update is done exactly on minute-
            switch. additionally, once per minute we sync with real clock
             */
            var curr_time = new DateTime.now_local();
            int curr_sec = curr_time.get_second();
            int curr_remaining = convert_remainder_topositive(
                6, Math.remainder (60 - (double)curr_sec, 6)
            );
            int remaining_cycles = (int)((60 - curr_sec) / 6);
            return {curr_remaining, remaining_cycles};
        }

        private bool run_time () {
            // make sure time shows instantly
            //update_interface();
            calibrate_time();
            // this is the main time-loop
            int[] calibrated_loopdata = calibrate_time();
            int loopcycle = 0;
            while (true) {
                if (!check_onapplet()) {
                    // exiting if applet is removed
                    Gtk.main_quit();
                    break;
                }
                if (loopcycle == 0){
                    next_time = calibrated_loopdata[0];
                }
                if (loopcycle >= calibrated_loopdata[1]) {
                    calibrated_loopdata = calibrate_time();
                    loopcycle = 0;
                    Idle.add ( () => {
                        update_interface();
                        return false;
                    });
                }
                loopcycle += 1;
                Thread.usleep(next_time * 1000000);
                next_time = 6;
            }
            return false;
        }
    }

    public static void main (string[] args) {
        Gtk.init(ref args);
        new TimeWindow();
        Gtk.main();
    }
}