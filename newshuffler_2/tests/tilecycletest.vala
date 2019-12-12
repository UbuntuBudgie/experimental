/*
* ShufflerII
* Author: Jacob Vlijm
* Copyright © 2017-2019 Ubuntu Budgie Developers
* Website=https://ubuntubudgie.org
* This program is free software: you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the Free
* Software Foundation, either version 3 of the License, or any later version.
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details. You should have received a copy of the GNU General Public
* License along with this program.  If not, see
* <https://www.gnu.org/licenses/>.
*/

private string[] remove_arritem (string s, string[] arr) {
    string[] newarr = {};
    foreach (string item in arr) {
        if (item != s) {
            newarr += item;
        }
    }
    return newarr;
}

public static void main(string[] args) {
    // fake windowid_list
    string[] windows = {"a", "b", "c", "d", "e", "f"};
    string[] tiles = {"tile1", "tile2", "tile3", "tile4"};

    int ntiles = 4;
    int i_tile = 0;

    while (windows.length > 0) {
        string currtile = tiles[i_tile];
        string window = windows[0]; // NB index is calculated nearest
        print(@"tile/window: $currtile, $window\n");
        windows = remove_arritem(window, windows);
        i_tile += 1;
        if (i_tile == ntiles) {
            i_tile = 0;
        }
    }
}