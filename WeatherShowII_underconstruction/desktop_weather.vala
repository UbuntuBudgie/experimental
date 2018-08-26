using Gtk;

public class DesktopWeather : Gtk.Window {

    public DesktopWeather () {
        /* 
        * todo:
        * make this window read the datafile, maintained by the applet.
        * update if needed. On first run (triggerfile in ~/.config/), 
        * set position relative to (main) screen, set image- and font
        * size relative. extend gschema with: header font size, 
        * data font size, image size. connect gsettings position(x/y)
        * to move the (this) window accordingly.
        * unavoidable: poll-check for applet to be in the panel, kill
        * window if not. Budgie Settings - change to -no-desktop- 
        * should also kill the window.
        * if -no-desktop-, applet should not maintain corresponding 
        * datafile in /tmp.
        */

        this.title = "Dog's Weather";
        File datasrc = File.new_for_path("/tmp/" + username + "_weatherdata");
        // monitor for changes
        FileMonitor monitor = datasrc.monitor(FileMonitorFlags.NONE, null);
        monitor.changed.connect(update_win);
        var maingrid = new Gtk.Grid();
    }

    private void update_win() {
        // work to do
    }

    public static void main(string[] ? args = null) {
        Gtk.init(ref args);
        Gtk.Window win = new DesktopWeather();
        win.show_all();
        win.destroy.connect(Gtk.main_quit);
        Gtk.main();
    }
}