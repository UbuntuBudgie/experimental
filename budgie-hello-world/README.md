Hello World
========

Hello World is a Budgie Desktop applet example of vala.  


Evo Pop                    |  Arc Design
:-------------------------:|:-------------------------:
<img src="https://github.com/UbuntuBudgie/experimental/blob/master/budgie-hello-world/screenshots/screenshot1.gif" width="300"/>  |  <img src="https://github.com/UbuntuBudgie/experimental/blob/master/budgie-hello-world/screenshots/screenshot2.gif" width="300"/>

<br/>

Install
-------
```bash
   # Clone or download the repository
   git clone https://github.com/UbuntuBudgie/experimental.git

   # Go to the budgie-hello-world directory (first)
   cd experimental/budgie-hello-world

   # Configure the the installation
   mkdir build && cd build
   meson --buildtype plain --prefix=/usr --libdir=/usr/lib

   # Install
   sudo ninja install

   # To uninstall
   sudo ninja uninstall

   # Logout and login after installing the applet.
   # You can add App Launcher to your panel from Budgie Desktop Settings.

   # Have fun!
```

<br/>

References
-------
[Ubuntu Budgie](https://ubuntubudgie.org/)<br/>
[solus-project/budgie-desktop](https://github.com/solus-project/budgie-desktop)<br/>
[UbuntuBudgie/budgie-weather-applet](https://github.com/UbuntuBudgie/budgie-weather-applet)<br/>


License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or at your option) any later version.