

namespace manage_triggers {


    public static void main(string[] args) {
        string user = Environment.get_user_name();
        // files
        File maintrigger = File.new_for_path(
            "/tmp/".concat(user, "_prvtrigger")
        );
        File nexttrigger = File.new_for_path(
            "/tmp/".concat(user, "_nexttrigger")
        );
        File previoustrigger = File.new_for_path(
            "/tmp/".concat(user, "_previoustrigger")
        );

        if (!maintrigger.query_exists()) {
            /*FileOutputStream createmain = maintrigger.create (
                FileCreateFlags.PRIVATE
            );
            createmain.write("".data);
            */
            print("main\n");
            create_trigger(maintrigger);
        }
        else {
            if (args[1] == "next") {
                create_trigger(nexttrigger);
            }
            else if (args[1] == "previous") {
                create_trigger(previoustrigger);
            }
        }
            // make previews window remove trigger on action
    }


    private void create_trigger (File trigger) {
        FileOutputStream createtrigger = trigger.create (
            FileCreateFlags.PRIVATE
        );
        createtrigger.write("".data);

    }
}