int main(int argc, array(string) argv)
{
    string s = Stdio.read_file("foo3");
    mapping(int:string) symbols = ([-1 : "    "]);
    mapping(int:array(int)) transformations = ([]);
    foreach (s / "\n" - ({""}), string row) {
	int a,b,c,d,e,f,g,h;
	int n;
	string t;
	sscanf(row, "%d: %d %d %d %d %d %d %d %d %s",
	       n, a, b, c, d, e, f, g, h, t);
	symbols[n] = t;
	transformations[n] = ({a, b, c, d, e, f, g, h});
    }

    array(string) rows = ({});
    foreach (symbols; int n; string t) {
	if (n == -1)
	    continue;
	string row = sprintf("%s: %s\n", t,
			     reverse(sort(symbols[transformations[n][*]])) * " ");
	rows += ({row});
    }

    write(sort(rows) * "");
    return 0;
}
