// valac --pkg gio-2.0 --pkg gtk+-3.0 --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE"
// add active window!
// check n-windows! (accumulation?)

/*
/ - monitordata is auto-updated
/
*/


namespace ShufflerEssentialInfo {

    // monitordata-dict
    HashTable<string, Variant> monitorgeo;
    // windowdata-dict
    HashTable<string, Variant> window_essentials;
    // misc.
    unowned Wnck.Screen wnckscr;
    Gdk.Display gdkdisplay;
    // windows-list
    // unowned GLib.List<Wnck.Window> wlist;
    // n-monitors
    int n_monitors;
    // scale
    int scale;

    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    public class ShufflerInfoServer : Object {
    ////////////////////////////////////////// dbus public functions

        public int getactivewin () {
            int activewin;
            Wnck.Window? curr_activewin = wnckscr.get_active_window();
            if (curr_activewin != null) {
                activewin = (int)curr_activewin.get_xid();
            }
            else {
                activewin = -1;
            }
            print(@"activewin: $activewin\n");
            return activewin;
        }

        public HashTable<string, Variant> get_winsdata () throws Error {
            // window data
            get_windata();
            return window_essentials;
        }

        public void move_window (int w_id, int x, int y, int width, int height) {
            print("whaaat \n");
            //  use_animation(w_id, true);
            unowned GLib.List<Wnck.Window> wlist = wnckscr.get_windows();
            foreach (Wnck.Window w in wlist) {
                if (w.get_xid() == w_id) {
                    now_move(w, x, y, width, height);
                }
            }
            //  use_animation(w_id, false);
        }

        private void now_move (Wnck.Window tomove, int x, int y, int width, int height) {
            tomove.unmaximize();
            tomove.set_geometry(
                Wnck.WindowGravity.NORTHWEST,
                Wnck.WindowMoveResizeMask.X |
                Wnck.WindowMoveResizeMask.Y |
                Wnck.WindowMoveResizeMask.WIDTH |
                Wnck.WindowMoveResizeMask.HEIGHT,
                x, y, width, height
            );
        }

        private void get_windata() {
            /*
            / maintaining function
            / get windowlist, per window:
            / xid = key, name, onthisworspace, monitor-of window, geometry
            */
            var winsdata = new HashTable<string, Variant> (str_hash, str_equal);
            unowned GLib.List<Wnck.Window> wlist = wnckscr.get_windows();
            // gdkdisp.error_trap_push(); ///////////////////////////////////////////////////////
            foreach (Wnck.Window w in wlist) {
                Wnck.WindowType type = w.get_window_type ();
                if (type == Wnck.WindowType.NORMAL) {
                    string name = w.get_name(); // needed?
                    bool onthisws = wnckscr.get_active_workspace() == w.get_workspace ();
                    int x;
                    int y;
                    int width;
                    int height;
                    w.get_geometry(out x, out y, out width, out height);
                    string winsmonitor = gdkdisplay.get_monitor_at_point(
                        (int)(x/scale), (int)(y/scale)
                    ).get_model();
                    ulong xid = w.get_xid();
                    Variant windowdata = new Variant(
                        "(sssiiii)", name, @"$onthisws", winsmonitor,
                        x, y, width, height
                    );
                    winsdata.insert(@"$xid", windowdata);
                }
            }
            window_essentials = winsdata;
            print("updated\n");
        }

        public HashTable<string, Variant> get_tiles (string mon_name, int cols, int rows) {
            var tiledata = new HashTable<string, Variant> (str_hash, str_equal);
            int[] xpositions = {};
            int[] ypositions = {};
            int[] widths = {};
            int[] heights = {};
            for (int i=0; i < n_monitors; i++) {
                Gdk.Monitor monitorsubj = gdkdisplay.get_monitor(i);
                if (monitorsubj.get_model()  == mon_name) {
                    Gdk.Rectangle mon_wa = monitorsubj.get_workarea();
                    int fullwidth = mon_wa.width * scale;
                    int tilewidth = (int)(fullwidth/cols);

                    int fullheight = mon_wa.height * scale;
                    int tileheight = (int)(fullheight/rows);

                    print(@"winwidth: $tilewidth\n");
                    print(monitorsubj.get_model() + "<-- here we are\n");

                    int NEx = mon_wa.x * scale;
                    int origx = NEx;
                    //  int i_tile = 0;
                    while (NEx < origx + fullwidth) {
                        xpositions += NEx;
                        print(@"NEx: $NEx\n");
                        NEx += tilewidth;
                    }

                    int NEy = mon_wa.y * scale;
                    int origy = NEy;
                    while (NEy < origy + fullheight) {
                        ypositions += NEy;
                        print(@"NEy: $NEy\n");
                        NEy += tileheight;
                    }
                    // now create tiles
                    //  var tiledata = new HashTable<string, Variant> (str_hash, str_equal);
                    print("\nnow sum up: \n");
                    int col = 0;

                    foreach (int nx in xpositions) {
                        int row = 0;
                        foreach (int ny in ypositions) {
                            // add this to variant ($col*$row = key)
                            print(@"$col*$row, $nx, $ny\n");

                            Variant newtile = new Variant(
                                "(iiii)", nx, ny, tilewidth, tileheight
                            );
                            print(@"from daemon: $nx, $ny, $tilewidth, $tileheight\n");
                            tiledata.insert(@"$col*$row", newtile);


                            row += 1;
                        }
                        col += 1;
                    }
                }
            }
            // should return
            return tiledata;
        }

        //  private void use_animation (int w_id, bool hide) {
        //      print("whaaat 1\n");
        //      string cmd = "";
        //      if (hide) {

        //          GLib.Timeout.add( 0, ()=> {
        //              cmd = "xdotool windowminimize ".concat(@"$w_id");
        //              GLib.Process.spawn_command_line_sync(cmd);
        //              return false;
        //          });


        //          //cmd = "xdotool windowminimize ".concat(@"$w_id");
        //      }
        //      else {
        //          GLib.Timeout.add( 500, ()=> {
        //              cmd = "xdotool windowactivate ".concat(@"$w_id");
        //              print("whaaat 2\n");
        //              GLib.Process.spawn_command_line_sync(cmd);
        //              return false;
        //          });

        //      }
        //      try {
        //          //GLib.Process.spawn_command_line_sync(cmd);
        //      }
        //      catch (SpawnError e) {
        //          // nothing to do
        //      }
        //  }

        public int get_yshift (int w_id) {
            int yshift = 0;
            string winsubj = @"$w_id";
            string cmd = "xprop -id ".concat(winsubj, " _NET_FRAME_EXTENTS");
            string output = "";
            try {
                GLib.Process.spawn_command_line_sync(cmd, out output);
            }
            catch (SpawnError e) {
                // nothing to do
            }
            if (output.contains("=")) {
                yshift = int.parse(output.split(", ")[2]);
            }
            print(@"$yshift\n");
            return yshift;
        }



    }

