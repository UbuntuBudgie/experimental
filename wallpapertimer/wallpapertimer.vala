/* 
* WallPaperTimer
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


class Wallpaper.Timer : GLib.Object {
    public static int main(string[] args) {
        int seconds = int.parse(args[2]) * 1000000;
        string directory = args[1];
        string settingspath = "org.gnome.desktop.background";
        Settings settings = new Settings(settingspath);
        while (true) {
            string[] getlist = walls(directory);
            run_walls(getlist, settings, seconds);
        }
    }
}


private string[] walls(string directory) {
    string[] somestrings = {};
    try {
        var dr = Dir.open(directory);
        string ? filename = null;
        while ((filename = dr.read_name()) != null) {
          string addpic = Path.build_filename(directory, filename);
          somestrings += addpic;
        }
    
    } catch (FileError err) {
          stderr.printf(err.message);
    }
    return somestrings;
}

private void run_walls(string[] paths, Settings settings, int seconds) {
    foreach (string s in paths) {
        Thread.usleep(seconds);
        settings.set_string("picture-uri", "file:///" + s);
    }
}

