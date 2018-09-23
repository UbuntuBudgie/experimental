# WeatherShowII
This will replace the python version.

# Install
- The color window (target-dir = /usr/lib/budgie-desktop/plugins/budgie-weathershow: 
`valac --pkg gtk+-3.0 --pkg glib-2.0 -X -lm <get_color.vala>`
- The desktop window (target-dir = /usr/lib/budgie-desktop/plugins/budgie-weathershow:
`valac --pkg gtk+-3.0 --pkg gee-0.8 --pkg glib-2.0 -X -lm <desktop_weather.vala>`

- The applet:
- `mkdir build && cd build`
- `meson --buildtype plain --prefix=/usr --libdir=/usr/lib`
- `ninja`
- `sudo ninja install`

