#!/usr/bin/python3

# This file is part of Trash

# Copyright © 2018 Serdar ŞEN <serdarbote@gmail.com>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.


import gi.repository
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk


class Dialog(Gtk.VBox):

    def __init__(self):
        Gtk.VBox.__init__(self)
        self.props.valign = Gtk.Align.CENTER
        ## page 2 inner Box 2 content
        self.title = Gtk.Label()
        self.setMargin(self.title, 0, 15, 0, 0)
        self.add(self.title)

        yesNoBtnBox = Gtk.HBox()
        yesNoBtnBox.props.valign = Gtk.Align.START
        self.add(yesNoBtnBox)
        self.setMargin(yesNoBtnBox, 0, 0, 0, 0)
        self.noBtn = Gtk.Button("No")
        yesNoBtnBox.add(self.noBtn)
        self.yesBtn = Gtk.Button("Yes")
        self.yesBtn.get_style_context().add_class("destructive-action")
        yesNoBtnBox.add(self.yesBtn)

    def addOnClickMethodToNoBtn(self, method):
        self.noBtn.connect("clicked", method)

    def addOnClickMethodToYesBtn(self, method):
        self.yesBtn.connect("clicked", method)

    def setTitle(self, text):
        titleText = "<span size='large'><b>%s</b></span>" % text
        self.title.set_markup(titleText)

    def setMargin(self, widget, top, bottom, left, right):
        widget.set_margin_top(top)
        widget.set_margin_bottom(bottom)
        widget.set_margin_left(left)
        widget.set_margin_right(right)