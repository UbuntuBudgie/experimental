using Wnck;
using Gtk;

namespace GetStrut {

    private int[] getstrut() {

    }

    private int[] getplankstrut() {
        
    }



    public static void main (string[] args) {
        Gtk.init(ref args);
        var scr = Wnck.Screen.get_default();
        scr.force_update();
        unowned GLib.List<Wnck.Window> winlist = scr.get_windows();
        foreach (Wnck.Window w in winlist) {
            string name = w.get_name();
            if (name == "plank") {
                int x;
                int y;
                int width;
                int height;
                w.get_geometry(out x, out y, out width, out height);
                print(@"$x, $y, $width, $height\n");
            }
        }
    }

}