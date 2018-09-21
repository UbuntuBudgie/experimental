using Gtk;
using Cairo;
using Gdk;

public class DesktopWeather : Gtk.Window {

    private File datasrc;
    private FileMonitor monitor;
    private Gtk.Grid maingrid;
    Label locationlabel;
    Label weatherlabel;
    GLib.Settings desktop_settings;
    private string css_data;
    private string css_template;
    Gtk.CssProvider css_provider;
    double new_transp;
    private Gdk.Pixbuf[] iconpixbufs_1;
    private Gdk.Pixbuf[] iconpixbufs_2;
    private Gdk.Pixbuf[] iconpixbufs_3;
    int currscale;
    string[] iconnames = {};



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

        // get icon data
        get_icondata();

        // template. x-es are replaced on color set
        css_template = """
            .biglabel {
                font-size: 20px;
                color: xxx-xxx-xxx;
                padding-bottom: 15px;
                padding-right: 15px;
                padding-top: 15px;
            }
            .label {
                padding-bottom: 15px;
                padding-right: 15px;
                font-size: 17px;
                color: xxx-xxx-xxx;
            }
            """;

        //////////////////////////////////////////////////
        // gsettings stuff
        desktop_settings = get_settings(
            "org.ubuntubudgie.plugins.weathershow"
        );

        desktop_settings.changed["desktopweather"].connect (() => {
            bool newval = desktop_settings.get_boolean("desktopweather");
            if (newval == false) {
                Gtk.main_quit();
            }    
        });

        desktop_settings.changed["textcolor"].connect (() => {
            update_style();
        });

        desktop_settings.changed["transparency"].connect (() => {
            int transparency = 100 - desktop_settings.get_int("transparency");
            new_transp = transparency/100.0;
            print(@"ex: $new_transp\n");
            this.queue_draw();
        });

        desktop_settings.changed["desktopweather"].connect (() => {
            bool newval = desktop_settings.get_boolean("desktopweather");
            if (newval == false) {
                Gtk.main_quit();
            }    
        });
        //////////////////////////////////////////////////
        css_data = get_css();
        print("css_data\n" + css_data + "\n");
        int transparency = 100 - desktop_settings.get_int("transparency");
        new_transp = transparency/100.0;
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
        css_provider = new Gtk.CssProvider();
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
        monitor.changed.connect(update_content);
        update_content();
    }

    private bool on_draw (Widget da, Context ctx) {
        // needs to be connected to transparency settings change
        ctx.set_source_rgba(0, 0, 0, new_transp);
        ctx.set_operator(Cairo.Operator.SOURCE);
        ctx.paint();
        ctx.set_operator(Cairo.Operator.OVER); 
        return false;
    }

    private GLib.Settings get_settings(string path) {
        var settings = new GLib.Settings(path);
        return settings;
    }

    private string get_css() {
        print(css_template + "\n");
        string[] currcolor = desktop_settings.get_strv("textcolor");
        return css_template.replace(
            "xxx-xxx-xxx", "rgb(".concat(string.joinv(", ", currcolor), ")")
        );
    }

    private void update_content () {
        try {
            var dis = new DataInputStream (datasrc.read ());
            string line;
            string[] weatherlines = {};
            while ((line = dis.read_line (null)) != null) {
                // work to do; image change
                weatherlines += line;
            }

            string newicon = find_mappedid(
                weatherlines[0]
            ).concat(weatherlines[1]);
            int n_lines = weatherlines.length;
            string weathersection = string.joinv("\n", weatherlines[3:n_lines]);
            locationlabel.set_label(weatherlines[2]);
            weatherlabel.set_label(weathersection);
        }
        catch (Error e) {
            /* 
            * on each refresh, the file is deleted by the applet
            * just wait for next signal. 
            */
        }
    }

    private void update_style() {
        // update the window if weather (file/datasrc) or settings changes
        // get/update textcolor
        css_data = get_css();
        weatherlabel.get_style_context().remove_class("label");
        locationlabel.get_style_context().remove_class("biglabel");
        css_provider.load_from_data(css_data);
        locationlabel.get_style_context().add_class("biglabel");
        weatherlabel.get_style_context().add_class("label");
    }

    private string find_mappedid (string icon_id) {

        /* 
        * OWM's icon codes are a bit oversimplified; different weather 
        * types are pushed into one icon. the data ("id") however offers a 
        * much more detailed set of weather types/codes, which can be used to
        * set an improved icon mapping. below my own (again) simplification 
        * of the extended set of weather codes, which is kind of the middle
        * between the two.
        */

        string[,] replacements = {
            {"221", "212"}, {"231", "230"}, {"232", "230"}, {"301", "300"}, 
            {"302", "300"}, {"310", "300"}, {"312", "311"}, {"314", "313"}, 
            {"502", "501"}, {"503", "501"}, {"504", "501"}, {"522", "521"}, 
            {"531", "521"}, {"622", "621"}, {"711", "701"}, {"721", "701"}, 
            {"731", "701"}, {"741", "701"}, {"751", "701"}, {"761", "701"}, 
            {"762", "701"}
        };
        int lenrep = replacements.length[0];
        for (int i=0; i < lenrep; i++) {
            if (icon_id == replacements[i, 0]) {
                return replacements[i, 1];

            }
        }
        return icon_id;
    }

    private void get_icondata () {
        // fetch the icon list
        string icondir = "/".concat(
            "usr/lib/budgie-desktop/plugins",
            "/budgie-weathershow/weather_icons"
        );
        iconnames = {}; 
        iconpixbufs_1 = {}; 
        iconpixbufs_2 = {};
        iconpixbufs_3 = {};
        try {
            var dr = Dir.open(icondir);
            string ? filename = null;
            while ((filename = dr.read_name()) != null) {
                // add to icon names
                iconnames += filename[0:4];
                // add to pixbufs
                string iconpath = GLib.Path.build_filename(
                    icondir, filename
                );
                iconpixbufs_1 += new Pixbuf.from_file_at_size (
                    iconpath, 80, 80
                );
                iconpixbufs_2 += new Pixbuf.from_file_at_size (
                    iconpath, 120, 120
                );
                iconpixbufs_3 += new Pixbuf.from_file_at_size (
                    iconpath, 160, 160
                );
            }
        } catch (FileError err) {
                // unlikely to occur, but:
                print("Something went wrong loading the icons");
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