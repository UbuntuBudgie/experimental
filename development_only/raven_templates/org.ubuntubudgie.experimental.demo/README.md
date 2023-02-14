# Demo Raven Widget

### Uptime Raven Plugin Widget

This plugin simply shows the uptime.
While it is a fully functioning widget, it was only designed to serve as a very basic example of a 3rd party Raven widget.

It will install the raven plugin, icons, and schema

Dependencies

* gtk+-3.0
* budgie-raven-plugin-1.0
* libpeas-gtk-1.0

To install (for Debian/Ubuntu):

    mkdir build
    cd build
    meson --prefix=/usr --libdir=/usr/lib
    ninja
    sudo ninja install

Logout / Login may be needed before the widget can be added to allow an installed schema to be recognized.

Notes:
* Raven Widgets require the plugin module name to be in reverse DNS format.
* If the widget supports settings, a schema must be installed with an ID that matches the name of the plugin module.
* After installing, logging out / in may be required for Budgie Desktop to recognize the schema.
