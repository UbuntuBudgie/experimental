
 /*
 * Copyright Ubuntu Budgie Developers
 * Copyright Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class DemoRavenPlugin : Budgie.RavenPlugin, Peas.ExtensionBase {
	public Budgie.RavenWidget new_widget_instance(string uuid, GLib.Settings? settings) {
		return new DemoRavenWidget(uuid, settings);
	}

	public bool supports_settings() {
		// do we have settings for this plugin?
		// if we do, a schema must be installed also with the same name as the module
		return true;
	}
}

public class DemoRavenWidget : Budgie.RavenWidget {

	private uint source_id;

	public DemoRavenWidget(string uuid, GLib.Settings? settings) {
		initialize(uuid, settings);

		// DemoDropDown is box containing header items and a revealer - any widget can be
		// added, but this is based on built-in widgets so the style would be consistent
		var dropdown = new DemoDropDown(settings);
		add(dropdown);
		show_all();

		// raven_expanded is triggered when the panel is opened or closed
		// start/stop the update - no need to update the widget when panel is closed
		raven_expanded.connect((expanded) => {
			if (!expanded && source_id != 0) {
				Source.remove(source_id);
				source_id = 0;
			} else if (expanded && source_id == 0) {
				dropdown.update();
				source_id = Timeout.add(1000, () => {
					dropdown.update();
					return true;
				});
			}
		});
	}

	public override Gtk.Widget build_settings_ui() {
		return new DemoRavenWidgetSettings(get_instance_settings());
	}
}

public class DemoRavenWidgetSettings : Gtk.Grid {
	// in this example we are using a relocatable schema
	Gtk.CheckButton checkbutton;

	public DemoRavenWidgetSettings (Settings? settings) {
		checkbutton = new Gtk.CheckButton.with_label("Show seconds");
		attach(checkbutton, 0, 1, 1, 1);
		settings.bind("show-seconds", checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);
		show_all();
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.RavenPlugin), typeof(DemoRavenPlugin));
}
