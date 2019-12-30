
namespace ToggleShufflerGUI {

    private void create_trigger (File trigger) {
        try {
            FileOutputStream createtrigger = trigger.create (
                FileCreateFlags.PRIVATE
            );
            createtrigger.write("".data);
        }
        catch (Error e) {
        }
    }

    public static void main (string[] args) {
        string user = Environment.get_user_name();
        File gridtrigger = File.new_for_path(
            "/tmp/".concat(user, "_gridtrigger")
        );
        bool gridtriggerexists = gridtrigger.query_exists();
        if (!gridtriggerexists) {
             create_trigger(gridtrigger);
            }
        else {
            try {
                gridtrigger.delete();
            }
            catch (Error e) {
            }
        }
    }
}