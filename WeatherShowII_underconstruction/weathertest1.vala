using Soup;
using Json;
using Gee;
using Math;

/* 
* we need this function to get the current data on the weather. either
* as a forecast, (multiple days, arg = "forecast") or a single day (arg =
* "weather"). multiple days is just a multi version of the single day- 
* data. 
* Data:
* weather(0) -> "description" (=sky state)
* weather(0) -> "id" (=weather code)
* weather(0) -> "icon" (=icon code) <- needed or not?
* main -> "temp" (temperature)
* main -> "humidity" (humidity)
* wind -> "deg" (wind direction)
* wind -> "speed" (wind speed)
* depends on libsoup2.4-dev!
*/


namespace WeatherShowFunctions {

    private GLib.Settings get_settings(string path) {
        var settings = new GLib.Settings(path);
        return settings;
    }
}


namespace WeatherShow {

    /* make sure settings are defined on applet startup */
    private GLib.Settings ws_settings;
    private string lang;
    private string tempunit;
    private string[] directions;
    /* fake applet, testing the function to get data */
    /* todo: set lang and units as args, move values to gsettings */
    /* no more! ^^^ make values namespace- wide, since they are used by multiple classes*/
    public static int main (string[] args) {

        directions = {"↓", "↙", "←", "↖", "↑", "↗", "→", "↘", "↓"};
        /* get current settings */
        ws_settings = WeatherShowFunctions.get_settings(
            "org.ubuntubudgie.plugins.weathershow"
        );
        tempunit = ws_settings.get_string("tempunit");
        print("tempunit is: " + tempunit);

        ws_settings.changed["tempunit"].connect (() => {
            tempunit = ws_settings.get_string("tempunit");
            print("changed!\n" + tempunit + "\n");
		}); 
        /* 
        * todo: fetch local language, see if it is in the list
        * fallback to default (en) if not. make checkbutton in settings
        */
        string lang = ws_settings.get_string("language");
        string key = ws_settings.get_string("key");
        var test = new get_weatherdata();
        Gtk.init(ref args);
        var win = new Gtk.Window();
        win.destroy.connect(Gtk.main_quit);
        win.show_all();
        int start = 0;
        GLib.Timeout.add (5000, () => {
            start += 1;
            string[] result = test.get_current(key);
            foreach (string s in result) {
                print("%s\n", s);
            }
            print(@"$start\n\n");
            return true;
        });
        Gtk.main();
        return 0;
    }


    public class get_weatherdata {

        private string fetch_fromsite (
            string wtype, string city, string key
        ) {
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
            return map;
        }

        private string[] getsnapshot (string data) {
            var parser = new Json.Parser ();
            parser.load_from_data (data);
            var root_object = parser.get_root ().get_object ();
            HashMap<string, Json.Object> map = get_categories(
                root_object
            );
            /* get weatherline */
            string skydisplay = check_stringvalue(
                map["weather"], "description"
            );
            /* get temp */
            string tempdisplay;
            float temp = check_numvalue(map["main"], "temp");
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
            /* get wind speed */
            float wspeed = check_numvalue(map["wind"], "speed");
            string wspeeddisplay;
            if (wspeed != 1000) {
                wspeeddisplay = wspeed.to_string().concat(" m/sec");
            }
            else {
                wspeeddisplay = "";
            }
            /* get wind direction */
            float wdirection = check_numvalue(map["wind"], "deg");
            string wdirectiondisplay;
            if (wdirection != 1000) {
                int iconindex = (int) Math.round(wdirection/45);
                wdirectiondisplay = directions[iconindex];
            }
            else {
                wdirectiondisplay = "";
            }
            /* get humidity */
            string humiddisplay;
            int humid = (int) check_numvalue(map["main"], "humidity");
            if (humid != 1000) {
                humiddisplay = humid.to_string().concat("%");
            }
            else {
                humiddisplay = "";
            }
            return {
                skydisplay, tempdisplay, 
                wspeeddisplay.concat(" ", wdirectiondisplay), humiddisplay
            };
        }

        public string[] get_current (string key) {
            /* 
            * get "raw" data. if successful, create new data, else create
            * empty lines in the output array.
            */
            string data = fetch_fromsite("weather", "2907911", key);
            if (data != "no data") {
                return getsnapshot(data);
            }
            else {
                return {};
            }
        }
    }
}

