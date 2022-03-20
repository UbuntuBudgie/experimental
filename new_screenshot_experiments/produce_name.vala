


private string get_scrshotname() {
    DateTime now = new DateTime.now_local();
    return now.format("Snapshot_%F_%H-%M-%S.png");
}


public static int main(string[] args) {
    string fname = get_scrshotname();
    print(@"$fname\n");
    return 0;
}