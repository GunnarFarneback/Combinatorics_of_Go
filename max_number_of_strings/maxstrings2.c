/* Results obtained with this code:
 * size    max strings   max states
 * 1x1          0                 1
 * 2x2          2                 4
 * 3x3          6                19
 * 4x4         12                46
 * 5x5         18               111
 * 6x6         26               268
 * 7x7         37               647
 * 8x8         48              1562
 * 9x9         61              3771
 * 10x10       76              9104
 * 11x11       92             21979
 * 12x12      109             53062
 * 13x13      129            128103
 * 14x14      149            309268
 * 15x15      172            746639
 * 16x16      196           1802546
 * 17x17      221           4351731
 * 18x18      248          10506008
 * 19x19      277          25363747
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>

struct entry {
  uint64_t state:54;
  uint64_t max_strings:10;
};

int ordering(const void *A, const void *B)
{
  const struct entry *a = A;
  const struct entry *b = B;

  if (a->state > b->state)
    return -1;
  if (a->state < b->state)
    return 1;

  if (a->max_strings > b->max_strings)
    return -1;
  if (a->max_strings < b->max_strings)
    return 1;

  return 0;
}
      

int main(int argc, char **argv)
{
  int k;
  struct entry *old_table;
  struct entry *new_table;

  printf("foo:%lu\n", sizeof(struct entry));
  
  if (argc < 3) {
    fprintf(stderr, "Usage: %s height width\n", argv[0]);
    return EXIT_FAILURE;
  }

  int M = atoi(argv[1]);
  int N = atoi(argv[2]);

  int a = 3;
  int b = 8;
  for (k = 2; k < M; k++) {
    int c = 2 * b + a;
    a = b;
    b = c;
  }
  int max_entries = b;
  
  int table_size = 2 * max_entries * sizeof(old_table[0]);
  printf("table size: %d\n", table_size);
  old_table = malloc(table_size);
  new_table = malloc(table_size);
  if (!old_table || !new_table) {
    fprintf(stderr, "Failed to allocate %d bytes for the tables.\n",
	    2 * table_size);
    return EXIT_FAILURE;
  }

  int old_num_entries = 1;
  old_table[0].state = 0;
  old_table[0].max_strings = 0;
  for (int n = 0; n < N; n++) {
    for (int m = 1; m <= M; m++) {
      int new_num_entries = 0;
      uint64_t previous_state = ~0;
      int num_states = 0;
      uint64_t mask = UINT64_C(3) << (2 * m);
      uint64_t liberty_bit = UINT64_C(1) << (2 * m);
      uint64_t stone_bit = UINT64_C(2) << (2 * m);
      for (k = 0; k < old_num_entries; k++) {
	uint64_t state = old_table[k].state;
	if (state == previous_state)
	  continue;

	previous_state = state;
	num_states++;
	
	int max_strings = old_table[k].max_strings;

	uint64_t new_state = state;
	new_state &= ~mask;
	new_state |= liberty_bit;
	if (new_state & (stone_bit >> 2))
	  new_state |= (liberty_bit >> 2);
	assert(new_num_entries < 2 * max_entries);
	new_table[new_num_entries].state = new_state;
	new_table[new_num_entries++].max_strings = max_strings;

	new_state = state;
	if ((new_state & mask) == stone_bit)
	  continue;
	int has_liberty = (((new_state & mask) == liberty_bit)
			   || ((new_state & (mask >> 2)) == (liberty_bit >> 2)));
	new_state &= ~mask;
	new_state |= stone_bit;
	if (has_liberty)
	  new_state |= liberty_bit;
	assert(new_num_entries < 2 * max_entries);
	new_table[new_num_entries].state = new_state;
	new_table[new_num_entries++].max_strings = max_strings + 1;
      }

      printf("num_states: %d (%d %d)\n", num_states, m, n);
      qsort(new_table, new_num_entries, sizeof(old_table[0]), ordering);
      struct entry *tmp = new_table;
      new_table = old_table;
      old_table = tmp;
      old_num_entries = new_num_entries;
    }
  }

  uint64_t libs = 0;
  for (k = 0; k < M; k++) {
    libs |= 1;
    libs <<= 2;
  }

  int max_number_of_strings = 0;
  for (int k = 0; k < old_num_entries; k++) {
    if ((old_table[k].state & libs) == libs)
      if (old_table[k].max_strings > max_number_of_strings)
	max_number_of_strings = old_table[k].max_strings;
  }

  printf("%dx%d: %d\n", M, N, max_number_of_strings);
  
  return EXIT_SUCCESS;
}
