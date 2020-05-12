# Toggle desktop icons

Toggle desktop icons is an experimental applet, not so much for its functionality but for the fact that it has built-in spacers. The space can be set from Budgie Settings.

This has great advantages in organizing and reorganizing the panel, setting initial spacing on default installs etc, but also when using "conditionally" showing up applet icons like DropBy. These icons leave a double space when hiden, which shows ugly in the panel.

We could make built-in spacer a dconf -option-, or even make the settings option in Budgie Settings an option, in case any distro would not use it.

# Install

* Copy panelspacer.png to /usr/share/pixmaps
* install the gschema (copy to /usr/share/glib-2.0/schemas, then run sudo glib-compile-schemas /usr/share/glib-2.0/schemas/)
* Copy the folder toggledesktopicons to ~/.local/share/budgie-desktop/plugins
* Restart the panel or log out/in

 
