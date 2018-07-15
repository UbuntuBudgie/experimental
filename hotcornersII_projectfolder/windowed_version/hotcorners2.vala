using Gtk;
using Gdk;
using Math;
using Json;

/* 
* HotCornersII
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


namespace SupportingFunctions {

    // Here we keep the (possibly) shared stuff

    private GLib.Settings get_settings(string path) {
        var settings = new GLib.Settings(path);
        return settings;
    }
    /* below functions are look- ups for mostly GUI items */
    private int get_checkbuttonindex (
        ToggleButton button, CheckButton[] arr
        ) {
        for (int i=0; i < arr.length; i++) {
            if(button == arr[i]) return i;
        } return -1;
    }
    private int get_togglebuttonindex (
        ToggleButton button, ToggleButton[] arr
        ) {
        for (int i=0; i < arr.length; i++) {
            if(button == arr[i]) return i;
        } return -1;
    }
    private int get_entryindex (Editable entry, Entry[] arr) {
        for (int i=0; i < arr.length; i++) {
            if(entry == arr[i]) return i;
        } return -1;
    }
    private bool command_isdefault(string cmd, string[] defaults) {
        for (int i=0; i < defaults.length; i++) {
            if(cmd == defaults[i]) return true;
        } return false;
    }
    private int get_stringindex (string s, string[] arr) {
        for (int i=0; i < arr.length; i++) {
            if(s == arr[i]) return i;
        } return -1;
    }
    private int get_cboxindex (ComboBox c, ComboBox[] arr) {
        for (int i=0; i < arr.length; i++) {
            if(c == arr[i]) return i;
        } return -1;
    }
}

public class WatchCorners : Gtk.Window {

    /* process stuff */
    private int action_area;
    private int[] x_arr;
    private int[] y_arr;
    private int pressure;
    private GLib.Settings hc_settings;
    private int time_steps; 
    private bool include_pressure;
    /* GUI stuff */
    private Grid maingrid;
    private Entry[] entries;
    private ToggleButton[] buttons;
    private CheckButton[] cbuttons;
    private string[] commands;
    private ComboBox[] dropdowns;
    private string[] dropdown_namelist;
    private string[] dropdown_cmdlist;

    /* below is the actual applet popup section */
    public void managewindow(string[] ? args = null) {

        /* data */
        string css_data = """
        .label {
            padding-bottom: 3px;
            padding-top: 3px;
            font-weight: bold;
        }
        """;

        /* gsettings stuff */
        this.hc_settings = SupportingFunctions.get_settings(
            "org.ubuntubudgie.plugins.budgie-hotcorners"
        );
        this.hc_settings.changed["pressure"].connect(update_pressure);
        update_pressure ();
        read_setcommands ();
        populate_dropdown ();

        /* window def */
        this.title = "HotCorners Settings"; //obsolete
        /* grid */
        this.maingrid = new Grid();
        this.maingrid.set_row_spacing(7);
        this.maingrid.set_column_spacing(7);
        this.add(this.maingrid);
        /* header labels */
        var cornerlabel = new Gtk.Label(" Corner");
        cornerlabel.set_xalign(0);
        this.maingrid.attach(cornerlabel, 0, 0, 1, 1);
        var actionlabel = new Gtk.Label(" Action");
        actionlabel.set_xalign(0);
        this.maingrid.attach(actionlabel, 1, 0, 1, 1);
        var customlabel = new Gtk.Label(" Custom");
        customlabel.set_xalign(0);
        this.maingrid.attach(customlabel, 2, 0, 2, 1);
        /* set styling of headers */
        Label[] headers = {
            cornerlabel, actionlabel, customlabel
        };
        var screen = this.get_screen ();
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_data(css_data);
        Gtk.StyleContext.add_provider_for_screen(
            screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
        );
        foreach (Label l in headers) {
            l.get_style_context().add_class("label");
        };
        /* toggle buttons -names*/
        string[] namelist = {
            "Top-left", "Top-right", "Bottom-left", "Bottom-right"
        };
        /* create rows */
        int y_pos = 1;

        foreach (string name in namelist) {
            /* create toggle buttons */
            var latest_togglebutton = new ToggleButton.with_label(name);
            buttons += latest_togglebutton;
            this.maingrid.attach(latest_togglebutton, 0, y_pos, 1, 1);
            /* create entries */
            var latest_entry = new Entry();
            this.entries += latest_entry;  
            latest_entry.set_size_request(220, 20);
            /* create dropdown */
            var command_combo = new ComboBoxText();
            command_combo.set_size_request(220, 20);
            foreach (string cmd_name in this.dropdown_namelist) {
                command_combo.append_text(cmd_name);
            }
            this.dropdowns += command_combo;
            /* space */
            var spacer = new Label(" ");
            this.maingrid.attach(spacer, 2, y_pos, 1, 1);
            var spacer2 = new Label(" ");
            this.maingrid.attach(spacer2, 4, y_pos, 1, 1);
            /* checkbutton cusom command */
            var latest_check = new CheckButton();
            this.cbuttons += latest_check;
            this.maingrid.attach(latest_check, 3, y_pos, 1, 1);
            /* populate with command situation */
            string set_command = this.commands[y_pos - 1];
            if (set_command == "") {
                latest_togglebutton.set_active(false);
                this.maingrid.attach(command_combo, 1, y_pos, 1, 1);
                command_combo.set_sensitive(false);
                latest_check.set_sensitive(false);
            }
            else {
                latest_togglebutton.set_active(true);
                bool test = SupportingFunctions.command_isdefault(
                    set_command, this.dropdown_cmdlist
                );
                if (test == true) {
                    this.maingrid.attach(command_combo, 1, y_pos, 1, 1);
                    int combo_index = SupportingFunctions.get_stringindex(
                        set_command, this.dropdown_cmdlist
                    );
                    command_combo.active = combo_index;
                    latest_check.set_active(false);
                }
                else {
                    this.maingrid.attach(latest_entry, 1, y_pos, 1, 1);
                    latest_entry.set_text(set_command);
                    latest_check.set_active(true);
                }
            }
            /* connect the whole row */
            latest_togglebutton.toggled.connect(toggle_corner);
            latest_check.toggled.connect(act_on_checkbuttontoggle);
            command_combo.changed.connect(get_fromcombo);
            latest_entry.changed.connect(update_fromentry);
            y_pos += 1;
        }

        this.show_all();
        watch_loop();
        Gtk.main();
    }

