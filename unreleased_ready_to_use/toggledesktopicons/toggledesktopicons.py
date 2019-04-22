#!/usr/bin/env python3
import subprocess
import gi.repository
gi.require_version('Budgie', '1.0')
from gi.repository import Budgie, GObject, Gtk, Gio


# stuff to read the current gsettings value

key = "org.nemo.desktop"
val = "show-desktop-icons"
currset = Gio.Settings.new(key)


class ToggleDesktopIcons(GObject.GObject, Budgie.Plugin):

    __gtype_name__ = "ToggleDesktopIcons"

    def __int__(self):
        GObject.Object.__init__(self)

    def do_get_panel_widget(self, uuid):
        return ToggleDesktopIconsApplet(uuid)


class ToggleDesktopIconsApplet(Budgie.Applet):

    manager = None

    def __init__(self, uuid):

        Budgie.Applet.__init__(self)

        self.box = Gtk.EventBox()
        self.add(self.box)
        img = Gtk.Image.new_from_icon_name(
            "preferences-desktop-display-symbolic", Gtk.IconSize.MENU
        )
        self.box.add(img)
        self.box.connect("button-press-event", self.toggle_show)
        self.box.show_all()
        self.show_all()

    def toggle_show(self, box, button):
        currset.set_boolean(
            val, currset.get_boolean(val) == False
        )

    def alternative_desktop(self, box, button):
        path = "/home/jacob/Desktop/alternative_desktop"
        try:
            pid = subprocess.check_output([
                "pgrep", "-f", path
            ]).decode("utf-8").strip()
            subprocess.Popen(["kill", str(pid)])
        except subprocess.CalledProcessError:
            subprocess.Popen(path)
        
