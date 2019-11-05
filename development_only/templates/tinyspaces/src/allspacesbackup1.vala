using Gtk;
using Gdk.X11;

namespace ShowAllSpaces {

    // unowned Gdk.Screen gdkscr;
    unowned Wnck.Screen wnckscr;

    class AllSpacesOverview : Gtk.Window {

        private Label create_label (int currsubj, uint n_spaces) {

            Label spaceheader = new Label("");
            spaceheader.set_xalign(0);
            string s = "\n";
            for (int i=0; i < n_spaces; i++) {
                string add = "○ ";
                if (i == currsubj) {
                    add = "● ";
                }
                s = s + add;
            }
            spaceheader.set_text(s + "\n");
            return spaceheader;
        }

        public AllSpacesOverview () {

            // window basics
            Grid maingrid = new Gtk.Grid();
            unowned GLib.List<Wnck.Window> wnckstack = wnckscr.get_windows ();
            unowned GLib.List<Wnck.Workspace> wnckspaces = wnckscr.get_workspaces ();
            uint n_spaces = wnckspaces.length();
            

            Grid[] spacegrids = {};
            int[] grids_rows = {};

            // create blocks per space
            for (int i=0; i < n_spaces; i++) {
                print(@"$i\n");
                Grid spacegrid = new Grid();
                Label header = create_label (i, n_spaces);
                spacegrid.attach(header, 0, 0, 1, 1);
                spacegrids += spacegrid;
                grids_rows += 0;
            }

            foreach (Wnck.Window w in wnckstack) {
                // get xid
                ulong xid = w.get_xid();
                // get desktop (workspace)
                Wnck.Workspace currspace = w.get_workspace ();
                int currspaceindex = 0;
                int i = 0;
                foreach (Wnck.Workspace win in wnckspaces) {
                    if (win == currspace) {
                        currspaceindex = i;
                        break;
                    }
                    i += 1;
                }
                // type 
                Wnck.WindowType type = w.get_window_type ();
                bool normalwindow = type == Wnck.WindowType.NORMAL;
                // icon
                Gdk.Pixbuf appimage = w.get_mini_icon ();
                // name 
                string wname = w.get_name ();
                print(@"window found: $xid $currspaceindex $type $normalwindow $wname\n");


                // add to grid
                if (normalwindow) {
                    Grid editgrid = spacegrids[currspaceindex];
                    int row = grids_rows[currspaceindex];
                    Label windownamebutton = new Label(wname);
                    windownamebutton.set_xalign(0);
                    editgrid.attach(windownamebutton, 0, row + 1, 1, 1);
                    grids_rows[currspaceindex] = row + 1;
                }


                


                // add to grid in a chaotic way
                
            }

            int blockrow = 0;
            foreach (Grid g in spacegrids) {
                if (grids_rows[blockrow] != 0) {
                    maingrid.attach(g, 1, blockrow + 1, 1, 1);
                }
                blockrow += 1;
            }

            this.add(maingrid);
            this.show_all();


            //  GLib.List<Gdk.Window> wstack = gdkscr.get_window_stack();
            //  foreach (Gdk.Window w in wstack) {
            //      // get xid
            //      Gdk.X11.Window window = (Gdk.X11.Window)w;
            //      uint xid = (uint)window.get_xid();
            //      // get desktop (workspace)
            //      uint32 workspace = window.get_desktop ();
            //      // type / valid
            //      Gdk.WindowTypeHint type = w.get_type_hint ();
            //      bool valid = (type == Gdk.WindowTypeHint.NORMAL);
            //      print(@"$xid, $workspace $type $valid\n");
            //      // get window app icon
            //      Image appicon = w.get_mini_icon (); 
            //  }

        }
    }

    public static int main (string[] args) {

        Gtk.init(ref args);
        // gdkscr = Gdk.Screen.get_default (); // needed?
        wnckscr =  Wnck.Screen.get_default();
        wnckscr.force_update();
        new AllSpacesOverview();
        Gtk.main ();
        return 0;
        
    }
}