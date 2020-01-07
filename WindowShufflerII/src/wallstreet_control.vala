using Gtk;
using Math;

// valac -X -lm --pkg gtk+-3.0

/*
Budgie WallStreet
Author: Jacob Vlijm
Copyright © 2017-2020 Ubuntu Budgie Developers
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

// make it: settings / shortcuts / gui grid

namespace ShufflerControls {

    //  GLib.Settings wallstreet_settings;
    GLib.Settings shuffler_settings;

    class ControlsWindow : Gtk.Window {

        // strings & things ---------------------------------
        // Settings
        string daemonexpl = "Enable tiling and window jump shortcuts";
        string guiexpl = "Enable grid tiling gui shortcut";
        string swapgeexpl = "When using junp shortcuts, swap window geometry if a window moves to an existing window's position";
        string colsexpl = "Number of grid colums (for gui, grid-all- and jump shortcuts)";
        string default_expl = "Move the mouse over a button to explain the option it represents";
        string cols_expl = "Number of grid columns, used by gui grid, jump and tile-all shortcuts";
        string rows_expl = "Number of grid rows, used by gui grid, jump and tile-all shortcuts";
        // Q-tiling
        string qtiling_header = "Shortcuts for quarter and half tiling:\n\n";
        string topleft = "Ctrl-7".concat("\t", "Top-left");
        string topright = "Ctrl-9".concat("\t", "Top-right");
        string bottomright = "Ctrl-3".concat("\t", "Bottom-right");
        string bottomleft = "Ctrl-1".concat("\t", "Top-left");
        string lefthalf = "Ctrl-4".concat("\t", "Left-half");
        string tophalf = "Ctrl-8".concat("\t", "Top-half");
        string rightthalf = "Ctrl-6".concat("\t", "Right-half");
        string bottomhalf = "Ctrl-2".concat("\t", "Bottom-half");
        // Jump
        string jump_header = "Shortcuts for jumping to the nearest grid cell:\n\n";
        string jumpleft = "Super+Alt_L+left-arrow".concat("\t", "Jump left");
        string jumpright = "Super+Alt_L+right-arrow".concat("\t", "Jump right");
        string jumpup = "Super+Alt_L+up-arrow".concat("\t", "Jump up");
        string jumpdown = "Super+Alt_L+down-arrow".concat("\t", "Jump down");
        // Gui grid
        string guigrid_header = "Shortcuts for the grid gui:\n\n";
        string callgrid = "Call the grid gui".concat("\t", "Super + S");
        string addcol = "Add a column to grid".concat("\t", "˃");
        string addrow = "Add a row to grid".concat("\t", "˅");
        string remcol = "Remove a column".concat("\t", "˂");
        string remrow = "Remove a row".concat("\t", "˄");



        private Stack controlwin_stack; ////////////////////////////*************************************
        SpinButton columns_spin;
        SpinButton rows_spin;
        Entry dir_entry;
        string default_folder;
        Button set_customtwalls;
        ToggleButton toggle_gui;
        ToggleButton toggle_shuffler;
        ToggleButton toggle_swapgeo;
        string runinstruction;
        Label expl_label;
        Gtk.CssProvider css_provider; // needed here?
        Gdk.Screen screen; // needed here?
        Gtk.Grid supergrid;

        public ControlsWindow () {

            // window stuff
            string shufflercontrols_stylecss = """
            .explanation {
                font-style: italic;
            }
            .stackbuttons {
                border-radius: 0px 0px 0px 0px;
            }
            .stackbuttonleft {
                border-radius: 8px 0px 0px 8px;
            }
            .stackbuttonright{
                border-radius: 0px 8px 8px 0px;
            }
            .active {
                font-weight: bold;
            }
            """;

            //  border-radius: 10px 10px 0px 0px;
            //  border-width: 5px 5px 0px 0px;
            this.set_default_size(10, 10);
            initialiseLocaleLanguageSupport();
            this.set_position(Gtk.WindowPosition.CENTER);
            this.title = "Window Shuffler Control";  // -lang

            supergrid = new Gtk.Grid(); ////////////////////////////*************************************

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////
            // settingsgrid
            var settingsgrid = new Gtk.Grid();
            //set_margins(settingsgrid);

            runinstruction = "Enable Window Shuffler";
            toggle_shuffler = new Gtk.CheckButton.with_label(runinstruction); // -lang
            settingsgrid.attach(toggle_shuffler, 1, 1, 1, 1);

            toggle_gui = new Gtk.CheckButton.with_label("Enable Window Shuffler GUI"); // -lang
            settingsgrid.attach(toggle_gui, 1, 2, 1, 1);


            var givemesomespace = new Gtk.Label("");
            settingsgrid.attach(givemesomespace, 1, 3, 1, 1);

            toggle_swapgeo = new Gtk.CheckButton.with_label("Swap geometry"); // -lang
            settingsgrid.attach(toggle_swapgeo, 1, 4, 1, 1);

            var empty = new Label("");
            settingsgrid.attach(empty, 1, 12, 1, 1);
            // time settings section
            var colslabel = new Label("\n" + "Grid gui: columns & rows" + "\n"); // -lang
            colslabel.set_xalign(0);
            settingsgrid.attach(colslabel, 1, 13, 1, 1);
            var geogrid = new Gtk.Grid();
            settingsgrid.attach(geogrid, 1, 14, 2, 3);
            var columns_label = new Label("Columns" + "\t"); // -lang
            columns_label.set_xalign(0);
            geogrid.attach(columns_label, 0, 0, 1, 1);
            columns_spin = new Gtk.SpinButton.with_range(0, 10, 1);
            geogrid.attach(columns_spin, 1, 0, 1, 1);
            var rows_label = new Label("Rows" + "\t"); // -lang
            rows_label.set_xalign(0);
            geogrid.attach(rows_label, 0, 1, 1, 1);
            rows_spin = new Gtk.SpinButton.with_range(0, 10, 1);
            geogrid.attach(rows_spin, 1, 1, 1, 1);

            var okbox = new Box(Gtk.Orientation.HORIZONTAL, 0);
            var ok_button = new Button.with_label("Close"); // -lang
            okbox.pack_end(ok_button, false, false, 0);

            var empty2 = new Label("");
            geogrid.attach(empty2, 1, 20, 1, 1);
            /////////////////////////////////////////////////////////////
            Gtk.Label expl_vertspace = new Gtk.Label("\n\n\n\n");
            settingsgrid.attach(expl_vertspace, 0, 21, 1, 1);
            // whole bunch of styling
            screen = this.get_screen();
            css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_data(shufflercontrols_stylecss);
                Gtk.StyleContext.add_provider_for_screen(
                    screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
                );
            }
            catch (Error e) {
            }
            expl_label = new Gtk.Label(default_expl);
            expl_label.set_xalign(0);
            expl_label.set_line_wrap(true);
            settingsgrid.attach(expl_label, 1, 21, 99, 1);
            var sct = expl_label.get_style_context();
            sct.add_class("explanation");
            /////////////////////////////////////////////////////////////
            supergrid.attach(okbox, 2, 99, 4, 1); /////////////////////////////////////////////////// in bbox
            ok_button.clicked.connect(Gtk.main_quit);
            this.destroy.connect(Gtk.main_quit);
            // display initial value(s)
            // connect spin buttons after fetching initial values
            columns_spin.value_changed.connect(get_time);
            rows_spin.value_changed.connect(get_time);
            // get initial wallpaperfolder default/custom
            //  string initialwalls = wallstreet_settings.get_string(
            //      "wallpaperfolder"
            //  );
            //  bool testwallfolder = initialwalls == default_folder;
            //  if (!testwallfolder) {
            //      dir_entry.set_text(initialwalls);
            //  }
            //  toggle_defaultwalls.set_active(testwallfolder);
            //  toggle_customwall_widgets(testwallfolder);
            // connect afterwards
            //  toggle_defaultwalls.toggled.connect(manage_direntry);
            // fetch run wallstreet
            //  toggle_shuffler.set_active(
            //      wallstreet_settings.get_boolean("runwallstreet")
            //  );
            toggle_shuffler.toggled.connect(manage_boolean);
            // fetch toggle_gui
            //  toggle_gui.set_active(
            //      wallstreet_settings.get_boolean("random")
            //  );
            toggle_gui.toggled.connect(manage_boolean);
            // fetch toggle_shuffler
            //  toggle_shuffler.set_active(
            //      wallstreet_settings.get_boolean("lockscreensync")
            //  );
            toggle_shuffler.toggled.connect(manage_boolean);
            ///////////////////////
            toggle_shuffler.enter_notify_event.connect(() => {
                expl_label.set_text(daemonexpl);
                return false;
            });
            toggle_shuffler.leave_notify_event.connect(() => {
                expl_label.set_text(default_expl);
                return false;
            });
            ///////////////////////
            toggle_gui.enter_notify_event.connect(() => {
                expl_label.set_text(guiexpl);
                return false;
            });
            toggle_gui.leave_notify_event.connect(() => {
                expl_label.set_text(default_expl);
                return false;
            });
            ///////////////////////
            toggle_swapgeo.enter_notify_event.connect(() => {
                expl_label.set_text(swapgeexpl);
                return false;
            });
            toggle_swapgeo.leave_notify_event.connect(() => {
                expl_label.set_text(default_expl);
                return false;
            });
            ///////////////////////
            columns_spin.enter_notify_event.connect(() => {
                expl_label.set_text(cols_expl);
                return false;
            });
            columns_spin.leave_notify_event.connect(() => {
                expl_label.set_text(default_expl);
                return false;
            });
            ///////////////////////
            rows_spin.enter_notify_event.connect(() => {
                expl_label.set_text(cols_expl);
                return false;
            });
            rows_spin.leave_notify_event.connect(() => {
                expl_label.set_text(default_expl);
                return false;
            });

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////

            // shortcutsgrid
            var shortcutsgrid = new Gtk.Grid(); ////////////////////////////*************************************
            var shortcutsheader = new Label("Blub");
            shortcutsgrid.attach(shortcutsheader, 0, 0, 1, 1);

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////

            // gui-grid grid

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////

            // supergrid to contain stack
            
            supergrid.attach(new Label("\n"), 0, 2, 1, 1);
            set_margins(supergrid);
            int buttonwidth = 100;
            var settingsbutton = new Gtk.Button.with_label("Settings");
            set_buttonstyle(settingsbutton, "stackbuttonleft");
            supergrid.attach(settingsbutton, 1, 1, 1, 1);
            settingsbutton.set_size_request(buttonwidth, 10);
            var qtilebutton = new Gtk.Button.with_label("Q-tiling");
            set_buttonstyle(qtilebutton, "stackbuttons");
            supergrid.attach(qtilebutton, 2, 1, 1, 1);
            qtilebutton.set_size_request(buttonwidth, 10);
            var jumpbutton = new Gtk.Button.with_label("Jump");
            set_buttonstyle(jumpbutton, "stackbuttons");
            supergrid.attach(jumpbutton, 3, 1, 1, 1);
            jumpbutton.set_size_request(buttonwidth, 10);
            var gridbutton = new Gtk.Button.with_label("GUI grid");
            set_buttonstyle(gridbutton, "stackbuttonright");
            supergrid.attach(gridbutton, 4, 1, 1, 1);
            gridbutton.set_size_request(buttonwidth, 10);
            

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////////////////////////////////////////////////

            // stack
            var controlwin_stack = new Stack();
            // page 1
            controlwin_stack.add_named(settingsgrid, "settings"); ////////////////////////////*************************************

            controlwin_stack.add_named(shortcutsgrid, "shortcuts"); ////////////////////////////*************************************

            // throw in a bucket, set one active
            

            supergrid.attach(controlwin_stack, 1, 3, 4, 1);
            
            this.add(supergrid); ////////////////////////////*************************************
            // controlwin_stack.set_visible_child_name("shortcuts");
            supergrid.show_all();

            controlwin_stack.set_visible_child_name("settings");

            //  geogrid.show_all();
        }

        private void set_hoveractions(Gtk.Button b) {
            print("widget works\n");
        }

        /**
         * Ensure translations are displayed correctly
         * according to the locale
         */
        private void set_buttonstyle (Gtk.Button b, string style) {
            print("setting style\n");
            var sct = b.get_style_context();
            sct.add_class(style);
        }

        private bool test_hover (string str) {
            print("hover works\n");
            expl_label.set_text(str);
            return false;
        }
        public void initialiseLocaleLanguageSupport() {
            // Initialize gettext
            //  GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
            //  GLib.Intl.bindtextdomain(
            //      Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR
            //  );
            //  GLib.Intl.bind_textdomain_codeset(
            //      Config.GETTEXT_PACKAGE, "UTF-8"
            //  );
            //  GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
        }

        private void manage_boolean (ToggleButton button) {
            //  if (button == toggle_gui) {
            //      wallstreet_settings.set_boolean(
            //          "random", button.get_active()
            //      );
            //  }
            //  else if (button == toggle_shuffler) {
            //      wallstreet_settings.set_boolean(
            //          "lockscreensync", button.get_active()
            //      );
            //  }
            //  else if (button == toggle_shuffler) {
            //      bool newsetting = button.get_active();
            //      wallstreet_settings.set_boolean(
            //          "runwallstreet", newsetting
            //      );
            //      if (newsetting) {
            //          check_firstrunwarning();
            //      }
            //      else {
            //          toggle_shuffler.set_label(runinstruction);
            //      }
            //  }
        }

        private void check_firstrunwarning() {
            /*
            / 0.1 dec after gsettings change check if process is running
            / if not -> show message in label
            */
            GLib.Timeout.add(100, () => {
                bool runs = processruns("/budgie-wallstreet/wallstreet");
                if (!runs) {
                    toggle_shuffler.set_label(
                        runinstruction + "\t" +
                            "Please log out/in to initialize"
                         // -lang
                    );
                }
                return false;
            });
        }

        private bool processruns (string application) {
            string cmd = "pgrep -f " + application;
            string output;
            try {
                GLib.Process.spawn_command_line_sync(cmd, out output);
                if (output != "") {
                    // remove trailing \n, does not count
                    string[] pids = output[0:output.length-1].split("\n");
                    int n_pids = pids.length;
                    if (n_pids >= 2) {
                        return true;
                    }
                    else {
                        return false;
                    }
                }
            }
            /* on an (unlikely to happen) exception, show the message */
            catch (SpawnError e) {
                return false;
            }
            return false;
        }

        private void manage_direntry (ToggleButton button) {
            //  bool active = button.get_active();
            //  toggle_customwall_widgets(active);
            //  if (active) {
            //      dir_entry.set_text("");
            //      wallstreet_settings.set_string(
            //          "wallpaperfolder", default_folder
            //      );
            //  }
        }

        private void toggle_customwall_widgets (bool newstate) {
            dir_entry.set_sensitive(!newstate);
            set_customtwalls.set_sensitive(!newstate);
        }

        private void get_time () {
            /*
            convert hrs/mins/secs to plain seconds,
            update time interval setting
            */
            //  int hrs = (int)columns_spin.get_value();
            //  int mins = (int)minutes_spin.get_value();
            //  int secs = (int)seconds_spin.get_value();
            //  int time_in_seconds = (hrs * 3600) + (mins * 60) + secs;
            //  // don't allow < 5
            //  if (time_in_seconds <= 5) {
            //      time_in_seconds = 5;
            //  }
            //  wallstreet_settings.set_int("switchinterval", time_in_seconds);
        }

        private void set_margins (Grid grid) {
            // I admit, lazy layout
            int[,] corners = {
                {0, 0}, {100, 0}, {2, 0}, {0, 100}, {100, 100}
            };
            int lencorners = corners.length[0];
            for (int i=0; i < lencorners; i++) {
                var spacelabel = new Label("\t");
                grid.attach(
                    spacelabel, corners[i, 0], corners[i, 1], 1, 1
                );
            }
        }
    }

    public static int main (string[] args) {
        Gtk.init(ref args);

        //////////////////////////////////////////////////
        //remove/replace
        //  wallstreet_settings = new GLib.Settings(
        //      "org.ubuntubudgie.budgie-wallstreet"
        //  );

        shuffler_settings = new GLib.Settings(
            "org.ubuntubudgie.windowshuffler"
        );
        //////////////////////////////////////////////////
        var controls = new ControlsWindow();
        controls.show_all();
        Gtk.main();
        return 0;
    }
}