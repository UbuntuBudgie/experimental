// valac --pkg gio-2.0 --pkg gtk+-3.0

[DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

interface ShufflerInfoClient : Object {

    public abstract int mutiply (int n1, int n2) throws Error;
    public abstract string defaultmon_name () throws Error;
    public abstract GLib.HashTable<string, Variant> get_mondata () throws Error;
}

void main () {
    while(true) {
        try {
            ShufflerInfoClient client = Bus.get_proxy_sync (
                BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                ("/org/ubuntubudgie/shufflerinfodaemon"));
                int result = client.mutiply (12, 40);
                print(@"$result\n");
                string mon_name = client.defaultmon_name();
                print(@"$mon_name\n");
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
        }

        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
        Thread.usleep(5000000);
    }
}