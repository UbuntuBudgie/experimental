using Gtk;
using Gdk;
using GLib.Math;
using Json;
using Gee;

/* 
* Template
* Author: Jacob Vlijm
* Copyright © 2017-2018 Ubuntu Budgie Developers
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

/* inserted section -------------------- */
namespace WeatherShowFunctions {

    private GLib.Settings get_settings(string path) {
        var settings = new GLib.Settings(path);
        return settings;
    }
}
/* end inserted section -------------------- */


namespace TemplateApplet { 
    /* ^ watch out for name, was weird (used as classname) in draft applet */



    /* inserted section -------------------- */

    /* make sure settings are defined on applet startup */
    private GLib.Settings ws_settings;
    private bool show_ondesktop;
    private bool dynamic_icon;
    private bool show_forecast;
    private string lang;
    private string tempunit;
    private string[] directions;
    private string key;
    private bool customposition;

    private void get_weather (GetWeatherdata test) {

        // get forecast; conditional
        HashMap result_forecast = test.get_forecast();
        // get current; run anyway. writing to file is optiional for desktop
        string result_current = test.get_current();
        print("read_current:\n\n" + result_current);
        // write current to file; conditional, only for desktop
        if (show_ondesktop == true) {
            string username = Environment.get_user_name();
            string src = "/tmp/".concat(username, "_weatherdata");
            File datasrc = File.new_for_path(src);
            if (datasrc.query_exists ()) {
                datasrc.delete ();
            }
            var file_stream = datasrc.create (FileCreateFlags.NONE);
            var data_stream = new DataOutputStream (file_stream);
            data_stream.put_string (result_current);
        }
    }


    public class GetWeatherdata {

        private string fetch_fromsite (string wtype, string city) {
            /* fetch data from OWM */
            string website = "http://api.openweathermap.org/data/2.5/"; 
            string langstring = "&".concat("lang=", lang);
            string url = website.concat(
                wtype, "?id=", city, "&APPID=", key, "&", langstring
            );
            /* cup of libsoup */
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", url);
            session.send_message (message);
            string output = (string) message.response_body.flatten().data;
            int len_output = output.length;
            if (len_output != 0) {
                return output;
            }
            else {
                return "no data";
            }
        }

        private string check_stringvalue(Json.Object obj, string val) {
            /* check if the value exists, create the string- output if so */
            if (obj.has_member(val)) {
                return obj.get_string_member(val);
            }
            return "";
        }

        private float check_numvalue(Json.Object obj, string val) {
            /* check if the value exists, create the num- output if so */
            if (obj.has_member(val)) {
                float info = (float) obj.get_double_member(val);
                return info;
            }
            return 1000;
        }

        private HashMap get_categories(Json.Object rootobj) {
            var map = new HashMap<string, Json.Object> ();
            /* get cons. weatherdata, wind data and general data */
            map["weather"] = rootobj.get_array_member(
                "weather"
            ).get_object_element(0);
            map["wind"] = rootobj.get_object_member ("wind");
            map["main"] = rootobj.get_object_member ("main");
            map["sys"] = rootobj.get_object_member ("sys");
            return map;
        }

        private string getsnapshot (string data) {
            print(data);
            var parser = new Json.Parser ();
            parser.load_from_data (data);
            var root_object = parser.get_root ().get_object ();
            HashMap<string, Json.Object> map = get_categories(
                root_object
            );
            /* get icon id */
            string id = check_numvalue(map["weather"], "id").to_string();

            /* get cityline (exists anyway) */
            string city = check_stringvalue(root_object, "name");
            string country = check_stringvalue(map["sys"], "country");
            string citydisplay = city.concat(", ", country);
            /* get weatherline */
            string skydisplay = check_stringvalue(
                map["weather"], "description"
            );
            /* get temp */
            string tempdisplay = get_temperature(map);
            /* get wind speed */
            string wspeeddisplay = get_windspeed(map);
            /* get wind direction */
            string wdirectiondisplay = get_winddirection(map);
            /* get humidity */
            string humiddisplay = get_humidity(map);
            /* combined */
            string[] collected = {
                id, citydisplay, skydisplay, tempdisplay, 
                wspeeddisplay.concat(" ", wdirectiondisplay), humiddisplay
            };
            string output = string.joinv("\n", collected);
            return output;
        }

