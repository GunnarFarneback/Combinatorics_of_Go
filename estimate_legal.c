#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "states.h"
#include "random.h"

#define N 10000

static unsigned int random_choice(unsigned int n)
{
  unsigned int k;
  unsigned int r = 0xffffffffU % n;

  do {
    k = gg_urand();
  } while (k < r);

  return k % n;
}

int
main(int argc, char **argv)
{
  static Word_t states[N];
  static Word_t out_states[3 * N];

  int num_outstates = 0;
  int j;
  int k;
  int x, y;
  double sum_p = 0.0;
  double sum_squared_p = 0.0;
  int num_legal_final_states;
  int height;
  int width;
  int num_iterations = 100;

  if (argc < 5) {
    fprintf(stderr, "Usage: estimate_legal_stratified <height> <width> <num_samples> <seed>\n");
    return 1;
  }

  height = atoi(argv[1]);
  width = atoi(argv[2]);
  num_iterations = atoi(argv[3]);
  gg_srand(atoi(argv[4]));
  setwidth(height);

  for (j = 0; j < num_iterations; j++) {
    double p = 1.0;
    
    for (k = 0; k < N; k++)
      states[k] = STARTSTATE;
    
    for (y = 0; y < width; y++)
      for (x = 0; x < height; x++) {
	num_outstates = 0;
	
	for (k = 0; k < N; k++) {
	  Word_t expanded_states[3];
	  int num_expanded_states;
	  int m;
	  num_expanded_states = expandstate(states[k], x, expanded_states);
	  for (m = 0; m < num_expanded_states; m++) {
	    out_states[num_outstates++] = expanded_states[m];
	  }
	}
	
	p *= (double) num_outstates / (3 * N);
	
	for (k = 0; k < N; k++)
	  states[k] = out_states[random_choice(num_outstates)];
      }
    
    num_legal_final_states = 0;
    for (k = 0; k < num_outstates; k++)
      num_legal_final_states += finalstate(out_states[k]);
    
    p *= (double) num_legal_final_states / num_outstates;
    sum_p += p;
    sum_squared_p += p * p;
    if ((j + 1) % 10 == 0) {
      double std = sqrt(sum_squared_p - sum_p * sum_p / (j + 1)) / j;
      printf("%d %10.8lg %lg %lg\n", j + 1, sum_p / (j + 1),
	     std, std * sqrt(j));
    }
  }
      
  printf("Estimated legal probability: %10.8lg\n", sum_p / num_iterations);
  printf("Standard deviation: %lg\n",
	 sqrt(sum_squared_p - sum_p * sum_p / num_iterations) / num_iterations);
  printf("Standard deviation per sample: %lg\n",
	 sqrt((sum_squared_p - sum_p * sum_p / num_iterations) / num_iterations));
  
  return 0;
}
