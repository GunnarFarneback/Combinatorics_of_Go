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
 * 20x20      308          61233502
 * 21x21      340         147830751
 * 22x22      373         356895004
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>

struct entry {
  uint64_t state:54;
  uint64_t max_strings:10;
};

int positive_ordering(const void *A, const void *B)
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
      
int negative_ordering(const void *A, const void *B)
{
  const struct entry *a = A;
  const struct entry *b = B;

  if (a->state > b->state)
    return 1;
  if (a->state < b->state)
    return -1;

  if (a->max_strings > b->max_strings)
    return 1;
  if (a->max_strings < b->max_strings)
    return -1;

  return 0;
}
      

int main(int argc, char **argv)
{
  long k;
  struct entry *table;

  if (argc < 3) {
    fprintf(stderr, "Usage: %s height width\n", argv[0]);
    return EXIT_FAILURE;
  }

  int M = atoi(argv[1]);
  int N = atoi(argv[2]);

  long a = 3;
  long b = 8;
  for (k = 2; k < M; k++) {
    int c = 2 * b + a;
    a = b;
    b = c;
  }
  long max_states = b;

  long max_entries = 2 * max_states + max_states / 10 + 10;
  long table_size = max_entries * sizeof(table[0]);
  printf("max_states: %ld, max_entries: %ld, table size: %ld\n", max_states, max_entries, table_size);
  table = malloc(table_size);
  if (!table) {
    fprintf(stderr, "Failed to allocate %ld bytes for the table.\n",
	    table_size);
    return EXIT_FAILURE;
  }

  long old_num_entries = 1;
  table[0].state = 0;
  table[0].max_strings = 0;
  int direction = -1;
  for (int n = 0; n < N; n++) {
    for (int m = 1; m <= M; m++) {
      long new_num_entries = 0;
      uint64_t previous_state = ~0;

      struct entry *old_pointer;
      struct entry *new_pointer;
      int increment;
      if (direction == -1) {
	old_pointer = table + old_num_entries - 1;
	new_pointer = table + max_entries - 1;
	increment = -1;
      }
      else {
	old_pointer = table + max_entries - old_num_entries;
	new_pointer = table;
	increment = 1;
      }
      
      long num_states = 0;
      uint64_t mask = UINT64_C(3) << (2 * m);
      uint64_t liberty_bit = UINT64_C(1) << (2 * m);
      uint64_t stone_bit = UINT64_C(2) << (2 * m);
      for (k = 0; k < old_num_entries; k++, old_pointer += increment) {
	uint64_t state = old_pointer->state;
	if (state == previous_state)
	  continue;

	previous_state = state;
	num_states++;
	
	int max_strings = old_pointer->max_strings;

#if 0
	printf("%lx %d %ld %ld\n", (unsigned long) state, max_strings,
	       old_pointer - table, new_pointer - table);
#endif
	assert(labs(new_pointer - old_pointer) > 4);
	
	uint64_t new_state = state;
	new_state &= ~mask;
	new_state |= liberty_bit;
	if (new_state & (stone_bit >> 2))
	  new_state |= (liberty_bit >> 2);
	assert(new_num_entries < max_entries);
	new_pointer->state = new_state;
	new_pointer->max_strings = max_strings;
	new_num_entries++;
	new_pointer += increment;
  
	new_state = state;
	if ((new_state & mask) == stone_bit)
	  continue;
	int has_liberty = (((new_state & mask) == liberty_bit)
			   || ((new_state & (mask >> 2)) == (liberty_bit >> 2)));
	new_state &= ~mask;
	new_state |= stone_bit;
	if (has_liberty)
	  new_state |= liberty_bit;
	assert(new_num_entries < max_entries);
	new_pointer->state = new_state;
	new_pointer->max_strings = max_strings + 1;
	new_num_entries++;
	new_pointer += increment;
      }

      printf("num_states: %ld (%d %d)\n", num_states, m, n);
      if (direction == -1)
	qsort(table + max_entries - new_num_entries, new_num_entries,
	      sizeof(table[0]), positive_ordering);
      else
	qsort(table, new_num_entries, sizeof(table[0]), negative_ordering);
      
      old_num_entries = new_num_entries;
      direction = -direction;
    }
  }

  uint64_t libs = 0;
  for (k = 0; k < M; k++) {
    libs |= 1;
    libs <<= 2;
  }

  int max_number_of_strings = 0;
  struct entry *p;
  if (direction == -1)
    p = table;
  else
    p = table + max_entries - old_num_entries;
  for (long k = 0; k < old_num_entries; k++, p++) {
    if ((p->state & libs) == libs)
      if (p->max_strings > max_number_of_strings)
	max_number_of_strings =p->max_strings;
  }

  printf("%dx%d: %d\n", M, N, max_number_of_strings);
  
  return EXIT_SUCCESS;
}
