using Gtk;
using Gdk;
using Cairo;
using Gst;

/*
Budgie Screenshot
Author: Jacob Vlijm
Copyright © 2022 Ubuntu Budgie Developers
Website=https://ubuntubudgie.org
This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or any later version. This
program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
should have received a copy of the GNU General Public License along with this
program.  If not, see <https://www.gnu.org/licenses/>.
*/

// valac --pkg cairo --pkg gtk+-3.0 --pkg gdk-3.0 --pkg gstreamer-1.0 --pkg gio-2.0


namespace NewScreenshotApp {


    GLib.Settings? screenshot_settings;
    BudgieScreenshotClient client;
    CurrentState windowstate;
    int newstate;

    [DBus (name = "org.buddiesofbudgie.Screenshot")]

    public interface BudgieScreenshotClient : GLib.Object {
        public abstract async void ScreenshotArea (
            int x, int y, int width, int height, bool include_cursor,
            bool flash, string filename, out bool success, out string filename_used
        ) throws Error;
        public abstract async void Screenshot (
            bool include_cursor, bool flash, string filename, out bool success,
            out string filename_used
        ) throws Error;
        public abstract async void ScreenshotWindow (
            bool include_frame, bool include_cursor, bool flash, string filename,
            out bool success, out string filename_used
        ) throws Error;
    }

    enum WindowState {
        NONE,
        MAINWINDOW,
        SELECTINGAREA,
        AFTERSHOT,
        WAITINGFORSHOT,
    }

    private class CurrentState : GLib.Object {
        public signal void changed();
        public void statechanged(int n) {
            newstate = n;
            print(@"newstate $newstate\n"); // remove
            changed();
        }
    }

    class MakeScreenshot {

        int delay;
        int scale;
        int[]? area;
        string screenshot_mode;
        bool include_cursor;
        bool include_frame;

        public MakeScreenshot(int[]? area) {
            this.area = area;
            scale = get_scaling();
            delay = screenshot_settings.get_int("delay");
            screenshot_mode = screenshot_settings.get_string("screenshot-mode");
            include_cursor = screenshot_settings.get_boolean("include-cursor");
            include_frame = screenshot_settings.get_boolean("include-frame");
            switch (screenshot_mode) {
                case "Selection":
                GLib.Timeout.add(100 + (delay*1000), ()=> {
                    shoot_area.begin();
                    return false;
                });
                break;
                case "Screen":
                GLib.Timeout.add(100 + (delay*1000), ()=> {
                    shoot_screen.begin();
                    return false;
                });
                break;
                case "Window":
                GLib.Timeout.add(100 + (delay*1000), ()=> {
                    shoot_window.begin();
                    return false;
                });
                break;
            }
        }

        async void shoot_window() {
            bool success = false;
            string filename_used = "";
                play_shuttersound(200);
            try {
                yield client.ScreenshotWindow (
                    include_frame, include_cursor, true, "", out success, out filename_used
                );
            }
            catch (Error e) {
                stderr.printf ("%s, failed to make screenhot\n", e.message);
                windowstate.statechanged(WindowState.NONE);
            }
            if (success) {
                new AfterShotWindow();
            }
        }

        private async void shoot_screen() {
            bool success = false;
            string filename_used = "";
            play_shuttersound(200);
            try {
                yield client.Screenshot (
                    include_cursor, true, "", out success, out filename_used
                );
            }
            catch (Error e) {
                stderr.printf ("%s, failed to make screenhot\n", e.message);
                windowstate.statechanged(WindowState.NONE);
            }
            if (success) {
                new AfterShotWindow();
            }
        }

        async void shoot_area () {
            play_shuttersound(0);
            bool success = false;
            string filename_used = "";
            int topleftx = this.area[0];
            int toplefty = this.area[1];
            int width = this.area[2];
            int height = this.area[3];
            // if we just click, forget to drag, set w/h to 1px
            (height == 0)? height = 1 : height;
            (width == 0)? width = 1 : width;
            try {
                yield client.ScreenshotArea (
                    topleftx*scale, toplefty*scale, width*scale, height*scale,
                    include_cursor, true, "", out success, out filename_used
                );
            }
            catch (Error e) {
                stderr.printf ("%s, failed to make screenhot\n", e.message);
                windowstate.statechanged(WindowState.NONE);
            }
            if (success) {
                new AfterShotWindow();
            }
        }

