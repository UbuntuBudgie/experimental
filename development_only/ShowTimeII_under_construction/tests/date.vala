public static void main(string[] args) {
    string langdata = Environment.get_variable("LOCALE");
    print("langdata: " + langdata + "\n");
    var tzone = new TimeZone.local();
    var currtime = new DateTime.now_local ();
    string tmention = "aa";
    var currtime2 = new DateTime.from_iso8601(tmention, tzone);
    print("tmention" + tmention + "\n");
    string t = currtime.format("%a");
    print(t + "\n");
}
