#!/usr/bin/python3

# This file is part of Trash

# Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
# Copyright © 2018 Serdar ŞEN <serdarbote@gmail.com>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.


import gi.repository
gi.require_version('Gtk', '3.0')
gi.require_version('Budgie', '1.0')
gi.require_version('Gio', '2.0')
from gi.repository import Gio
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Budgie
from Dialog import Dialog
from Log import Log
from Error import Error


class TrashApplet(Budgie.Applet):
    ## Budgie.Applet is in fact a Gtk.Bin

    def __init__(self, uuid):
        self.TAG = "budgie-trash.Trash"
        self.APPINDICATOR_ID = "io_serdarsen_github_budgie_trash"

        self.log = Log("budgie-trash")
        self.manager = None
        self.popover = None

        self.TRASH_EMPTY = "trash_empty"
        self.TRASH_FULL = "trash_full"
        self.TRASH_DELETING = "trash_deleting"
        self.state = self.TRASH_EMPTY

        self.popoverHeight = 0
        self.popoverWidth = 256
        self.popoverHeight = 110

        self.trashPath = "trash:///"
        self.trashFile = Gio.file_new_for_uri(self.trashPath)

        Budgie.Applet.__init__(self)
        self.buildIndicator()
        self.buildPopover()
        self.buildStack()

        self.setupWatch()
        self.update()


    ####################################
    # build START
    ####################################
    def buildIndicator(self):

        self.indicatorBox = Gtk.EventBox()
        self.add(self.indicatorBox)
        self.indicatorBox.connect("button-press-event", self.indicatorBoxOnPress)

    def buildPopover(self):
        self.popover = Budgie.Popover.new(self.indicatorBox)
        self.popover.set_default_size(self.popoverWidth, self.popoverHeight)
        # self.popover.get_style_context().add_class("budgie-menu")
        self.popover.get_child().show_all()
        self.show_all()

    def buildStack(self):
        self.stack = Gtk.Stack()
        self.stack.set_homogeneous(False)
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.popover.add(self.stack)
        self.buildStackPage1()
        self.buildStackPage2()

    def buildStackPage1(self):
        ## page 1
        page1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        page1.border_width = 0
        self.stack.add_named(page1, "page1")
        self.setMargins(page1, 10, 0, 0, 0)
        # page1.props.valign = Gtk.Align.CENTER

        ## page 1 content
        openButton = Gtk.Button("Open", xalign=0)
        page1.pack_start(openButton, False, False, 0)
        openButton.connect("clicked", self.openButtonOnClick)
        openButton.get_style_context().add_class("flat")
        openButton.set_size_request(0, 36)

        self.emptyButton = Gtk.Button("Empty Trash", xalign=0)
        page1.pack_start(self.emptyButton, False, False, 0)
        self.emptyButton.connect("clicked", self.emptyButtonOnClick)
        self.emptyButton.get_style_context().add_class("flat")
        self.emptyButton.set_size_request(0, 36)

    def buildStackPage2(self):
        ## page 2
        page2 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        page2.border_width = 0
        self.setMargins(page2, 10, 0, 0, 0)
        self.stack.add_named(page2, "page2")
        # page2.props.valign = Gtk.Align.CENTER

        ## page 2 content
        dialog = Dialog()
        dialog.setTitle("Empty trash?")
        dialog.addOnClickMethodToNoBtn(self.noButtonOnClick)
        dialog.addOnClickMethodToYesBtn(self.yesButtonOnClick)
        page2.pack_start(dialog, True, True, 0)
    ####################################
    # build END
    ####################################


    ####################################
    # open START
    ####################################
    def openStackPage1(self):
        self.stack.set_visible_child_name("page1")

    def openStackPage2(self):
        self.stack.set_visible_child_name("page2")
    ####################################
    # open END
    ####################################


    ####################################
    # OnPess START
    ####################################
    def indicatorBoxOnPress(self, box, e):
        self.openStackPage1()
        if e.button != 1:
            return Gdk.EVENT_PROPAGATE
        if self.popover.get_visible():
            self.popover.hide()
        else:
            self.update()
            self.manager.show_popover(self.indicatorBox)
        return Gdk.EVENT_STOP
    ####################################
    # OnPess END
    ####################################


    ####################################
    # onClick START
    ####################################
    def noButtonOnClick(self, button):
        self.openStackPage1()

    def yesButtonOnClick(self, button):
        self.hidePopover()
        self.emptyTrash()

    def openButtonOnClick(self, button):
        self.hidePopover()
        try:
            Gio.app_info_launch_default_for_uri(self.trashPath, None)
        except Exception as e:
            self.log.e(self.TAG, Error.ERROR_1010, e)

    def emptyButtonOnClick(self, button):
        self.openStackPage2()
    ####################################
    # onClick END
    ####################################


    ####################################
    # onChange START
    ####################################
    def onTrashChange(self, monitor, file1, file2, evt_type):
        if self.state is not self.TRASH_DELETING:
            if self.isTrashEmpty():
                self.updateIndicatorIcon(self.TRASH_EMPTY)
            else:
                self.updateIndicatorIcon(self.TRASH_FULL)
    ####################################
    # onChange END
    ####################################


    ####################################
    # update START
    ####################################
    def update(self):

        if self.isTrashEmpty():
            self.emptyButton.set_sensitive(False)
            self.updateIndicatorIcon(self.TRASH_EMPTY)
        else:
            self.emptyButton.set_sensitive(True)
            self.updateIndicatorIcon(self.TRASH_FULL)

        # self.popover.set_size_request(self.popoverWidth, self.popoverHeight)
        self.popover.get_child().show_all()
        self.show_all()

    ## This is a virtual method of the Budgie.Applet
    ## https://lazka.github.io/pgi-docs/Budgie-1.0/classes/Applet.html#Budgie.Applet.do_update_popovers
    def do_update_popovers(self, manager):
        self.manager = manager
        self.manager.register_popover(self.indicatorBox, self.popover)

    def updateIndicatorIcon(self, state):
        if self.indicatorBox is not None:
            for widget in self.indicatorBox.get_children():
                widget.destroy()
            self.state = state
            if self.state is self.TRASH_EMPTY:
                indicatorIcon = Gtk.Image.new_from_icon_name("budgie-trash-empty-symbolic", Gtk.IconSize.MENU)
                self.indicatorBox.add(indicatorIcon)
            elif self.state is self.TRASH_FULL:
                indicatorIcon = Gtk.Image.new_from_icon_name("budgie-trash-full-symbolic", Gtk.IconSize.MENU)
                self.indicatorBox.add(indicatorIcon)
            elif self.state is self.TRASH_DELETING:
                spinner = Gtk.Spinner()
                self.indicatorBox.add(spinner)
                spinner.start()
            self.indicatorBox.show_all()
    ####################################
    # update END
    ####################################


    ####################################
    # hide START
    ####################################
    def hidePopover(self):
        if (self.popover is not None):
            if self.popover.get_visible():
                self.popover.hide()
    ####################################
    # hide END
    ####################################


    ####################################
    # other START
    ####################################
    def setMargins(self, widget, top, bottom, left, right):
        widget.set_margin_top(top)
        widget.set_margin_bottom(bottom)
        widget.set_margin_left(left)
        widget.set_margin_right(right)

    def setupWatch(self):
        self.monitor = self.trashFile.monitor_directory(0, None)
        self.monitor.connect('changed', self.onTrashChange)

    def isTrashEmpty(self):
        children = self.trashFile.enumerate_children('*', 0, None)
        if children.next_file(None) is not None:
            return False
        else:
            return True

    def emptyTrash(self):
        children = self.trashFile.enumerate_children('*', 0, None)
        self.updateIndicatorIcon(self.TRASH_DELETING)
        while True:
            # self.log.d(self.TAG, "deleting...")
            childInfo = children.next_file(None)
            if childInfo  is not None:
                child = self.trashFile.get_child(childInfo.get_name())
                child.delete(None)
            else:
                # self.log.d(self.TAG, "done.")
                self.updateIndicatorIcon(self.TRASH_EMPTY)
                break
    ####################################
    # other END
    ####################################
