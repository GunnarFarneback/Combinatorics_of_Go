#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

typedef unsigned int uint128_t __attribute__((__mode__(TI)));
typedef int int128_t __attribute__((__mode__(TI)));

static unsigned long
modular_add(unsigned long modulus, unsigned long a, unsigned long b)
{
  return ((uint128_t) a + (uint128_t) b) % modulus;
}

static unsigned long
modular_sub(unsigned long modulus, unsigned long a, unsigned long b)
{
  return (((uint128_t) a + (uint128_t) modulus) - (uint128_t) b) % modulus;
}

static unsigned long
modular_mult(unsigned long modulus, unsigned long a, unsigned long b)
{
  return ((uint128_t) a * (uint128_t) b) % modulus;
}

static void
extended_euclid(unsigned long a, unsigned long b, int128_t *c, int128_t *d)
{
  int128_t e;
  int128_t f;
  
  if (b == 0) {
    *c = 1;
    *d = 0;
    return;
  }
  
  extended_euclid(b, a % b, &e, &f);
  *c = f;
  *d = e - f * (a / b);
}

static unsigned long
modular_div(unsigned long modulus, unsigned long a, unsigned long b)
{
  int128_t inverse;
  int128_t dummy;
  extended_euclid(modulus, b, &dummy, &inverse);
  inverse += modulus;
  inverse %= modulus;
  return modular_mult(modulus, a, (unsigned long) inverse);
}

int
main(int argc, char **argv)
{
  unsigned long *v;
  unsigned long *lambda;
  unsigned long *B;
  FILE *f;
  unsigned long modulus;
  int max_order;
  int n;
  long value;
  int L;
  unsigned long delta;
  int r;
  int k;
  
  if (argc < 4) {
    fprintf(stderr, "USAGE: %s modulus max_order filename\n", argv[0]);
    return 1;
  }

  modulus = atol(argv[1]);
  max_order = atoi(argv[2]);
  v = malloc(2 * max_order * sizeof(v[0]));
  f = fopen(argv[3], "r");
  fscanf(f, "%*s %*s\n");
  while (fscanf(f, "%d %lu\n", &n, &value) != EOF) {
    if (n > 2 * max_order) {
      /* Ignore extra items silently. */
      continue;
    }
    else if (n > 0)
      v[n - 1] = value;
    else
      break;
  }
  fclose(f);
  if (n < 2 * max_order)
    fprintf(stderr, "Too few entries in file for this maximum order.\n");

  lambda = malloc((max_order + 1) * sizeof(lambda[0]));
  B = malloc((max_order + 1) * sizeof(B[0]));
  for (k = 0; k < max_order; k++) {
    lambda[k] = 0;
    B[k] = 0;
  }
  lambda[max_order] = 1;
  B[max_order] = 1;

  L = 0;
  for (r = 0; r < 2 * max_order; r++) {
    delta = 0;
    if (r <= max_order) {
      for (k = 0; k <= r; k++)
	delta = modular_add(modulus, delta,
			    modular_mult(modulus, lambda[max_order - r + k],
					 v[k]));
    }
    else {
      for (k = 0; k <= max_order; k++)
	delta = modular_add(modulus, delta,
			    modular_mult(modulus, lambda[k],
					 v[r - max_order + k]));
    }

    if (delta != 0 && 2*L <= r)	{
      L = r + 1 - L;
      for (k = 0; k < max_order; k++) {
	B[k] = modular_div(modulus, lambda[k], delta);
	lambda[k] = modular_sub(modulus, lambda[k],
				modular_mult(modulus, delta, B[k+1]));
      }
      B[max_order] = modular_div(modulus, lambda[max_order], delta);
    }
    else {
      for (k = 0; k < max_order; k++) {
	B[k] = B[k+1];
	lambda[k] = modular_sub(modulus, lambda[k],
				modular_mult(modulus, delta, B[k+1]));
      }
      B[max_order] = 0;
    }
  }

  int order = 0;
  for (k = 0; k < max_order; k++)
    if (order > 0 || lambda[k] != 0)
      order++;
  
  printf("Order: %d\n", order);

  free(B);
  free(lambda);
  free(v);
  
  return 0;
}
