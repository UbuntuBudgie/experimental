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


public class HelloWorldApplet : Budgie.Applet{

    Gtk.EventBox indicatorBox;
    Gtk.Image indicatorIcon;
    Budgie.Popover? popover = null;
    private unowned Budgie.PopoverManager? manager = null;

    public HelloWorldApplet(){

        // Indicator box on Panel
        indicatorBox = new Gtk.EventBox();
        add(indicatorBox);
        indicatorIcon = new Gtk.Image.from_icon_name("hello-world-smile-symbolic", Gtk.IconSize.MENU);
        indicatorBox.add(indicatorIcon);
       
        // Popover
        popover = new HelloWorldPopover(indicatorBox);
        
        // On Press indicatorBox
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

        // Finally show all
        popover.get_child().show_all();
        show_all();

    }

    /*Update popover*/
    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(indicatorBox, popover);
    }

}