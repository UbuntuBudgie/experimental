// valac --pkg gio-2.0 --pkg gtk+-3.0 --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE"
// add active window!


namespace ShufflerEssentialInfo {

    Gdk.Display gdkdisplay;
    string defmonname;
    HashTable<string, Variant> monitorgeo;
    unowned Wnck.Screen wnckscr;
    HashTable<string, Variant> window_essentials;

    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    public class ShufflerInfoServer : Object {

        public int mutiply (int n1, int n2) throws Error {
            return n1 * n2;
        }

        public string defaultmon_name () throws Error {
            return defmonname;
        }

        public HashTable<string, Variant> get_mondata () throws Error {
            return monitorgeo;
        }

        public HashTable<string, Variant> get_winsdata () throws Error {
            return window_essentials;
        }


        public string get_activewin () throws Error {
            // directly called, occasional function
            ulong activewin = wnckscr.get_active_window().get_xid();
            return activewin.to_string();
        }
    }

    private void get_windata() {
        /*
        / maintaining function
        / get windowlist, per window:
        / xid = key, name, onthisworspace, monitor-of window, geometry
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
                string winsmonitor = gdkdisplay.get_monitor_at_point(x, y).get_model();
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
        // return winsdata;
    }

    private void get_monitors () {
        // maintaining function
        // collect data on connected monitors: real numbers! (unscaled)
        print("monitors updated\n");
        int n_monitors = gdkdisplay.get_n_monitors();
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

    /////////////////////////////////////////////////////////////////////

    private void newwin (
        Wnck.Window winsubj, int x, int y, int width, int height
    ) {
        winsubj.unmaximize();
        winsubj.set_geometry(
            Wnck.WindowGravity.NORTHWEST,
            Wnck.WindowMoveResizeMask.X |
            Wnck.WindowMoveResizeMask.Y |
            Wnck.WindowMoveResizeMask.WIDTH |
            Wnck.WindowMoveResizeMask.HEIGHT,
            x, y, width, height
        );
    }

    /////////////////////////////////////////////////////////////////////

    public static int main (string[] args) {
        Gtk.init(ref args);
        defmonname = "unknown";
        wnckscr = Wnck.Screen.get_default();
        wnckscr.force_update();
        monitorgeo = new HashTable<string, Variant> (str_hash, str_equal); //++
        window_essentials = new HashTable<string, Variant> (str_hash, str_equal);

        Gtk.init(ref args);
        gdkdisplay = Gdk.Display.get_default();
        Gdk.Screen gdkscreen = Gdk.Screen.get_default();
        get_monitors();
        gdkscreen.monitors_changed.connect(get_monitors);

        wnckscr.window_opened.connect(get_windata);
        wnckscr.window_closed.connect(get_windata);
        setup_dbus();

        ///////////////////////////////////////////////
        get_windata();
        ///////////////////////////////////////////////

        Gtk.main();
        return 0;
    }
}