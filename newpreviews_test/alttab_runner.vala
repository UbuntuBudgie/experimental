using Gtk;
using Cairo;
using Gdk;
using Gdk.X11;
using X11;


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

// valac --pkg gtk+-3.0 --pkg gio-2.0 --pkg cairo --pkg gdk-x11-3.0 --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE"


namespace NewPreviews {

    int currtilindex;
    bool no_windows;
    int currws;
    int maxcol;
    bool allworkspaces;
    bool allapps;
    Gtk.Button[] currbuttons;
    string user;
    File triggerdir;
    File nexttrigger;
    File allappstrigger;
    File previoustrigger;
    File triggercurrent;
    bool ignore;
    string filepath;
    PreviewsWindow previews_window;
    string[] num_ids_fromdir;
    FileMonitor monitor;
    unowned Wnck.Screen scr;
    unowned GLib.List<Wnck.Window> z_list;

    private int get_stringindex (string[] arr, string lookfor) {
        // get index of string in list
        for (int i=0; i < arr.length; i++) {
            if(lookfor == arr[i]) return i;
        }
        return -1;
    }

    public int hexval( string c ) {
        // (helper of hextoint)
        switch(c) {
            case "a":
            return 10;
            case "b":
            return 11;
            case "c":
            return 12;
            case "d":
            return 13;
            case "e":
            return 14;
            case "f":
            return 15;
            default:
            return int.parse(c);
        }
    }

    private string hextoint(string hex){
        // convert from hex to int
        // convert the string to lowercase
        string hexdown = hex.down();
        // get the length of the hex string
        int hexlen = hex.length;
        int64 ret_val = 0;
        string chr;
        int chr_int;
        int multiplier;
        // loop through the string
        for (int i = 0; i < hexlen ; i++) {
            // get the string chars from right to left
            int inv = (hexlen-1)-i;
            chr = hexdown[inv:inv+1];
            chr_int = hexval(chr);
            // how are we going to multiply the current characters value?
            multiplier = 1;
            for(int j = 0 ; j < i ; j++) {
            multiplier *= 16;
            }
            ret_val += chr_int * multiplier;
        }
        return ret_val.to_string();
    }


    public class PreviewsWindow : Gtk.Window {

        Grid maingrid;
        Grid currlast_startspacer;
        Grid[] subgrids;
        string[] win_workspaces;

        string newpv_css = """
            .windowbutton {
              border-width: 2px;
              border-color: #5A5A5A;
              background-color: transparent;
              padding: 4px;
              border-radius: 1px;
              -gtk-icon-effect: none;
              border-style: solid;
            }
            .windowbutton:hover {
              border-color: #E6E6E6;
              background-color: transparent;
              border-width: 1px;
              padding: 6px;
              border-radius: 1px;
              border-style: solid;
            }
            .windowbutton:focus {
              border-color: white;
              background-color: transparent;
              border-width: 2px;
              padding: 3px;
            }
            .label {
              color: white;
              padding-bottom: 0px;
            }
            """;

        public void actonbrowsetrigger () {
            // browse through tiles -only works if prv window exists-
            if (nexttrigger.query_exists()) {
                currtilindex += 1;
                if (currtilindex == currbuttons.length) {
                    currtilindex = 0;
                }
                delete_file(nexttrigger);
                currbuttons[currtilindex].grab_focus();
            }
            else if (previoustrigger.query_exists()) {
                currtilindex -= 1;
                if (currtilindex < 0) {
                    currtilindex =  currbuttons.length - 1;
                }
                delete_file(previoustrigger);
                currbuttons[currtilindex].grab_focus();
            }
        }

        public PreviewsWindow () {
            // if nothing to show
            no_windows = true;
            this.set_default_size(200, 150);
            this.set_decorated(false);
            this.set_keep_above(true);
            this.set_skip_taskbar_hint(true);
            monitor.changed.connect(actonbrowsetrigger);
            currbuttons = {};
            currtilindex = 0;
            // set initial numbers cols/rows etc.
            int row = 1;
            int col = 0;
            // whole bunch of styling
            var screen = this.get_screen();
            this.set_app_paintable(true);
            var visual = screen.get_rgba_visual();
            this.set_visual(visual);
            this.draw.connect(on_draw);
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(newpv_css);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
            }
            catch (Error e) {
            }
            // create maingrid
            maingrid = new Gtk.Grid();
            maingrid.attach(new Label(""), 0, 0, 1, 1);
            maingrid.attach(new Label("\n"), 100, 100, 1, 1);
            maingrid.set_column_spacing(20);
            maingrid.set_row_spacing(20);
            // create arrays from dirlist -> window_id arr, path arr (which is dirlist), workspace arr
            string previewspath = "/tmp/".concat(user, "_window-previews");
            string[] currpreviews = previews(previewspath);
            num_ids_fromdir = {};
            foreach (string s in currpreviews) {
                string[] fname = s.split("/");
                string[] last_section = fname[fname.length - 1].split(".");
                string win_workspace = last_section[1];
                win_workspaces += win_workspace;
                string found_xid = last_section[0];
                num_ids_fromdir += hextoint(found_xid);
            }

