using Gtk;
using Gdk;

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


    public class Plugin : Budgie.Plugin, Peas.ExtensionBase {
        public Budgie.Applet get_panel_widget(string uuid) {
            return new Applet();
        }
    }


    public class Applet : Budgie.Applet {

        private Gtk.EventBox indicatorBox;
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

            // set / update time label
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
            add(indicatorBox);
            indicatorBox.add(label);
            wnck_scr = Wnck.Screen.get_default();
            update_appearance();
            wnck_scr.active_workspace_changed.connect(() => {
                update_appearance();
            });
            show_all();
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