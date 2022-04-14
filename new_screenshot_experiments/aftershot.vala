using Gtk;
using Gdk;
using Pango;

// valac --pkg gio-2.0 --pkg gtk+-3.0


namespace AfterShot {

    class AfterShotWindow : Gtk.ApplicationWindow {

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


        public AfterShotWindow(Gtk.Application app) {
            Object (application: app, title: "Gtk.MessageDialog Example");
            this.set_resizable(false);
            this.set_default_size(100, 100);
            // headerbar
            HeaderBar decisionbar = new Gtk.HeaderBar();
            decisionbar.show_close_button = false;
            Box decisionbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            Button[] decisionbuttons = {};
            string[] header_imagenames = {
                "trash-shot-symbolic.svg",
                "save-shot-symbolic.svg",
                "clipboard-shot-symbolic.svg"
            };
            bool left = true;
            foreach (string s in header_imagenames) {
                Button decisionbutton = new Gtk.Button();
                //  decisionbutton.set_size_request(,10);
                Grid buttongrid = new Gtk.Grid();
                Gtk.Image decisionimage = new Gtk.Image.from_resource(
                    "/org/buddiesofbudgie/Screenshot/icons/scalable/apps/" + s);
                var pixbuf = decisionimage.get_pixbuf();
                //huh Gtk.IconSize.BUTTON should be used - but here it is size 4 px
                //so temporarily hardcode 24px
                var scaled_pixbuf = pixbuf.scale_simple(24,24,Gdk.InterpType.BILINEAR);
                decisionimage.set_from_pixbuf(scaled_pixbuf);
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
            this.set_titlebar(decisionbar);
            // grids
            Gtk.Grid maingrid = new Gtk.Grid();
            this.add(maingrid);
            set_margins(maingrid, 25, 25, 25, 25);
            Gtk.Grid directorygrid = new Gtk.Grid();
            directorygrid.set_row_spacing(8);

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

    public class MyApplication: Gtk.Application {
        public MyApplication () {
            Object(application_id: "testing.my.application",
                    flags: ApplicationFlags.FLAGS_NONE);
        }

        protected override void activate () {
            Gtk.ApplicationWindow window = new AfterShotWindow (this);
            window.show_all();
        }
    }

    public static int main (string[] args) {
        Gtk.init(ref args);
		return new MyApplication().run (args);
	}
}



