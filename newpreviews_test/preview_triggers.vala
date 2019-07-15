
namespace previews_triggers {

    /*
    possible args:
    - "current" (show only current apps)
    - "previous" (go one tile reverse)

    this executable first creates a trigger file -allappstrigger- if no arg is
    set, or -triggercurrent- if the arg "current" is set. this file will
    trigger the previews daemon to show previews of all apps or only current

    if the previews window exists however (and either one of the above
    triggers), this executabel creates an additional -nexttrigger- if not
    "previous" is set as arg, or -previoustrigger- if "previous" is set as arg
     */


    public static void main (string[] args) {

        // user
        string user = Environment.get_user_name();
        // files
        File allappstrigger = File.new_for_path(
            "/tmp/".concat(user, "_prvtrigger_all")
        );
        File nexttrigger = File.new_for_path(
            "/tmp/".concat(user, "_nexttrigger")
        );
        File previoustrigger = File.new_for_path(
            "/tmp/".concat(user, "_previoustrigger")
        );
        File triggercurrent = File.new_for_path(
            "/tmp/".concat(user, "_prvtrigger_current")
        );

        File trg = nexttrigger;
        if (allappstrigger.query_exists() || triggercurrent.query_exists()) {
            trg = nexttrigger;
            if (check_args (args, "previous")) {
                trg = previoustrigger;
            }
        }
        else {
            trg = allappstrigger;
            if (check_args(args, "current")) {
                trg = triggercurrent;
            }
        }
        create_trigger(trg);
    }

    private bool check_args (string[] args, string arg) {
        foreach (string s in args) {
            if (s == arg) {
                return true;
            }
        }
        return false;
    }

    private void create_trigger (File trigger) {
        FileOutputStream createtrigger = trigger.create (
            FileCreateFlags.PRIVATE
        );
        createtrigger.write("".data);
    }
}