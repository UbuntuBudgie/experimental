# Demo Raven Widget

### Sample Raven Plugin Widget

This plugin does nothing.
It serves as a basic example of a Raven plugin widget.

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

Logout / Login to allow an installed schema to be recognized.

Notes:
- Raven Widgets require the plugin module name to be in reverse DNS format.
- If the widget supports settings, a schema must be installed, and the schema ID must match the name of the plugin module.
- After installing, logging out / in may be required for Budgie Desktop to recognize the schema.
