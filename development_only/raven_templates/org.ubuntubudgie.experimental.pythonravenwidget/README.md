# Budgie Python Raven Widget Example

## A simple example of a Python based Raven widget

This example shows a basic Raven widget written in Python.
It has no function other than to provide:
* simple raven widget
* simple settings widget
* simple schema example

To install (for Debian/Ubuntu):

    mkdir build
    cd build
    meson --prefix=/usr --libdir=/usr/lib
    sudo ninja install

* for other distros omit libdir or specify the location of the distro library folder

This will:
* install plugin files to the Budgie Desktop Raven plugins folder
* install the necessary icons
* compile the schema

Notes when using Python Raven widgets:
* the module must be named in reverse DNS format, replacing "." with "_"
 i.e. org_ubuntubudgie_experimental_pythonravenwidget
* if the module supports settings, a schema must be installed with an ID that matches the module name