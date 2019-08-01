using Gdk;
using Gtk;

// Let's just convert the existing python function for now

namespace some_shuffler {

    Gdk.Screen gdk_scr;

    public void get_docks () {
        gdk_scr = Gdk.Screen.get_default();
        GLib.List<Gdk.Window> gdk_winlist = gdk_scr.get_window_stack();
        foreach (Gdk.Window w in gdk_winlist) {
            Gdk.WindowTypeHint wtype = w.get_type_hint();
            if (wtype == Gdk.WindowTypeHint.DOCK) {
                print("Yay\n");
            }
        }
    }

    public static void main(string[] args) {
        Gtk.init(ref args);
        get_docks();      
    }

}