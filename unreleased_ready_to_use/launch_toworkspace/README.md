# Launch to Workspace
Background process to redirect new windows of defined wm_class types to specific workspaces.

## Set up
- The Vala snippet needs to be compiled. To do so you need to install a few things: `sudo apt install valac libwnck-3-dev libgtk-3-dev`
- Copy or or download `launch_toworkspace.vala`
- Compile the file with the command: `valac --pkg gtk+-3.0 --pkg gio-2.0 --pkg libwnck-3.0 -X "-D WNCK_I_KNOW_THIS_IS_UNSTABLE" '/path/to/launch_toworkspace.vala'` 
- Run the created executable with the wm_class + targeted workspace as argument, separated by a `*`

An example: `/path/to/launch_toworkspace Gedit*1 Tilix*2` will launch new Gedit windows on workspace 1, Tilix windows on workspace 2 etc.

## Notes
- The first workspace is 0!
- If the targeted workspace does not exist, the window will appear on the current workspace.

