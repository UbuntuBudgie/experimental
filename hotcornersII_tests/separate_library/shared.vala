using Gee;

/* 
* HotCornersII
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

namespace BudgieExtrasLib {

    public string[] getcommands() {

        /* 
        * read the commands from the commands file
        * if it does not exist, fall back to defaults
        */

        HashMap<string, string> pathdata;

        pathdata = get_path ("hotcorners", "hotc_commands");
        string path = pathdata.get ("file");

        string[] commands = {};
        var file = File.new_for_path(path);
        //string output = "";
        try {
            var content = new DataInputStream(file.read());
            string line;
            int i = 0;
            while (i < 4) {
                line = content.read_line();
                print(line + "\n");
                commands += line;
                i += 1;
            } 
        }
        /* in case the file is not found, fall back to default */
        catch (GLib.IOError err) {
            commands = {
                "false",
                "false",
                "false",
                "false",
            };
        }
        foreach (string add in commands) {
            print("here we go " + add + "\n");
        }
        return commands;
    }

    public HashMap get_path (string applet_name, string ? filename = null) {

        /*
        * given the applet settingsfolder name, tell the full path
        * also, if optional filename is used as second arg, tell the
        * full path to the file
        */
        
        var map = new HashMap<string, string> ();
        string home = Environment.get_home_dir();
        string extras = Path.build_filename(
            home, ".config/budgie-extras", applet_name
        );

        map.set("appsettings", extras);

        if (filename != null) {
            string filepath = Path.build_filename(
                extras, filename
            );
            map.set("file", filepath);
        }
        else {
            map.set("file", "");
        }
        return map;
    }
}

            
            
            

            