            z_list = scr.get_windows_stacked();
            Wnck.ClassGroup wm_class = scr.get_active_window().get_class_group();

            foreach (Wnck.Window w in z_list) {
                if (w.get_window_type() == Wnck.WindowType.NORMAL) {
                    string z_intid = w.get_xid().to_string();
                    int dirlistindex = get_stringindex(num_ids_fromdir, z_intid);
                    int window_on_workspace = int.parse(
                        win_workspaces[dirlistindex]
                    );
                    /*
                    optionally filter out only windows on current workspace
                    and/or only current application
                    */
                    if (
                        filter_workspace(window_on_workspace, currws) &&
                        filter_wmclass(w, wm_class)
                    ) {
                        no_windows = false;
                        string img_path = currpreviews[dirlistindex];
                        Pixbuf icon = w.get_mini_icon();
                        Image img = new Gtk.Image.from_pixbuf(icon);
                        string wname = w.get_name();
                        Grid newtile = makebuttongrid(img_path, img, wname, w);
                        subgrids += newtile;
                    }
                }
            }
            // reverse buttons
            Button[] reversed_buttons = {};
            int n_buttons = currbuttons.length;
            while (n_buttons > 0) {
                reversed_buttons += currbuttons[n_buttons - 1];
                n_buttons -= 1;
            }
            currbuttons = reversed_buttons;
            // reverse order of tiles
            Grid[] reversed_tiles = {};
            int n_tiles = subgrids.length;
            while (n_tiles > 0) {
                reversed_tiles += subgrids[n_tiles-1];
                n_tiles -= 1;
            }
            // firstbox / row
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
            // start spacer
            box.pack_start(create_hspacer(), false, false, 0);
            currlast_startspacer = create_hspacer();
            foreach (Grid g in reversed_tiles) {
                box.pack_start(g, false, false, 0);
                col += 1;
                if (col == maxcol) {
                    // end spacer previous one
                    box.pack_start(create_hspacer(), false, false, 0);
                    maingrid.attach(box, 1, row, 1);
                    box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
                    currlast_startspacer = create_hspacer();
                    // start spacer new one
                    box.pack_start(currlast_startspacer, false, false, 0);
                    row += 1;
                    col = 0;
                }
            }
            // add last box, align (tile width = 300px)
            box.pack_start(create_hspacer(), false, false, 0);
            maingrid.attach(box, 1, row, 1);
            if (col != 0) {
                int tofix = maxcol - col;
                int add = tofix * 300 / 2;
                currlast_startspacer.set_column_spacing (add);
            }
            this.title = "PreviewsWindow";
            this.add(maingrid);
        }

        private bool filter_wmclass (Wnck.Window w, Wnck.ClassGroup wm_class) {
            // if set, only allow current wm_class
            if (allapps) {
                return true;
            }
            else {
                Wnck.ClassGroup group = w.get_class_group();
                if (group == wm_class) {
                    return true;
                }
                return false;
            }
        }

        private bool filter_workspace (int windowspace, int currspace) {
            // check windows on workspace if set in gsettings
            if (allworkspaces) {
                return true;
            }
            else {
                if (windowspace == currspace) {
                    return true;
                }
                return false;
            }
        }
        private Grid create_hspacer(int extend = 0) {
            /*
            last row needs to be positioned, add to all boxes,
            only set width > 0 on the last
            */
            var spacegrid = new Gtk.Grid();
            spacegrid.attach(new Gtk.Grid(), 0, 0, 1, 1);
            spacegrid.attach(new Gtk.Grid(), 1, 0, 1, 1);
            spacegrid.set_column_spacing(extend);
            return spacegrid;
        }

