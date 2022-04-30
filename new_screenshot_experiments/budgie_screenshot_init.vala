using Gtk;

public static int main(string[] args) {
    Gtk.init(ref args);
    try {
        Budgie.client = GLib.Bus.get_proxy_sync (
            BusType.SESSION, "org.buddiesofbudgie.Screenshot",
            ("/org/buddiesofbudgie/Screenshot")
        );
    }
    catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
    try {
        Budgie.ScreenshotServer server = new Budgie.ScreenshotServer();
        server.setup_dbus();
    }
    catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
    Gtk.main();
    return 0;
}