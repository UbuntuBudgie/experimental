using Gdk.X11;

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

// valac --pkg gio-2.0 --pkg gdk-x11-3.0 --pkg gtk+-3.0 --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE" -X -lm

namespace ShufflerEssentialInfo {

    // monitordata-dict
    HashTable<string, Variant> monitorgeo;
    // windowdata-dict
    HashTable<string, Variant> window_essentials;
    // misc.
    unowned Wnck.Screen wnckscr;
    Gdk.Display gdkdisplay;
    int n_monitors;
    Gdk.X11.Window timestamp_window;
    // scale
    int scale;

    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    public class ShufflerInfoServer : Object {

        public int getactivewin () throws Error {
            // get active window id
            int activewin;
            Wnck.Window? curr_activewin = wnckscr.get_active_window();
            if (curr_activewin != null) {
                activewin = (int)curr_activewin.get_xid();
            }
            else {
                activewin = -1;
            }
            return activewin;
        }

        public HashTable<string, Variant> get_winsdata () throws Error {
            // window data, send through
            get_windata();
            return window_essentials;
        }

        public void move_window (
            int w_id, int x, int y, int width, int height
        ) throws Error {
            // move window, external connection
            unowned GLib.List<Wnck.Window> wlist = wnckscr.get_windows();
            foreach (Wnck.Window w in wlist) {
                if (w.get_xid() == w_id) {
                    now_move(w, x, y, width, height);
                }
            }
        }

        private void now_move (
            Wnck.Window tomove, int x, int y, int width, int height
        ) {
            // executed version
            tomove.unmaximize();
            tomove.unminimize(get_now());
            tomove.set_geometry(
                Wnck.WindowGravity.NORTHWEST,
                Wnck.WindowMoveResizeMask.X |
                Wnck.WindowMoveResizeMask.Y |
                Wnck.WindowMoveResizeMask.WIDTH |
                Wnck.WindowMoveResizeMask.HEIGHT,
                x, y, width, height
            );
        }

        private uint get_now() {
            // timestamp
            return Gdk.X11.get_server_time(timestamp_window);
        }

        public HashTable<string, Variant> get_tiles (
            string mon_name, int cols, int rows
        ) throws Error {
            // get the list of tiles, properties
            var tiledata = new HashTable<string, Variant> (str_hash, str_equal);
            int[] xpositions = {};
            int[] ypositions = {};
            for (int i=0; i < n_monitors; i++) {
                Gdk.Monitor monitorsubj = gdkdisplay.get_monitor(i);
                if (monitorsubj.get_model()  == mon_name) {
                    Gdk.Rectangle mon_wa = monitorsubj.get_workarea();
                    int fullwidth = mon_wa.width * scale;
                    int tilewidth = (int)(fullwidth/cols);
                    int fullheight = mon_wa.height * scale;
                    int tileheight = (int)(fullheight/rows);
                    int NEx = mon_wa.x * scale;
                    int origx = NEx;
                    //  int i_tile = 0;
                    while (NEx < origx + fullwidth) {
                        xpositions += NEx;
                        NEx += tilewidth;
                    }
                    int NEy = mon_wa.y * scale;
                    int origy = NEy;
                    while (NEy < origy + fullheight) {
                        ypositions += NEy;
                        NEy += tileheight;
                    }
                    string[] xpositions_str = {};
                    string[] ypositions_str = {};

                    foreach (int xp in xpositions) {
                        xpositions_str += @"$xp";
                    }
                    foreach (int yp in ypositions) {
                        ypositions_str += @"$yp";
                    }
                    tiledata.insert("x_anchors", string.joinv(" ", xpositions_str));
                    tiledata.insert("y_anchors", string.joinv(" ", ypositions_str));
                    /*
                    / ok, width/height is already in tiledata, but for jump r/l, we need it separatly.
                    / optimize, or are we lazy? nah, leave it. We need to calc tiles anyway.
                    */
                    tiledata.insert("tilewidth", tilewidth);
                    tiledata.insert("tileheight", tileheight);
                    // now create tiles
                    int col = 0;

                    foreach (int nx in xpositions) {
                        int row = 0;
                        foreach (int ny in ypositions) {
                            Variant newtile = new Variant(
                                "(iiii)", nx, ny, tilewidth, tileheight
                            );
                            tiledata.insert(@"$col*$row", newtile);
                            row += 1;
                        }
                        col += 1;
                    }
                }
            }
            return tiledata;
        }


        public int get_yshift (int w_id) throws Error {
            /*
            / windows with property NET_FRAME_EXTENTS need to be positioned
            / differently, y-wise. below calculated offset
            */
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
            return yshift;
        }

        public string getactivemon_name () throws Error {
            // get the monitor with active window or ""
            string activemon_name = "";
            Wnck.Window curr_activew = wnckscr.get_active_window();
            if (curr_activew != null) {
                int x;
                int y;
                int w;
                int h;
                curr_activew.get_geometry(out x, out y, out w, out h);
                Gdk.Monitor activemon = gdkdisplay.get_monitor_at_point(x, y);
                activemon_name = activemon.get_model();
            }
            return activemon_name;
        }
    }

    private void getscale() {
        // get scale factor of primary (which we are using)
        Gdk.Monitor monitorsubj = gdkdisplay.get_primary_monitor();
        scale = monitorsubj.get_scale_factor();
    }

    private void get_monitors () {
        // maintaining function
        // collect data on connected monitors: real numbers! (unscaled)
        monitorgeo = new HashTable<string, Variant> (str_hash, str_equal); //++
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
            Variant geodata = new Variant("(iiii)", x , y, width, height);
            monitorgeo.insert(mon_name, geodata);
        }
    }

    // setup dbus
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

    private void get_windata() {
        /*
        / maintaining function
        / get windowlist, per window:
        / xid = key. then: name, onthisworspace, monitor-of-window, geometry
        */
        var winsdata = new HashTable<string, Variant> (str_hash, str_equal);
        unowned GLib.List<Wnck.Window> wlist = wnckscr.get_windows();
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
    }

    public static int main (string[] args) {
        Gtk.init(ref args);

        // X11 stuff, non-dynamic part
        unowned X.Window xwindow = Gdk.X11.get_default_root_xwindow();
        unowned X.Display xdisplay = Gdk.X11.get_default_xdisplay();
        Gdk.X11.Display display = Gdk.X11.Display.lookup_for_xdisplay(xdisplay);
        timestamp_window = new Gdk.X11.Window.foreign_for_display(display, xwindow);
        // misc.
        wnckscr = Wnck.Screen.get_default();
        wnckscr.force_update();
        monitorgeo = new HashTable<string, Variant> (str_hash, str_equal);
        window_essentials = new HashTable<string, Variant> (str_hash, str_equal);

        gdkdisplay = Gdk.Display.get_default();
        Gdk.Screen gdkscreen = Gdk.Screen.get_default();

        get_monitors();
        getscale();

        ////////////////////////////////////////////////////
        ////////////////////////////////////////////////////
        //  get_anchors("eDP-1", 3, 3);
        ////////////////////////////////////////////////////
        ////////////////////////////////////////////////////
        gdkscreen.monitors_changed.connect(get_monitors);
        gdkscreen.monitors_changed.connect(getscale);
        wnckscr.window_opened.connect(get_windata);
        wnckscr.window_closed.connect(get_windata);
        setup_dbus();
        Gtk.main();
        return 0;
    }
}