    private void get_fromcombo (ComboBox combo) {
        /* 
        * reads the chosen command from the ComboBoxText and updates
        * the hotcorner/commands list 
        */
        /* corner index */
        int combo_index = SupportingFunctions.get_cboxindex(
            combo, this.dropdowns
        );
        /* command index */
        int command_index = combo.get_active();
        string new_cmd = dropdown_cmdlist[command_index];
        this.commands[combo_index] = new_cmd;
        this.hc_settings.set_strv("commands", this.commands);
    }

    private void update_pressure () {
        this.pressure = this.hc_settings.get_int("pressure");
        if (this.pressure > 0) {
            include_pressure = true;
        }
        else {
            this.include_pressure = false;
        }
    }

    private void read_setcommands () {
        this.commands = this.hc_settings.get_strv("commands");
    }

    private void populate_dropdown () {
        /* 
        * reads the default dropdown commands/names and populates
        * the dropdown menu
        */
        var parser = new Json.Parser ();
        string[] dropdown_source = this.hc_settings.get_strv("dropdown");
        foreach (string s in dropdown_source) {
            read_json(parser, s);
        }
    }

    private void read_json(Json.Parser parser, string command) {
        /* reads json data from gsettings name/command couples */
        parser.load_from_data (command);
        var root_object = parser.get_root ().get_object ();
        string test = root_object.get_string_member ("name");
        string test2 = root_object.get_string_member ("command");
        this.dropdown_namelist += test;
        this.dropdown_cmdlist += test2;
    }

    private void update_fromentry(Editable entry) {
        /* reads the entry and edits the corner / commands list */
        int buttonindex = SupportingFunctions.get_entryindex(
            entry, this.entries
        );
        string new_cmd = entry.get_chars(0, 100);
        this.commands[buttonindex] = new_cmd;
        this.hc_settings.set_strv("commands", this.commands);
    }

    private void act_on_checkbuttontoggle(ToggleButton button) {
        /*
        * if custom checkbox is toggled, both GUI and command list changes
        * need to take place
        */
        // add: command change!!
        int b_index = SupportingFunctions.get_checkbuttonindex(
            button, this.cbuttons
        );
        bool active = button.get_active();
        if (active) { 
            Entry new_source = this.entries[b_index];
            this.maingrid.attach(new_source, 1, b_index + 1, 1, 1);
            this.maingrid.remove(this.dropdowns[b_index]);
            new_source.set_text("");
        }
        else { 
            this.maingrid.remove(this.entries[b_index]);
            ComboBox newsource = this.dropdowns[b_index];
            newsource.set_active(0);
            this.maingrid.attach(newsource, 1, b_index + 1, 1, 1);
        }
        //string new_cmd = "";

        this.commands[b_index] = "";
        this.hc_settings.set_strv("commands", this.commands);

        // edit this.commands
        this.show_all();
    }

