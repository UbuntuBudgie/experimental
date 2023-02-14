/* Template Applet for Budgie Panel */

public class TemplateRavenPlugin : Budgie.RavenPlugin, Peas.ExtensionBase {
	public Budgie.RavenWidget new_widget_instance(string uuid, GLib.Settings? settings) {
		return new TemplateRavenWidget(uuid, settings);
	}

	public bool supports_settings() {
		return false;
	}
}

public class TemplateRavenWidget : Budgie.RavenWidget {

	Gtk.Image icon;
	Gtk.Box widget;
	Gtk.Label label;

	public TemplateRavenWidget(string uuid, GLib.Settings? settings) {
		
		initialize(uuid, settings);

		widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		add(widget);
		widget.get_style_context().add_class("raven-header");

		icon = new Gtk.Image.from_icon_name("ubuntu-budgie-symbolic", Gtk.IconSize.MENU);
		icon.margin = 4;
		icon.margin_start = 12;
		icon.margin_end = 10;
		widget.add(icon);
		
		label = new Gtk.Label("Ubuntu Budgie");
		widget.add(label);
		
		show_all();
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.RavenPlugin), typeof(TemplateRavenPlugin));
}
