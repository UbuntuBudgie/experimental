# WindowShuffler

## Description
WindowShuffler is a window placement add-on. Click a window and subsequently click a tile in the grid, the window moves to the corresponding position on the screen. Shift-click two tiles will make the window span the two. Shift-click does not need to be on two tiles next to each other; cross- selection and spanning multiple tiles is possible.

## Set up
- Make sure all of the below dependencies are installed:
 wmctrl
 xdotool
 python3-gi-cairo
 python3-cairo
- Copy all three icons to /usr/share/pixmaps
- Run the wrapper `matrix_wrapper` from either a shortcut or a hotcorner. Running the wrapper again toggles the grid.

## Limitations
- This test version runs on a single monitor setup.
- Some windows have a fixed size, they cannot be resized.
- Some windows have a minimum size, they cannot be resized below their minimum size.

