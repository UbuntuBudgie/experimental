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

public class HelloWorldPlugin : Budgie.Plugin, Peas.ExtensionBase{
    
    public Budgie.Applet get_panel_widget(string uuid){
    
        return new HelloWorldApplet();
    }

}

[ModuleInit]
public void peas_register_types(TypeModule module){

    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(HelloWorldPlugin));

}