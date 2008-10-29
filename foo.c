struct queue_item
{
  int node;
  int parent_stratum;
  long double weight;
};

struct queue_item Q[NUMBER_OF_STATES];
long double sum_weights[NUMBER_OF_STATES];

int compute_stratum(int node, int visited_nodes[NUMBER_OF_STATES])
{
  static long marks[NUMBER_OF_STATES];
  static long mark = 0;
  int stack[NUMBER_OF_STATES];
  int stackp = 0;
  int size = -1;

  mark++;
  
  stack[stackp++] = node;
  while (stackp > 0) {
    int state = stack[--stackp];
    int s;
    size++;
    marks[state] = mark;
    for (s = 0; s < 2 * NUMBER_OF_POINTS; s++) {
      int next_state = transformations[state][s];
      if (next_state >= 0
	  && !visited_states[next_state]
	  && marks[next_state] != mark) {
	stack[stackp++] = next_state;
      }
    }
  }
}

int main(int argc, char **argv)
{
  int visited_states[NUMBER_OF_STATES];
  int k;
  int j;
  const int N = 100;
  long double size;

  gg_srand(6);

  for (k = 0; k < NUMBER_OF_STATES; k++) {
    visited_states[k] = 0;
    sum_weights[k] = 0.0;
  }
  
  for (i = 0; i < N; i++) {
    for (k = 0; k < NUMBER_OF_STATES; k++)
      Q[k].node = -1;

    Q[NUMBER_OF_STATES - 1].node = 0;
    Q[NUMBER_OF_STATES - 1].parent_stratum = -1;
    Q[NUMBER_OF_STATES - 1].weight = 1.0;
  
    for (k = NUMBER_OF_STATES - 1; k >= 0; k++) {
      int r;
      int state = Q[k].node;
      if (state == -1)
	continue;

      sum_weights[k] += Q[k].weight;
      
      for (r = k; r > 0; r = Q[r].parent_stratum) {
	visited_states[Q[r].node] = 1;
      }
      
      for (s = 0; s < 2 * NUMBER_OF_POINTS; s++) {
	int next_state = transformations[state][s];
	if (next_state >= 0
	    && !visited_states[next_state]) {
	  int next_stratum = compute_stratum(next_state, visited_states);
	  if (Q[next_stratum].node == -1) {
	    Q[next_stratum].node = next_state;
	    Q[next_stratum].parent_stratum = k;
	    Q[next_stratum].weight = Q[k].weight;
	  }
	  else {
	    Q[next_stratum].weight += Q[k].weight;
	    if (gg_drand() * Q[next_stratum] < Q[k].weight) {
	      Q[next_stratum].node = next_state;
	      Q[next_stratum].parent_stratum = k;
	    }
	  }
	}
      }
      
      for (r = k; r > 0; r = Q[r].parent_stratum) {
	visited_states[Q[r].node] = 0;
      }
    }
  }

  size = 0.0;
  for (k = NUMBER_OF_STATES - 1; k >= 0; k++) {
    size += Q[k].weight;
    printf("%d %Lg %Lg\n", k, Q[k].weight / N, size / N);
  }

  printf("Estimated size: %Lg\n%Lf\n", size / N, size / N);

  return 0;
}
