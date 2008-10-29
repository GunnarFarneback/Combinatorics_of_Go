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

void analyze(int height)
{
    mapping(int:Gmp.mpf) L = ([]);
    Gmp.mpf mpf1 = Gmp.mpf(1, 2048);
    
    foreach ((Stdio.read_file("L" + height) / "\n")[1..], string row)
    {
	int n;
	string l;
	if (sscanf(row, "%d %s", n, l) == 2)
	    L[n] = Gmp.mpf(l, 2048);
    }

    int N = sizeof(L);
    
    int num_digits = sizeof(sprintf("%d", (mpf1 / (L[N] / L[N-1] - L[N-1] / L[N-2]))->get_int())) - 3;

    Gmp.mpf lambda_m = L[N] / L[N-1];
    
    Stdio.append_file("lambda_m",
		      sprintf("%d %s\n", height,
			      print_mpf(lambda_m, num_digits)));

    Gmp.mpf a_m = L[N] / mpf_pow(lambda_m, N);

    Stdio.append_file("a_m",
		      sprintf("%d %s\n", height, print_mpf(a_m, num_digits)));

    string u_mn = "";
    for (int k = 1; k <= N - 5; k++)
    {
	u_mn += sprintf("%d %s\n", k, (L[k] / (a_m * mpf_pow(lambda_m, k)) - 1)->set_precision(64)->get_string());
    }
    Stdio.write_file(sprintf("u%d", height), u_mn);
}

int main(int argc, array(string) argv)
{
    int height;
    foreach (argv[1..], string arg)
	analyze((int) arg);
    
    return 0;
}
