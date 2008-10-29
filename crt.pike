#!/usr/bin/env pike

int main(int argc, array(string) argv)
{
  int modulo = (int) argv[1];
  int remainder = (int) argv[2];
  for (int k = 3; k + 1 < argc; k += 2) {
    remainder = crt(modulo, (int) argv[k], remainder, (int) argv[k + 1]);
    modulo *= (int) argv[k];
  }

  write("x %% %d = %d\n", modulo, remainder);
  return 0;
}

int crt(int m, int n, int a, int b)
{
  [Gmp.mpz u, Gmp.mpz v] = Gmp.mpz(m)->gcdext(n)[1..];
  return (int) Gmp.bignum((u * m * b + v * n * a) % (m * n));
}
