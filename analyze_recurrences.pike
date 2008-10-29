#!/usr/bin/env pike

string print_mpq(Gmp.mpq q, int n)
{
    int d = q->get_int();
    Gmp.mpq r = q - d;
    Gmp.mpq scaled_remainder = r * pow(10, n);
    int decimals = scaled_remainder->get_int();
    if (scaled_remainder - decimals >= Gmp.mpq(1, 2))
	decimals++;
    return sprintf("%d.%*0d", d, n, decimals);
}

string print_mpf(Gmp.mpf x, int n)
{
    int d = x->get_int();
    Gmp.mpf r = x - Gmp.mpz(d);
    Gmp.mpf scaled_remainder = r * Gmp.mpz(pow(10, n));
    int decimals = scaled_remainder->get_int();
    if (scaled_remainder - Gmp.mpz(decimals) >= Gmp.mpf(0.5))
	decimals++;
    return sprintf("%d.%*0d", d, n, decimals);
}

Gmp.mpf mpf_pow(Gmp.mpf x, int n)
{
    if (n == 0)
	return Gmp.mpf(1);
    
    return Array.reduce(`*, ({x}) * n);
}

int main(int argc, array(string) argv)
{
    int height;
    if (argc < 2)
	height = 1;
    else
	height = (int) argv[1];

    mapping(int:int) L = ([]);
    
    foreach ((Stdio.read_file("L" + height) / "\n")[1..], string row)
    {
	int n, l;
	if (sscanf(row, "%d %d", n, l) == 2)
	L[n] = l;
    }

    int N = sizeof(L);
//    N = 40;
    int num_digits = sizeof(sprintf("%d",(Gmp.mpq(Gmp.mpz(L[N])) / Gmp.mpz(L[N-1]) - Gmp.mpq(Gmp.mpz(L[N-1])) / Gmp.mpz(L[N-2]))->invert()->get_int())) - 1;
    
    for (int k = 2; k <= N; k++)
    {
	write("%s\n", print_mpq(Gmp.mpq(Gmp.mpz(L[k])) / Gmp.mpz(L[k-1]),
				num_digits));
    }

    mapping(int:Gmp.mpf) L2 = ([]);
    for (int k = 1; k <= N; k++)
	L2[k] = Gmp.mpf(1)->set_precision(2048) * Gmp.mpz(L[k]);

    for (int k = 2; k <= N; k++)
    {
	write("%s\n", print_mpf(L2[k] / L2[k-1], num_digits));
    }

    Gmp.mpf lambda_m = L2[N] / L2[N-1];
    
    for (int k = 1; k <= N; k++)
    {
	write("%d %s\n", k, print_mpf(L2[k] / mpf_pow(lambda_m, k), num_digits));
    }

    Gmp.mpf a_m = L2[N] / mpf_pow(lambda_m, N);

    for (int k = 1; k <= N; k++)
    {
	write("%d %s\n", k, (L2[k] / (a_m * mpf_pow(lambda_m, k)) - 1)->set_precision(64)->get_string());
    }
    
    return 0;
}