        public string get_current () {
            /* 
            * get "raw" data. if successful, create new data, else create
            * empty lines in the output array.
            */
            string data = fetch_fromsite("weather", "2907911");
            if (data != "no data") {
                return getsnapshot(data);
            }
            else {
                return "";
            }
        }

        private string get_windspeed (
            HashMap<string, Json.Object> categories
            ) {
                /* get wind speed */
                float wspeed = check_numvalue(categories["wind"], "speed");
                string wspeeddisplay;
                if (wspeed != 1000) {
                    wspeeddisplay = wspeed.to_string().concat(" m/sec");
                }
                else {
                    wspeeddisplay = "";
                }
                return wspeeddisplay;
            }

        private string get_temperature(
            HashMap<string, Json.Object> categories
        ) {
            /* get temp */
            string tempdisplay;
            float temp = check_numvalue(categories["main"], "temp");
            if (temp != 1000) {
                string dsp_unit;
                if (tempunit == "Celsius") {
                    temp = temp - (float) 273.15;
                    dsp_unit = "℃";
                }
                else {
                    temp = (temp * (float) 1.80) - (float) 459.67;
                    dsp_unit = "℉";
                }
                double rounded_temp = Math.round((double) temp);
                tempdisplay = rounded_temp.to_string().concat(dsp_unit);
            }
            else {
                tempdisplay = "";
            }
            return tempdisplay;
        }

        private string get_winddirection (
            HashMap<string, Json.Object> categories
        ) {
            /* get wind direction */
            float wdirection = check_numvalue(categories["wind"], "deg");
            string wdirectiondisplay;
            if (wdirection != 1000) {
                int iconindex = (int) Math.round(wdirection/45);
                wdirectiondisplay = directions[iconindex];
            }
            else {
                wdirectiondisplay = "";
            }
            return wdirectiondisplay;
        }

        private string get_humidity (
            HashMap<string, Json.Object> categories
        ) {
            /* get humidity */
            string humiddisplay;
            int humid = (int) check_numvalue(categories["main"], "humidity");
            if (humid != 1000) {
                humiddisplay = humid.to_string().concat("%");
            }
            else {
                humiddisplay = "";
            }
            return humiddisplay;
        }

        private HashMap getspan(string data) {
            // get the forecast
            //print(data);
            var map = new HashMap<int, string> ();
            var parser = new Json.Parser ();
            parser.load_from_data (data);
            var root_object = parser.get_root ().get_object ();
            /* we need to parse each datasection from <list> */
            Json.Array newroot = root_object.get_array_member("list");
            /* get nodes */
            var nodes = newroot.get_elements();
            int n_snapshots = 0;
            foreach (Json.Node n in nodes) {
                var obj = n.get_object();
                HashMap<string, Json.Object> categories = get_categories(obj);
                /* get icon id */
                string id = check_numvalue(categories["weather"], "id").to_string();
                print("%s\n", id);
                /* get timestamp */
                int timestamp = (int) obj.get_int_member("dt");
                print(@"$timestamp\n");
                /* get skystate */
                /* why no function? Ah, no numvalue, no editing, no unit*/
                string skydisplay = check_stringvalue(
                    categories["weather"], "description"
                );
                print(skydisplay + "\n");
                /* get temp */
                string temp = get_temperature(categories);
                print(temp + "\n");
                /* get wind speed/direction */
                string wspeed = get_windspeed(categories);
                string wind = get_winddirection(categories).concat(" ", wspeed);
                print(wind + "\n");
                /* get humidity */
                string humidity = get_humidity(categories);
                print(humidity + "\n\n");
                /* now combine the first 16 into a HashMap timestamp (int) /snapshot (str) */
                n_snapshots += 1;
                if (n_snapshots == 16) {
                    break;
                }
            }
            return map;
        }

