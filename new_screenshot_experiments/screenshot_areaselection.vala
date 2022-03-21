using Gtk;
using Gdk;
using Cairo;
using Gst;

// valac --pkg cairo --pkg gtk+-3.0 --pkg gdk-3.0 --pkg gstreamer-1.0

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
        double red = 0; // fallback
        double green = 0; // fallback
        double blue = 1; // fallback
        GLib.Settings? theme_settings;

        public SelectLayer(int delay) {
            theme_settings = new GLib.Settings("org.gnome.desktop.interface");
            theme_settings.changed["gtk-theme"].connect(()=> {
                get_theme_fillcolor();
            });
            //  this.destroy.connect(Gtk.main_quit); // not in final version?
            this.set_type_hint(Gdk.WindowTypeHint.UTILITY);
            this.fullscreen();
            this.set_keep_above(true);
            get_theme_fillcolor();
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

        private void get_theme_fillcolor(){
            Gtk.StyleContext style_ctx = new Gtk.StyleContext();
            Gtk.WidgetPath widget_path =  new Gtk.WidgetPath();
            widget_path.append_type(typeof(Gtk.Button));
            style_ctx.set_path(widget_path);
            Gdk.RGBA fcolor = style_ctx.get_color(Gtk.StateFlags.LINK);
            red = fcolor.red;
            green = fcolor.green;
            blue = fcolor.blue;
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
            Widget da, Cairo.Context ctx, int x1, int y1, int x2, int y2
        ) {
            ctx.set_source_rgba(red, green, blue, 0.3);
            ctx.rectangle(x1, y1, x2, y2);
            ctx.fill_preserve();
            ctx.set_source_rgba(red, green, blue, 1.0);
            ctx.set_line_width(0.5);
            ctx.stroke();
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
                play_shuttersound();
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
            //  print(@"taking a shot: $topleftx, $toplefty, $width, $height\n");
            return true;
        }

        private void play_shuttersound (string[]? args=null) {
            // todo: we should probably not hardcode the soundfile?
            Gst.init(ref args);
            Gst.Element pipeline;
            try {
                pipeline = Gst.parse_launch(
                    "playbin uri=file:///usr/share/sounds/freedesktop/stereo/screen-capture.oga"
                );
            }
            catch (Error e) {
                error ("Error: %s", e.message);
            }
            pipeline.set_state (State.PLAYING);
            Gst.Bus bus = pipeline.get_bus();
            bus.timed_pop_filtered(
                Gst.CLOCK_TIME_NONE, Gst.MessageType.ERROR | Gst.MessageType.EOS
            );
            pipeline.set_state (Gst.State.NULL);
        }
    }

    public static int main(string[] args) {
        // Just for testing, we are running it now from cli
        Gtk.init(ref args);
        int delay;
        (args.length != 1)? delay = int.parse(args[1]) : delay = 0;
        new SelectLayer(delay);
        Gtk.main();
        return 0;
    }
}