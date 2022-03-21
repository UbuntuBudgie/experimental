using Gtk;

class Win : Gtk.Window {

    public Win() {
        this.show_all();
        foreach(double d in get_theme_fillcolor()) {
            print(@"$d\n");
        }
    }

    private double[] get_theme_fillcolor(){
        Gtk.StyleContext style_ctx = new Gtk.StyleContext();
        Gtk.WidgetPath widget_path =  new Gtk.WidgetPath();
        widget_path.append_type(typeof(Gtk.Button));
        style_ctx.set_path(widget_path);
        Gdk.RGBA fcolor = style_ctx.get_color(Gtk.StateFlags.LINK);
        return {fcolor.red, fcolor.green, fcolor.blue};
    }
}

public static void main(string[] args) {
    Gtk.init(ref args);
    new Win();
    Gtk.main();

}