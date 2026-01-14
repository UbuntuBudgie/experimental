/* Template Applet for Budgie Panel */

public class TemplateRavenPlugin : Budgie.RavenPlugin, Peas.ExtensionBase {
	public Budgie.RavenWidget new_widget_instance(string uuid, GLib.Settings? settings) {
		/*
		 * Typically we don't need the plugin info, but if we do, we get it here
		 * and pass it to the new Raven widget
		 */
		// Peas.PluginInfo plugin_info = get_plugin_info();
		return new TemplateRavenWidget(uuid, settings);
	}

	public bool supports_settings() {
		/*
		 * If we support settings, we also MUST install a schema with the same
		 * reverse DNS name of the plugin module or the plugin will not load
		 */
		return true;
	}
}

public class TemplateRavenWidget : Budgie.RavenWidget {

	Gtk.Image icon;
	Gtk.Box widget;
	Gtk.Label label;
	GLib.Settings? settings;

	public TemplateRavenWidget(string uuid, GLib.Settings? settings) {
		
		this.settings = settings;
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

	public override Gtk.Widget build_settings_ui() {
		return new TemplateRavenWidgetSettings(get_instance_settings());
	}
}


public class TemplateRavenWidgetSettings : Gtk.Grid {

	public TemplateRavenWidgetSettings (Settings? settings) {
		Gtk.Label demolabel = new Gtk.Label("Demo setting");
		Gtk.Switch demoswitch = new Gtk.Switch();
		demoswitch.set_active(settings.get_boolean("demo-setting"));
		settings.bind("demo-setting", demoswitch, "active", GLib.SettingsBindFlags.DEFAULT);
		attach(demolabel, 0,0,1,1);
		attach(demoswitch,1,0,1,1);
		show_all();
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.RavenPlugin), typeof(TemplateRavenPlugin));
}
