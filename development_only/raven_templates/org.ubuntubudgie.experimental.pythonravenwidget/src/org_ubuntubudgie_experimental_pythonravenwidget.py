"""
    Budgie Python Raven Widget Example
    Simple example of a Raven Widget written in Python

    Author: Sam Lane
    Copyright © 2023 Ubuntu Budgie Developers
    Website=https://ubuntubudgie.org
    This program is free software: you can redistribute it and/or modify it under
    the terms of the GNU General Public License as published by the Free Software
    Foundation, either version 3 of the License, or any later version. This
    program is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
    A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
    should have received a copy of the GNU General Public License along with this
    program.  If not, see <https://www.gnu.org/licenses/>.
"""


#!/usr/bin/env python3
import gi
gi.require_version("Gtk", "3.0")
gi.require_version('BudgieRaven', '1.0')
from gi.repository import BudgieRaven, GObject, Gtk, Gio


class PythonRavenPlugin(GObject.GObject, BudgieRaven.RavenPlugin):
    """ This is simply an entry point into your Budgie Raven Plugin implementation.
        Note you must always override Object, and implement RavenPlugin.
    """
    # Good manners, make sure we have unique name in GObject type system
    __gtype_name__ = "org_ubuntubudgie_experimental_pythonravenwidget"

    def __init__(self):
        """ Initialisation is important.
        """
        GObject.Object.__init__(self)

    def do_new_widget_instance(self, uuid, settings):
        """ This is where the real fun happens. Return a new BudgieRaven.RavenWidget
            instance with the given UUID. The UUID is determined by the
            BudgiePanelManager, and is used for lifetime tracking.
        """
        return PythonRavenWidget(uuid, settings)

    def do_supports_settings(self):
        """ If we have support settings, a schema must be installed with an ID
            that matches the reverse DNS format python module name
        """
        return True


class PythonRavenWidget(BudgieRaven.RavenWidget):

    def __init__(self, uuid, settings):
        BudgieRaven.RavenWidget.__init__(self)
        self.uuid = uuid
        self.settings = settings

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        box.get_style_context().add_class("raven-header")

        icon = Gtk.Image()
        icon.set_from_icon_name("python-widget-symbolic", Gtk.IconSize.MENU)
        icon.set_margin_start(12)
        icon.set_margin_end(12)
        box.add(icon)

        label = Gtk.Label(label="Sample Python Widget")
        box.add(label)

        self.add(box)
        self.show_all()

        """ Connect to the raven-expanded signal
            Triggered whenever Raven is opened or closed
        """
        self.connect("raven_expanded", self.on_raven_expanded)

        self.settings.connect("changed::boolean-setting", self.on_settings_changed)

    def on_raven_expanded(self, widget, expanded):
        if expanded:
            print("Raven was expanded")
        else:
            print("Raven was closed")

    def on_settings_changed(self, settings, settingname):
        if settings.get_boolean(settingname):
            print("Setting switch toggled on")
        else:
            print("Setting switch toggled off")

    def do_build_settings_ui(self):
        """ If we support settings, return the settings grid
        """
        return PythonRavenWidgetSettings(self.settings)


class PythonRavenWidgetSettings(Gtk.Grid):
    """ Our Raven Widget settings grid
    """
    def __init__(self, settings):
        super().__init__()
        self.settings = settings
        self.label = Gtk.Label("Setting Switch: ")
        self.switch = Gtk.Switch()
        self.settings.bind("boolean-setting", self.switch, "active",
                           Gio.SettingsBindFlags.DEFAULT)
        self.attach(self.label, 0, 0, 1, 1)
        self.attach(self.switch, 1, 0, 1, 1)
        self.show_all()
