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
        private CheckButton[] cbuttons; ////////////////////////////
        private string[] add_args;

        //public signal void toggled.connect(string testarg); ///////////////////////////

        public TemplateSettings(GLib.Settings? settings) {
            /*
            * Gtk stuff, widgets etc. here 
            */
            ondesktop_checkbox = new CheckButton.with_label((_("Show on desktop")));
            cbuttons += ondesktop_checkbox;
            add_args += "desktopweather";
            this.attach(ondesktop_checkbox, 0, 0, 1, 1);
            ondesktop_checkbox.set_active(show_ondesktop);
            ondesktop_checkbox.toggled.connect(toggle_value);

            dynamicicon_checkbox = new CheckButton.with_label((_("Show dynamic panel icon")));
            cbuttons += dynamicicon_checkbox;
            add_args += "dynamicicon";
            this.attach(dynamicicon_checkbox, 0, 1, 1, 1);
            dynamicicon_checkbox.set_active(dynamic_icon);
            dynamicicon_checkbox.toggled.connect(toggle_value);

            forecast_checkbox = new CheckButton.with_label((_("Show forecast in popover")));
            cbuttons += forecast_checkbox;
            add_args += "forecast";
            this.attach(forecast_checkbox, 0, 2, 1, 1);
            forecast_checkbox.set_active(show_forecast);
            forecast_checkbox.toggled.connect(toggle_value);
            this.show_all();
        }

        private int get_buttonarg (ToggleButton button) {
            for (int i = 0; i < cbuttons.length; i++) {
                if (cbuttons[i] == button) {
                    return i;
                }
            } return -1; 
        }

        private void toggle_value(ToggleButton button) {
            bool newsetting = button.get_active();
            string currsetting = add_args[get_buttonarg(button)];
            ws_settings.set_boolean(currsetting, newsetting);
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
    objmodule.register_extension_type(typeof(
        Budgie.Plugin), typeof(TemplateApplet.Plugin)
    );
}