#!/usr/bin/env python3
import requests
import calendar as cal
import json
import os
import gi
gi.require_version("Gdk", "3.0")
gi.require_version('Pango', '1.0')
from gi.repository import Gio, Pango, Gdk, GdkPixbuf
import subprocess
import time


"""
Budgie WeatherShow
Author: Jacob Vlijm
Copyright © 2017-2018 Ubuntu Budgie Developers
Website=https://ubuntubudgie.org
This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or any later version. This
program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
should have received a copy of the GNU General Public License along with this
program.  If not, see <http://www.gnu.org/licenses/>.
"""


# paths
prefspath = os.path.join(
    os.environ["HOME"], ".config", "budgie-extras", "weathershow"
)
app_path = os.path.dirname(os.path.abspath(__file__))


# lists
markers = [
    "10d", "01n", "09n", "03d", "01d", "13d", "11n", "04d", "04n",
    "10n", "11d", "13n", "02n", "50d", "50n", "02d", "09d", "03n", "qmark",
]
arrows = [
    "↓", "↙", "←", "↖", "↑", "↗", "→", "↘", "↓",
]


# pixbuf
w_icons = []
small_icons = []
for icon in markers:
    w_icons.append(
        GdkPixbuf.Pixbuf.new_from_file_at_size(
            "/usr/share/pixmaps/budgie-wt-" + icon + ".svg", 150, 150,
        )
    )
    small_icons.append(
        GdkPixbuf.Pixbuf.new_from_file_at_size(
            "/usr/share/pixmaps/budgie-wt-" + icon + ".svg", 80, 80,
        )
    )


# files / paths
citylist = os.path.join(prefspath, "cities.txt")
textcolor = os.path.join(prefspath, "textcolor")
pos_file = os.path.join(prefspath, "position")
transparency = os.path.join(prefspath, "transparency")
keyfile = os.path.join(prefspath, "customkey")
currlang = os.path.join(prefspath, "currlang")
currcity = os.path.join(prefspath, "currcity")
wondesktop = os.path.join(app_path, "weathershow")
user = os.environ["USER"]
panelrunner = os.path.join(app_path, "wshow_panelrunner")


def convert_temp(temp):
    # prepare temp display
    return str(round(temp - 273.15)) + "℃" if temp else ""


def validate_val(source):
    return "" if not source else source


# make sure the dirs exist
try:
    os.makedirs(prefspath)
except FileExistsError:
    pass


def get(command):
    try:
        return subprocess.check_output(command).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        pass


def get_pid(proc):
    return get(["pgrep", "-f", "-u", user, proc]).splitlines()


def get_dayname(datestr):
    day = time.strptime(datestr, "%Y-%m-%d")
    return [d for d in cal.day_name][day[6]]


def restart_weather():
    for proc in [wondesktop, panelrunner]:
        try:
            for p in get_pid(proc):
                subprocess.Popen(["kill", p])
        except AttributeError:
            pass
    subprocess.Popen(panelrunner)


def get_area():
    # width of the primary screen.
    dspl = Gdk.Display()
    dsp = dspl.get_default()
    prim = dsp.get_primary_monitor()
    geo = prim.get_geometry()
    return [geo.width, geo.height]


def get_position():
    try:
        pos = [int(p) for p in open(pos_file).readlines()][:2]
        x = pos[0]
        y = pos[1]
        custom = True
    except (FileNotFoundError, ValueError, IndexError):
        scr = get_area()
        x = scr[0] * 0.2
        y = scr[1] * 0.2
        custom = False
    return (custom, x, y)


def get_transparency():
    try:
        return float(open(transparency).read())
    except FileNotFoundError:
        return 0


def getkey():
    try:
        return open(keyfile).read().strip()
    except FileNotFoundError:
        return "<key>"


def get_currlang():
    try:
        return open(currlang).read().strip()
    except FileNotFoundError:
        return "en"


def getcity():
    try:
        return [s.strip() for s in open(currcity).readlines()]
    except FileNotFoundError:
        return ["2643743", "London, GB"]


def read_color(f):
    try:
        return [int(n) for n in open(f).read().splitlines()]
    except FileNotFoundError:
        return [65535, 65535, 65535]


def write_settings(file, newval):
    subj = os.path.join(prefspath, file)
    open(subj, "wt").write(newval)


def hexcolor(rgb):
    c = [int((int(n) / 65535) * 255) for n in rgb]
    return '#%02x%02x%02x' % (c[0], c[1], c[2])


def get_weatherdata(key, city, wtype="weather"):
    # get weatherdata: forecast = 5 days / 3hrs, weather = curr
    try:
        data = requests.get(
            "http://api.openweathermap.org/data/2.5/" + wtype + "?id=" +
            city.strip() + "&APPID=" + key
        )
        if data.status_code == requests.codes.ok:
            return dict(json.loads(data.text))
    except Exception:
        pass


def get_citymatches(cityname):
    # given a name of a city, return the matches
    matches = []
    try:
        test = open(citylist)
        for l in test:
            if cityname in l:
                matches.append(l)
        return [matches, True]
    except FileNotFoundError:
        try:
            return get_textfile(cityname)
        except Exception:
            return [[], False]


def get_textfile(cityname):
    # secondary to get_citymatches()
    # fetches the citylist remotely if not locally present
    matches = []
    url = "http://openweathermap.org/help/city_list.txt"
    data = requests.get(url)
    if data.status_code == requests.codes.ok:
        open(citylist, "wt").write(data.text)
        return get_citymatches(cityname)


def get_font():
    fontkey = "org.gnome.desktop.wm.preferences"
    settings = Gio.Settings.new(fontkey)
    fontdata = settings.get_string("titlebar-font")
    fdscr = Pango.FontDescription(fontdata)
    return Pango.FontDescription.get_family(fdscr)
