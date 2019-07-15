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

- run the daemon `alttab_runner`

# Still to fix
- We'll see

# Still to do.
- rewrite backgrounder in Vala (should be a quick one)
- hotcorner integration

# Possible tweaks/improvements
- n-columns is currently taken from primary monitor, make it more sophisticated?
- rearranging buttons on closing windows from previews could be more sophisticated.