        public HashMap get_forecast() {
            /* here we create a hashmap<time, string> */
            string data = fetch_fromsite("forecast", "2907911");
            var map = new HashMap<int, string> ();

            if (data != "no data") {
                print("succes!\n");
                getspan(data);
                // print(data + "\n");
                // get nodes
            }
            return map;
        }
    }

    /* end inserted section -------------------- */

    public class TemplateSettings : Gtk.Grid {
        /* Budgie Settings -section */
        GLib.Settings? settings = null;
        private CheckButton ondesktop_checkbox;
        private CheckButton dynamicicon_checkbox;
        private CheckButton forecast_checkbox;
        private CheckButton[] cbuttons; 
        private string[] add_args;
        private string css_data;
        private int buttoncolor;
        private Gtk.Scale transparency_slider;
        private Gtk.Button colorbutton;
        private Gtk.Label colorlabel;
        private Gtk.CheckButton setposbutton;
        private Gtk.Entry xpos;
        private Gtk.Entry ypos;
        private Gtk.Label xpos_label;
        private Gtk.Label ypos_label;
        private Gtk.Button apply;
        private Gtk.Label transparency_label;
        private Gtk.Label desktop_category;
        private Stack stack;
        private Gtk.Button button_desktop;
        private Gtk.Button button_general;
        private Label currmarker_label1;
        private Label currmarker_label2;


