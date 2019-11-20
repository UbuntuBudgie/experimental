// valac --pkg gio-2.0 --pkg gtk+-3.0

[DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

interface ShufflerInfoClient : Object {

    public abstract int mutiply (int n1, int n2) throws Error;
    public abstract string defaultmon_name () throws Error;
    public abstract GLib.HashTable<string, Variant> get_mondata () throws Error;
    public abstract GLib.HashTable<string, Variant> get_winsdata () throws Error;
    public abstract string get_activewin () throws Error;
}

void main () {
    while(true) {
        try {
            ShufflerInfoClient client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon")
            );

            int result = client.mutiply (12, 40);
            print(@"$result\n");
            string mon_name = client.defaultmon_name();
            print(@"$mon_name\n");
            ////
            GLib.HashTable<string, Variant> monitordata = client.get_mondata();
            print("just for fun:\n");
            GLib.List<unowned string> keys = monitordata.get_keys ();
            foreach (string s in keys) {
                Variant mongeo = monitordata[s];
                foreach (GLib.Variant n in mongeo) {
                    int newn = n.get_int32();
                    print(@"$newn\n");
                }
                print(s + "\n");
            }
            ////
            ////
            string activewin = client.get_activewin();
            GLib.HashTable<string, Variant> windata = client.get_winsdata();
            GLib.List<unowned string> windata_keys = windata.get_keys();
            foreach (string s in windata_keys) {
                if (s == activewin) {
                    // pick xid of any of the existing windows:
                    Variant var1 = windata[s];
                    print("match\n");
                    print(@"$s\n");
                    string name = "";
                    string isonws = "";
                    string winsmonitor = "";
                    int x = -1;
                    int y = -1;
                    int wdth = -1;
                    int hght = -1;
                    VariantIter iter = var1.iterator ();
                    iter.next("s", &name);
                    iter.next("s", &isonws);
                    iter.next("s", &winsmonitor);
                    iter.next("i", &x);
                    iter.next("i", &y);
                    iter.next("i", &wdth);
                    iter.next("i", &hght);
                    print(@"data: $name, $isonws, $winsmonitor, $x, $y, $wdth, $hght\n");
                }
            }
        }

        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
        print("\n");
        Thread.usleep(5000000);
    }
}