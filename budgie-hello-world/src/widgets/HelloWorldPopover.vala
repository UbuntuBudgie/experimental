/*
 * This file is part of UbuntuBudgie
 *
 * Copyright © 2015-2017 Budgie Desktop Developers
 * Copyright © 2018-2019 Ubuntu Budgie Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

namespace HelloWorldApplet.Widgets {

public class HelloWorldPopover : Budgie.Popover {

    private Gtk.EventBox indicatorBox;
    private Gtk.Image indicatorIcon;

    public HelloWorldPopover(Gtk.EventBox indicatorBox) {
        Object(relative_to: indicatorBox);

        this.indicatorBox = indicatorBox;

        indicatorIcon = new Gtk.Image.from_icon_name("hello-world-smile-symbolic", Gtk.IconSize.MENU);
        indicatorBox.add(indicatorIcon);

        set_size_request(200, 100);
        
        Gtk.Box mainContent = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(mainContent);

        Gtk.Label helloWorldLabel = new Gtk.Label(_("Hello World!"));
        mainContent.set_center_widget(helloWorldLabel);

    }

}

}