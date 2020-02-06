using Gtk;
using Cairo;

// valac --pkg gtk+-3.0 --pkg cairo monkey.vala

namespace TransparentWindowTest {

    public static void main(string[] args) {
        Gtk.init(ref args);
        new TransparentWindow ();
        Gtk.main();
    }

    public class TransparentWindow : Gtk.Window {

        string monkeycss = """
        .monkeyfont {
        font-size: 50px;
        color: white;
        }
        """;
        Label monkeylabel;

        public TransparentWindow () {
            // window definitions
            this.set_title ("Monkey");
            this.set_type_hint(Gdk.WindowTypeHint.DESKTOP);
            this.set_decorated(false);
            // ...and here we go
            var maingrid = new Grid();
            this.add(maingrid);
            monkeylabel = new Label("Monkey on your desktop");
            maingrid.attach(monkeylabel, 0, 0, 1, 1);
            this.destroy.connect(Gtk.main_quit);
            // transparency
            var screen = this.get_screen();
            this.set_app_paintable(true);
            var visual = screen.get_rgba_visual();
            this.set_visual(visual);
            this.draw.connect(on_draw);
            // set font
            set_monkeyfont(screen);
            this.move(300, 300);
            this.show_all();
        }

        private bool on_draw (Widget da, Context ctx) {
            // needs to be connected to transparency settings change
            ctx.set_source_rgba(0, 0, 0, 0);
            ctx.set_operator(Cairo.Operator.SOURCE);
            ctx.paint();
            ctx.set_operator(Cairo.Operator.OVER);
            return false;
        }

        public void set_monkeyfont (Gdk.Screen screen) {
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(monkeycss);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
                monkeylabel.get_style_context().add_class("monkeyfont");
            }
            catch (Error e) {
                // not much to be done
                print("Error loading css data\n");
            }
        }
    }
}