using Gtk;
using Cairo;

/* 
This is a snippet to be used for popup situations, or dialogs like shuffler
window can be populated as usual, but now with <window.add_widget(widget)
radius can be set by the optional arg (default = 16)
*/

// valac --pkg gtk+-3.0 --pkg cairo

namespace OwnRoundedWindow {

    public class RoundedWindow : Gtk.Window {

        Box mainbox;
        Gtk.Layout mainlayout;
        DrawingArea drawing_area;
        //  private const int radius = 8;
        int? radius;
        int? winwidth;
        int? winheight;

        public RoundedWindow(int round = 16) {
            radius = round;
            mainlayout = new Gtk.Layout();
            mainbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            make_background_transparent();
            this.set_decorated(false);
            this.destroy.connect (Gtk.main_quit);
            define_background();           
        }

        private void define_background() {
            drawing_area = new DrawingArea();
            drawing_area.draw.connect(on_draw);
            mainlayout.put(drawing_area, 0, 0);
            mainlayout.put(mainbox, 0, 0);
            this.add(mainlayout);
        }

        public void add_widget (Widget w) {
            mainbox.add(w);
            this.show_all();
        }

        private bool on_draw (Widget da, Context ctx) {
            Allocation alloc;
            /* size of mainbox => windowsize */
            mainbox.get_allocation(out alloc);
            winwidth = alloc.width;
            winheight = alloc.height;
            this.resize(winwidth, winheight);
            drawing_area.set_size_request(winwidth, winheight);
            /* fetch window color */
            var style = this.get_style_context();
            Gdk.RGBA color = (Gdk.RGBA) style.get_property("background-color", Gtk.StateFlags.NORMAL);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            /* draw stuff */
            ctx.set_line_width (radius);
            ctx.set_line_join (LineJoin.ROUND);
            this.draw_background (ctx, ctx.stroke);
            this.draw_background (ctx, ctx.fill);
            return true;
        }

        private delegate void FillorStroke ();

        private void draw_background(Context ctx, FillorStroke draw_method) {
            ctx.save ();
            rectangle (ctx);
            draw_method ();
        }

        private void rectangle (Context ctx) {
            ctx.move_to (radius/2, radius/2);
            ctx.rel_line_to (winwidth - radius, 0);
            ctx.rel_line_to (0, winheight - (radius));
            ctx.rel_line_to (- (winwidth - radius), 0);
            ctx.close_path ();
        }

        private void make_background_transparent() {
            this.set_app_paintable(true);
            var visual = screen.get_rgba_visual();
            this.set_visual(visual);
        }
    }

    private void set_margins (
        Widget w, int l, int r, int t, int b
    ) {
        w.set_margin_start(l);
        w.set_margin_end(r);
        w.set_margin_top(t);
        w.set_margin_bottom(b);
    }

    public static int main(string[] args) {
        Gtk.init(ref args);
        var rounded = new RoundedWindow();
        rounded.show_all();

        /* Just a test to see if we can populate the popup window like a normal one */
        Grid testgrid = new Gtk.Grid();
        set_margins(testgrid, 20, 20, 20, 20);
        testgrid.attach(new Label("Test123 Test123Test123"), 0, 0, 1, 1);
        rounded.add_widget(testgrid);

        Gtk.main();
        return 0;
    }
}