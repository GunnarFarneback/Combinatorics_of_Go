#!/usr/bin/env pike

int main(int argc, array(string) argv)
{
//    array(int) v = (array(int)) argv[1..];
    array(Gmp.mpz) v = ({});
    foreach (argv[1..], string arg)
      v += ({Gmp.mpz(arg)});

    Gmp.mpz m = v[0];
    v = v[1..];
    
    int n = sizeof(v) / 2;
    array(Gmp.mpz) Lambda = ({Gmp.mpz(0)}) * n + ({Gmp.mpz(1)});
    array(Gmp.mpz) B = copy_value(Lambda);
    int L = 0;
    Gmp.mpz delta;
    
    for (int r = 0; r < 2 * n; r++)
    {
	if (r <= n)
	    delta = Array.sum(Lambda[n-r..n][*] * v[0..r][*]) % m;
	else
	    delta = Array.sum(Lambda[*] * v[r-n..r][*]) % m;

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
    write("%O\n", Lambda[*]%m);
    return 0;
}
