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