        public TemplateSettings(GLib.Settings? settings) {
            /*
            * Gtk stuff, widgets etc. here 
            */

            ///////////////////////////////////////////////////////////////////
            // stack, container for subgrids
            css_data = """
            .colorbutton {
              border-color: transparent;
              background-color: #AFC826;
              padding: 0px;
              border-width: 1px;
              border-radius: 4px;
            }
            .activebutton {
            }
            """;

            // css
            var screen = this.get_screen();
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_data(css_data);
            Gtk.StyleContext.add_provider_for_screen(
                screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
            );


            stack = new Stack();
            stack.set_transition_type(
                Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
            );
            stack.set_vexpand(true);
            stack.set_hexpand(true);
            this.attach(stack, 0, 10, 2, 1);
            var header_space = new Gtk.Label("\n");
            this.attach(header_space, 0, 2, 1, 1);


            button_general = new Button.with_label((_("General")));
            button_general.clicked.connect(on_button_general_clicked);
            //button_general.get_style_context().add_class("activebutton");
            button_general.set_size_request(100, 20);
            this.attach(button_general, 0, 0, 1, 1);
            currmarker_label1 = new Gtk.Label("⸻");
            this.attach(currmarker_label1, 0, 1, 1, 1);

            button_desktop = new Button.with_label((_("Desktop")));
            button_desktop.clicked.connect(on_button_desktop_clicked);
            button_desktop.set_size_request(100, 20);
            this.attach(button_desktop, 1, 0, 1, 1);
            currmarker_label2 = new Gtk.Label("");
            this.attach(currmarker_label2, 1, 1, 1, 1);

            var subgrid_general = new Grid();
            stack.add_named(subgrid_general, "Page1");
            var subgrid_desktop = new Grid();
            stack.add_named(subgrid_desktop, "Page2");

            
            // set city section
            var citylabel = new Label((_("City")));
            citylabel.set_xalign(0);
            subgrid_general.attach(citylabel, 0, 0, 1, 1);
            var citybox = new Box(Gtk.Orientation.HORIZONTAL, 0);
            subgrid_general.attach(citybox, 0, 1, 1, 1);
            var cityentry = new Entry();
            citybox.pack_start(cityentry, false, false, 0);
            var search_button = new Button.from_icon_name(
                "system-search-symbolic"
            );
            citybox.pack_end(search_button, false, false, 0);
            var spacelabel1 = new Gtk.Label("");
            subgrid_general.attach(spacelabel1, 0, 2, 1, 1);
            // set language 
            var langlabel = new Gtk.Label((_("Interface language")));
            langlabel.set_xalign(0);
            subgrid_general.attach(langlabel, 0, 3, 1, 1);
            var langentry = new Gtk.Entry();
            subgrid_general.attach(langentry, 0, 4, 1, 1);
            /*langentry.set_text(
            langlist[langcodes.index(wt.get_currlang())]
            )*/
            var spacelabel2 = new Gtk.Label("");
            subgrid_general.attach(spacelabel2, 0, 5, 1, 1);
            // show on desktop
            var ondesktop_checkbox = new CheckButton.with_label(
                (_("Show on desktop"))
            );
            subgrid_general.attach(ondesktop_checkbox, 0, 10, 1, 1);
            ondesktop_checkbox.set_active(show_ondesktop);
            ondesktop_checkbox.toggled.connect(toggle_value);

            // dynamic icon
            var dynamicicon_checkbox = new CheckButton.with_label(
                (_("Show dynamic panel icon"))
            );
            subgrid_general.attach(dynamicicon_checkbox, 0, 11, 1, 1);
            dynamicicon_checkbox.set_active(dynamic_icon);
            dynamicicon_checkbox.toggled.connect(toggle_value);
            // forecast
            var forecast_checkbox = new CheckButton.with_label(
                (_("Show forecast in popover"))
            );
            subgrid_general.attach(forecast_checkbox, 0, 12, 1, 1);
            forecast_checkbox.set_active(show_forecast);
            forecast_checkbox.toggled.connect(toggle_value);
            var spacelabel3 = new Gtk.Label("");
            subgrid_general.attach(spacelabel3, 0, 13, 1, 1);
            // temp unit
            var tempunit_checkbox = new CheckButton.with_label(
                (_("Use Fahrenheit"))
            );
            subgrid_general.attach(tempunit_checkbox, 0, 14, 1, 1);
            // tempunit_checkbox.set_active(show_forecast);
            tempunit_checkbox.set_active(get_tempstate());
            tempunit_checkbox.toggled.connect(set_tempunit);
            var spacelabel4 = new Gtk.Label("");
            subgrid_general.attach(spacelabel4, 0, 15, 1, 1);
            // optional settings: show on desktop
            transparency_label = new Gtk.Label(
                (_("Transparency"))
            );
            transparency_label.set_xalign(0);
            subgrid_desktop.attach(transparency_label, 0, 22, 1, 1);

            transparency_slider = new Gtk.Scale.with_range(
                Gtk.Orientation.HORIZONTAL, 0, 100, 5
            );
            subgrid_desktop.attach(transparency_slider, 0, 23, 1, 1);
            //transparency_slider.set_value(visible_pressure);
            //transparency_slider.value_changed.connect(edit_pressure);
            var spacelabel6 = new Gtk.Label("\n");
            subgrid_desktop.attach(spacelabel6, 0, 24, 1, 1);
            // text color
            var colorbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            subgrid_desktop.attach(colorbox, 0, 30, 1, 1);
            colorbutton = new Gtk.Button();
            //self.text_color.connect("clicked", self.pick_color, self.tcolorfile);
            colorbutton.set_size_request(10, 10);
            colorbutton.get_style_context().add_class("colorbutton");
            //locationlabel.get_style_context().add_class("biglabel");
            colorbox.pack_start(colorbutton, false, false, 0);
            colorlabel = new Gtk.Label("\t" + (_("Set text color")));
            colorlabel.set_xalign(0);
            colorbox.pack_start(colorlabel, false, false, 0);



            var spacelabel7 = new Gtk.Label("\n");
            subgrid_desktop.attach(spacelabel7, 0, 31, 1, 1);

            // checkbox custom position
            setposbutton = new Gtk.CheckButton.with_label(
                (_("Set custom position (px)"))
            );
            subgrid_desktop.attach(setposbutton, 0, 50, 1, 1);
            setposbutton.set_active(customposition);
            setposbutton.toggled.connect(toggle_value);


            var posholder = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            xpos = new Gtk.Entry();
            xpos.set_width_chars(4);
            xpos.set_sensitive(customposition);
            xpos_label = new Gtk.Label("x: ");
            xpos_label.set_sensitive(customposition);
            ypos = new Gtk.Entry();
            ypos.set_width_chars(4);
            ypos.set_sensitive(customposition);
            ypos_label = new Gtk.Label(" y: ");
            ypos_label.set_sensitive(customposition);
            posholder.pack_start(xpos_label, false, false, 0);
            posholder.pack_start(xpos, false, false, 0);
            posholder.pack_start(ypos_label, false, false, 0);
            posholder.pack_start(ypos, false, false, 0);

            apply = new Gtk.Button.with_label("OK");
            apply.set_sensitive(customposition);
            //self.apply.connect("pressed", self.get_xy)
            posholder.pack_end(apply, false, false, 0);
            subgrid_desktop.attach(posholder, 0, 51, 1, 1);
            button_desktop.set_sensitive(show_ondesktop);

            cbuttons = {
                ondesktop_checkbox, dynamicicon_checkbox, 
                forecast_checkbox, setposbutton
            };
            add_args = {
                "desktopweather", "dynamicicon", "forecast", 
                "customposition"
            };

            this.show_all();
        }

