#include <stdio.h>
#include "states.h"
#include "random.h"

#define N 10

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
  Word_t states[N];
  Word_t out_states[3 * N];
  int num_outstates;
  int k;
  int x, y;
  double p = 1.0;
  int num_legal_final_states;

  gg_srand(4);
  
  for (k = 0; k < N; k++)
    states[k] = STARTSTATE;
  
  for (y = 0; y < 5; y++)
    for (x = 0; x < 5; x++) {
      printf("%d %d\n", x, y);
      Word_t expanded_states[3];
      num_outstates = 0;
      
      for (k = 0; k < N; k++) {
	int num_expanded_states = expandstate(states[k], x, expanded_states);
	int m;
	for (m = 0; m < num_expanded_states; m++)
	  out_states[num_outstates++] = expanded_states[m];
      }
      
      p *= (double) num_outstates / (3 * N);

      for (k = 0; k < N; k++)
	states[k] = out_states[random_choice(num_outstates)];
    }
      
  num_legal_final_states = 0;
  for (k = 0; k < num_outstates; k++)
    num_legal_final_states += finalstate(states[k]);

  p *= (double) num_legal_final_states / num_outstates;

  printf("Estimated legal probability: %lf\n", p);
  
  return 0;
}
