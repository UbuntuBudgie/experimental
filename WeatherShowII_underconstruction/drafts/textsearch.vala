private string[] get_matches(string path, string lookfor) {
    // fix possibly messed up title- case
    File datasrc = File.new_for_path(path);
    int len_lookfor = lookfor.char_count();
    string fixed = lookfor.substring(0, 1).up().concat(
        lookfor.substring(1, len_lookfor - 1).down());
    try {
        var dis = new DataInputStream (datasrc.read ());
        string line;
        string[] matches = {};
        while ((line = dis.read_line (null)) != null) {
            // work to do; image change
            if (line.contains(fixed)) {
                matches += line;
            }
        }
        return matches;
    }
    catch (Error e) {
        /* 
        * on each refresh, the file is deleted by the applet
        * just wait for next signal. 
        */
        return {};
    }
}


public static int main(string[] args) {
    string[] matches = get_matches(
        "/usr/lib/budgie-desktop/plugins/budgie-weathershow/cities",
        "denv"
        );
    foreach (string s in matches) {
        print(s + "\n");
    }
    return 0;
}