        private void on_button_general_clicked (Button button) {
            stack.set_visible_child_name("Page1");
            currmarker_label1.set_text("⸻");
            currmarker_label2.set_text("");
        }
        

        private void on_button_desktop_clicked(Button button) {
            stack.set_visible_child_name("Page2");
            currmarker_label2.set_text("⸻");
            currmarker_label1.set_text("");
        }

        private int get_buttonarg (ToggleButton button) {
            for (int i = 0; i < cbuttons.length; i++) {
                if (cbuttons[i] == button) {
                    return i;
                }
            } return -1; 
        }

        private bool get_tempstate () {
            return (
                tempunit == "Fahrenheit"
            );
        }

        private void set_tempunit (ToggleButton button) {
            bool newsetting = button.get_active();
            if (newsetting == true) {
                tempunit = "Fahrenheit";
            }
            else {
                tempunit = "Celsius";
            }
            ws_settings.set_string("tempunit", tempunit);
        }

        private void toggle_value(ToggleButton button) {
            bool newsetting = button.get_active();
            int val_index = get_buttonarg(button);
            string currsetting = add_args[val_index];
            ws_settings.set_boolean(currsetting, newsetting);
            // possible additional actions, depending on the togglebutton
            if (val_index == 0) {
                button_desktop.set_sensitive(newsetting);
            }
            else if (val_index == 3) {
                // ugly sumnation, but the alternative is more verbose
                xpos_label.set_sensitive(newsetting);
                ypos_label.set_sensitive(newsetting);
                xpos.set_sensitive(newsetting);
                ypos.set_sensitive(newsetting);
                apply.set_sensitive(newsetting);
            }
        }
    }

    public class Plugin : Budgie.Plugin, Peas.ExtensionBase {
        public Budgie.Applet get_panel_widget(string uuid) {
            return new Applet();
        }
    }


    public class TemplatePopover : Budgie.Popover {
        private Gtk.EventBox indicatorBox;
        private Gtk.Image indicatorIcon;
        /* process stuff */
        /* GUI stuff */
        private Grid maingrid;
        /* misc stuff */

        public TemplatePopover(Gtk.EventBox indicatorBox) {
            GLib.Object(relative_to: indicatorBox);
            this.indicatorBox = indicatorBox;
            /* set icon */
            this.indicatorIcon = new Gtk.Image.from_icon_name(
                "templateicon-symbolic", Gtk.IconSize.MENU
            );
            indicatorBox.add(this.indicatorIcon);

            /* gsettings stuff */

            /* grid */
            this.maingrid = new Gtk.Grid();
            this.add(this.maingrid);
        }
    }


    public class Applet : Budgie.Applet {

