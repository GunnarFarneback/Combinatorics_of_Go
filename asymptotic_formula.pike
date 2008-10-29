#!/usr/bin/env pike

Gmp.mpf mpf_pow(Gmp.mpf x, int n)
{
    if (n == 0)
	return Gmp.mpf(1);
    
    return Array.reduce(`*, ({x}) * n);
}

int main(int argc, array(string) argv)
{
  if (argc < 3) {
    werror("Usage: %s <height> <width>", argv[0]);
    return 1;
  }

  int m = (int) argv[1];
  int n = (int) argv[2];

  Gmp.mpf A = Gmp.mpf("0.850639925845833", 2048);
  Gmp.mpf B = Gmp.mpf("0.96553505933836965", 2048);
  Gmp.mpf L = Gmp.mpf("2.97573419204335725", 2048);

  Gmp.mpf result = A * mpf_pow(B, m + n) * mpf_pow(L, m * n);
  write("%s\n", result->get_string());
  write("lambda_%d = %s\n", m, (B * mpf_pow(L, m))->get_string());
}