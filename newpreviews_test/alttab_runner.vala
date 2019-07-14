using Gtk;
using Cairo;
using Gdk;

// valac --pkg gtk+-3.0 --pkg gio-2.0 --pkg cairo --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE"

namespace NewPreviews {

    int currtilindex;
    int maxcol;
    Gtk.Button[] currbuttons;
    string user;
    File triggerdir;
    File triggernext;
    File triggerfile;
    File triggerprevious;
    bool ignore;
    PreviewsWindow showstuff;
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
        //convert the string to lowercase
        string hexdown = hex.down();
        //get the length of the hex string
        int hexlen = hex.length;
        int64 ret_val = 0;
        string chr;
        int chr_int;
        int multiplier;
        //loop through the string
        for (int i = 0; i < hexlen ; i++) {
            //get the string chars from right to left
            int inv = (hexlen-1)-i;
            chr = hexdown[inv:inv+1];
            chr_int = hexval(chr);
            //how are we going to multiply the current characters value?
            multiplier = 1;
            for(int j = 0 ; j < i ; j++) {
            multiplier *= 16;
            }
            ret_val += chr_int * multiplier;
        }
        return ret_val.to_string();
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



    public class PreviewsWindow : Gtk.Window {

        Grid maingrid;
        Grid currlast_startspacer;
        Grid[] subgrids;
        string[] win_workspaces;
       // Gtk.StyleContext stylecontext;
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
            .wsbutton {
              border-color: white;
              border-width: 0px;
              padding-left: 2px;
              padding-right: 2px;
            }
            .closebutton {
               border-width: 0px;
               padding: 3px;
            }
            .closebutton:hover {
               border-radius: 3px;
               padding: 3px;
                background-color: transparent;
            }
            .label {
              color: white;
              padding-bottom: 0px;
            }
            .labelbottom {
              color: white;
              padding: 0px;
            }
            """;

        public void actonbrowsetrigger () {
            if (triggernext.query_exists()) {
                currtilindex += 1;
                if (currtilindex == currbuttons.length) {
                    currtilindex = 0;
                }
                delete_file(triggernext);
                currbuttons[currtilindex].grab_focus();
            }
            else if (triggerprevious.query_exists()) {
                currtilindex -= 1;
                if (currtilindex < 0) {
                    currtilindex =  currbuttons.length - 1;
                }
                delete_file(triggerprevious);
                currbuttons[currtilindex].grab_focus();
            }
        }

        public PreviewsWindow () {
            this.set_decorated(false);
            monitor.changed.connect(actonbrowsetrigger);
            currbuttons = {};
            currtilindex = 0;
            // [1] set initial numbers cols/rows etc.
            int row = 1;
            int col = 0;
            // int maxcol = 5; // <- should depend on screen width
            // [2] whole bunch of styling
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
            // [3] create maingrid, you never know if we can use it...
            maingrid = new Gtk.Grid();
            maingrid.attach(new Label("\n"), 0, 0, 1, 1); /////////////////////////////////////////////////////////////////////// removed \t  -> naar box
            maingrid.attach(new Label("\n"), 100, 100, 1, 1); /////////////////////////////////////////////////////////////////////// removed \t -> naar box
            maingrid.set_column_spacing(20);
            maingrid.set_row_spacing(20);
            // [4] create arrays from dirlist -> window_id arr, path arr (which is dirlist), workspace arr
            string previewspath = "/tmp/".concat(user, "_window-previews"); // <- replace username!! ////////////////////////////////////////////////////////////// replace user
            string[] currpreviews = previews(previewspath); // < paths, read from directory
            num_ids_fromdir = {};
            foreach (string s in currpreviews) {
                string[] fname = s.split("/");
                string[] last_section = fname[fname.length - 1].split(".");
                string win_workspace = last_section[1];
                win_workspaces += win_workspace;
                string found_xid = last_section[0];
                num_ids_fromdir += hextoint(found_xid);
            }
            /*
            [5]
            [a] get windowstack.
            [b] get workspace
            Per window:
            [c] get xid, from that, index in currpreviews
                to look up img, path, workspace
            [d] get appicon, w_name
            [e] create buttongrid from ^
            [f] add to subgrid array
            */
            // [a] get windowstack
            z_list = scr.get_windows_stacked();
            // [b] get workspace
            int ws = -1;
            Wnck.Workspace curr = scr.get_active_workspace(); //.get_number();
            if (curr != null) {
                ws = curr.get_number();
            }
            foreach (Wnck.Window w in z_list) {
                if (w.get_window_type() == Wnck.WindowType.NORMAL) {
                    // [c]
                    string z_intid = w.get_xid().to_string();
                    int dirlistindex = get_stringindex(num_ids_fromdir, z_intid);
                    string img_path = currpreviews[dirlistindex]; // <
                    string window_on_workspace = win_workspaces[dirlistindex];
                    print(@"$z_intid, $dirlistindex, $img_path, on workspace: $window_on_workspace, currws: $ws\n");
                    // [d]
                    Pixbuf icon = w.get_mini_icon();
                    Image img = new Gtk.Image.from_pixbuf(icon); // <
                    string wname = w.get_name(); // < ellipsize in subgrid creator
                    // [e]
                    Grid newtile = makebuttongrid(img_path, img, wname, w);
                    // [f]
                    subgrids += newtile;
                }
            }
            // new: reverse buttons, don't forget to delete on closing tile
            Button[] reversed_buttons = {};
            int n_buttons = currbuttons.length;
            while (n_buttons > 0) {
                reversed_buttons += currbuttons[n_buttons - 1];
                n_buttons -= 1;
            }
            currbuttons = reversed_buttons;
            // [6] reverse order of tiles
            Grid[] reversed_tiles = {};
            int n_tiles = subgrids.length;
            while (n_tiles > 0) {
                reversed_tiles += subgrids[n_tiles-1];
                n_tiles -= 1;
            }
            // [7] add to maingrid
            // todo! add row-grid layer



////////////////////////////////////////////////////////////////////////////////////////////////////////////// edit: make Box, add spacer etx
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20); // firstbox
            box.pack_start(create_hspacer(), false, false, 0); // start spacer
            currlast_startspacer = create_hspacer();
            foreach (Grid g in reversed_tiles) {
                box.pack_start(g, false, false, 0);
                col += 1;
                if (col == maxcol) {
                    box.pack_start(create_hspacer(), false, false, 0); // end spacer previous one
                    maingrid.attach(box, 1, row, 1);
                    box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
                    currlast_startspacer = create_hspacer();
                    box.pack_start(currlast_startspacer, false, false, 0); // start spacer new one
                    row += 1;
                    col = 0;
                }
            }
            // add last box
            maingrid.attach(box, 1, row, 1);
            //print("col:" + col.to_string() + "\n");
            if (col != 0) {
                print("need to adapt\n");
                int tofix = maxcol - col;
                print(@"need to adapt, $tofix\n");
                int add = tofix * 300 / 2;
                currlast_startspacer.set_column_spacing (add);
            }

            this.title = "PreviewsWindow";
            this.add(maingrid);
        }

        private Grid create_hspacer(int extend = 0) {
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
            var newimage = new Gtk.Image.from_file(path);
            button.set_image(newimage);
        }

        private void remove_button (Button button) {
            Button[] newbuttons = {};
            foreach (Button b in currbuttons) {
                if (b != button) {
                    newbuttons += b;
                }
            }
            currbuttons = newbuttons;
        }

        private Grid makebuttongrid(
            string imgpath, Image appicon, string windowname, Wnck.Window w
            ) {

            string picspath = "/usr/share/budgie-desktop/plugins/budgie-wprviews/pics";
            var subgrid = new Gtk.Grid();
            subgrid.set_row_spacing(0);
            // window image button
            var button = new Gtk.Button();
            button.set_size_request(280, 180);
            var image = new Gtk.Image.from_file (imgpath); // < s
            button.set_image(image);
            var st_ct = button.get_style_context();
            st_ct.add_class("windowbutton");
            st_ct.remove_class("image-button");
            button.set_relief(Gtk.ReliefStyle.NONE);

            button.clicked.connect (() => {
                //raise_win(s);
                uint now = Gtk.get_current_event_time();
                w.activate(now);
                showstuff.destroy();
            });

            currbuttons += button;
            subgrid.attach(button, 0, 1, 1, 1);
            // box
            Gtk.Box actionbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            subgrid.attach(actionbar, 0, 0, 1, 1);
            // app icon
            actionbar.pack_start(appicon, false, false, 0); // < icon
            // window name
            Label wname = new Label(windowname); // < wname
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
            //////
            closebutton.enter_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat("/white2_x.png"));
                return false;
            });
            closebutton.leave_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat("/grey_x.png"));
                return false;
            });

            button.enter_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat("/white_x.png"));
                return false;
            });
            button.leave_notify_event.connect (() => {
                set_closebuttonimg(closebutton, picspath.concat("/grey_x.png"));
                return false;
            });
            actionbar.pack_end(closebutton, false, false, 0);
            closebutton.clicked.connect (() => {
                // remove Button -button- from buttons!
                remove_button(button);
                uint now = Gtk.get_current_event_time();
                w.close(now);
                subgrid.destroy();
                this.resize(100, 100);
                //this.set_position(Gtk.WindowPosition.CENTER);
            });
            return subgrid;
        }

    private string[] previews (string directory) {
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
        delete (main) triggerfile after it did its job, reset ignore
        (ignore is set true to prevent multiple previews while previews)
        window exists
        */
        delete_file(triggerfile);
        ignore = false;
    }

    private bool close_onrelease(Gdk.EventKey k) {
        // on releasing Alt_L, destroy previews, virtually click current button
        // (connect is gone with destroying previews window)
        print("release event\n");
        if (Gdk.keyval_name(k.keyval) == "Alt_L") {
            currbuttons[currtilindex].clicked();
        }
        return true;
    }

    private void actonfile() {
        // specifically acts on main triggerdir to create / destroy previews
        // next / previous is handled form window
        if (triggerfile.query_exists()) {
            if (!ignore) {
                showstuff = new PreviewsWindow();
                showstuff.destroy.connect(cleanup);
                showstuff.key_release_event.connect(close_onrelease);
                showstuff.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
                showstuff.show_all();
            }
            ignore = true;
        }
        else {
            showstuff.destroy();
            ignore = false;
        }
    }

    private void raise_previewswin(Wnck.Window newwin) {
        // make sure new previews window is activated on creation
        if (newwin.get_name() == "PreviewsWindow") {
            uint timestamp = Gtk.get_current_event_time();
            newwin.activate(timestamp);
        }
    }

    private void get_n_cols () {
        Gdk.Monitor prim = Gdk.Display.get_default().get_primary_monitor();
        var geo = prim.get_geometry();
        int width = geo.width;
        print(@"width: $width\n");
        maxcol = width / 360;
    }

    private void windowdeamon(string[]? args = null) {
        // This is the daemon from where the previews window rises
        // paths and stuff
        user = Environment.get_user_name();
        triggerdir = File.new_for_path("/tmp");
        triggerfile = File.new_for_path("/tmp/".concat(user, "_prvtrigger"));
        triggernext = File.new_for_path("/tmp/".concat(user, "_nexttrigger"));
        triggerprevious = File.new_for_path("/tmp/".concat(user, "_previoustrigger"));
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
        scr.window_opened.connect(raise_previewswin);
        // prevent cold start (no clue why, but it works)
        showstuff = new PreviewsWindow();
        showstuff.destroy();
        z_list = scr.get_windows_stacked();
        Gtk.main();
    }

    public static void main (string[] args) {
        NewPreviews.windowdeamon();
    }
}