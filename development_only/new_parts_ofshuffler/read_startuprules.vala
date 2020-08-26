/*
* ShufflerII
* Author: Jacob Vlijm
* Copyright © 2017-2020 Ubuntu Budgie Developers
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

/*
/ this is just the functionality to read created .rules files for new windows.
/ it is planned to be added to the daemon, which will watch the .rules directory
/ and update the HashTable on changes.
*/

/*
/ .windowrule files look like (wm_class is filename and key):
/ XPosition=
/ YPosition=
/ Rows=
/ Cols=
/ XSpan=
/ YSpan=
/ Monitor=
*/

// valac --pkg gio-2.0


namespace get_rulesdata {

    HashTable<string, Variant> windowrules;

    private string create_dirs_file (string subpath) {
        // defines, and if needed, creates directory for rules
        string homedir = Environment.get_home_dir();
        string fullpath = GLib.Path.build_path(
            GLib.Path.DIR_SEPARATOR_S, homedir, subpath
        );
        GLib.File file = GLib.File.new_for_path(fullpath);
        try {
            file.make_directory_with_parents();
        }
        catch (Error e) {
            /* the directory exists, nothing to be done */
        }
        return fullpath;
    }

    private bool endswith (string str, string tail ) {
        int str_len = str.length;
        int tail_len = tail.length;
        if (tail_len  <= str_len) {
            if (str[str_len-tail_len:str_len] == tail) {
                return true;
            }
        }
        return false;
    }

    private bool startswith (string str, string substr ) {
        int str_len = str.length;
        int field_len = substr.length;
        if (field_len  <= str_len) {
            if (str[0:field_len] == substr) {
                return true;
            }
        }
        return false;
    }

    private void readfile (string rulesdir, string fname) {
        // read file & add resulting Variant to HashTable
        // since wm_class is filename, it's key. No need to make it a field
        string monitor = "";
        string xposition = "";
        string yposition = "";
        string rows = "";
        string cols = "";
        string xspan = "";
        string yspan = "";

        var file = File.new_for_path (rulesdir.concat("/", fname));
        string[] fields = {
            "Monitor", "XPosition", "YPosition",
            "Rows", "Cols", "XSpan", "YSpan"
        };

        try {
            var dis = new DataInputStream (file.read ());
            string line;
            // walk through lines, fetch arguments
            while ((line = dis.read_line (null)) != null) {
                int fieldindex = 0;
                foreach (string field in fields) {
                    if (startswith (line, field)) {
                        string new_value = line.split("=")[1];
                        switch (fieldindex) {
                            case 0:
                                monitor = new_value;
                                break;
                            case 1:
                                xposition = new_value;
                                break;
                            case 2:
                                yposition = new_value;
                                break;
                            case 3:
                                rows = new_value;
                                break;
                            case 4:
                                cols = new_value;
                                break;
                            case 5:
                                xspan = new_value;
                                break;
                            case 6:
                                yspan = new_value;
                                break;
                        }
                    }
                    fieldindex += 1;
                }
            }
        }
        catch (Error e) {
            error ("%s", e.message);
        }
        // populate HashTable here
        Variant newrule = new Variant(
            "(sssssss)" , monitor, xposition,
            yposition, rows, cols, xspan, yspan
        );
        windowrules.insert(fname, newrule);
    }

    private void find_rules (string rulesdir) {
        // walk through files, collect rules
        try {
            var dr = Dir.open(rulesdir);
            string? filename = null;
            // walk through relevant files
            while ((filename = dr.read_name()) != null) {
                if (endswith(filename, ".windowrule")) {
                    readfile (rulesdir, filename);
                }
            }
        }
        catch (Error e) {
            error ("%s", e.message);
        }
    }

    public static void main (string[] args) {
        // define & create dir if it doesn't
        string rulesdir = create_dirs_file(".config/budgie-extras/shuffler");
        // create empty HashTable
        windowrules = new HashTable<string, Variant> (str_hash, str_equal);
        // go catch some rules
        find_rules(rulesdir);
    }

}