# Raven Widget Template Plugin

Barebones Raven Widget Template with Settings

Dependencies

* gtk+-3.0

For Budgie Desktop 10.9.3 and earlier (Raven plugins introduced in 10.7)

* budgie-raven-plugin-1.0
* libpeas-1.0

For Budgie Destkop 10.9.4 (and later 10.9.x versions)

* budgie-raven-plugin-2.0
* libpeas-2

For 10.10 (Wayland)

* budgie-raven-plugin-3.0
* libpeas-2

To specify the version to build for, use ```-Dbudgie-version``` option:
```
 -Dbudgie-version=1.0  (for 10.9.3 and ealier)
 -Dbudgie-version=2.0  (for 10.9.4)
 -Dbudgie-version=3.0  (for 10.10 and later)
```

To set up your build environment on Debian/Ubuntu:
```
sudo apt update
sudo apt install meson valac budgie-core-dev
```

To build and install for Budgie Deskop on Ubuntu Budgie 23.04 - 25.10 (Budgie Desktop 10.7 - 10.9.3):
```
mkdir build && cd build
meson setup --prefix=/usr --libdir=/usr/lib -Dbudgie-version=1.0
ninja
sudo ninja install
```

To build and install on Ubuntu 26.04 and later (Budgie Desktop 10.10 Wayland), omit --libdir. E.g.

```
mkdir build && cd build
meson setup --prefix=/usr -Dbudgie-version=3.0
ninja
sudo ninja install
```

For other distros, omit --libdir or specify the correct path

Logout / Login to allow an installed schema to be recognized. If you try to add the Raven widget before doing so, you will see a message stating a schema needs to be installed.

Notes:
- Raven Widgets require the plugin module name to be in reverse DNS format.
- If the widget supports settings, a schema must be installed, and the schema ID must match the name of the plugin module.
- After installing, logging out / in will be required for Budgie Desktop to recognize the schema.
