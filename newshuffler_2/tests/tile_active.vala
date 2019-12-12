// valac --pkg gio-2.0 --pkg gtk+-3.0

namespace TileActive {

    [DBus (name = "org.UbuntuBudgie.ShufflerInfoDaemon")]

    interface ShufflerInfoClient : Object {
        public abstract GLib.HashTable<string, Variant> get_winsdata () throws Error;
        public abstract int getactivewin () throws Error;
        public abstract HashTable<string, Variant> get_tiles (string mon, int cols, int rows) throws Error;
        public abstract void move_window (int wid, int x, int y, int width, int height) throws Error;
        public abstract int get_yshift (int w_id) throws Error;
        public abstract int grid_allwindows (int w_id) throws Error;
    }

    public static void main() {
        
    }

    //  void main (string[] args) {
    //      // check args; incorrect args make the daemon crash (or fix in daemon?)
    //      if (args.length == 5 &&
    //      int.parse(args[1]) < int.parse(args[3]) &&
    //      int.parse(args[2]) < int.parse(args[4])
    //      ) {
    //          grid_window(args);
    //      }
    //      else {
    //          print("incorrect arguments\n");
    //      }
    //  }

    //  void grid_window (string[] args) {
    //      try {
    //          ShufflerInfoClient client = Bus.get_proxy_sync (
    //              BusType.SESSION, "org.UbuntuBudgie.ShufflerInfoDaemon",
    //              ("/org/ubuntubudgie/shufflerinfodaemon")
    //          );

    //          int activewin = client.getactivewin();
    //          // get data, geo on windows
    //          GLib.HashTable<string, Variant> windata = client.get_winsdata();
    //          GLib.List<unowned string> windata_keys = windata.get_keys();
    //          // vars
    //          string name = "";
    //          string isonws = "";
    //          int x = -1;
    //          int y = -1;
    //          int wdth = -1;
    //          int hght = -1;
    //          int yshift = 0;
    //          string winsmonitor = "";
    //          foreach (string s in windata_keys) {
    //              if (int.parse(s) == activewin) {
    //                  yshift = client.get_yshift(activewin);
    //                  Variant var1 = windata[s];
    //                  VariantIter iter = var1.iterator ();
    //                  iter.next("s", &name);
    //                  iter.next("s", &isonws);
    //                  iter.next("s", &winsmonitor);
    //                  iter.next("i", &x);
    //                  iter.next("i", &y);
    //                  iter.next("i", &wdth);
    //                  iter.next("i", &hght);
    //              }
    //          }
    //          // get tiles -> matching tile
    //          HashTable<string, Variant> tiles = client.get_tiles(
    //              winsmonitor, int.parse(args[3]), int.parse(args[4])
    //          );
    //          GLib.List<unowned string> tilekeys = tiles.get_keys();
    //          foreach (string tilename in tilekeys) {
    //              if (args[1].concat("*", args[2]) == tilename) {
    //                  Variant vari = tiles[tilename];
    //                  VariantIter t_iter = vari.iterator();
    //                  int tile_x = 0;
    //                  int tile_y = 0;
    //                  int tile_wdth = 0;
    //                  int tile_hght = 0;
    //                  t_iter.next("i", &tile_x);
    //                  t_iter.next("i", &tile_y);
    //                  t_iter.next("i", &tile_wdth);
    //                  t_iter.next("i", &tile_hght);
    //                  client.move_window(
    //                      activewin, tile_x, tile_y - yshift, tile_wdth, tile_hght
    //                  );
    //              }
    //          }
    //      }

    //      catch (Error e) {
    //              stderr.printf ("%s\n", e.message);
    //      }
    //  }
}