        private bool on_draw (Widget da, Context ctx) {
            // needs to be connected to transparency settings change
            ctx.set_source_rgba(0.15, 0.15, 0.15, 0.85);
            ctx.set_operator(Cairo.Operator.SOURCE);
            ctx.paint();
            ctx.set_operator(Cairo.Operator.OVER);
            return false;
        }

        private void set_closebuttonimg(Button button, string path) {
            // we don't like repeating
            var newimage = new Gtk.Image.from_file(path);
            button.set_image(newimage);
        }

        private void remove_button (Button button) {
            /*
            remove a button from the array of buttons
            to prevent browse errors
            */
            Button[] newbuttons = {};
            foreach (Button b in currbuttons) {
                if (b != button) {
                    newbuttons += b;
                }
            }
            currbuttons = newbuttons;
        }

        /*
        private uint get_now () {
            return 0;
        }
        */

        private Grid makebuttongrid(
            string imgpath, Image appicon, string windowname, Wnck.Window w
            ) {
            string picspath = filepath.concat("/pics");
            var subgrid = new Gtk.Grid();
            subgrid.set_row_spacing(0);
            // window image button
            var button = new Gtk.Button();
            button.set_size_request(280, 180);
            var image = new Gtk.Image.from_file (imgpath);
            button.set_image(image);
            var st_ct = button.get_style_context();
            st_ct.add_class("windowbutton");
            st_ct.remove_class("image-button");
            button.set_relief(Gtk.ReliefStyle.NONE);
            button.clicked.connect (() => {
                //raise_win(s);
                uint now = Gtk.get_current_event_time();
                // uint now =
                // uint now = get_now();
                w.activate(now);
                previews_window.destroy();
            });
            currbuttons += button;
            subgrid.attach(button, 0, 1, 1, 1);
            // box
            Gtk.Box actionbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            subgrid.attach(actionbar, 0, 0, 1, 1);
            // app icon
            actionbar.pack_start(appicon, false, false, 0);
            // window name
            Label wname = new Label(windowname);
            wname.set_ellipsize(Pango.EllipsizeMode.END);
            wname.set_max_width_chars(22);
            var label_ct = wname.get_style_context();
            label_ct.add_class("label");
            actionbar.pack_start(wname, false, false, 10);
            // close X button
            var closebutton = new Gtk.Button();
            set_closebuttonimg(closebutton, picspath.concat("/grey_x.png"));
            closebutton.set_relief(Gtk.ReliefStyle.NONE);
            closebutton.set_can_focus(false);
            closebutton.enter_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat(
                    "/white2_x.png"
                ));
                return false;
            });
            closebutton.leave_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat(
                    "/grey_x.png"
                ));
                return false;
            });

            button.enter_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat(
                    "/white_x.png"
                ));
                return false;
            });
            button.leave_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat(
                    "/grey_x.png"
                ));
                return false;
            });
            actionbar.pack_end(closebutton, false, false, 0);
            closebutton.clicked.connect (() => {
                // remove Button -button- from buttons!
                uint now = Gtk.get_current_event_time();
                w.close(now);
                if (currbuttons.length == 1) {
                    this.destroy();
                }
                else {
                    remove_button(button);
                    subgrid.set_sensitive(false);
                    currtilindex = 0;
                    this.resize(100, 100);
                }
            });
            return subgrid;
        }

    private string[] previews (string directory) {
        // list the created preview images
        string[] somestrings = {};
        try {
            var dr = Dir.open(directory);
            string ? filename = null;
            while ((filename = dr.read_name()) != null) {
                string addpic = GLib.Path.build_filename(directory, filename);
                somestrings += addpic;
            }
        }
        catch (FileError err) {
                stderr.printf(err.message);
        }
        return somestrings;
    }
}

    private void delete_file (File file) {
        try {
            file.delete();
        }
        catch (Error e) {
        }
    }

    private void cleanup () {
        /*
        delete triggers after they did their job, reset -ignore-
        (ignore is set true to prevent multiple previews while previews)
        window exists
        */
        delete_file(allappstrigger);
        delete_file(triggercurrent);
        ignore = false;
    }

    private bool close_onrelease(Gdk.EventKey k) {
        // on releasing Alt_L, destroy previews, virtually click current button
        // (connect is gone with destroying previews window)
        string key = Gdk.keyval_name(k.keyval);
        if (key == "Escape") {
            previews_window.destroy();
        }
        if (key == "Alt_L") {
            if (!no_windows) {
                currbuttons[currtilindex].clicked();
            }
            else {
                previews_window.destroy();
            }
        }
        return true;
    }

    private void raise_previewswin(Wnck.Window newwin) {
        // make sure new previews window is activated on creation
        if (newwin.get_name() == "PreviewsWindow") {
            uint timestamp = Gtk.get_current_event_time();
            newwin.activate(timestamp);
        }
    }

    private void get_n_cols () {
        // set number of columns, depending on screen width
        Gdk.Monitor prim = Gdk.Display.get_default().get_primary_monitor();
        var geo = prim.get_geometry();
        int width = geo.width;
        maxcol = width / 360;
    }

    private void update_currws () {
        // keep track of current workspace
        scr.force_update();
        var currspace = scr.get_active_workspace();
        unowned GLib.List<Wnck.Workspace> currspaces = scr.get_workspaces();
        int n = 0;
        foreach (Wnck.Workspace ws in currspaces) {
            if (ws == currspace) {
                currws = n;
                break;
            }
            n += 1;
        }
    }

    private void actonfile() {
        /*
        possible args, set here to decide action in the window:
        - "current" (show only current apps)
        - "previous" (go one tile reverse) <- handled from window

        [previews_triggers] first creates a trigger file -allappstrigger- if no arg is
        set, or -triggercurrent- if the arg "current" is set. this file will
        trigger the previews daemon to show previews of all apps or only current

        if the previews window exists however (and either one of the above
        triggers), this executabel creates an additional -nexttrigger- if not
        "previous" is set as arg, or -previoustrigger- if "previous" is set as arg
        */
        // optimize? -> file and event as args
        bool allapps_trigger = allappstrigger.query_exists();
        bool onlycurrent_trigger = triggercurrent.query_exists();
        if (
            allapps_trigger || onlycurrent_trigger
        ) {
            if (!ignore) {
                if (allapps_trigger) {
                    allapps = true;
                }
                else {
                    allapps = false;
                }
                previews_window = new PreviewsWindow();
                previews_window.destroy.connect(cleanup);
                previews_window.key_release_event.connect(close_onrelease);
                previews_window.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
                previews_window.show_all();
            }
            ignore = true;
        }
        else {
            previews_window.destroy();
            ignore = false;
        }
    }

    private string get_filepath (string arg) {
        // get path of current (executable) file
        string[] steps = arg.split("/");
        string[] trim_filename = steps[0:steps.length-1];
        return string.joinv("/", trim_filename);
    }

    private void windowdeamon(string[]? args = null) {

        filepath = get_filepath (args[0]);
        GLib.Settings previews_settings = new GLib.Settings(
            "org.ubuntubudgie.plugins.budgie-wpreviews"
        );
        allworkspaces = previews_settings.get_boolean("allworkspaces");
        previews_settings.changed.connect (() => {
            allworkspaces = previews_settings.get_boolean("allworkspaces");
        });
        user = Environment.get_user_name();
        triggerdir = File.new_for_path("/tmp");
        allappstrigger = File.new_for_path(
            "/tmp/".concat(user, "_prvtrigger_all")
        );
        nexttrigger = File.new_for_path(
            "/tmp/".concat(user, "_nexttrigger")
        );
        previoustrigger = File.new_for_path(
            "/tmp/".concat(user, "_previoustrigger")
        );
        triggercurrent = File.new_for_path(
            "/tmp/".concat(user, "_prvtrigger_current")
        );
        // start the loop
        Gtk.init(ref args);
        // monitoring files / dirs
        try {
            monitor = triggerdir.monitor(FileMonitorFlags.NONE, null);
            monitor.changed.connect(actonfile);
        }
        catch (Error e) {
        }
        // monitoring Screen & Display for n_columns
        var gdk_screen = Gdk.Screen.get_default();
        gdk_screen.monitors_changed.connect(get_n_cols);
        get_n_cols();
        // miscellaneous
        scr = Wnck.Screen.get_default();
        scr.active_workspace_changed.connect(update_currws);
        update_currws();
        scr.window_opened.connect(raise_previewswin);
        // prevent cold start (no clue why, but it works)
        previews_window = new PreviewsWindow();
        previews_window.destroy();
        z_list = scr.get_windows_stacked();
        Gtk.main();
    }

    public static void main (string[] args) {
        NewPreviews.windowdeamon(args);
    }
}