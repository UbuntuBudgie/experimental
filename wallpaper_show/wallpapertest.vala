/*
 * First babysteps on programming on Vala. This code will switch
 * wallpapers from a directory of images. Arguments are the folder of
 * images and the time the images shows. After eacht time the complete
 * set of images has passed, the list of images is refreshed, so
 * images may be added or removed from the directory while the
 * executable is running.
 */

class Wallpaper.Test : GLib.Object {
public
  static int main(string[] args) {
    int seconds = int.parse(args[2]) * 1000000;
    string directory = args[1];
    walls(directory);
    string settingspath = "org.gnome.desktop.background";
    Settings settings = new Settings(settingspath);
    while (1 == 1) {
      string[] getlist = walls(directory);
      run_walls(getlist, settings, seconds);
    }
    return 0;
  }
}

private
string[] walls(string directory) {
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

private
void run_walls(string[] paths, Settings settings, int seconds) {
  foreach (string s in paths) {
    Thread.usleep(seconds);
    settings.set_string("picture-uri", "file:///" + s);
  }
}

