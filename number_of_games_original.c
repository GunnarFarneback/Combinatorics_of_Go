#include <stdio.h>

#define NUMBER_OF_STATES 5
#define NUMBER_OF_VERTICES 2

int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_VERTICES] = {
{ 4,  3,  2,  1}, /*  0: .. */
{ 4,  0, -1, -1}, /*  1: O. */
{ 3,  0, -1, -1}, /*  2: X. */
{ 2,  0, -1, -1}, /*  3: .O */
{ 1,  0, -1, -1}}; /*  4: .X */

void play_games(int state, int *visited_states, unsigned long long *n)
{
  int k;
  visited_states[state] = 1;
  (*n)++;
  for (k = 0; k < 2 * NUMBER_OF_VERTICES; k++) {
    int next_state = transformations[state][k];
    if (next_state >= 0
	&& !visited_states[next_state])
      play_games(next_state, visited_states, n);
  }
  visited_states[state] = 0;
}

int main(int argc, char **argv)
{
  unsigned long long n = 0;
  int visited_states[NUMBER_OF_STATES];
  int k;

  for (k = 0; k < NUMBER_OF_STATES; k++)
    visited_states[k] = 0;

  play_games(0, visited_states, &n);
  
  printf("Number of games: %Lu\n", n);
  return 0;
}
