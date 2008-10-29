#!/usr/bin/env pike

int main(int argc, array(string) argv)
{
    if (argc < 3)
    {
	werror("USAGE: %s modulus filename", argv[0]);
	return 1;
    }

    Gmp.mpz m = Gmp.mpz(argv[1]);
    array(Gmp.mpz) v = ({});
    foreach (Stdio.read_file(argv[2]) / "\n", string row)
    {
	int n;
	int l;
	if (sscanf(row, "%d %d", n, l) == 2)
	    v += ({Gmp.mpz(l)});
    }
    
    int n = sizeof(v) / 2;
    n = 20;
    array(Gmp.mpz) Lambda = ({Gmp.mpz(0)}) * n + ({Gmp.mpz(1)});
    array(Gmp.mpz) B = copy_value(Lambda);
    int L = 0;
    Gmp.mpz delta;
    
    for (int r = 0; r < 2 * n; r++)
    {
	write("%d\n", r);
	for (int k = 0; k <= n; k++)
	    write("%d %d %d\n", k, Lambda[k], B[k]);
	write("\n");
	if (r <= n)
	    delta = Array.sum(Lambda[n-r..n][*] * v[0..r][*]) % m;
	else
	    delta = Array.sum(Lambda[*] * v[r-n..r][*]) % m;

	write("delta = %d\n", delta);
	
	if (delta != 0 && 2*L <= r)
	{
	    L = r + 1 - L;
	    array(Gmp.mpz) Lambda0 = copy_value(Lambda);
	    Lambda = Lambda[*] - (delta*(B[1..] + ({Gmp.mpz(0)}))[*])[*];
	    Lambda = Lambda[*] % m;
	    B = Lambda0[*] * delta->invert(m);
	    B = B[*] % m;
	}
	else
	{
	    B = B[1..] + ({Gmp.mpz(0)});
	    Lambda = Lambda[*] - (delta * B[*])[*];
	    Lambda = Lambda[*] % m;
	}
    }
    write("%O\n", Lambda[*] % m);

    int order = 0;
    foreach (Lambda, Gmp.mpz l)
	if (order > 0 || l != 0)
	    order++;
    order--;

    write("Order: %d\n", order);
    
    return 0;
}
