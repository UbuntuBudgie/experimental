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

public static void main (string[] args) {
    string[] arr = {"a", "b", "c"};
    string arg = args[1];
    arr = remove_arritem(arg, arr);

    foreach (string s in arr) {
        print(@"$s\n");
    }

}

private string[] remove_arritem (string s, string[] arr) {
    string[] newarr = {};
    foreach (string item in arr) {
        if (item != s) {
            newarr += item;
        }
    }
    return newarr;
}