# HotCornersII

Just a test to move functions around.

HCII reads commands from the file `~/.config/budgie-extras/hotcorners/hotc_commands`, which should be a four-line file, one command per line. If the file does not exist, HCII falls back to defaults (all none atm).

## compiling

hotcorners:
`valac --pkg gio-2.0 --pkg gee-0.8 --pkg gdk-3.0 --pkg gtk+-3.0 -X -lm shared.vapi get_hot_class_withpressure.vala -X shared.so -X -I. -o get_hot_class_withpressure`

library:
`valac --pkg gee-0.8 --pkg gio-2.0 --library=shared -H shared.h shared.vala -X -fPIC -X -shared -o shared.so`

After compiling, beforefor testing run: `export LD_LIBRARY_PATH=.`

Eventually, the library will be compiled into hotcorners, but drowning in arguments atm.
