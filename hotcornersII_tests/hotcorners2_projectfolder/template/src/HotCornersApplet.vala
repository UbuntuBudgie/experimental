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
    /* 
    * Here we keep the (possibly) shared stuff, or general functions, to
    * keep the main code clean and readable
    */
}


namespace HotCornersApplet { 

    public class HotCornersSettings : Gtk.Grid { //B
        GLib.Settings? settings = null;
        public HotCornersSettings(GLib.Settings? settings)
        {
            this.settings = settings;
            Gtk.Button button = new Gtk.Button.with_label("Monkey strikes");
            this.attach(button, 0, 0, 1, 1);
            this.show_all();
        }
    }


    public class Plugin : Budgie.Plugin, Peas.ExtensionBase { //D
        public Budgie.Applet get_panel_widget(string uuid) {
            return new Applet();
        }
    }


    public class HotCornersPopover : Budgie.Popover { //E (function in python)
        private Gtk.EventBox indicatorBox;
        private Gtk.Image indicatorIcon;
    
        public HotCornersPopover(Gtk.EventBox indicatorBox) {
            GLib.Object(relative_to: indicatorBox);
            this.indicatorBox = indicatorBox;
            /* set icon */
            indicatorIcon = new Gtk.Image.from_icon_name(
                "hello-world-smile-symbolic", Gtk.IconSize.MENU
            );
            indicatorBox.add(indicatorIcon);
            /* just a test */
            Gtk.Label HotCornersLabel = new Gtk.Label("Hello Prutser!");
            /* Math test */
            double x_travel = Math.pow(8, 2);
            /* test math */
            print(@"$x_travel\n\n");
            this.add(HotCornersLabel);
        }
    }

    public class Applet : Budgie.Applet { //A

        private Gtk.EventBox indicatorBox;
        private HotCornersPopover popover = null;
        private unowned Budgie.PopoverManager? manager = null;
        public string uuid { public set; public get; }

        /* specifically to the settings section */
        public override bool supports_settings()
        {
            return true;
        }
        public override Gtk.Widget? get_settings_ui()
        {
            return new HotCornersSettings(this.get_applet_settings(uuid));
        }

        public Applet() {
            initialiseLocaleLanguageSupport();
            /* box */
            indicatorBox = new Gtk.EventBox();
            add(indicatorBox);
            /* Popover */
            popover = new HotCornersPopover(indicatorBox);
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
            show_all();
        }

        /* Update popover */
        public override void update_popovers(Budgie.PopoverManager? manager)
        {
            this.manager = manager;
            manager.register_popover(indicatorBox, popover);
        }

        public void initialiseLocaleLanguageSupport(){
            // Initialise gettext
            GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
            GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
            GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
        }
    }
}

/* category: "ok, i believe you" */
[ModuleInit]
public void peas_register_types(TypeModule module){
    /* boilerplate - all modules need this */
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(
        Budgie.Plugin), typeof(HotCornersApplet.Plugin)
    );
}