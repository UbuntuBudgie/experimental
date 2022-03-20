using Gtk;

namespace ScreenshotHome {

    class ScreenshotHomeWindow : Gtk.Window {

        GLib.Settings? buttonplacement;
        Gtk.HeaderBar topbar;
        int selectmode = 0;
        bool ignore = false;

        public ScreenshotHomeWindow() {

            this.set_resizable(false);

            string home_css = """
            .buttonlabel {
                margin-top: -12px;
            }
            .centerbutton {
                border-radius: 0px 0px 0px 0px;
                border-width: 0px;
            }
            .shootbutton {
                border-radius: 5px 5px 5px 5px;
                border-width: 0px;
            }
            .optionslabel {
                margin-left: 12px;
                margin-bottom: 2px;
            }
            """;

            topbar = new Gtk.HeaderBar();
            topbar.show_close_button = true;
            this.set_titlebar(topbar);

            /*
            / left or right windowbuttons, that's the question when
            / (re-?) arranging headerbar buttons
            */
            buttonplacement = new GLib.Settings(
                "com.solus-project.budgie-wm"
            );
            buttonplacement.changed["button-style"].connect(()=> {
                print("buttons moved\n");
                rearrange_headerbar();
            });
            rearrange_headerbar();

            // css stuff
            Gdk.Screen screen = this.get_screen();
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(home_css);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
            }
            catch (Error e) {
                // not much to be done
                print("Error loading css data\n");
            }

            // so, let's add some content - areabuttons
            Grid maingrid = new Gtk.Grid();
            maingrid.set_row_spacing(10);
            set_margins(maingrid, 25, 25, 25, 25);
            Gtk.Box areabuttonbox = setup_areabuttons();
            maingrid.attach(areabuttonbox, 0, 0, 1, 1);
            maingrid.attach(new Label(""), 0, 1, 1, 1);

            // - show pointer
            Gtk.Box showpointerbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Gtk.Grid showpointerswitchgrid = new Gtk.Grid();
            Gtk.Switch showpointerswitch = new Gtk.Switch();
            //  showpointerswitch.set_vexpand(true);
            showpointerswitchgrid.attach(showpointerswitch, 0, 0, 1, 1);
            showpointerbox.pack_end(showpointerswitchgrid);
            Label showpointerlabel = new Label("Show Pointer");
            // let's set a larger width than the actual, so font size won't matter
            showpointerlabel.set_size_request(290, 10);
            showpointerlabel.get_style_context().add_class("optionslabel");
            showpointerlabel.xalign = 0;
            showpointerbox.pack_start(showpointerlabel);
            maingrid.attach(showpointerbox, 0, 2, 1, 1);

            // - delay
            Gtk.Box delaybox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Gtk.Grid spinbuttongrid = new Gtk.Grid();
            Gtk.SpinButton delayspin = new Gtk.SpinButton.with_range(0, 60, 1);
            spinbuttongrid.attach(delayspin, 1, 0, 1, 1);
            delaybox.pack_end(spinbuttongrid);
            Label delaylabel = new Label("Delay in seconds");
            // let's set a larger width than the actual, so font size won't matter
            delaylabel.set_size_request(230, 10);
            delaylabel.get_style_context().add_class("optionslabel");
            delaylabel.xalign = 0;
            delaybox.pack_start(delaylabel);
            maingrid.attach(delaybox, 0, 3, 1, 1);

            this.add(maingrid);
            this.show_all();
        }

        private void rearrange_headerbar() {
            /*
            / we want screenshot button and help button arranged
            / outside > inside, so order depends on button positions
            */
            string buttonpos = buttonplacement.get_string("button-style");
            print(@"moved to: $buttonpos\n");
            foreach (Widget w in topbar.get_children()) {
                w.destroy();
            }
            Gtk.Button shootbutton = new Gtk.Button.from_icon_name (
                "shootscreen-symbolic", Gtk.IconSize.DND
            );
            shootbutton.set_size_request(60, 4);
            shootbutton.get_style_context().add_class("shootbutton");
            shootbutton.get_style_context().add_class(
                Gtk.STYLE_CLASS_SUGGESTED_ACTION
            );
            Gtk.Button helpbutton = new Gtk.Button();
            helpbutton.label = "･･･";
            helpbutton.get_style_context().add_class(
                Gtk.STYLE_CLASS_RAISED
            );
            if (buttonpos == "left") {
                topbar.pack_end(shootbutton);
                topbar.pack_end(helpbutton);
            }
            else {
                topbar.pack_start(shootbutton);
                topbar.pack_start(helpbutton);
            }
            this.show_all();
        }

        private Gtk.Box setup_areabuttons() {
            Gtk.Box areabuttonbox = new Gtk.Box(
                Gtk.Orientation.HORIZONTAL, 0
            );
            // translate!
            string[] areabuttons_labels = {
                "Screen", "Window", "Selection"
            };
            string[] icon_names = {
                "selectscreen-symbolic",
                "selectwindow-symbolic",
                "selectselection-symbolic"
            };
            int i = 0;
            ToggleButton[] selectbuttons = {};
            foreach (string s in areabuttons_labels) {
                Gtk.Image selecticon = new Gtk.Image.from_icon_name(
                    icon_names[i], Gtk.IconSize.DIALOG
                );
                selecticon.pixel_size = 60;
                Grid buttongrid = new Gtk.Grid();
                buttongrid.attach(selecticon, 0, 0, 1, 1);
                // label
                Label selectionlabel = new Label(s);
                selectionlabel.set_size_request(90, 10); ////
                selectionlabel.xalign = (float)0.5;
                selectionlabel.get_style_context().add_class("buttonlabel");
                buttongrid.attach(selectionlabel, 0, 1, 1, 1);
                // grid in button
                ToggleButton b = new Gtk.ToggleButton();
                b.get_style_context().add_class("centerbutton");
                b.add(buttongrid);
                areabuttonbox.pack_start(b);
                selectbuttons += b;
                b.clicked.connect(()=> {
                    if (!ignore) {
                        print("clicked\n");
                        ignore = true;
                        select_action(b, selectbuttons);
                        b.set_active(true);
                        GLib.Timeout.add(200, ()=> {
                            ignore = false;
                            return false;
                        });
                    }
                });
                i += 1;
            }
            return areabuttonbox;
        }

        private void select_action(
            ToggleButton b, ToggleButton[] btns
        ) {
            int i = 0;
            foreach (ToggleButton bt in btns) {
                if (bt != b) {
                    bt.set_active(false);
                }
                else {
                    selectmode = i;
                    print(@"selectmode: $i\n");
                }
                i += 1;
            }
        }

        private void set_margins(
            Gtk.Grid grid, int left, int right, int top, int bottom
        ) {
            grid.set_margin_start(left);
            grid.set_margin_end(right);
            grid.set_margin_top(top);
            grid.set_margin_bottom(bottom);
        }
    }


    public static int main(string[] args) {
        Gtk.init(ref args);
        new ScreenshotHomeWindow();
        Gtk.main();
        return 0;
    }
}