#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include "states.h"
#include "random.h"

#define MAX_HEIGHT 21

#define MAX_NUMBER_OF_STRATA (2 * MAX_HEIGHT + 1)

struct queue_item
{
  Word_t node;
  long double weight;
};

struct queue_item Q1[MAX_NUMBER_OF_STRATA];
struct queue_item Q2[MAX_NUMBER_OF_STRATA];

int compute_stratum(Word_t s)
{
    int stratum = 0;

    while (s) {
	if ((s & 7) == 1)
	    stratum += 2;
	else if (!(s & 4))
	    stratum++;
	s >>= 3;
    }
    
    assert(stratum < MAX_NUMBER_OF_STRATA);
    return stratum;
}

int main(int argc, char **argv)
{
  int k;
  int j;
  long double size = 0.0;
  long double sum_size = 0.0;
  long double sum_squared_size = 0.0;
  int width;
  int height;
  struct queue_item *Qin = Q1;
  struct queue_item *Qout = Q2;
  struct queue_item *tmp;
  int x, y;
  int num_iterations = 10000;

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
    for (k = 0; k < MAX_NUMBER_OF_STRATA; k++)
      Qin[k].weight = -1.0;

    Qin[0].node = STARTSTATE;
    Qin[0].weight = 1.0;

    for (y = 0; y < width; y++)
      for (x = 0; x < height; x++) {

	for (k = 0; k <= 2 * height + 1; k++)
	  Qout[k].weight = -1.0;
	
	for (k = 0; k <= 2 * height + 1; k++) {
	  Word_t state = Qin[k].node;
	  Word_t expanded_states[3];
	  int num_expanded_states;
	  int m;
      
	  if (Qin[k].weight == -1.0)
	    continue;
      
	  num_expanded_states = expandstate(state, x, expanded_states);
	  for (m = 0; m < num_expanded_states; m++) {
	    Word_t next_state = expanded_states[m];
	    int next_stratum = compute_stratum(next_state);
	    if (Qout[next_stratum].weight == -1.0) {
	      Qout[next_stratum].node = next_state;
	      Qout[next_stratum].weight = Qin[k].weight / 3.0;
	    }
	    else {
	      Qout[next_stratum].weight += Qin[k].weight / 3.0;
	      if (gg_drand() * Qout[next_stratum].weight < Qin[k].weight / 3.0)
		Qout[next_stratum].node = next_state;
	    }
	  }
	}

	tmp = Qin;
	Qin = Qout;
	Qout = tmp;
      }

    size = 0;
    for (k = 0; k <= 2 * height + 1; k++)
      if (Qin[k].weight != -1.0 && finalstate(Qin[k].node))
	size += Qin[k].weight;

    sum_size += size;
    sum_squared_size += size * size;

    if ((j + 1) % 1000 == 0) {
      double std = sqrt(sum_squared_size - sum_size * sum_size / (j + 1)) / j;
      printf("%d %10.8Lg %lg %lg\n", j + 1, sum_size / (j + 1),
	     std, std * sqrt(j));
    }
  }
  
  printf("Estimated legal probability: %10.8Lg\n", sum_size / num_iterations);
  printf("Standard deviation: %lg\n",
	 sqrt(sum_squared_size - sum_size * sum_size / num_iterations) / num_iterations);
  printf("Standard deviation per sample: %lg\n",
	 sqrt((sum_squared_size - sum_size * sum_size / num_iterations) / num_iterations));
  
  return 0;
}
