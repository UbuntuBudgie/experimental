#!/usr/bin/envpython3
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib
from notifythesecond import NotifyWindow


class SomeWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self)
        self.title = "Blubtest"
        self.show_all()
        button = Gtk.Button()
        self.add(button)
        button.connect("clicked", self.clickstuff)
        self.show_all()
        GLib.idle_add(self.run_notify)
        self.connect("destroy", Gtk.main_quit)
        Gtk.main()

    def run_notify(self):
        NotifyWindow(
            "Title", "SomeBody else is writing this",
            "budgie-foldertrack-symbolic", "gedit", 2, 10
        )
        return False

    def clickstuff(self, button):
        print("clickme")


SomeWindow()

