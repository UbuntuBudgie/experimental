# Setup

- compile `triggermaster.vala `
- compile `alttab_runner.vala`

Create shortcuts
- Alt + Tab -> `triggermaster next`
- Alt + Shift + Tab -> `triggermaster previous`

*Alt_L is needed as modifier, to trigger closing previews

- run the daemon `alttab_runner`

# Still to do
- select only current app or all (currently all).
- select current workspaces or all (currently all)

both are prepared in the code though.

# Possible tweaks/improvements
- n-columns is currently taken from primary monitor, make it more sophisticated?
- rearranging buttons on closing windows from previews could be more sophisticated.
