using Soup;
using Json;
using Gee;
using Math;
using Gtk;

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

    private void get_weather (WeatherShow.get_weatherdata test, string key) {
        /*
        * fetch data, write current weather to file. still need to handle
        * forcast, but that is for the applet's popover.
        */

        // conditional; connect to settings
        HashMap result_forecast = test.get_forecast(key);
        string result_current = test.get_current(key);
        print("read_current:\n\n" + result_current);
        // monitored datafile -> todo: move to function!
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


    public static int main (string[] args) {

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

        //print(mapped[1, 0]);

        // get current settings
        ws_settings = WeatherShowFunctions.get_settings(
            "org.ubuntubudgie.plugins.weathershow"
        );
        tempunit = ws_settings.get_string("tempunit");
        ws_settings.changed["tempunit"].connect (() => {
            tempunit = ws_settings.get_string("tempunit");
            print("changed!\n" + tempunit + "\n");
		});  
        // todo: fetch local language, see if it is in the list
        // fallback to default (en) if not. make checkbutton in settings
        string lang = ws_settings.get_string("language");
        string key = ws_settings.get_string("key");
        var test = new get_weatherdata();
        Gtk.init(ref args);
        var win = new Gtk.Window();
        win.destroy.connect(Gtk.main_quit);
        win.show_all();
        get_weather(test, key);
        GLib.Timeout.add (60000, () => {
            get_weather(test, key);   
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

        public string get_current (string key) {
            /* 
            * get "raw" data. if successful, create new data, else create
            * empty lines in the output array.
            */
            string data = fetch_fromsite("weather", "2907911", key);
            if (data != "no data") {
                return getsnapshot(data);
            }
            else {
                return "";
            }
        }

        /////////////////////////////////////////////////////////////////////////
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
        /////////////////////////////////////////////////////////////////////////

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

        public HashMap get_forecast(string key) {
            /* here we create a hashmap<time, string> */
            string data = fetch_fromsite("forecast", "2907911", key);
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
}