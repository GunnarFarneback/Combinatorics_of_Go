#!/usr/bin/env pike

int debug = 0;

int width = 0;
int total_modulo = 0;
mapping(int:int) total_remainders = ([]);

int main(int argc, array(string) argv)
{
  foreach (argv[1..], string filename) {
    write("Processing %s\n", filename);
    process_file(Stdio.read_file(filename));
  }
  return 0;
}

void process_file(string file)
{
  array(string) rows = file / "\n";
  int a, b, mod, legal, c, d;
  int current_modulo = 0;
  mapping(int:int) current_remainders = ([]);
  for (int k = 0; k < sizeof(rows); k++) {
    sscanf(rows[k], "(%d,%d) %*s mod %d", a, b, mod);
    if (sscanf(rows[k], "newillegal %*s legal %d at (%d,%d)", legal, c, d) == 4
	&& d == 0) {
      if (width == 0)
	width = b + 1;
      else if (width != b + 1) {
	werror("Inconsistent board widths.\n");
	exit(1);
      }
      if (current_modulo == 0)
	current_modulo = mod;
      else if (current_modulo != mod) {
	werror("Inconsistent modulo within the same file.\n");
	exit(1);
      }
      if (debug)
	write("%dx%d %d %d\n", width, c, mod, legal);
      current_remainders[c] += legal;
      current_remainders[c] %= current_modulo;
    }
  }
  
  foreach (sort(indices(current_remainders)), int h) {
    if (debug)
      write("%dx%d %d %d\n", width, h, current_modulo, current_remainders[h]);
    if (!total_remainders[h])
      total_remainders[h] = current_remainders[h];
    else {
      int r = total_remainders[h];
      if (Gmp.mpz(total_modulo)->gcd(current_modulo) != 1) {
	werror("Non-coprime moduli detected. Same modulo repeated?\n");
	exit(1);
      }
      total_remainders[h] = crt(total_modulo, current_modulo,
		       total_remainders[h], current_remainders[h]);
    }
  }
  if (total_modulo == 0)
    total_modulo = current_modulo;
  else
    total_modulo *= current_modulo;

  float L = 2.9757341920433572493;
  float B = 0.965535059338374;
  float A = 0.8506399258457;
  write("Modulo %d:\n", total_modulo);
  foreach (sort(indices(total_remainders)), int h) {
    string comment = "";
    if (width > 5 && h < 10 * width) {
      float approximate_result = pow(L, width * h) * pow(B, width + h) * A;
      if (approximate_result > 1.01 * (float) total_modulo)
	comment = " (more moduli needed)";
      else if (approximate_result > 0.9 * (float) total_modulo)
	comment = " (more moduli possibly needed)";
    }
    write("%dx%d %d%s\n", width, h, total_remainders[h], comment);
  }
}

int crt(int m, int n, int a, int b)
{
  [Gmp.mpz u, Gmp.mpz v] = Gmp.mpz(m)->gcdext(n)[1..];
  return (int) Gmp.bignum((u * m * b + v * n * a) % (m * n));
}
