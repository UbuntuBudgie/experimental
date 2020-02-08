using Gtk;

namespace PowerTest {

    [DBus (name = "org.freedesktop.UPower.Device")]
    public interface Device : Object {
        public abstract double percentage {get;}
    }

    public static void main(string[] args) {
        Gtk.init(ref args);
        new OneMoreWindow();
        Gtk.main();
    }


    public class OneMoreWindow : Gtk.Window {

        GLib.Settings percentage_settings;
        string origindicatorcss = """
        .indicatorfont {
        font-size: {fontsize}px;
        color: red;
        }
        """;
        string indicatorcss;
        new Gdk.Screen screen;
        Gtk.CssProvider css_provider = new Gtk.CssProvider();
        Label percentlabel;

        public OneMoreWindow () {
            percentage_settings = new GLib.Settings("org.rinzwind.batterystatus");
            percentage_settings.changed.connect(update_windowprops);
            screen = this.get_screen();
            percentlabel = new Label("");

            try {
                Device upower1 = Bus.get_proxy_sync(
                    BusType.SYSTEM,
                    "org.freedesktop.UPower",
                    "/org/freedesktop/UPower/devices/battery_BAT0"
                );

                update_label(upower1);
                GLib.Timeout.add_seconds(10, ()=> {
                    update_label(upower1);
                    return true;
                });
                this.add(percentlabel);
                update_window();
                this.show_all();
            }
            catch (Error e) {
                print("Something went wrong, but I am not telling you what\n");
            }
        }

        public void set_font () {
            try {
                css_provider.load_from_data(indicatorcss);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
                percentlabel.get_style_context().add_class("indicatorfont");
            }
            catch (Error e) {
                // not much to be done
                print("Error loading css data\n");
            }
        }

        private void update_label (Device upower1) {
            GLib.Idle.add( () => {
                string perc = upower1.percentage.to_string();
                percentlabel.set_text(@"$perc%");
                return false;
            });
        }

        private void update_windowprops () {
            int xpos = percentage_settings.get_int("xpos");
            int ypos = percentage_settings.get_int("ypos");
            int fontsize = percentage_settings.get_int("fontsize");
            indicatorcss = origindicatorcss.replace("{fontsize}", @"$fontsize");
            GLib.Idle.add( () => {
                set_font();
                this.move(xpos, ypos);
                return false;
            });
        }
    }
}