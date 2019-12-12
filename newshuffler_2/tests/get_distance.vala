public static void main(string[] args) {
    get_distance(
        double.parse(args[1]),
        double.parse(args[2]),
        double.parse(args[3]),
        double.parse(args[4])
    );
}

private void get_distance (double x1, double y1, double x2, double y2) {
    double x_comp = Math.pow(x1 - x2, 2);
    double y_comp = Math.pow(y1 - y2, 2);
    double radius = Math.pow(x_comp + y_comp, 0.5);
    print(@"$x_comp $y_comp $radius\n");
}