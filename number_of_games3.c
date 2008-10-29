#include <stdio.h>

#if 0
/* 1x2 */
#define NUMBER_OF_STATES 5
#define NUMBER_OF_POINTS 2

int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_POINTS] = {
{ 4,  3,  2,  1}, /*  0: .. */
{ 4,  0, -1, -1}, /*  1: O. */
{ 3,  0, -1, -1}, /*  2: X. */
{ 2,  0, -1, -1}, /*  3: .O */
{ 1,  0, -1, -1}, /*  4: .X */
};
#endif
#if 0
/* 1x3 */
#define NUMBER_OF_STATES 15
#define NUMBER_OF_POINTS 3

int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_POINTS] = {
{ 6,  5,  4,  3,  2,  1}, /*  0: ... */
{ 9,  8,  7,  4, -1, -1}, /*  1: O.. */
{12, 11, 10,  3, -1, -1}, /*  2: X.. */
{13,  7, -1, -1, -1, -1}, /*  3: .O. */
{14, 10, -1, -1, -1, -1}, /*  4: .X. */
{13, 11,  8,  4, -1, -1}, /*  5: ..O */
{14, 12,  9,  3, -1, -1}, /*  6: ..X */
{ 6,  0, -1, -1, -1, -1}, /*  7: OO. */
{ 4,  0, -1, -1, -1, -1}, /*  8: O.O */
{14,  7, -1, -1, -1, -1}, /*  9: O.X */
{ 5,  0, -1, -1, -1, -1}, /* 10: XX. */
{13, 10, -1, -1, -1, -1}, /* 11: X.O */
{ 3,  0, -1, -1, -1, -1}, /* 12: X.X */
{ 2,  0, -1, -1, -1, -1}, /* 13: .OO */
{ 1,  0, -1, -1, -1, -1}, /* 14: .XX */
};
int colorflip[NUMBER_OF_STATES] = {
  0, 2, 1, 4, 3, 6, 5, 10, 12, 11, 7, 9, 8, 14, 13
};
#endif
#if 0
/* 1x3 cyclic */
#define NUMBER_OF_STATES 19
#define NUMBER_OF_POINTS 3

int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_POINTS] = {
{ 6,  5,  4,  3,  2,  1}, /*  0: ... */
{10,  9,  8,  7, -1, -1}, /*  1: O.. */
{14, 13, 12, 11, -1, -1}, /*  2: X.. */
{16, 15, 11,  7, -1, -1}, /*  3: .O. */
{18, 17, 12,  8, -1, -1}, /*  4: .X. */
{17, 15, 13,  9, -1, -1}, /*  5: ..O */
{18, 16, 14, 10, -1, -1}, /*  6: ..X */
{ 6,  0, -1, -1, -1, -1}, /*  7: OO. */
{18,  9, -1, -1, -1, -1}, /*  8: OX. */
{ 4,  0, -1, -1, -1, -1}, /*  9: O.O */
{18,  7, -1, -1, -1, -1}, /* 10: O.X */
{15, 14, -1, -1, -1, -1}, /* 11: XO. */
{ 5,  0, -1, -1, -1, -1}, /* 12: XX. */
{15, 12, -1, -1, -1, -1}, /* 13: X.O */
{ 3,  0, -1, -1, -1, -1}, /* 14: X.X */
{ 2,  0, -1, -1, -1, -1}, /* 15: .OO */
{14,  7, -1, -1, -1, -1}, /* 16: .OX */
{12,  9, -1, -1, -1, -1}, /* 17: .XO */
{ 1,  0, -1, -1, -1, -1}, /* 18: .XX */
};
int colorflip[NUMBER_OF_STATES] = {
  0, 2, 1, 4, 3, 6, 5, 12, 11, 14, 13, 8, 7, 10, 9, 18, 17, 16, 15
};
#endif
#if 1
/* 1x4 */
#define NUMBER_OF_STATES 41
#define NUMBER_OF_POINTS 4

