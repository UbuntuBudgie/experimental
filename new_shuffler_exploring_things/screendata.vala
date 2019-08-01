using Gtk;
using Gdk;
using Gee;

namespace newshuffler {

    // we are calculating in real pixel numbers
    private Gdk.Monitor[] monitors;
    private int n_mons;

    private void getscreendata () {
        Gdk.Display dsp = Gdk.Display.get_default();
        n_mons = dsp.get_n_monitors();
        for (int i=0; i < n_mons; i++) {
            monitors += dsp.get_monitor(i);
        }
    }

    private HashMap lookup_monitordata (int monitorindex) {
        var monitordata = new HashMap<string, int> ();
        var currmon = monitors[monitorindex];
        Rectangle area = currmon.get_geometry();
        int scale = currmon.get_scale_factor();
        monitordata.set("x", area.x*scale);
        monitordata.set("y", area.y*scale);
        monitordata.set("width", area.width*scale);
        monitordata.set("height", area.height*scale);
        monitordata.set("scale", scale);
        return monitordata;
    }

    public static void main(string[] args) {
        Gtk.init(ref args);
        newshuffler.getscreendata();
        HashMap<string, int> firstmon = newshuffler.lookup_monitordata(0);
        int h = firstmon["height"];
        print(@"height: $h\n");
        Gtk.main();
    }
}


