#!/usr/bin/env python3
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib
import sys
import subprocess

"""
notifythesecond
Author: Jacob Vlijm
Copyright ©2019 Ubuntu Budgie Developers
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

class NotifyWindow(Gtk.Window):

    def __init__(self):
        Gtk.Window.__init__(self)
        self.set_decorated(False)
        distance = 80 # gsettings
        winwidth = 300 # gsettings
        winheight = 80 # gsettings
        self.set_default_size(winwidth, winheight)
        self.maingrid = Gtk.Grid()
        self.add(self.maingrid)  
        self.set_space()
        self.winpos = 4 # gsettings? default = SE
        self.get_args()
        self.currage = 0
        self.targetage = 10 # gsettings,life seconds
        GLib.timeout_add_seconds(1, self.limit_windowlife) 
        self.maingrid.show_all()
        self.position_popup(self.winpos, winwidth, winheight, distance)
        self.show_all()
        Gtk.main()

    def get_winpos(self, arg):
        self.winpos = int(arg)
        
    def limit_windowlife(self):
        if self.currage >= self.targetage:
            Gtk.main_quit()
        self.currage = self.currage + 1;
        return True        

    def position_popup(self, winpos, winwidth, winheight, distance):
        monitordata = self.get_primarymonitor()
        winsize = self.get_size()
        winwidth, winheight = winsize.width, winsize.height
        if winpos == 1:
            wintargetx = monitordata[2] + distance
            wintargety = monitordata[3] + distance
        elif winpos == 2:
            wintargetx = monitordata[0] + monitordata[2] - winwidth - distance
            wintargety = monitordata[3] + distance
        elif winpos == 3:
            wintargetx = monitordata[2] + distance
            wintargety = monitordata[3] + monitordata[1] - (
                distance + winheight
            )
        elif winpos == 4:
            wintargetx = monitordata[0] + monitordata[2] - winwidth - distance
            wintargety = monitordata[3] + monitordata[1] - (
                distance + winheight
            )
        self.move(wintargetx, wintargety)

    def get_primarymonitor(self):
        # see what is the resolution on the primary monitor
        prim = Gdk.Display.get_default().get_primary_monitor()
        geo = prim.get_geometry()
        [width, height, screen_xpos, screen_ypos] = [
            geo.width, geo.height, geo.x, geo.y
        ]
        height = geo.height
        return width, height, screen_xpos, screen_ypos
        
    def show_title(self, title):
        title_label = Gtk.Label(label=title)
        self.maingrid.attach(title_label, 3, 1, 1, 1)
        title_label.set_xalign(0)
        # set title bold
        self.noti_css = ".title {font-weight: bold; padding-bottom: 5px;}"
        self.provider = Gtk.CssProvider.new()
        self.provider.load_from_data(self.noti_css.encode())
        self.set_textstyle(title_label, "title")

    def set_body(self, body):
        body_label = Gtk.Label(
            label=body
        )
        self.maingrid.attach(body_label, 3, 2, 1, 1)
        body_label.set_xalign(0)
        body_label.set_size_request(250, -1)
        body_label.set_line_wrap(True)

    def set_icon(self, icon):
        self.maingrid.attach(Gtk.Label(label="\t"), 2, 0, 1, 1)
        if not "/" in icon:
            newicon = Gtk.Image.new_from_icon_name(
                icon, Gtk.IconSize.DIALOG
            )
            self.maingrid.attach(newicon, 1, 1, 1, 2)
            self.maingrid.show_all()

    def get_args(self):
        args = sys.argv[1:]
        funcs = [
            self.show_title, self.set_body, self.set_icon,
            self.connect_action, self.get_winpos,
        ]
        argnames = ["title", "body", "icon", "command", "position"]
        for arg in args:
            argdata = arg.split("=")
            argname = argdata[0]
            arg = argdata[1]
            try:
                i = argnames.index(argname)
                funcs[i](arg)
            except ValueError:
                print("invalid argument:", arg)             

    def connect_action(self, arg):
        self.connect("button_press_event", self.run_command, arg)
        pass
                    
    def set_textstyle(self, widget, style):
        widget_cont = widget.get_style_context()
        widget_cont.add_class(style)
        Gtk.StyleContext.add_provider(
            widget_cont,
            self.provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )               
                
    def run_command(self, event, key, command):
        if key.get_button()[1] == 1:
            subprocess.Popen(["/bin/bash", "-c", command])

    def set_space(self):
        for cell in [[0, 0], [100, 0], [0, 100], [100, 100]]:
            self.maingrid.attach(
                Gtk.Label(label="\t"), cell[0], cell[1], 1, 1
            )

NotifyWindow()
