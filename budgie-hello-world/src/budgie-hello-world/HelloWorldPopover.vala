/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2017 Budgie Desktop Developers
 * Copyright © 2018-2019 Ubuntu Budgie Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class HelloWorldPopover : Budgie.Popover {


    public HelloWorldPopover(Gtk.Widget? indicatorBox) {
        Object(relative_to: indicatorBox);

        set_size_request(200, 100);
        
        Gtk.Box mainContent = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(mainContent);

        Gtk.Label helloWorldLabel = new Gtk.Label("Hello World!");
        mainContent.set_center_widget(helloWorldLabel);

    }

}