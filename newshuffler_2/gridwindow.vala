using Gtk;
using Cairo;
using Gdk;
using Gdk.X11;

//valac --pkg gdk-x11-3.0 --pkg gtk+-3.0 --pkg gdk-3.0 --pkg cairo --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE"

// N.B. Eventually, this Gtk thread runs as a daemon, waiting to show its window.
// N.B. Move functions to inside window-class, no reason for higher level.

namespace GridWindowSection {

    int gridcols;
    int gridrows;
    Gtk.Button[] buttonarr;
    int[] xpos;
    int[] ypos;
    int cols;
    int rows;
    Gtk.Grid buttongrid;
    ulong? previously_active;
    Wnck.Screen wnckscr;
    Gdk.X11.Window timestamp_window;

    ShufflerInfoClient client;
    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    interface ShufflerInfoClient : Object {
        public abstract GLib.HashTable<string, Variant> get_winsdata () throws Error;
        public abstract int getactivewin () throws Error;
        public abstract HashTable<string, Variant> get_tiles (string mon, int cols, int rows) throws Error;
        public abstract void move_window (int wid, int x, int y, int width, int height) throws Error;
        public abstract int get_yshift (int w_id) throws Error;
        public abstract string getactivemon_name () throws Error;
        public abstract int[] get_grid () throws Error;
        public abstract void set_grid (int cols, int rows) throws Error;
        public abstract bool swapgeo () throws Error;
        public abstract void show_tilepreview (int col, int row) throws Error;
        public abstract void kill_tilepreview () throws Error;
    }

    private void setup_client () {
        try {
            client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon")
            );
        }
        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    // ctx.set_source_rgba(0.0, 0.30, 0.50, 0.40);
    public class GridWindow: Gtk.Window {
        bool shiftispressed;
        Gtk.Grid maingrid;
        string gridcss = """
        .gridmanage {
            border-radius: 3px;
        }
        .gridmanage:hover {
            background-color: rgb(0, 77, 128);
        }
        .selected {
            background-color: rgb(0, 77, 128);
        }
        """;

        public GridWindow() {
            this.title = "Gridwindows";
            this.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
            this.enter_notify_event.connect(showquestionmark);
            this.key_press_event.connect(manage_keypress);
            this.key_release_event.connect(manage_keyrelease);
            // whole bunch of styling
            var screen = this.get_screen();
            this.set_app_paintable(true);
            var visual = screen.get_rgba_visual();
            this.set_visual(visual);
            this.draw.connect(on_draw);
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(gridcss);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
            }
            catch (Error e) {
            }
            // grid and stuff
            maingrid = new Gtk.Grid();
            maingrid.set_column_spacing(6);
            maingrid.set_row_spacing(6);
            this.add(maingrid);
            setgrid();
            //add_gridcontrols();
            maingrid.show_all();
            this.set_decorated(false);
            this.set_keep_above(true);
            this.show_all();
        }

        private bool manage_keyrelease (Gdk.EventKey key) {
            string released = Gdk.keyval_name(key.keyval);
            if (released.contains("Shift")) {
                shiftispressed = false;
                print(@"shift: $shiftispressed\n");
            }
            return false;
        }

        private bool manage_keypress (Gdk.EventKey key) {
            string pressed = Gdk.keyval_name(key.keyval);
            if (pressed.contains("Shift")) {
                shiftispressed = true;
                print(@"shift: $shiftispressed\n");
            }
            else {
                managegrid(pressed);
            }
            return false;
        }

        private bool showquestionmark () {
            //print("show help button\n");
            return false;
        }
        ///////////////////////////////////////////////////////////////
        private void showpreview (Button b) {
            int bindex = find_buttonindex(b);
            int col = xpos[bindex];
            int row = ypos[bindex];
            client.show_tilepreview(col, row);
        }

        private bool killpreview () {
            client.kill_tilepreview();
            return false;
        }
        ///////////////////////////////////////////////////////////////

        private bool managegrid (string pressed) {
            client.kill_tilepreview();
            //  string pressed = Gdk.keyval_name(key.keyval);
            int[] currgrid = client.get_grid();
            int currcols = currgrid[0];
            int currrows = currgrid[1];
            print(@"setting g grid, $pressed\n");
            switch (pressed) {
                case "Up":
                if (currrows > 1) {
                    gridrows = currrows - 1;
                }
                break;
                case "Down":
                if (currrows < 5) {
                    gridrows = currrows + 1;
                }
                break;
                case "Left":
                if (currcols > 1) {
                    gridcols = currcols - 1;
                }
                break;
                case "Right":
                if (currcols < 5) {
                    gridcols = currcols + 1;
                }
                break;
            }
            client.set_grid(gridcols, gridrows);
            buttongrid.destroy();
            setgrid();
            maingrid.show_all();
            return false;
        }

        private bool on_draw (Widget da, Context ctx) {
            // needs to be connected to transparency settings change
            ctx.set_source_rgba(0.15, 0.15, 0.15, 0.0);
            ctx.set_operator(Cairo.Operator.SOURCE);
            ctx.paint();
            ctx.set_operator(Cairo.Operator.OVER);
            return false;
        }

