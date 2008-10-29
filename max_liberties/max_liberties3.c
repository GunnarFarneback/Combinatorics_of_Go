/* This differs from max_liberties.c by keeping track of one path
 * leading to each maximum liberty state in each iteration.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <math.h>
#include <string.h>

struct entry {
  uint64_t state:57;
  uint64_t max_liberties_offset:7;
  uint64_t history[5];
};

int positive_ordering(const void *A, const void *B)
{
  const struct entry *a = A;
  const struct entry *b = B;

  if (a->state > b->state)
    return -1;
  if (a->state < b->state)
    return 1;

  if (a->max_liberties_offset > b->max_liberties_offset)
    return -1;
  if (a->max_liberties_offset < b->max_liberties_offset)
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

  if (a->max_liberties_offset > b->max_liberties_offset)
    return 1;
  if (a->max_liberties_offset < b->max_liberties_offset)
    return -1;

  return 0;
}

void
update_history(struct entry *old_pointer, struct entry *new_pointer,
	       int m, int n, int M, int value)
{
  memcpy(new_pointer->history, old_pointer->history,
	 sizeof(old_pointer->history));
  if (value) {
    int position = m + n * M;
    int index = position / 64;
    int bit = position % 64;
    new_pointer->history[index] |= UINT64_C(1) << bit;
  }
}

void
print_board(struct entry *pointer, int M, int N, int liberties)
{
  printf("%d liberties\n", liberties);
  for (int m = 0; m < M; m++) {
    for (int n = 0; n < N; n++) {
      int position = m + n * M;
      int index = position / 64;
      int bit = position % 64;
      if (pointer->history[index] & (UINT64_C(1) << bit))
	printf("X");
      else
	printf(".");
    }
    printf("\n");
  }
  printf("\n");
}


int main(int argc, char **argv)
{
  long k;
  struct entry *table;

  if (argc < 3) {
    fprintf(stderr, "Usage: %s height width\n", argv[0]);
    return EXIT_FAILURE;
  }

  char *game = "..................XXXXXXXXXXXXXXXX.X.............X..X..X.......X..X..X..XXXXXXXXX..X..X..X.......X..X..X..X.......X..X..X..X.XXXXX.X..X........XXX..X..X.XXXXXXXX.X..X..X..........X..X..X.............X..X.XXXXXXXXXXXXX..X................X..............X.X.XXXXXXXXXXXXXXXX..................";
  
  int M = atoi(argv[1]);
  int N = atoi(argv[2]);

  unsigned long max_states_table[19] = {2, 7, 17, 46, 129, 367, 1051, 3022,
					8727, 25316, 73794, 216158, 636246,
					1881523, 5588885, 16700000, 50100000,
					151000000, 457000000};
  long max_states = max_states_table[M - 1];

  long max_entries = 2 * max_states + max_states / 10 + 10;
  long table_size = max_entries * sizeof(table[0]);
  printf("max_states: %ld, max_entries: %ld, table size: %ld\n",
	 max_states, max_entries, table_size);
  table = malloc(table_size);
  if (!table) {
    fprintf(stderr, "Failed to allocate %ld bytes for the table.\n",
	    table_size);
    return EXIT_FAILURE;
  }

  /* Otherwise the history doesn't fit. */
  assert(M * N <= 5 * 64);

  int max_liberties_found_so_far = 0;
  
  int new_max_liberties_base = 0;
  int old_max_liberties_base = 0;

  long old_num_entries = 1;
  table[0].state = 0;
  table[0].max_liberties_offset = 0;
  memset(table[0].history, 0, sizeof(table[0].history));
  
  int direction = -1;
  for (int n = 0; n < N; n++) {
    for (int m = 0; m < M; m++) {
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

      int min_max_liberties = M * N;
      
#define EMPTY            (UINT64_C(2))
#define LIBERTY          (UINT64_C(1))
#define OFF_BOARD        (UINT64_C(0))
#define STONE_BIT        (UINT64_C(4))
#define STRING_START_BIT (UINT64_C(2))
#define STRING_END_BIT   (UINT64_C(1))
#define EMPTY_BIT        (UINT64_C(2))
#define LIBERTY_BIT      (UINT64_C(1))
#define SINGLETON        (STONE_BIT | STRING_START_BIT | STRING_END_BIT)
#define STONE_BITS       (UINT64_C(0x124924924924924))
      
      long num_states = 0;
      uint64_t mask = UINT64_C(7) << (3 * m);
      uint64_t stone_bit = STONE_BIT << (3 * m);
      uint64_t string_start_bit = STRING_START_BIT << (3 * m);
      uint64_t string_end_bit = STRING_END_BIT << (3 * m);
      uint64_t empty_bit = EMPTY_BIT << (3 * m);
      uint64_t liberty_bit = LIBERTY_BIT << (3 * m);
      for (k = 0; k < old_num_entries; k++, old_pointer += increment) {
	uint64_t state = old_pointer->state;
	if (state == previous_state)
	  continue;

	previous_state = state;
	num_states++;
	
	int max_liberties = (old_max_liberties_base
			     + old_pointer->max_liberties_offset);

	/* The state where all points are non-liberties will forever
	 * have max_liberties = 0, since the case where all strings
	 * have been finished are discarded. However, keeping the all
	 * empty state around after the second full column is clearly
	 * not going to yield a maximum number of liberties. In order
	 * to make the base/offset system work we need to throw this
	 * away for any board size with max_liberties larger than 127,
	 * since the offset is only 7 bits.
	 */
	if (n > 1 && max_liberties == 0)
	  continue;
	
#if 0
	if (m == 6 && n == 2)
	  printf("%lo %d\n", (unsigned long) state, max_liberties);
#endif
	
#if 1
	for (k = 0; k < M; k++)
	  printf("%c", "|?._-)(*"[(state >> (3*k))&7]);
	printf(" %d %d %d\n", max_liberties, m, n);
#endif
	assert(labs(new_pointer - old_pointer) > 4);

	uint64_t left = (state >> (3 * m)) & 7;
	uint64_t down = OFF_BOARD;
	if (m > 0)
	  down = (state >> (3 * (m - 1))) & 7;
	
	int left_is_stone = left & STONE_BIT;
	int down_is_stone = down & STONE_BIT;
	int new_liberties = 0;

	/* Current vertex is empty. */
	uint64_t new_state = state;
	int bad_state = 0;
	new_state &= ~mask;
	new_state |= empty_bit;
	if (left_is_stone | down_is_stone) {
	  new_state |= liberty_bit;
	  new_liberties++;
	}
	if (left == SINGLETON) {
	  bad_state = 1;
	  if ((((state & STONE_BITS) - 1) & (state & STONE_BITS)) == 0)
	    if (max_liberties_found_so_far < max_liberties + new_liberties) {
	      max_liberties_found_so_far = max_liberties + new_liberties;
	      print_board(old_pointer, M, N, max_liberties_found_so_far);
	    }
	}
	else if (left == (STONE_BIT | STRING_START_BIT)) {
	  int depth = 0;
	  int i;
	  for (i = m + 1; i < M; i++) {
	    uint64_t current = (state >> (3 * i)) & 7;
	    if (current == (STONE_BIT | STRING_START_BIT))
	      depth++;
	    else if ((current & STONE_BIT) && !(current & STRING_START_BIT)) {
	      if (depth > 0 && (current & STRING_END_BIT))
		depth--;
	      else if (depth == 0) {
		new_state |= STRING_START_BIT << (3 * i);
		break;
	      }
	    }
	  }
	}
	else if (left == (STONE_BIT | STRING_END_BIT)) {
	  int depth = 0;
	  int i;
	  for (i = m - 1; i >= 0; i--) {
	    uint64_t current = (state >> (3 * i)) & 7;
	    if (current == (STONE_BIT | STRING_END_BIT))
	      depth++;
	    else if ((current & STONE_BIT) && !(current & STRING_END_BIT)) {
	      if (depth > 0 && (current & STRING_START_BIT))
		depth--;
	      else if (depth == 0) {
		new_state |= STRING_END_BIT << (3 * i);
		break;
	      }
	    }
	  }
	}
	if (!bad_state && game[m + n * M] == '.') {
	  assert(new_num_entries < max_entries);
	  new_pointer->state = new_state;
	  if (new_state == 0xddb9e)
	    fprintf(stdout, "empty %lo %lo %d %d\n", state, new_state, m, n);
	  new_pointer->max_liberties_offset = (max_liberties + new_liberties
					       - new_max_liberties_base);
	  if (max_liberties + new_liberties < min_max_liberties)
	    min_max_liberties = max_liberties + new_liberties;
	  update_history(old_pointer, new_pointer, m, n, M, 0);
	  new_num_entries++;
	  new_pointer += increment;
	}

	/* Current vertex is a stone. */
	new_state = state;
	new_liberties = 0;
	if (down == EMPTY) {
	  new_state |= liberty_bit >> 3;
	  new_liberties++;
	}
	if (left == EMPTY)
	  new_liberties++;

	if (!left_is_stone && !down_is_stone)
	  new_state |= stone_bit | string_start_bit | string_end_bit;
	else if (!left_is_stone && down_is_stone) {
	  if (down & STRING_END_BIT) {
	    new_state &= ~(string_end_bit >> 3);
	    new_state |= stone_bit | string_end_bit;
	    new_state &= ~string_start_bit;
	  }
	  else {
	    new_state |= stone_bit;
	    new_state &= ~(string_start_bit | string_end_bit);
//	    fprintf(stderr, "hej %lo %lo %d %d\n", state, new_state, m, n);	    
	  }
	}
	else if (left_is_stone && down_is_stone) {
	  if (down == SINGLETON) {
	    if (left & STRING_START_BIT) {
	      new_state &= ~(string_end_bit >> 3);
	      new_state &= ~string_start_bit;
	    }
	    else
	      new_state &= ~((string_start_bit | string_end_bit) >> 3);
	  }
	  else if (left == SINGLETON) {
	    if (down == (STONE_BIT | STRING_END_BIT)) {
	      new_state &= ~(string_end_bit >> 3);
	      new_state &= ~string_start_bit;
	    }
	    else
	      new_state &= ~(string_start_bit | string_end_bit);
	  }
	  else if (down == (STONE_BIT | STRING_END_BIT)
		   && left == (STONE_BIT | STRING_START_BIT)) {
	    new_state &= ~(string_end_bit >> 3);
	    new_state &= ~string_start_bit;
	  }
	  else if (left == (STONE_BIT | STRING_START_BIT)
		   && (down & STONE_BIT)
		   && !(down & STRING_END_BIT)) {
	    new_state &= ~string_start_bit;
	    int depth = 0;
	    int i;
	    for (i = m + 1; i < M; i++) {
	      uint64_t current = (state >> (3 * i)) & 7;
	      if (current == (STONE_BIT | STRING_START_BIT))
		depth++;
	      else if (current == (STONE_BIT | STRING_END_BIT)) {
		if (depth > 0)
		  depth--;
		else {
		  new_state &= ~(STRING_END_BIT << (3 * i));
		  break;
		}
	      }
	    }
	    assert(depth == 0);
	  }
	  else if (down == (STONE_BIT | STRING_END_BIT)
		   && (left & STONE_BIT)
		   && !(left & STRING_START_BIT)) {
	    new_state &= ~(string_end_bit >> 3);
	    int depth = 0;
	    int i;
	    for (i = m - 2; i >= 0; i--) {
	      uint64_t current = (state >> (3 * i)) & 7;
	      if (current == (STONE_BIT | STRING_END_BIT))
		depth++;
	      else if (current == (STONE_BIT | STRING_START_BIT)) {
		if (depth > 0)
		  depth--;
		else {
		  new_state &= ~(STRING_START_BIT << (3 * i));
		  break;
		}
	      }
	    }
	    assert(depth == 0);
	  }
	}

	if (game[m + n * M] == 'X') {
	  assert(new_num_entries < max_entries);
	  new_pointer->state = new_state;
	  if (new_state == 0xddb9e)
	    fprintf(stdout, "stone %lo %lo %d %d\n", state, new_state, m, n);
	  new_pointer->max_liberties_offset = (max_liberties + new_liberties
					       - new_max_liberties_base);
	  if (max_liberties < min_max_liberties)
	    min_max_liberties = max_liberties;
	  update_history(old_pointer, new_pointer, m, n, M, 1);
	  new_num_entries++;
	  new_pointer += increment;
	}
      }

//      printf("num_states: %ld (%d %d)\n", num_states, m, n);
      if (direction == -1)
	qsort(table + max_entries - new_num_entries, new_num_entries,
	      sizeof(table[0]), positive_ordering);
      else
	qsort(table, new_num_entries, sizeof(table[0]), negative_ordering);
      
      old_num_entries = new_num_entries;
      direction = -direction;

//      printf("base %d %d %d\n", old_max_liberties_base, new_max_liberties_base, min_max_liberties);
      old_max_liberties_base = new_max_liberties_base;
      new_max_liberties_base = min_max_liberties;
    }
  }

  uint64_t string_starts = 0;
  for (k = 0; k < M; k++) {
    string_starts <<= 3;
    string_starts |= STONE_BIT | STRING_START_BIT;
  }

  int max_number_of_liberties = max_liberties_found_so_far;
  struct entry *p;
  if (direction == -1)
    p = table;
  else
    p = table + max_entries - old_num_entries;
  for (long k = 0; k < old_num_entries; k++, p++) {
    uint64_t starts = p->state & string_starts;
    starts &= (starts >> 1);
    if (((starts - 1) & starts) == 0)
      if (p->max_liberties_offset + old_max_liberties_base > max_number_of_liberties) {
	max_number_of_liberties = p->max_liberties_offset + old_max_liberties_base;
	print_board(p, M, N, max_number_of_liberties);
      }
  }

  printf("%dx%d: %d\n", M, N, max_number_of_liberties);
  
  return EXIT_SUCCESS;
}
