public static int main(string[] args) {
    int yshift = 0;
    string winsubj = args[1];
    string cmd = "xprop -id ".concat(winsubj, " _NET_FRAME_EXTENTS");
    string output = "";
    try {
        GLib.Process.spawn_command_line_sync(cmd, out output);
    }
    catch (SpawnError e) {
        // nothing to do
    }
    if (output.contains("=")) {
        yshift = int.parse(output.split(", ")[2]);
    }
    print(@"$yshift\n");
    return yshift;
}