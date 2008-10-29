#!/usr/bin/env pike

int main(int argc, array(string) argv)
{
    array(int) v = (array(int)) argv[1..];

    int n = sizeof(v) / 2;
    array(Gmp.mpq) Lambda = ({Gmp.mpq(0)}) * n + ({Gmp.mpq(1)});
    array(Gmp.mpq) B = copy_value(Lambda);
    int L = 0;
    Gmp.mpq delta;
    
    for (int r = 0; r < 2 * n; r++)
    {
	if (r <= n)
	    delta = Array.sum(Lambda[n-r..n][*] * v[0..r][*] );
	else
	    delta = Array.sum(Lambda[*] * v[r-n..r][*]);

	if (delta != 0 && 2*L <= r)
	{
	    L = r + 1 - L;
	    array(Gmp.mpq) Lambda0 = copy_value(Lambda);
	    Lambda = Lambda[*] - (delta*(B[1..] + ({Gmp.mpq(0)}))[*])[*];
	    B = Lambda0[*] / delta;
	}
	else
	{
	    B = B[1..] + ({Gmp.mpq(0)});
	    Lambda = Lambda[*] - (delta * B[*])[*];
	}
    }
    write("%O\n", Lambda);
    return 0;
}
