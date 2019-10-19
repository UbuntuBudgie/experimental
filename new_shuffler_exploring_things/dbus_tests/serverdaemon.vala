// valac --pkg gio-2.0 --pkg gtk+-3.0


namespace ShufflerEssentialInfo {

    Gdk.Display gdkdisplay;
    string defmonname;
    HashTable<string, Variant> monitorgeo;


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
    }

    private void get_monitors () {
        // collect data on connected monitors
        print("monitors updated\n");
        int n_monitors = gdkdisplay.get_n_monitors();
        for (int i=0; i < n_monitors; i++) {
            Gdk.Monitor newmonitor = gdkdisplay.get_monitor(i);
            string mon_name = newmonitor.get_model();
            Gdk.Rectangle mon_geo = newmonitor.get_geometry();
            int scalefactor = newmonitor.get_scale_factor ();
            int x = mon_geo.x * scalefactor;
            int y = mon_geo.y * scalefactor;
            int width = mon_geo.width * scalefactor;
            int height = mon_geo.height * scalefactor;
            Variant geodata = new Variant("(iiii)", x, y, width, height);
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

    public static int main (string[] args) {
        defmonname = "unknown";
        monitorgeo = new HashTable<string, Variant> (str_hash, str_equal); //++
        Gtk.init(ref args);
        gdkdisplay = Gdk.Display.get_default();
        Gdk.Screen gdkscreen = Gdk.Screen.get_default();
        get_monitors();
        gdkscreen.monitors_changed.connect(get_monitors);
        setup_dbus();
        Gtk.main();
        return 0;
    }
}