        private void setgrid() {
            buttongrid = new Gtk.Grid();
            buttongrid.set_column_spacing(3);
            buttongrid.set_row_spacing(3);
            maingrid.attach(buttongrid, 0, 0, 1, 1);
            for (int iy=0; iy < gridrows; iy++) {
                for (int ix=0; ix < gridcols; ix++) {
                    //  print(@"$ix, $iy, $gridcols, $gridrows\n");
                    var gridbutton = new Gtk.Button();
                    gridbutton.set_size_request(50, 50);
                    var st_gb = gridbutton.get_style_context();
                    st_gb.add_class("gridmanage");
                    buttongrid.attach(gridbutton, ix, iy, 1, 1);
                    xpos += ix;
                    ypos += iy;
                    buttonarr += gridbutton;
                    gridbutton.clicked.connect(show_pos);
                    gridbutton.enter_notify_event.connect(()=> {
                        showpreview(gridbutton);
                        return false;
                    });
                    gridbutton.leave_notify_event.connect(killpreview); //////////////////////////////////////
                    //  client.show_tilepreview();
                }
            }
        }

        //  private void add_gridcontrols () {
        //      // print("Adding comtrols\n");
        //      var horbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        //      //  horbox.set_baseline_position(Gtk.BaselinePosition.CENTER);
        //      maingrid.attach(horbox, 0, 1, 1, 1);

        //      var button_up = new Gtk.Button.from_icon_name(
        //          "pan-up-symbolic", Gtk.IconSize.MENU
        //      );
        //      var st_bu = button_up.get_style_context();
        //      st_bu.add_class("bottomright");

        //      var button_down = new Gtk.Button.from_icon_name(
        //          "pan-down-symbolic", Gtk.IconSize.MENU
        //      );
        //      var st_bd = button_down.get_style_context();
        //      st_bd.add_class("bottomleft");

        //      horbox.pack_end(button_up, false, false, 0);
        //      horbox.pack_end(button_down, false, false, 0);


        //      var vertbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        //      maingrid.attach(vertbox, 1, 0, 1, 1);

        //      var button_right = new Gtk.Button.from_icon_name(
        //          "pan-end-symbolic", Gtk.IconSize.MENU
        //      );
        //      var st_tr = button_right.get_style_context();
        //      st_tr.add_class("topright");

        //      var button_left = new Gtk.Button.from_icon_name(
        //          "pan-end-symbolic-rtl", Gtk.IconSize.MENU
        //      );
        //      var st_br = button_left.get_style_context();
        //      st_br.add_class("bottomright");

        //      vertbox.pack_end(button_left, false, false, 0);
        //      vertbox.pack_end(button_right, false, false, 0);

        //      Gtk.Button[] managebuttons = {
        //          button_left, button_right, button_up, button_down
        //      };

        //      //  foreach (Gtk.Button b in managebuttons) {
        //      //      var st_ct = b.get_style_context();
        //      //      st_ct.add_class("gridmanage");
        //      //  }
        //  }
    }

    private int find_buttonindex(Gtk.Button b) {
        int i = 0;
        foreach (Gtk.Button button in buttonarr) {
            if (button == b) {
                return i;
            }
            i += 1;
        }
        return -1;
    }

    private void manage_activebuttons (Gtk.Button b) {
        

    }

    private void show_pos (Gtk.Button b) {

        int index = find_buttonindex(b);
        if (index != -1 && previously_active != null) {
            int x = xpos[index];
            int y = ypos[index];
            print(@"$x, $y, $gridcols, $gridrows\n");
            string cm = "/home/jacob/Desktop/experisync/newshuffler_2/tile_active ".concat(
                @"$x $y $gridcols $gridrows ", "id=", @"$previously_active");
            print(@"$cm\n");
            Process.spawn_command_line_async(cm);
        }
    }
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
    private uint get_now () {
        // timestamp
        return Gdk.X11.get_server_time(timestamp_window);
    }

    private void set_this_active (string wname) {
        foreach (Wnck.Window w in wnckscr.get_windows()) {
            if (w.get_name() == wname) {
                w.activate(get_now());
                break;
            }
        }
    }

    private void get_subject () {
        Wnck.Window? curr_active = wnckscr.get_active_window();
        if (curr_active != null) {
            Wnck.WindowType type = curr_active.get_window_type ();
            string wname = curr_active.get_name();
            print(@"newname: $wname\n");
            if (
                wname != "tilingpreview" && 
                wname != "Gridwindows" && 
                type == Wnck.WindowType.NORMAL
                ) {
                previously_active = curr_active.get_xid();
            }
            set_this_active("Gridwindows");
        }
        // activate this, get now etc
        //curr_active.activate(get_now());
    }

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

    public static void main(string[] args) {

        setup_client();
        Gtk.init(ref args);
        wnckscr = Wnck.Screen.get_default();
        // X11 stuff, non-dynamic part
        unowned X.Window xwindow = Gdk.X11.get_default_root_xwindow();
        unowned X.Display xdisplay = Gdk.X11.get_default_xdisplay();
        Gdk.X11.Display display = Gdk.X11.Display.lookup_for_xdisplay(xdisplay);
        timestamp_window = new Gdk.X11.Window.foreign_for_display(display, xwindow);
        // get first previously active!!
        wnckscr.active_window_changed.connect(get_subject);
        wnckscr.force_update();
        // get initial subject on startup
        Wnck.Window? curr_active = wnckscr.get_active_window();
        if (curr_active != null) {
            previously_active = curr_active.get_xid();
        }
        int[] colsrows = client.get_grid();
        gridcols = colsrows[0];
        gridrows = colsrows[1];
        print(@"$gridcols, $gridrows\n");
        new GridWindow();
        Gtk.main();
    }
}