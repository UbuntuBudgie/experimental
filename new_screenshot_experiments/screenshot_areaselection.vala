using Gtk;
using Gdk;
using Cairo;

// valac --pkg cairo --pkg gtk+-3.0 --pkg gdk-3.0

/*
/ We don't kill the Gtk thread after the job is done, since this will be part
/ of a comprehensive process, calling and dismissing windows until we are all
/ done.
/ SelectLayer can be run with or without delay (int) as argument.
*/

namespace SelectArea2 {

    class SelectLayer : Gtk.Window {

        int startx;
        int starty;
        int topleftx;
        int toplefty;
        int width;
        int height;

        public SelectLayer(int delay) {
            //  this.destroy.connect(Gtk.main_quit); // not in final version?
            this.set_type_hint(Gdk.WindowTypeHint.UTILITY);
            this.fullscreen();
            // connect draw
            Gtk.DrawingArea darea = new Gtk.DrawingArea();
            darea.draw.connect((w, ctx)=> {
                // draw: x, y, width, height
                draw_rectangle(
                    w, ctx, topleftx, toplefty,
                    width, height
                );
                return true;
            });
            this.add(darea);
            // connect button & move
            this.button_press_event.connect(determine_startpoint);
            this.button_release_event.connect(()=> {
                take_shot(delay);
                return true;
            });
            this.motion_notify_event.connect(update_preview);
            set_win_transparent();
            this.show_all();
            change_cursor();
        }

        private bool determine_startpoint(Gtk.Widget w, EventButton e) {
            /*
            / determine first point of the selected rectangle, which is not
            / necessarily topleft(!)
            */
            startx = (int)e.x;
            starty = (int)e.y;
            return true;
        }

        private bool update_preview(Gdk.EventMotion e) {
            /*
            / determine end of selected area, which is not necessarily
            / bottom_right(!)
            */
            int endx = (int)e.x;
            int endy = (int)e.y;
            // now make sure we define top-left -> bottom-right
            int[] areageo = calculate_rectangle(
                startx, starty, endx, endy
            );
            topleftx = areageo[0];
            toplefty = areageo[1];
            width = areageo[2];
            height = areageo[3];
            //  print(@"latest_update: $topleftx, $toplefty, $width, $height\n");
            // update
            Gdk.Window window = this.get_window();
            var region = window.get_clip_region ();
            window.invalidate_region (region, true);
            return true;
        }

        private int[] calculate_rectangle(
            int startx, int starty, int endx, int endy
        ) {
            /*
            / user might not move in the expected direction (top-left ->
            / bottom-right), so we need to convert & calculate into the
            / right format for drawing the rectangle or taking scrshot
            */
            (endx < startx)? topleftx = endx : topleftx = startx;
            (endy < starty)? toplefty = endy : toplefty = starty;
            return {
                topleftx, toplefty, (startx-endx).abs(), (starty-endy).abs()
            };
        }

        private void draw_rectangle(
            Widget da, Context ctx, int x1, int y1, int x2, int y2
        ) {
            ctx.set_source_rgba(0.0, 0.4, 0.8, 0.3);
            ctx.rectangle(x1, y1, x2, y2);
            ctx.set_line_width(1);
            ctx.stroke_preserve();
            ctx.fill();
        }

        private void set_win_transparent() {
            this.set_app_paintable(true);
            var visual = screen.get_rgba_visual();
            this.set_visual(visual);
            //  this.draw.connect(on_draw);
            this.draw.connect((da, ctx)=> {
                ctx.set_source_rgba(0, 0, 0, 0);
                ctx.set_operator(Cairo.Operator.SOURCE);
                ctx.paint();
                ctx.set_operator(Cairo.Operator.OVER);
                return false;
            });
        }

        private void change_cursor() {
            Gdk.Cursor selectcursor = new Gdk.Cursor.from_name(
                Gdk.Display.get_default(), "crosshair"
            );
            this.get_window().set_cursor(selectcursor);
        }

        private bool take_shot(int delay) {
            /*
            / for now, we are using Gdk.Pixbuf to make the shot, but we'll
            / have the window manager do the job finally.
            */
            this.destroy();
            string user_home = GLib.Environment.get_home_dir();
            Gdk.Window rootwindow = Gdk.get_default_root_window();
            // make sure the colored preview selection is gone before we shoot
            GLib.Timeout.add(100 + (delay*1000), ()=> {
                // checking delay
                print("Bam! there we go.\n");
                Gdk.Pixbuf currpix = Gdk.pixbuf_get_from_window(
                    rootwindow, topleftx, toplefty, width, height
                );
                try {
                    currpix.savev(@"$user_home/firstshot.png", "png", {}, {});
                }
                catch (Error e) {
                    error ("Error: %s", e.message);
                }
                return false;
            });
            print(@"taking a shot: $topleftx, $toplefty, $width, $height\n");
            return true;
        }
    }

    public static int main(string[] args) {
        // Just for testing, we are running it now from cli
        Gtk.init(ref args);
        int delay = 0;
        if (args.length != 1) {
            delay = int.parse(args[1]);
        }
        new SelectLayer(delay);
        Gtk.main();
        return 0;
    }
}