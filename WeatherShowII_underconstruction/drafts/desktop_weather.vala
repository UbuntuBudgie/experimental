using Gtk;
using Cairo;

public class DesktopWeather : Gtk.Window {

    private File datasrc;
    private FileMonitor monitor;
    private Gtk.Grid maingrid;
    Label locationlabel;
    Label weatherlabel;

    public DesktopWeather () {
        /* 
        * this window monitors the datafile, maintained by the applet.
        * updates if needed. 
        * todo:
        * on first run (triggerfile in ~/.config/), 
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

        // make relative
        string css_data = """
            .biglabel {
                font-size: 20px;
                color: white;
                padding-bottom: 15px;
                padding-right: 15px;
                padding-top: 15px;
            }
            .label {
                padding-bottom: 15px;
                padding-right: 15px;
                font-size: 17px;
                color: white;
            }
            """;

        // transparency
        var screen = this.get_screen();
        this.set_app_paintable(true);
        var visual = screen.get_rgba_visual();
        this.set_visual(visual);
        this.draw.connect(on_draw);
        // monitored datafile
        string username = Environment.get_user_name();
        string src = "/tmp/".concat(username, "_weatherdata");
        datasrc = File.new_for_path(src);
        // report
        maingrid = new Gtk.Grid();
        this.add(maingrid);
        locationlabel = new Label("");
        weatherlabel = new Label("");
        weatherlabel.set_xalign(0);
        locationlabel.set_xalign(0);
        // css (needs a separate function to update)
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_data(css_data);
        Gtk.StyleContext.add_provider_for_screen(
            screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
        );
        weatherlabel.get_style_context().add_class("label");
        locationlabel.get_style_context().add_class("biglabel");
        maingrid.attach(locationlabel, 1, 0, 1, 1);
        maingrid.attach(weatherlabel, 1, 1, 1, 4);
        // monitor
        monitor = datasrc.monitor(FileMonitorFlags.NONE, null);
        monitor.changed.connect(update_win);
        update_win();
    }

    private bool on_draw (Widget da, Context ctx) {
        // needs to be connected to transparency settings change
        ctx.set_source_rgba(1.0, 0.2, 0.2, 0.2);
        ctx.set_operator(Cairo.Operator.SOURCE);
        ctx.paint();
        ctx.set_operator(Cairo.Operator.OVER); 
        return false;
    }

    private void update_win() {
        // update the window if weather (file/datasrc) changes
        try {
            var dis = new DataInputStream (datasrc.read ());
            string line;
            string[] weatherlines = {};
            while ((line = dis.read_line (null)) != null) {
                // work to do; image change
                weatherlines += line;
            }
            int n_lines = weatherlines.length;
            string weathersection = string.joinv("\n", weatherlines[2:n_lines]);
            locationlabel.set_label(weatherlines[1]);
            weatherlabel.set_label(weathersection);
        }
        catch (Error e) {
            /* 
            * on each refresh, the file is deleted by the applet
            * just wait for next signal. 
            */
        }
    }

    public static void main(string[] ? args = null) {
        Gtk.init(ref args);
        Gtk.Window win = new DesktopWeather();
        win.show_all();
        win.destroy.connect(Gtk.main_quit);
        Gtk.main();
    }
}