int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_POINTS] = {
{ 8,  7,  6,  5,  4,  3,  2,  1}, /*  0: .... */
{13, 12, 11, 10,  9,  4, -1, -1}, /*  1: O... */
{18, 17, 16, 15, 14,  3, -1, -1}, /*  2: X... */
{22, 21, 20, 19,  9, -1, -1, -1}, /*  3: .O.. */
{26, 25, 24, 23, 14, -1, -1, -1}, /*  4: .X.. */
{27, 23, 19, 15, 10, -1, -1, -1}, /*  5: ..O. */
{28, 24, 20, 16, 11, -1, -1, -1}, /*  6: ..X. */
{27, 25, 21, 17, 12,  6, -1, -1}, /*  7: ...O */
{28, 26, 22, 18, 13,  5, -1, -1}, /*  8: ...X */
{31, 30, 29,  6, -1, -1, -1, -1}, /*  9: OO.. */
{32, 29, 23, -1, -1, -1, -1, -1}, /* 10: O.O. */
{33, 24,  6, -1, -1, -1, -1, -1}, /* 11: O.X. */
{32, 30, 25, 11, -1, -1, -1, -1}, /* 12: O..O */
{33, 31, 26, 10, -1, -1, -1, -1}, /* 13: O..X */
{36, 35, 34,  5, -1, -1, -1, -1}, /* 14: XX.. */
{37, 19,  5, -1, -1, -1, -1, -1}, /* 15: X.O. */
{38, 34, 20, -1, -1, -1, -1, -1}, /* 16: X.X. */
{37, 35, 21, 16, -1, -1, -1, -1}, /* 17: X..O */
{38, 36, 22, 15, -1, -1, -1, -1}, /* 18: X..X */
{39, 29, -1, -1, -1, -1, -1, -1}, /* 19: .OO. */
{21, 16,  6,  3, -1, -1, -1, -1}, /* 20: .OX. */
{39, 30, 20, -1, -1, -1, -1, -1}, /* 21: .O.O */
{31, 19,  3, -1, -1, -1, -1, -1}, /* 22: .O.X */
{26, 10,  5,  4, -1, -1, -1, -1}, /* 23: .XO. */
{40, 34, -1, -1, -1, -1, -1, -1}, /* 24: .XX. */
{35, 24,  4, -1, -1, -1, -1, -1}, /* 25: .X.O */
{40, 36, 23, -1, -1, -1, -1, -1}, /* 26: .X.X */
{39, 37, 32,  4, -1, -1, -1, -1}, /* 27: ..OO */
{40, 38, 33,  3, -1, -1, -1, -1}, /* 28: ..XX */
{ 8,  0, -1, -1, -1, -1, -1, -1}, /* 29: OOO. */
{ 6,  0, -1, -1, -1, -1, -1, -1}, /* 30: OO.O */
{29, 28, -1, -1, -1, -1, -1, -1}, /* 31: OO.X */
{ 4,  0, -1, -1, -1, -1, -1, -1}, /* 32: O.OO */
{40,  9, -1, -1, -1, -1, -1, -1}, /* 33: O.XX */
{ 7,  0, -1, -1, -1, -1, -1, -1}, /* 34: XXX. */
{34, 27, -1, -1, -1, -1, -1, -1}, /* 35: XX.O */
{ 5,  0, -1, -1, -1, -1, -1, -1}, /* 36: XX.X */
{39, 14, -1, -1, -1, -1, -1, -1}, /* 37: X.OO */
{ 3,  0, -1, -1, -1, -1, -1, -1}, /* 38: X.XX */
{ 2,  0, -1, -1, -1, -1, -1, -1}, /* 39: .OOO */
{ 1,  0, -1, -1, -1, -1, -1, -1}, /* 40: .XXX */
};

int colorflip[NUMBER_OF_STATES] = {
  0, 2, 1, 4, 3, 6, 5, 8, 7, 14, 16,
  15, 18, 17, 9, 11, 10, 13, 12, 24, 23,
  26, 25, 20, 19, 22, 21, 28, 27, 34, 36,
  35, 38, 37, 29, 31, 30, 33, 32, 40, 39
};

char *boards[NUMBER_OF_STATES] = {
  "....",
  "O...",
  "X...",
  ".O..",
  ".X..",
  "..O.",
  "..X.",
  "...O",
  "...X",
  "OO..",
  "O.O.",
  "O.X.",
  "O..O",
  "O..X",
  "XX..",
  "X.O.",
  "X.X.",
  "X..O",
  "X..X",
  ".OO.",
  ".OX.",
  ".O.O",
  ".O.X",
  ".XO.",
  ".XX.",
  ".X.O",
  ".X.X",
  "..OO",
  "..XX",
  "OOO.",
  "OO.O",
  "OO.X",
  "O.OO",
  "O.XX",
  "XXX.",
  "XX.O",
  "XX.X",
  "X.OO",
  "X.XX",
  ".OOO",
  ".XXX"
};
#endif

int visiting_order[NUMBER_OF_STATES];

void play_games(int state, int *visited_states, unsigned long long *n, int depth)
{
  int k;
  int flipped = 1;
  visited_states[state] = 1;
  visiting_order[depth] = state;
  (*n)++;
  int mid = (NUMBER_OF_STATES - 1) / 2;

  if (depth == NUMBER_OF_STATES - 1) {
    for (k = 0; k < NUMBER_OF_STATES; k++) {
      printf("%d ", visiting_order[k]);
      if (flipped && k > 0 && k <= mid
	  && visiting_order[mid + k] != colorflip[visiting_order[k]]) {
	flipped = 0;
	printf("*");
      }
    }
    if (flipped) {
      printf("!!!!\n");
      for (k = 0; k < NUMBER_OF_STATES; k++)
	printf("%s\n", boards[visiting_order[k]]);
    }
    printf("\n");
  }
  
  for (k = 0; k < 2 * NUMBER_OF_POINTS; k++) {
    int next_state = transformations[state][k];
    if (next_state >= 0
	&& !visited_states[next_state])
      play_games(next_state, visited_states, n, depth + 1);
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

  play_games(0, visited_states, &n, 0);
  
  printf("Number of games: %Lu\n", n);
  return 0;
}
