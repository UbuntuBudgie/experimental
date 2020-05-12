#!/usr/bin/env python3
import gi.repository
gi.require_version('Budgie', '1.0')
gi.require_version('Gtk', '3.0')
from gi.repository import Budgie, GObject, Gtk, Gio


class ToggleDesktopIcons(GObject.GObject, Budgie.Plugin):

    __gtype_name__ = "ToggleDesktopIcons"

    def __int__(self):
        GObject.Object.__init__(self)

    def do_get_panel_widget(self, uuid):
        return ToggleDesktopIconsApplet(uuid)

class ToggleDesktopIconsSettings(Gtk.Grid):

    def __init__(self, setting):

        super().__init__()

        self.setting = setting
        # grid & layout
        toggleicons_spacegrid = Gtk.Grid()
        self.add(toggleicons_spacegrid)
        for cell in [[0, 0], [100, 0], [0, 100], [100, 100]]:
            toggleicons_spacegrid.attach(
                Gtk.Label(label="\t"), cell[0], cell[1], 1, 1
            )
        self.space_settings = Gio.Settings(
            schema="org.ubuntubudgie.plugins.toggle-desktop-icons"
        )
        currvalue = self.space_settings.get_int("spacersize")
        space = Gtk.SpinButton()
        space.set_range(0, 30)
        space.set_increments(1, 1)
        space.set_value(currvalue)
        space.connect("value-changed", self.update_value)
        label = Gtk.Label("Set built-in spacer (0 = off)" + "\n")
        toggleicons_spacegrid.attach(label, 1, 1, 2, 1)
        toggleicons_spacegrid.attach(space, 1, 2, 1, 1)
        self.show_all()

    def update_value(self, spin):
        newval = spin.get_value()
        self.space_settings.set_int("spacersize", newval)

class ToggleDesktopIconsApplet(Budgie.Applet):

    manager = None

    def __init__(self, uuid):

        Budgie.Applet.__init__(self)
        self.uuid = uuid
        # replace the button by an EventBox
        # some definitions
        self.icon_align = None
        self.position_index = 0 # index of panel position
        self.space_settings = Gio.Settings(
            schema="org.ubuntubudgie.plugins.toggle-desktop-icons"
        )
        self.currvalue = self.space_settings.get_int("spacersize")
        self.space_settings.connect("changed", self.update_alignment)
        self.box = Gtk.EventBox()    
        self.add(self.box)
        self.to_toggle = Gio.Settings(schema="org.nemo.desktop")
        self.box.connect("button-press-event", self.toggle_desktopicons)
        self.box.show_all()
        self.show_all()

    def do_get_settings_ui(self):
        """Return the applet settings with given uuid"""
        return ToggleDesktopIconsSettings(self.get_applet_settings(self.uuid))

    def do_supports_settings(self):
        """Return True if support setting through Budgie Setting,
        False otherwise.
        """
        return True

    def do_panel_size_changed(self, panelsize, icsize, small_icsize):
        diff = icsize - small_icsize
        newspace = round(panelsize/2 - small_icsize/2 + (diff/4))
        if icsize >= 48:
            newspace = newspace + 2 
        elif panelsize < 39:
            newspace = 9
        self.icon_align = newspace
        self.update_alignment()

    def update_alignment(self, *args):
        self.currvalue = self.space_settings.get_int("spacersize")
        newgrid = self.create_icongrid(self.position_index)
        for item in self.box.get_children():
            self.box.remove(item)
        newgrid.show_all()
        if self.icon_align is not None:
            if self.position_index in [0, 1]:
                newgrid.set_column_spacing(self.icon_align)
                newgrid.set_row_spacing(self.currvalue)
            else:
                newgrid.set_row_spacing(self.icon_align)
                newgrid.set_column_spacing(self.currvalue)
        self.box.add(newgrid)
        
    def do_panel_position_changed(self, panelposition):
        if panelposition != Budgie.PanelPosition.NONE:
            panelpositions = [
                Budgie.PanelPosition.RIGHT,
                Budgie.PanelPosition.LEFT,
                Budgie.PanelPosition.BOTTOM,
                Budgie.PanelPosition.TOP,
            ]
            self.position_index = panelpositions.index(panelposition)
            self.update_alignment()
            
    def create_icongrid(self, exclude):
        icongrid = Gtk.Grid()
        img_path = "/usr/share/pixmaps/panelspacer.png"
        main_icon = Gtk.Image.new_from_icon_name(
            "preferences-desktop-display-symbolic", Gtk.IconSize.MENU
        )
        placers = [[0, 1], [2, 1], [1, 0], [1, 2]]
        for n in range(4):
            if not n == exclude:
                icongrid.attach(
                    Gtk.Image.new_from_file(img_path),
                    placers[n][0], placers[n][1], 1, 1,
                )
        icongrid.attach(main_icon, 1, 1, 1, 1)
        return icongrid

    def toggle_desktopicons(self, Button, *args):
        newstate = not self.to_toggle.get_boolean("show-desktop-icons")
        self.to_toggle.set_boolean("show-desktop-icons", newstate)
