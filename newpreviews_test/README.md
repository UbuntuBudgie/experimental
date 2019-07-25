# Setup

[Currently running, using the existing previews backgrounder!]

- compile `preview_triggers.vala `
- compile `alttab_runner.vala`
- install the gschema

Create shortcuts
- all applications / browse forward: Alt + Tab -> `preview_triggers`
- all applications / browse backward: Alt + Shift + Tab -> `preview_triggers previous`
- current application / browse forward: Alt + above-Tab -> `preview_triggers current`
- all applications / browse backward: Alt + Shift + above-Tab -> `preview_triggers current previous`

*Alt_L is needed as modifier, to trigger closing previews

# Run from hotcorners
- `preview_triggers`

or 

- `preview_triggers current`

- Press Escape to close

- run the daemon `alttab_runner`

# Still to fix
- Currently, runner has an now unnecessary translation to hex- window id. We still need to make the connection to uint xid. 
- The above unfortunately cannot be done since we first need to fix an error that was caused (?) by a recent (Gtk?) update, breaking the alttab-runner.

# Still to do.
- See above

# Possible tweaks/improvements
- n-columns is currently taken from primary monitor, make it more sophisticated?