    private void toggle_corner(ToggleButton button) {
        /* updates GUI if button is toggled, updates commands accordingly */
        bool active = button.get_active();
        int buttonindex = SupportingFunctions.get_togglebuttonindex(
            button, this.buttons
        );
        CheckButton currcheck = this.cbuttons[buttonindex];
        bool custom_isset = currcheck.get_active();
        Entry currentry = this.entries[buttonindex];
        currentry.set_text("");
        ComboBox currdrop = this.dropdowns[buttonindex];
        currdrop.set_active(0);
        if (active) {
            if (custom_isset) {
                currentry.set_sensitive(true);
            }
            else {
                currdrop.set_sensitive(true);
            }
        }
        else {
            if (custom_isset) {
                currentry.set_sensitive(false);
            }
            else {
                currdrop.set_sensitive(false);
            }
        }
        string new_cmd = "";
        this.commands[buttonindex] = new_cmd;
        this.hc_settings.set_strv("commands", this.commands);
        currcheck.set_sensitive(active);
    }

    /* see what is the resolution on the primary monitor */
    private int[] check_res() {
        var prim = Gdk.Display.get_default().get_primary_monitor();
        var geo = prim.get_geometry();
        int width = geo.width;
        int height = geo.height;
        return {width, height};
    }

    /* the last <n> positions will be kept in mind, to decide on pressure */
    private int[] keepsection(int[] arr_in, int lastn) {
        /* equivalent to list[index:] */
        int[] temparr = {};
        int currlen = arr_in.length;
        if (currlen > lastn) {
            int remove = currlen - lastn;
            temparr = arr_in[remove:currlen];
            return temparr;
        }
        return arr_in;    
    }

    /* see if we are in a corner, if so, which one */
    private int check_corner(int xres, int yres, Seat seat) {
        int x;
        int y;
        seat.get_pointer().get_position(null, out x, out y);
        /* add coords to array, edit array */
        this.x_arr += x;
        this.x_arr = keepsection(this.x_arr, this.time_steps);
        this.y_arr += y;
        this.y_arr = keepsection(this.y_arr, this.time_steps);
        int n = -1;
        bool[] tests = {
            (x < this.action_area && y < this.action_area),
            (x > xres - this.action_area && y < this.action_area),
            (x < this.action_area && y > yres - this.action_area),
            (x > xres - this.action_area && y > yres - this.action_area),
        };
        foreach (bool test in tests) {
            n += 1;
            if (test == true) {
                return n;
            }
        }
        return -1;
    }

    private bool check_onpressure () {
        if (this.include_pressure == true) {
            bool approve = decide_onpressure();
            return approve;
        }
        else {
            return true;
        }
    }

    /* decide if the pressure is enough */
    private bool decide_onpressure () {
        double x_travel = Math.pow(
            this.x_arr[0] - this.x_arr[this.time_steps - 1], 2
        );
        double y_travel = Math.pow(
            this.y_arr[0] - this.y_arr[this.time_steps - 1], 2
        );
        double travel = Math.pow(x_travel + y_travel, 0.5);
        if (travel > this.pressure) {
            return true;
        }
        else {
            return false;
        }
    }

    /* execute the command */
    private void run_command (int corner) {
        string cmd = this.commands[corner];
        if (cmd != "") {
            try {
                Process.spawn_command_line_async(cmd);
            }
            catch (GLib.SpawnError err) {
                /* 
                * in case an error occurs, the command most likely is
                * incorrect not much use for any action
                */
            }
        }
    }
  
    private int watch_loop(string[] ? args = null) {
        Gdk.init(ref args);
        Gdk.Seat seat = Gdk.Display.get_default().get_default_seat();
        int[] res = check_res();
        /* here we set the size of the array (20 = 1 sec.) */
        this.action_area = 5;
        /* here we set the time steps (size of array, 20 = last 1 second) */
        this.time_steps = 3;
        this.x_arr = {0};
        this.y_arr = {0};
        int xres = res[0];
        int yres = res[1];
        bool reported = false;

        GLib.Timeout.add (50, () => {
            int corner = check_corner(xres, yres, seat);
            if (corner != -1 && reported == false) {
                if (check_onpressure() == true) {
                    run_command(corner);
                    reported = true;
                }
            }
            else if (corner == -1) {
                reported = false;
            }
            return true;
        });
        return 0;
    }
}

public static int main(string[] args) {
    Gtk.init(ref args);
    var instance = new WatchCorners();
    instance.managewindow();
    return 0;
}