    /////////////////// Internal stuff V ////////////////////////////


    private void getscale() {
        Gdk.Monitor monitorsubj = gdkdisplay.get_primary_monitor();
        scale = monitorsubj.get_scale_factor();
    }


    private void get_monitors () {
        // maintaining function
        // collect data on connected monitors: real numbers! (unscaled)
        monitorgeo = new HashTable<string, Variant> (str_hash, str_equal); //++
        print("monitors updated\n");
        n_monitors = gdkdisplay.get_n_monitors();
        for (int i=0; i < n_monitors; i++) {
            Gdk.Monitor newmonitor = gdkdisplay.get_monitor(i);
            string mon_name = newmonitor.get_model();
            Gdk.Rectangle mon_geo = newmonitor.get_workarea();
            int sf = newmonitor.get_scale_factor ();
            int x = mon_geo.x * sf;
            int y = mon_geo.y * sf;
            int width = mon_geo.width * sf;
            int height = mon_geo.height * sf;

            print(@"sizes: $x, $y, $width, $height\n");
            Variant geodata = new Variant("(iiii)", x , y, width, height);
            monitorgeo.insert(mon_name, geodata);
        }
    }

    ////////////////////////////////////////// setup dbus
    void on_bus_aquired (DBusConnection conn) {
        // register the bus
        try {
            conn.register_object ("/org/ubuntubudgie/shufflerinfodaemon",
                new ShufflerInfoServer ());
        }
        catch (IOError e) {
            stderr.printf ("Could not register service\n");
        }
    }

    public void setup_dbus () {
        Bus.own_name (
            BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
            BusNameOwnerFlags.NONE, on_bus_aquired,
            () => {}, () => stderr.printf ("Could not aquire name\n"));
    }
    ////////////////////////////////////////// setup dbus




    public static int main (string[] args) {
        Gtk.init(ref args);
        wnckscr = Wnck.Screen.get_default();
        wnckscr.force_update();
        monitorgeo = new HashTable<string, Variant> (str_hash, str_equal);
        window_essentials = new HashTable<string, Variant> (str_hash, str_equal);

        Gtk.init(ref args);
        gdkdisplay = Gdk.Display.get_default();

        Gdk.Screen gdkscreen = Gdk.Screen.get_default();

        // move in!!
        get_monitors();
        getscale();
        gdkscreen.monitors_changed.connect(get_monitors);
        gdkscreen.monitors_changed.connect(getscale);
        //wnckscr.window_opened.connect(get_windata);
        //wnckscr.window_closed.connect(get_windata);
        setup_dbus();
        Gtk.main();
        return 0;
    }
}