        private Gtk.EventBox indicatorBox;
        private TemplatePopover popover = null;
        private unowned Budgie.PopoverManager? manager = null;
        public string uuid { public set; public get; }
        /* specifically to the settings section */
        public override bool supports_settings()
        {
            return true;
        }
        public override Gtk.Widget? get_settings_ui()
        {
            return new TemplateSettings(this.get_applet_settings(uuid));
        }

        public Applet() {


            /* inserted section -------------------- */
            directions = {"↓", "↙", "←", "↖", "↑", "↗", "→", "↘", "↓"};
            /* 
            * OWM's icon codes are a bit oversimplified; different weather 
            * types are pushed into one icon. the data however offers a much 
            * more detailed set of weather types/codes, which can be used to
            * set an improved icon mapping. below my own (again) simplification 
            * of the extended set of weather codes, which is kind of the middle
            * between the two.result_forecast
            */
            string[,] mapped = {
                {"221", "212"}, {"231", "230"}, {"232", "230"}, {"301", "300"}, 
                {"302", "300"}, {"310", "300"}, {"312", "311"}, {"314", "313"}, 
                {"502", "501"}, {"503", "501"}, {"504", "501"}, {"522", "521"}, 
                {"531", "521"}, {"622", "621"}, {"711", "701"}, {"721", "701"}, 
                {"731", "701"}, {"741", "701"}, {"751", "701"}, {"761", "701"}, 
                {"762", "701"}
            };

            // get current settings
            ws_settings = WeatherShowFunctions.get_settings(
                "org.ubuntubudgie.plugins.weathershow"
            );
            tempunit = ws_settings.get_string("tempunit");
            ws_settings.changed["tempunit"].connect (() => {
                tempunit = ws_settings.get_string("tempunit");
		    });  
            // todo: fetch local language, see if it is in the list
            // fallback to default (en) if not. make checkbutton in settings
            // settings, used across classes!!
            lang = ws_settings.get_string("language");
            key = ws_settings.get_string("key");

            show_ondesktop = ws_settings.get_boolean("desktopweather");
            ws_settings.changed["desktopweather"].connect (() => {
                show_ondesktop = ws_settings.get_boolean("desktopweather");
            }); 

            dynamic_icon = ws_settings.get_boolean("dynamicicon");
            ws_settings.changed["dynamicicon"].connect (() => {
                dynamic_icon = ws_settings.get_boolean("dynamicicon");
            }); 

            show_forecast = ws_settings.get_boolean("forecast");
            ws_settings.changed["forecast"].connect (() => {
                show_forecast = ws_settings.get_boolean("forecast");
            });

            customposition = ws_settings.get_boolean("customposition");
            ws_settings.changed["customposition"].connect (() => {
                customposition = ws_settings.get_boolean("customposition");
            }); 
            
            var test = new GetWeatherdata();
            print("applet ok\n");
            get_weather(test);
            GLib.Timeout.add (60000, () => {
                print("loop ok\n");
                get_weather(test);   
                return true;
            });
            /* end inserted section -------------------- */


            initialiseLocaleLanguageSupport();
            /* box */
            indicatorBox = new Gtk.EventBox();
            add(indicatorBox);
            /* Popover */
            popover = new TemplatePopover(indicatorBox);
            /* On Press indicatorBox */
            indicatorBox.button_press_event.connect((e)=> {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    this.manager.show_popover(indicatorBox);
                }
                return Gdk.EVENT_STOP;
            });
            popover.get_child().show_all();
            show_all();
        }

        public override void update_popovers(Budgie.PopoverManager? manager)
        {
            this.manager = manager;
            manager.register_popover(indicatorBox, popover);
        }

        public void initialiseLocaleLanguageSupport(){
            // Initialize gettext
            GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
            GLib.Intl.bindtextdomain(
                Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR
            );
            GLib.Intl.bind_textdomain_codeset(
                Config.GETTEXT_PACKAGE, "UTF-8"
            );
            GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
        }
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module){
    /* boilerplate - all modules need this */
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(
        typeof(
        Budgie.Plugin
        ), typeof(
            TemplateApplet.Plugin
            )
    );
}