namespace GridWindowSection {

    int gridcols;
    int gridrows;
    Gtk.Button[] buttonarr;
    int[] xpos;
    int[] ypos;
    int cols;
    int rows;

    public class GridWindow: Gtk.Window {

        Gtk.Grid maingrid;

        public GridWindow() {
            this.title = "Gridwindow";
            maingrid = new Gtk.Grid();
            this.add(maingrid);
            // var controlsgrid = new Gtk.Grid();
            // maingrid.attach(controlsgrid, 0, 0, 1, 1);
            setgrid();
            add_gridcontrols();
            maingrid.show_all();
            this.show_all();
        }

        private void setgrid() {
            var buttongrid = new Gtk.Grid();
            maingrid.attach(buttongrid, 0, 0, 1, 1);
            for (int iy=0; iy < gridrows; iy++) {
                for (int ix=0; ix < gridcols; ix++) {
                    //  print(@"$ix, $iy, $gridcols, $gridrows\n");
                    var gridbutton = new Gtk.Button();
                    gridbutton.set_size_request(75, 75);
                    buttongrid.attach(gridbutton, ix, iy, 1, 1);
                    xpos += ix;
                    ypos += iy;
                    buttonarr += gridbutton;
                    print(@"adding $ix\n");
                    gridbutton.clicked.connect(show_pos);
                }
            }
        }

        private void add_gridcontrols () {
            print("Adding comtrols\n");
            var horbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            maingrid.attach(horbox, 0, 1, 1, 1);

            var button_up = new Gtk.Button.from_icon_name(
                "pan-up-symbolic", Gtk.IconSize.LARGE_TOOLBAR
            );
            button_up.set_relief(Gtk.ReliefStyle.NONE);

            var button_down = new Gtk.Button.from_icon_name(
                "pan-down-symbolic", Gtk.IconSize.LARGE_TOOLBAR
            );
            button_down.set_relief(Gtk.ReliefStyle.NONE);
            horbox.pack_end(button_up, false, false, 0);
            horbox.pack_end(button_down, false, false, 0);


            var vertbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            maingrid.attach(vertbox, 1, 0, 1, 1);

            var button_right = new Gtk.Button.from_icon_name(
                "pan-end-symbolic", Gtk.IconSize.LARGE_TOOLBAR
            );
            button_right.set_relief(Gtk.ReliefStyle.NONE);

            var button_left = new Gtk.Button.from_icon_name(
                "pan-end-symbolic-rtl", Gtk.IconSize.LARGE_TOOLBAR
            );
            button_left.set_relief(Gtk.ReliefStyle.NONE);
            vertbox.pack_end(button_left, false, false, 0);
            vertbox.pack_end(button_right, false, false, 0);
        }
    }

    private int find_buttonindex(Gtk.Button b) {
        int i = 0;
        foreach (Gtk.Button button in buttonarr) {
            if (button == b) {
                return i;
            }
            i += 1;
        }
        return -1;
    }

    private void show_pos (Gtk.Button b) {
        int index = find_buttonindex(b);
        if (index != -1) {
            int x = xpos[index];
            int y = ypos[index];
            print(@"$x, $y, $cols, $rows\n");
        }
    }

    public static void main(string[] args) {
        Gtk.init(ref args);
        gridcols = 3;
        gridrows = 2;
        new GridWindow();
        Gtk.main();
    }
}