using Gtk;
using Gdk.X11;

namespace ShowAllSpaces {

    unowned Wnck.Screen wnckscr;
    private ScrolledWindow scrollwin;

    class AllSpacesOverview : Gtk.Window {

        private Button create_spacebutton (int currsubj, uint n_spaces) {
            // creates the header-per-workspace button
            Button spaceheader = new Button.with_label("");
            Gtk.Label l = (Gtk.Label)spaceheader.get_child();
            l.set_xalign((float)0.5);
            string s = "";
            for (int i=0; i < n_spaces; i++) {
                string add = "○ ";
                if (i == currsubj) {
                    add = "● ";
                }
                s = s + add;
            }
            l.set_text(s);
            return spaceheader;
        }

        public AllSpacesOverview () {
            // window basics
            this.set_decorated(false);
            Grid maingrid = new Gtk.Grid();
            // topleft / botomrignt space
            maingrid.attach(new Label("\t"), 0, 0, 1, 1);
            maingrid.attach(new Label("\t"), 100, 100, 1, 1);

            unowned GLib.List<Wnck.Window> wnckstack = wnckscr.get_windows ();
            unowned GLib.List<Wnck.Workspace> wnckspaces = wnckscr.get_workspaces ();
            uint n_spaces = wnckspaces.length();
            
            // create blocks per space
            Grid[] spacegrids = {};
            int[] grids_rows = {}; // <- to keep track of row while adding buttons
            for (int i=0; i < n_spaces; i++) {
                Grid spacegrid = new Grid();
                Button header = create_spacebutton (i, n_spaces);
                header.set_relief(Gtk.ReliefStyle.NONE);
                header.set_size_request(260, 0);
                // lazy layout
                spacegrid.attach(header, 2, 0, 10, 1);
                spacegrid.attach(new Label(" "), 1, 1, 1, 1);
                spacegrid.attach(new Label(""), 0, 1, 1, 1);
                spacegrid.attach(new Label(""), 0, 100, 1, 1);

                spacegrids += spacegrid;
                grids_rows += 0;
            }
            // collect window data & create windowname-buttons
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
                Gdk.Pixbuf app_pixbuf = w.get_mini_icon ();
                Gtk.Image app_image = new Gtk.Image.from_pixbuf(app_pixbuf);
                // name 
                string wname = w.get_name ();
                print(@"window found: $xid $currspaceindex $type $normalwindow $wname\n");
                // add to grid
                if (normalwindow) {
                    // fetch the corresponding grid from array & add button
                    Grid editgrid = spacegrids[currspaceindex];
                    int row = grids_rows[currspaceindex];
                    Button windownamebutton = new Gtk.Button.with_label(wname);
                    windownamebutton.set_relief(Gtk.ReliefStyle.NONE);
                    Gtk.Label wbuttonlabel = (Gtk.Label)windownamebutton.get_child();
                    wbuttonlabel.set_ellipsize(Pango.EllipsizeMode.END);
                    wbuttonlabel.set_max_width_chars(28);
                    wbuttonlabel.set_xalign(0);
                    editgrid.attach(windownamebutton, 2, row + 2, 10, 1);
                    editgrid.attach(app_image, 0, row + 2, 1, 1);
                    grids_rows[currspaceindex] = row + 1;
                }
            }

            int blockrow = 0;
            foreach (Grid g in spacegrids) {
                if (grids_rows[blockrow] != 0) {
                    maingrid.attach(g, 1, blockrow + 1, 1, 1);
                }
                blockrow += 1;
            }
            scrollwin = new Gtk.ScrolledWindow (null, null);
            scrollwin.set_min_content_height(350);
            scrollwin.set_min_content_width(380);
            scrollwin.add(maingrid);
            this.add(scrollwin);
            this.show_all();
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