        private void play_shuttersound (int timeout, string[]? args=null) {
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
            GLib.Timeout.add(timeout, ()=> {
                // fake thread to make sure flash and shutter are in sync
                pipeline.set_state(State.PLAYING);
                Gst.Bus bus = pipeline.get_bus();
                bus.timed_pop_filtered(
                    Gst.CLOCK_TIME_NONE, Gst.MessageType.ERROR | Gst.MessageType.EOS
                );
                pipeline.set_state (Gst.State.NULL);
                return false;
            });
        }
    }

    /////////////////// 1 /////////////////////////

    class ScreenshotHomeWindow : Gtk.Window {

        GLib.Settings? buttonplacement;
        Gtk.HeaderBar topbar;
        int selectmode = 0;
        bool ignore = false;

        public ScreenshotHomeWindow() {
            //////////////////////////////////////////////////////////////////////////// newsignal
            windowstate.statechanged(WindowState.MAINWINDOW);
            windowstate.changed.connect(()=> {
                this.destroy();
            });
            // we'll also need to update if user just closes mainwindow by X
            this.destroy.connect(()=> {
                if (newstate == WindowState.MAINWINDOW) {
                    windowstate.statechanged(WindowState.NONE);
                }
            });

            this.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
            this.set_resizable(false);

            string home_css = """
            .buttonlabel {
                margin-top: -12px;
            }
            .centerbutton {
                border-radius: 0px 0px 0px 0px;
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
            screenshot_settings.bind(
                "include-cursor", showpointerswitch, "state",
                SettingsBindFlags.GET|SettingsBindFlags.SET
            );
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
            screenshot_settings.bind(
                "delay", delayspin, "value",
                SettingsBindFlags.GET|SettingsBindFlags.SET
            );
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
            foreach (Widget w in topbar.get_children()) {
                w.destroy();
            }
            /*
            / all the things you need to do to work around Gtk peculiarities:
            / if you set an image on a button, button gets crazy roundings,
            / if you set border radius, you get possible theming issues,
            / so.. add icon to grid, grid to button, button behaves. pfff.
            */
            Gtk.Button shootbutton = new Gtk.Button();
            Gtk.Image shootimage = new Gtk.Image.from_icon_name(
                "shootscreen-symbolic", Gtk.IconSize.DND);
            shootimage.pixel_size = 24;
            Gtk.Grid shootgrid = new Gtk.Grid();
            shootgrid.attach(shootimage, 0, 0, 1, 1);
            shootbutton.add(shootgrid);
            set_margins(shootgrid, 10, 10, 0, 0);
            shootbutton.get_style_context().add_class(
                Gtk.STYLE_CLASS_SUGGESTED_ACTION
            );

            shootbutton.clicked.connect(()=> {
                string shootmode = screenshot_settings.get_string("screenshot-mode");
                switch (shootmode) {
                    case "Selection":
                    new SelectLayer();
                    break;
                    case "Screen":
                    windowstate.statechanged(WindowState.WAITINGFORSHOT);
                    new MakeScreenshot(null);
                    break;
                    case "Window":
                    windowstate.statechanged(WindowState.WAITINGFORSHOT);
                    new MakeScreenshot(null);
                    break;
                }
            });

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
            string[] selectmodes = {"Screen", "Window", "Selection"};
            int i = 0;
            foreach (ToggleButton bt in btns) {
                if (bt != b) {
                    bt.set_active(false);
                }
                else {
                    selectmode = i;
                    screenshot_settings.set_string(
                        "screenshot-mode", selectmodes[i]
                    );
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

    //////////////////// 2 ///////////////////////////////

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

        public SelectLayer() {
            windowstate.statechanged(WindowState.SELECTINGAREA); // signal, no need to set connect, since it destroys itself after shot (-signal from)
            theme_settings = new GLib.Settings("org.gnome.desktop.interface");
            theme_settings.changed["gtk-theme"].connect(()=> {
                get_theme_fillcolor();
            });
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
                take_shot.begin();
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
            // update
            Gdk.Window window = this.get_window();
            var region = window.get_clip_region();
            window.invalidate_region(region, true);
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

        async void take_shot() {
            this.destroy();
            windowstate.statechanged(WindowState.NONE);
            int[] area = {topleftx, toplefty, width, height};
            new MakeScreenshot(area);
        }
    }

    ///////////////////////// 3 /////////////////////////////////

    class AfterShotWindow : Gtk.Window {
     /*
    * after the screenshot was taken, we need to present user a window
    * with a preview. from there we can decide what to do with it
    */

        Gtk.ListStore dir_liststore;
        Gtk.ComboBox pickdir_combo;
        VolumeMonitor monitor;
        bool act_ondropdown = true;
        string[]? custompath_row = null;
        string[] alldirs = {};
        Button[] decisionbuttons = {};
        string? extension;
        int n_dirs;

        enum Column {
            DIRPATH,
            DISPLAYEDNAME,
            ICON,
            ISSEPARATOR
        }

        public AfterShotWindow() {
            int scale = get_scaling();
            Clipboard clp = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
            Pixbuf pxb = clp.wait_for_image();
            windowstate.statechanged(WindowState.AFTERSHOT);
            windowstate.changed.connect(this.destroy);
            this.set_resizable(false);
            this.set_default_size(100, 100);
            this.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
            // headerbar
            HeaderBar decisionbar = new Gtk.HeaderBar();
            decisionbar.show_close_button = false;
            //  Button[] decisionbuttons = {};
            string[] header_imagenames = {
                "trash-shot-symbolic",
                "save-shot-symbolic",
                "clipboard-shot-symbolic",
                "edit-shot-symbolic"
            };
            bool left = true;
            foreach (string s in header_imagenames) {
                Button decisionbutton = new Gtk.Button();
                decisionbutton.set_can_focus(false);
                set_buttoncontent(decisionbutton, s);
                if (left) {
                    decisionbar.pack_start(decisionbutton);
                    left = false;
                }
                else {
                    decisionbar.pack_end(decisionbutton);
                }
                decisionbuttons += decisionbutton;
            }
            // save to file is suggested action
            decisionbuttons[1].get_style_context().add_class(
                Gtk.STYLE_CLASS_SUGGESTED_ACTION
            );
            this.set_titlebar(decisionbar);
            // grids
            Gtk.Grid maingrid = new Gtk.Grid();
            // create resized image for preview
            Gtk.Image img = resize_pixbuf(pxb, scale);
            maingrid.attach(img, 0, 0, 1, 1);
            this.add(maingrid);
            set_margins(maingrid, 25, 25, 25, 25);
            Gtk.Grid directorygrid = new Gtk.Grid();
            directorygrid.set_row_spacing(8);
            set_margins(directorygrid, 0, 0, 25, 0);
            // dir-entry (in a box)
            Box filenamebox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Label filenamelabel = new Gtk.Label("Name" + ":");
            filenamelabel.xalign = 0;
            filenamelabel.set_size_request(80, 10);
            filenamebox.pack_start(filenamelabel);
            Entry filenameentry = new Gtk.Entry();
            filenameentry.set_size_request(265, 10);
            filenameentry.set_text(get_scrshotname());
            filenamebox.pack_end(filenameentry);
            directorygrid.attach(filenamebox, 0, 0, 1, 1);
            // combo (in a box)
            dir_liststore = new Gtk.ListStore (
                4, typeof (string), typeof (string), typeof (string), typeof (bool)
            );
            Box pickdirbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Label pickdirlabel = new Gtk.Label("Folder" + ":");
            pickdirlabel.xalign = 0;
            pickdirlabel.set_size_request(80, 10);
            pickdirbox.pack_start(pickdirlabel);
            pickdir_combo = new Gtk.ComboBox.with_model (dir_liststore);
            pickdir_combo.set_popup_fixed_width(true);
            pickdir_combo.set_size_request(265, 10);
            pickdirbox.pack_end(pickdir_combo);
            directorygrid.attach(pickdirbox, 0, 1, 1, 1);
            // volume monitor
            monitor = VolumeMonitor.get();
            monitor.mount_added.connect(update_dropdown);
            monitor.mount_removed.connect(update_dropdown);
            update_dropdown();
            pickdir_combo.changed.connect(()=> {
                if (act_ondropdown) {
                    item_changed(pickdir_combo);
                }
            });
            maingrid.attach(directorygrid, 0, 1, 1, 1);
            // set headerbar button actions
            // - trash button: cancel
            decisionbuttons[0].clicked.connect(()=> {;
                windowstate.statechanged(WindowState.NONE);;
            });
            // - save to file
            decisionbuttons[1].clicked.connect(()=> {
                save_tofile(filenameentry, pickdir_combo, pxb);
                windowstate.statechanged(WindowState.NONE);
            });
            // - copy to clipboard
            decisionbuttons[2].clicked.connect(()=> {
                windowstate.statechanged(WindowState.NONE);
                //  Clipboard clp = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                clp.set_image(pxb);
                windowstate.statechanged(WindowState.NONE);
            });
            // - save to file
            decisionbuttons[3].clicked.connect(()=> {
                string usedpath = save_tofile(filenameentry, pickdir_combo, pxb);
                open_indefaultapp(usedpath);
                windowstate.statechanged(WindowState.NONE);
            });
            this.show_all();
        }

        private void open_indefaultapp(string path) {
            File file = File.new_for_path (path);
            if (file.query_exists ()) {
                try {
                    AppInfo.launch_default_for_uri (file.get_uri (), null);
                } catch (Error e) {
                    warning ("Unable to launch %s", path);
                }
            }
        }

        private string? get_path_fromcombo(Gtk.ComboBox combo) {
            // get the info from liststore from selected item
            Gtk.TreeIter iter;
            GLib.Value val;
            combo.get_active_iter(out iter);
            dir_liststore.get_value(iter, 0, out val);
            return (string)val;
        }

        private string get_scrshotname() {
            // create timestamped name
            extension = screenshot_settings.get_string("file-type");
            GLib.DateTime now = new GLib.DateTime.now_local();
            return now.format(@"Snapshot_%F_%H-%M-%S.$extension");
        }

        private string save_tofile(
            Gtk.Entry entry, ComboBox combo, Pixbuf pxb
        ) {
            // todo: make extension arbitrary (gsettings)
            string? found_dir = get_path_fromcombo(combo);
            string filename = entry.get_text().split(".")[0]; // make more robust, what if user includes dots in filename?
            string usedpath = @"$found_dir/$filename.$extension";
            try {
                pxb.save(usedpath, extension);
            }
            catch (Error e) {
                stderr.printf ("%s\n", e.message);
                set_buttoncontent(
                    decisionbuttons[1], "saveshot-noaccess-symbolic"
                );
            }
            return usedpath;
        }

        private void set_buttoncontent(Button b, string icon) {
            foreach (Widget w in b.get_children()) {
                w.destroy();
            }
            Grid buttongrid = new Gtk.Grid();
            var theme = Gtk.IconTheme.get_default();
            theme.add_resource_path (
                "/org/buddiesofbudgie/Screenshot/icons/scalable/apps/"
            );
            var iconfile =  new ThemedIcon(name=icon);
            Gtk.Image buttonimage = new Gtk.Image.from_gicon(
                iconfile,Gtk.IconSize.BUTTON
            );
            buttonimage.pixel_size = 24;
            buttongrid.attach(buttonimage, 0, 0, 1, 1);
            set_margins(buttongrid, 8, 8, 0, 0);
            b.add(buttongrid);
            buttongrid.show_all();
        }

        private Gtk.Image resize_pixbuf(Pixbuf pxb, int scale) {
            /*
            * before showing the image, resize it to fit the max available
            * availabble space in the decision window (345 x 345)
            */
            int maxw_h = 345;
            float resize = 1;
            int scaled_width = (int)(pxb.get_width()/scale);
            int scaled_height = (int)(pxb.get_height()/scale);

            if (scaled_width > maxw_h || scaled_height > maxw_h) {
                (scaled_width >= scaled_height)? resize = (float)maxw_h/scaled_width : resize;
                (scaled_height >= scaled_width)? resize = (float)maxw_h/scaled_height : resize;
            }
            int dest_width = (int)(scaled_width * resize);
            int dest_height = (int)(scaled_height * resize);
            Gdk.Pixbuf resized = pxb.scale_simple(dest_width, dest_height, InterpType.BILINEAR);
            return new Gtk.Image.from_pixbuf(resized);
        }

        private void create_row(
            // the labor work to add a row
            string? path, string? mention,
            string? iconname, bool separator = false) {
            // create a liststore-row
            Gtk.TreeIter iter;
            dir_liststore.append (out iter);
            dir_liststore.set (iter, Column.DIRPATH, path);
            dir_liststore.set (iter, Column.DISPLAYEDNAME, mention);
            dir_liststore.set (iter, Column.ICON, iconname);
            dir_liststore.set (iter, Column.ISSEPARATOR, separator);
            (path == null)? path = "#None" : path;
            alldirs += path;
        }

        private bool is_separator (
            Gtk.TreeModel dir_liststore, Gtk.TreeIter iter
        ) {
            // separator function to check if ISSEPARATOR is true
            GLib.Value is_sep;
            dir_liststore.get_value(iter, 3, out is_sep);
            return (bool)is_sep;
        }

        private int find_stringindex(string str, string[] arr) {
            for(int i=0; i<arr.length; i++) {
                if (str == arr[i]) {
                    return i;
                }
            }
            return -1;
        }

        private void update_dropdown() {
            alldirs = {};
            // temporarily surpass dropdown-connect
            act_ondropdown = false;
            // - and clean up stuff
            pickdir_combo.clear();
            dir_liststore.clear();
            // look up user dirs & add
            string[] userdir_iconnames = {
                "user-desktop", "folder-documents", "folder-download",
                "folder-music", "folder-pictures", "folder-publicshare",
                "folder-templates", "folder-videos"
            }; // do we need fallbacks?
            // first section: user-dirs
            n_dirs = UserDirectory.N_DIRECTORIES;
            for(int i=0; i<n_dirs; i++) {
                string path = Environment.get_user_special_dir(i);
                string[] dirmention = path.split("/");
                string mention = dirmention[dirmention.length-1];
                string iconname = userdir_iconnames[i];
                create_row(path, mention, iconname, false);
            }
            create_row(null, null, null, true);
            // second section: look up mounted volumes
            bool add_separator = false;
            List<Mount> mounts = monitor.get_mounts ();
            foreach (Mount mount in mounts) {
                add_separator = true;
                GLib.Icon icon = mount.get_icon();
                string ic_name = get_icon_fromgicon(icon);
                string displayedname = mount.get_name();
                string dirpath = mount.get_default_location ().get_path ();
                create_row(dirpath, displayedname, ic_name, false);
            }
            if (add_separator) {
                create_row(null, null, null, true);
            }
            // second section: (possible) custom path
            int r_index = -1;
            if (custompath_row != null) {
                string c_path = custompath_row[0];
                // check if the picked dir is already listed
                r_index = find_stringindex(c_path, alldirs);
                if (r_index == -1) {
                    create_row(
                        c_path, custompath_row[1], custompath_row[2], false
                    );
                    // now update the index to set new dir active
                    r_index = find_stringindex(c_path, alldirs);
                    create_row(null, null, null, true);
                }
            }
            // Other -> call Filebrowser (path = null)
            create_row(null, "Other...", null, false);
            // set separator
            pickdir_combo.set_row_separator_func(is_separator);
            // populate dropdown
            Gtk.CellRendererText cell = new Gtk.CellRendererText();
            cell.set_padding(10, 1);
            cell.set_property("ellipsize", Pango.EllipsizeMode.END);
            cell.set_fixed_size(15, -1);
            Gtk.CellRendererPixbuf cell_pb = new Gtk.CellRendererPixbuf();
            pickdir_combo.pack_end (cell, false);
            pickdir_combo.pack_end (cell_pb, false);
            pickdir_combo.set_attributes (cell, "text", Column.DISPLAYEDNAME);
            pickdir_combo.set_attributes (cell_pb, "icon_name", Column.ICON);
            // if we picked a custom dir, set it active
            int active_row;
            active_row = screenshot_settings.get_int("last-save-directory");
            // prevent segfault error on incorrect gsettings value
            (active_row > n_dirs)? active_row = 0 : active_row;
            (r_index != -1)? active_row = r_index : active_row;
            pickdir_combo.set_active(active_row);
            pickdir_combo.show();
            act_ondropdown = true;
        }

        void save_customdir (Gtk.Dialog dialog, int response_id) {
            // setting user response on dialog as custom path (the labor work)
            var save_dialog = dialog as Gtk.FileChooserDialog;
            if (response_id == Gtk.ResponseType.ACCEPT) {
                File file = save_dialog.get_file();
                FileInfo info = file.query_info("standard::icon", 0);
                Icon icon = info.get_icon();
                string ic_name = get_icon_fromgicon(icon);
                // so, the actual path
                string custompath = file.get_path();
                // ...and its mention in the dropdown
                string[] custompath_data = custompath.split("/");
                string mention = custompath_data[custompath_data.length - 1];
                // delivering info to set new row
                custompath_row = {custompath, mention, ic_name};
                update_dropdown();
            }
            dialog.destroy ();
        }

        private string get_icon_fromgicon(GLib.Icon ic) {
            /*
            * kind of dirty, we should find a cleaner one
            * if gicon holds ThemedIcon info, it starts with "". ThemedIcon",
            * so we pick first icon after that from the list
            * in other cases, single icon name is the only data in gicon.
            */
            string found_icon = "";
            string[] iconinfo = ic.to_string().split(" ");
            (iconinfo.length >=3)? found_icon = iconinfo[2] : found_icon = iconinfo[0];
            return found_icon;
        }

        private void get_customdir() {
            // set custom dir to found dir
            Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(
                "Open Folder", this, Gtk.FileChooserAction.SELECT_FOLDER,
                ("Cancel"), Gtk.ResponseType.CANCEL, ("Open"),
                Gtk.ResponseType.ACCEPT, null
            );
            dialog.response.connect(save_customdir);
            dialog.show();
        }

        private void set_margins(
            Gtk.Grid grid, int left, int right, int top, int bottom
        ) {
            // setting margins for a grid
            grid.set_margin_start(left);
            grid.set_margin_end(right);
            grid.set_margin_top(top);
            grid.set_margin_bottom(bottom);
        }

        private void item_changed (Gtk.ComboBox combo) {
            /*
            * on combo selection change, check if we need to add custom
            * path. selected item then has null for field path.
            * remember picked enum. no need for vice versa, since this is
            * set after window is called, and selection is set.
            */
            int new_selection = combo.get_active();
            if (new_selection <= n_dirs) {
                screenshot_settings.set_int("last-save-directory", new_selection);
            }
            // if we change directory, reset save button's icon
            set_buttoncontent(decisionbuttons[1], "save-shot-symbolic");
            if (get_path_fromcombo(combo) == null) {
                get_customdir();
            }
            else {
                custompath_row = null;
            }
        }
    }

    private int get_scaling() {
        // not very sophisticated, but for now, we'll assume one scale
        Gdk.Monitor gdkmon = Gdk.Display.get_default().get_monitor(0);
        int curr_scale = gdkmon.get_scale_factor();
        return curr_scale;
    }

    public static int main(string[] args) {
        // set windowstate signal and initial state
        Gtk.init(ref args);
        windowstate = new CurrentState();
        newstate = 0;
        try {
            client = GLib.Bus.get_proxy_sync (
                BusType.SESSION, "org.buddiesofbudgie.Screenshot",
                ("/org/buddiesofbudgie/Screenshot")
            );
        }
        catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
        screenshot_settings = new GLib.Settings(
            "org.buddiesofbudgie.screenshot"
        );
        new ScreenshotHomeWindow(); // just for testing
        Gtk.main();
        return 0;
    }
}

// 1090