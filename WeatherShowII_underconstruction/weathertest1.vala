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

namespace weathershow {


    /* make sure settings are defined on applet startup */
    private GLib.Settings ws_settings;


    /* fake applet, testing the function to get data */
    /* todo: set lang and units as args, move values to gsettings */
    public static int main () {
        

        int start = 0;
        var test = new get_weatherdata();
        while (true) {
            start += 1;
            Thread.usleep(10000000);
            string[] result = test.get_current("celsius");
            foreach (string s in result) {
                print("%s\n", s);
            }
            print(@"$start\n");
        }
        return 0;
    }








    public class get_settingsdata {
    }



    public class get_weatherdata {


        private string fetch_fromsite (
            string wtype, string city, string ? lang = null
        ) {
            /* fetch data from OWM */
            string website = "http://api.openweathermap.org/data/2.5/"; /* move to gsettings key */
            /* please don't copy the string below for use outside this applet. */
            string key = "cfd52641f834ca80ed94a28de864bb64";
            /* see if lang is set */
            string langstring;
            if (lang != null) {
                langstring = "&".concat("lang=", lang);
            }
            else {
                langstring = "";
            }
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
            /* check if the value exists, create the int- output if so */
            if (obj.has_member(val)) {
                float info = (float) obj.get_double_member(val);
                return info;
            }
            return 1000;
        }

        private HashMap get_categories(Json.Object rootobj) {
            var map = new HashMap<string, Json.Object> ();
            /* get cons. weatherdata, wind data and general data */
            map["weather"] = rootobj.get_array_member("weather").get_object_element(0);
            map["wind"] = rootobj.get_object_member ("wind");
            map["main"] = rootobj.get_object_member ("main");
            return map;
        }

        public string[] get_current (string temp_unit) {
            /* get raw data and make a hasmap from the nodes */
            string data = fetch_fromsite("weather", "2907911", "nl");
            //print(data + "\n");
            string[] directions = {"↓", "↙", "←", "↖", "↑", "↗", "→", "↘", "↓"};

            if (data != "no data") {
                string tempdisplay;
                var parser = new Json.Parser ();
                parser.load_from_data (data);
                var root_object = parser.get_root ().get_object ();
                HashMap<string, Json.Object> map = get_categories(root_object);
                /* get weatherline src = string*/
                string skydisplay = check_stringvalue(map["weather"], "description");
                /* get temp src = float */
                float temp = check_numvalue(map["main"], "temp");
                if (temp != 1000) {
                    if (temp_unit == "celsius") {
                        temp = temp - (float) 273.15;
                        tempdisplay = temp.to_string().concat("℃");
                    }
                    else {
                        temp = (temp * (float) 1.80) - (float) 459.67;
                        tempdisplay = temp.to_string().concat("℉");
                    }
                }
                else {
                    tempdisplay = "";
                }
                /* get wind speed src = float */
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
                /* so, to conclude: */
                return {
                    skydisplay, tempdisplay, 
                    wspeeddisplay.concat(" ", wdirectiondisplay), humiddisplay
                };
            }
            else {
                return {};
            }
        }
    }
}

