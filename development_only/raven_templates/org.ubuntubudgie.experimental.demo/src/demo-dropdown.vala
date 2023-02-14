 /*
 * Copyright Ubuntu Budgie Developers
 * Copyright Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

 public class DemoDropDown : Gtk.Box {

	private Gtk.Revealer content_revealer;
	private Gtk.Box header_box;
	private Gtk.Box content;
	private Gtk.Widget header_icon;
	private Gtk.Widget header_label;
	private Gtk.Label uptime_label;
	private bool show_seconds;

	private int read_uptime() {
		// read the uptime from /proc/uptime and return the seconds
		File file = File.new_for_path ("/proc/uptime");
		string line = "";
		try {
			FileInputStream @is = file.read ();
			DataInputStream dis = new DataInputStream (@is);
			line = dis.read_line().split(" ", 0)[0];
		} catch (Error e) {
			message ("Unable to get uptime: %s\n", e.message);
			return 0;
		}
		return int.parse(line);
	}

	private string get_uptime_string() {
		// get the uptime in seconds and convert it do dd:hh:mm:ss
		int total_time = read_uptime();
		int days = (int) total_time / 86400;
		total_time = total_time % 86400;
		int hours = (int) total_time / 3600;
		total_time = total_time % 3600;
		int minutes = (int) total_time / 60;
		total_time = total_time % 60;
		int seconds = (int) total_time;
		string formatted_uptime = "%id %02dh %02dm".printf (days, hours, minutes);
		if (show_seconds) {
			formatted_uptime += " %02ds".printf(seconds);
		}
		return formatted_uptime;
	}

	public DemoDropDown (Settings? settings) {
		header_icon = new Gtk.Image.from_icon_name("demo-icon-symbolic", Gtk.IconSize.MENU);
		header_label = new Gtk.Label("Budgie Uptime");

		// These properties are the same used by the similar syle built-in Raven widgets
		// It makes sense to copy these values so the styling remains consistent
		set_orientation(Gtk.Orientation.VERTICAL);
		set_spacing(0);
		header_icon.margin = 4;
		header_icon.margin_start = 12;
		header_icon.margin_end = 10;
		header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		header_box.get_style_context().add_class("raven-header");

		header_box.add(header_icon);
		header_box.add(header_label);
		add(header_box);

		content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		content.get_style_context().add_class("raven-background");
		content_revealer = new Gtk.Revealer();
		content_revealer.add(content);
		content_revealer.reveal_child = true;
		add(content_revealer);

		var header_reveal_button = new Gtk.Button.from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
		header_reveal_button.get_style_context().add_class("flat");
		header_reveal_button.get_style_context().add_class("expander-button");
		header_reveal_button.margin = 4;
		header_reveal_button.valign = Gtk.Align.CENTER;
		header_reveal_button.clicked.connect(() => {
			content_revealer.reveal_child = !content_revealer.child_revealed;
			var image = (Gtk.Image?) header_reveal_button.get_image();
			if (content_revealer.reveal_child) {
				image.set_from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
			} else {
				image.set_from_icon_name("pan-end-symbolic", Gtk.IconSize.MENU);
			}
		});
		header_box.pack_end(header_reveal_button, false, false, 0);

		var grid = new DemoDropDownGrid();
		content.add(grid);

		show_seconds = settings.get_boolean("show-seconds");
		uptime_label = new Gtk.Label(get_uptime_string());
		uptime_label.set_halign(Gtk.Align.CENTER);
		uptime_label.set_hexpand(true);

		grid.attach(uptime_label,0,0,1,1);
		settings.changed["show-seconds"].connect (() => {
			show_seconds = settings.get_boolean("show-seconds");
			update();
		});

		show_all();
	}

	public void update() {
		uptime_label.set_text(get_uptime_string());
	}
}

/*
 * Just a Gtk.Grid that mimics the margins used by built-in widgets
 */

public class DemoDropDownGrid : Gtk.Grid {

	public DemoDropDownGrid () {
		hexpand = true;
		margin_start = 12;
		margin_end = 12;
		margin_top = 8;
		margin_bottom = 8;
	}
}