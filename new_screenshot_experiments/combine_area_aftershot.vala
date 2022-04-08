using Gtk;
using Gdk;
using Cairo;
using Gst;

// valac --pkg cairo --pkg gtk+-3.0 --pkg gdk-3.0 --pkg gstreamer-1.0 --pkg gio-2.0

namespace NewScreenshotApp {

    BudgieScreenshotClient client;

    [DBus (name = "org.buddiesofbudgie.Screenshot")]

    public interface BudgieScreenshotClient : GLib.Object {

        public abstract async void ScreenshotArea (
            int x, int y, int width, int height, bool include_cursor,
            bool flash, string filename, out bool success, out string filename_used
        ) throws Error;
    }


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
                setup_client();
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

            private void setup_client() {
                try {
                    client = GLib.Bus.get_proxy_sync (
                        BusType.SESSION, "org.buddiesofbudgie.Screenshot",
                        ("/org/buddiesofbudgie/Screenshot")
                    );
                }
                catch (Error e) {
                    stderr.printf ("%s\n", e.message);
                }
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

            private int get_scaling() {
                // not very sophisticated, but for now, we'll assume one scale
                Gdk.Monitor gdkmon = Gdk.Display.get_default().get_monitor(0);
                int curr_scale = gdkmon.get_scale_factor();
                return curr_scale;
            }

            async void shoot_area () {
                int scale = get_scaling();
                bool success = false;
                string filename_used = "";
                yield client.ScreenshotArea (
                    topleftx*scale, toplefty*scale, width*scale, height*scale, false, true, "",
                    out success, out filename_used
                );
                play_shuttersound();
                if (success) {
                    Clipboard clp = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                    Pixbuf pxb = clp.wait_for_image();
                    print("we did it\n");
                    new AfterShot.AfterShotWindow(pxb, scale);
                }
            }

            async bool take_shot(int delay) {
                this.destroy();
                // make sure the colored preview selection is gone before we shoot
                GLib.Timeout.add(100 + (delay*1000), ()=> {
                    shoot_area();
                    return false;
                });
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
            try {
                client = GLib.Bus.get_proxy_sync (
                    BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
                    ("/org/ubuntubudgie/shufflerinfodaemon")
                );
            }
            catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }


            // Just for testing, we are running it now from cli
            Gtk.init(ref args);
            int delay;
            (args.length != 1)? delay = int.parse(args[1]) : delay = 0;
            new SelectLayer(delay);
            Gtk.main();
            return 0;
        }
    }

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

    namespace AfterShot {

        class AfterShotWindow : Gtk.Window {

            Gtk.ListStore dir_liststore;
            Gtk.ComboBox pickdir_combo;
            VolumeMonitor monitor;
            string[] dirpaths;
            bool act_ondropdown = true;


            enum Column {
                DIRPATH,
                DISPLAYEDNAME,
                ICON,
                ISSEPARATOR
            }


            public AfterShotWindow(Gdk.Pixbuf pxb, int scale) {
                this.set_resizable(false);
                this.set_default_size(100, 100);
                this.set_position(Gtk.WindowPosition.CENTER_ALWAYS);
                // headerbar
                HeaderBar decisionbar = new Gtk.HeaderBar();
                decisionbar.show_close_button = false;
                //  Box decisionbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                Button[] decisionbuttons = {};
                string[] header_imagenames = {
                    "trash-shot-symbolic",
                    "save-shot-symbolic",
                    "clipboard-shot-symbolic"
                };
                bool left = true;
                foreach (string s in header_imagenames) {
                    Button decisionbutton = new Gtk.Button();
                    //  decisionbutton.set_size_request(,10);
                    Grid buttongrid = new Gtk.Grid();
                    Gtk.Image decisionimage = new Gtk.Image.from_icon_name(
                        s, Gtk.IconSize.BUTTON
                    );
                    decisionimage.pixel_size = 24;
                    buttongrid.attach(decisionimage, 0, 0, 1, 1);
                    set_margins(buttongrid, 8, 8, 0, 0);
                    decisionbutton.add(buttongrid);
                    buttongrid.show_all();
                    if (left) {
                        decisionbar.pack_start(decisionbutton);
                        left = false;
                    }
                    else {
                        decisionbar.pack_end(decisionbutton);
                    }
                    decisionbuttons += decisionbutton;
                }
                decisionbuttons[0].clicked.connect(()=> {
                    this.destroy();
                });
                decisionbuttons[1].get_style_context().add_class(
                    Gtk.STYLE_CLASS_SUGGESTED_ACTION
                );
                this.set_titlebar(decisionbar);
                // grids
                Gtk.Grid maingrid = new Gtk.Grid();
                ///////////////////////////////////////////////
                Gtk.Image img = resize_pixbuf(pxb, scale);
                maingrid.attach(img, 0, 0, 1, 1);
                ///////////////////////////////////////////////


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
                pickdir_combo.changed.connect(item_changed);
                maingrid.attach(directorygrid, 0, 1, 1, 1);
                this.show_all();
            }

            private Gtk.Image resize_pixbuf(Pixbuf pxb, int scale) {
                // Since this will be used by multiple, move to a higher scope
                // before showing the image, resize it to fit the max available
                // space in the decision window (345 x 345)
                int maxw_h = 345;
                float resize = 1;
                int scaled_width = (int)(pxb.get_width()/scale);
                int scaled_height = (int)(pxb.get_height()/scale);

                if (scaled_width > maxw_h || scaled_height > maxw_h) {
                    (scaled_width >= scaled_height)? resize = (float)maxw_h/scaled_width : resize = resize;
                    (scaled_height >= scaled_width)? resize = (float)maxw_h/scaled_height : resize = resize;
                }
                int dest_width = (int)(scaled_width * resize);
                int dest_height = (int)(scaled_height * resize);
                Gdk.Pixbuf resized = pxb.scale_simple (dest_width, dest_height, InterpType.BILINEAR);
                return new Gtk.Image.from_pixbuf(resized);
            }


            private void create_row(
                string? path, string? mention,
                string? iconname, bool separator = false) {
                // create a liststore-row
                Gtk.TreeIter iter;
                dir_liststore.append (out iter);
                dir_liststore.set (iter, Column.DIRPATH, path);
                dir_liststore.set (iter, Column.DISPLAYEDNAME, mention);
                dir_liststore.set (iter, Column.ICON, iconname);
                dir_liststore.set (iter, Column.ISSEPARATOR, separator);
            }

            private bool is_separator (
                Gtk.TreeModel dir_liststore, Gtk.TreeIter iter
            ) {
                // separator function to check if ISSEPARATOR is true
                GLib.Value is_sep;
                dir_liststore.get_value(iter, 3, out is_sep);
                return (bool)is_sep;
            }

            private void update_dropdown() {
                // on adding/removing a volume, update the dropdown
                // temporarily surpass dropdown-connect
                act_ondropdown = false;
                // - and clean up stuff
                dirpaths = {};
                pickdir_combo.clear();
                dir_liststore.clear();
                // look up user dirs & add
                string[] userdir_iconnames = {
                    "user-desktop", "folder-documents", "folder-download",
                    "folder-music", "folder-pictures", "folder-publicshare",
                    "folder-templates", "folder-videos"
                }; // do we need fallbacks?
                int n_dirs = UserDirectory.N_DIRECTORIES;
                for(int i=0; i<n_dirs; i++) {
                    string path = Environment.get_user_special_dir(i);
                    dirpaths += path; //
                    string[] dirmention = path.split("/");
                    string mention = dirmention[dirmention.length-1];
                    string iconname = userdir_iconnames[i];
                    create_row(path, mention, iconname, false);
                }
                // separator
                create_row(null, null, null, true);
                dirpaths += "";
                // look up mounted volumes
                bool add_separator = false;
                List<Mount> mounts = monitor.get_mounts ();
                foreach (Mount mount in mounts) {
                    add_separator = true;
                    GLib.Icon icon = mount.get_icon();
                    string ic_name = icon.to_string().split(" ")[2]; // seems awfully dirty...
                    string displayedname = mount.get_name();
                    string dirpath = mount.get_default_location ().get_path ();
                    dirpaths += dirpath;
                    create_row(dirpath, displayedname, ic_name, false);
                }
                // only add separator if there are volumes to list
                if (add_separator) {
                    create_row(null, null, null, true);
                    dirpaths += "";
                }
                // Other -> call Filebrowser
                create_row(null, "Other...", null, false);
                dirpaths += "#pick_custom_path";
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
                pickdir_combo.set_active(0); // change! needs a gsettings check
                pickdir_combo.show();
                act_ondropdown = true;
            }

            private void set_margins(
                Gtk.Grid grid, int left, int right, int top, int bottom
            ) {
                grid.set_margin_start(left);
                grid.set_margin_end(right);
                grid.set_margin_top(top);
                grid.set_margin_bottom(bottom);
            }

            void item_changed (Gtk.ComboBox combo) {;
                if (act_ondropdown) {
                    int combo_index = combo.get_active();
                    string found_dir = dirpaths[combo_index];
                    print (@"You chose: $combo_index, $found_dir\n");
                }
            }
        }
    }
}