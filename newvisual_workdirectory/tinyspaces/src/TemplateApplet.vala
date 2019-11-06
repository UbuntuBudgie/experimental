using Gtk;
using Gdk;
using Gdk.X11;

/*
* Template
* Author: Jacob Vlijm
* Copyright © 2017-2018 Ubuntu Budgie Developers
* Website=https://ubuntubudgie.org
* This program is free software: you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the Free
* Software Foundation, either version 3 of the License, or any later version.
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details. You should have received a copy of the GNU General Public
* License along with this program.  If not, see
* <https://www.gnu.org/licenses/>.
*/


namespace TemplateApplet {

    public class TemplatePopover : Budgie.Popover {

        Gdk.X11.Window timestamp_window;
        unowned Wnck.Screen wnckscr;
        private ScrolledWindow scrollwin;
        private Gtk.EventBox indicatorBox;
        private Grid maingrid;

        public TemplatePopover(Gtk.EventBox indicatorBox) {
            GLib.Object(relative_to: indicatorBox);
            this.indicatorBox = indicatorBox;

            // X11 stuff, non-dynamic part
            unowned X.Window xwindow = Gdk.X11.get_default_root_xwindow();
            unowned X.Display xdisplay = Gdk.X11.get_default_xdisplay();
            Gdk.X11.Display display = Gdk.X11.Display.lookup_for_xdisplay(xdisplay);
            timestamp_window = new Gdk.X11.Window.foreign_for_display(display, xwindow);
            // Wnck initial stuff
            wnckscr =  Wnck.Screen.get_default();
            wnckscr.force_update();
            maingrid = new Gtk.Grid();
            maingrid.show_all();
            produce_content ();
            scrollwin.add(maingrid);
            this.add(scrollwin);
            //this.show_all();
            wnckscr.window_closed.connect(update_interface);
            wnckscr.window_opened.connect(update_interface);
        }

        private uint get_now() {
            // timestamp
            return Gdk.X11.get_server_time(timestamp_window);
        }

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

        private void produce_content () {

            // topleft / botomrignt space
            maingrid.attach(new Label("\t"), 0, 0, 1, 1);
            maingrid.attach(new Label("\t"), 100, 100, 1, 1);

            unowned GLib.List<Wnck.Window> wnckstack = wnckscr.get_windows ();
            unowned GLib.List<Wnck.Workspace> wnckspaces = wnckscr.get_workspaces ();
            uint n_spaces = wnckspaces.length ();
            // create blocks per space
            Grid[] spacegrids = {};
            int[] grids_rows = {}; // <- to keep track of row while adding buttons

            for (int i=0; i < n_spaces; i++) {
                Grid spacegrid = new Grid();
                Button header = create_spacebutton (i, n_spaces);
                // set spacebutton action
                Wnck.Workspace ws = null;
                int wsindex = 0;
                foreach (Wnck.Workspace w in wnckspaces) {
                    if (wsindex == i) {
                        ws = w;
                        header.clicked.connect (() => {
                            // move to workspace
                            uint now = get_now();
                            ws.activate(now);
                            this.hide();
                        });
                        break;
                    }
                    wsindex += 1;
                }

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
                // add to grid
                if (normalwindow) {
                    // fetch the corresponding grid from array & add button
                    Grid editgrid = spacegrids[currspaceindex];
                    int row = grids_rows[currspaceindex];
                    Button windownamebutton = new Gtk.Button.with_label(wname);
                    // set window button action
                    windownamebutton.clicked.connect (() => {
                        //raise_win(s)
                        uint now = get_now();
                        w.activate(now);
                        this.hide();
                    });

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
            //return maingrid;
        }

        private void update_interface () {
            GLib.List<weak Gtk.Widget> widgets = maingrid.get_children();
            foreach (Gtk.Widget wdg in widgets) {
                GLib.Idle.add( () => {
                    wdg.destroy();
                    return false;
                });
            }
            GLib.Idle.add( () => {
                produce_content ();
                maingrid.show_all();
                scrollwin.show_all();
                // this.show_all();
                return false;
            });
        }
     }

    public class Plugin : Budgie.Plugin, Peas.ExtensionBase {
        public Budgie.Applet get_panel_widget(string uuid) {
            return new Applet();
        }
    }


    public class Applet : Budgie.Applet {

        private Gtk.EventBox indicatorBox;
        private TemplatePopover popover = null;
        private unowned Budgie.PopoverManager? manager = null;

        public string uuid { public set; public get; }
        ButtonBox? spacebox = null;
        Label label = new Label("");
        bool usevertical;
        unowned Wnck.Screen wnck_scr;

        public void set_spacing (Gdk.Screen screen) {
            string fontspacing_css = """
            .fontspacing {letter-spacing: 3px; font-size: 12px;}
            .fontspacing_vertical {font-size: 10px;}
            """;

            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(fontspacing_css);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
                label.get_style_context().add_class("fontspacing");
            }
            catch (Error e) {
                // not much to be done
                print("Error loading css data\n");
            }
        }

        public override void panel_position_changed(Budgie.PanelPosition position) {
            if (
                position == Budgie.PanelPosition.LEFT ||
                position == Budgie.PanelPosition.RIGHT
            ) {
                usevertical = true;
                update_appearance();
            }
        }

        private void update_appearance () {
            string s = "";
            string charc = "";
            spacebox = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
            unowned GLib.List<Wnck.Workspace> spaces = wnck_scr.get_workspaces();
            Wnck.Workspace curractive = wnck_scr.get_active_workspace();
            foreach (Wnck.Workspace w in spaces) {
                if (w == curractive) {
                    charc = "●";
                }
                else {
                    charc = "○";
                }
                s = s + charc;
                if (usevertical) {
                    s = s + "\n";
                }
            }
            label.set_text(s);
            set_spacing(this.get_screen());
            indicatorBox.show_all();
            spacebox.show_all();
        }

        public Applet() {
            initialiseLocaleLanguageSupport();
            /* box */
            indicatorBox = new Gtk.EventBox();
            /* Popover */
            popover = new TemplatePopover(indicatorBox);
            /* On Press indicatorBox */
            indicatorBox.button_press_event.connect((e)=> {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    this.manager.show_popover(indicatorBox);
                }
                return Gdk.EVENT_STOP;
            });
            popover.get_child().show_all();

            add(indicatorBox);
            indicatorBox.add(label);
            wnck_scr = Wnck.Screen.get_default();
            update_appearance();
            wnck_scr.active_workspace_changed.connect(() => {
                update_appearance();
            });
            show_all();
        }

        public override void update_popovers(Budgie.PopoverManager? manager)
        {
            this.manager = manager;
            manager.register_popover(indicatorBox, popover);
        }

        public void initialiseLocaleLanguageSupport(){
            // Initialize gettext
            GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
            GLib.Intl.bindtextdomain(
                Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR
            );
            GLib.Intl.bind_textdomain_codeset(
                Config.GETTEXT_PACKAGE, "UTF-8"
            );
            GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
        }
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module){
    /* boilerplate - all modules need this */
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(
        Budgie.Plugin), typeof(TemplateApplet.Plugin)
    );
}