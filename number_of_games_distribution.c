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
#endif
#if 0
/* 2x2 */
#define NUMBER_OF_STATES 57
#define NUMBER_OF_POINTS 4

int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_POINTS] = {
{ 8,  7,  6,  5,  4,  3,  2,  1}, /*  0: .... */
{14, 13, 12, 11, 10,  9, -1, -1}, /*  1: O... */
{20, 19, 18, 17, 16, 15, -1, -1}, /*  2: X... */
{24, 23, 22, 21, 15,  9, -1, -1}, /*  3: .O.. */
{28, 27, 26, 25, 16, 10, -1, -1}, /*  4: .X.. */
{30, 29, 25, 21, 17, 11, -1, -1}, /*  5: ..O. */
{32, 31, 26, 22, 18, 12, -1, -1}, /*  6: ..X. */
{31, 29, 27, 23, 19, 13, -1, -1}, /*  7: ...O */
{32, 30, 28, 24, 20, 14, -1, -1}, /*  8: ...X */
{36, 35, 34, 33, -1, -1, -1, -1}, /*  9: OO.. */
{38, 37, 28, 11, -1, -1, -1, -1}, /* 10: OX.. */
{39, 33, -1, -1, -1, -1, -1, -1}, /* 11: O.O. */
{41, 40, 37, 34, -1, -1, -1, -1}, /* 12: O.X. */
{40, 39, 38, 35, -1, -1, -1, -1}, /* 13: O..O */
{41, 36, 28, 11, -1, -1, -1, -1}, /* 14: O..X */
{43, 42, 23, 18, -1, -1, -1, -1}, /* 15: XO.. */
{47, 46, 45, 44, -1, -1, -1, -1}, /* 16: XX.. */
{49, 48, 44, 42, -1, -1, -1, -1}, /* 17: X.O. */
{50, 45, -1, -1, -1, -1, -1, -1}, /* 18: X.X. */
{48, 46, 23, 18, -1, -1, -1, -1}, /* 19: X..O */
{50, 49, 47, 43, -1, -1, -1, -1}, /* 20: X..X */
{52, 51, 42, 33, -1, -1, -1, -1}, /* 21: .OO. */
{53, 34, 23, 18, -1, -1, -1, -1}, /* 22: .OX. */
{51, 35, -1, -1, -1, -1, -1, -1}, /* 23: .O.O */
{53, 52, 43, 36, -1, -1, -1, -1}, /* 24: .O.X */
{54, 44, 28, 11, -1, -1, -1, -1}, /* 25: .XO. */
{56, 55, 45, 37, -1, -1, -1, -1}, /* 26: .XX. */
{55, 54, 46, 38, -1, -1, -1, -1}, /* 27: .X.O */
{56, 47, -1, -1, -1, -1, -1, -1}, /* 28: .X.X */
{54, 51, 48, 39, -1, -1, -1, -1}, /* 29: ..OO */
{52, 49, 28, 11, -1, -1, -1, -1}, /* 30: ..OX */
{55, 40, 23, 18, -1, -1, -1, -1}, /* 31: ..XO */
{56, 53, 50, 41, -1, -1, -1, -1}, /* 32: ..XX */
{ 8,  0, -1, -1, -1, -1, -1, -1}, /* 33: OOO. */
{35, 32, -1, -1, -1, -1, -1, -1}, /* 34: OOX. */
{ 6,  0, -1, -1, -1, -1, -1, -1}, /* 35: OO.O */
{33, 32, -1, -1, -1, -1, -1, -1}, /* 36: OO.X */
{56, 13, -1, -1, -1, -1, -1, -1}, /* 37: OXX. */
{39, 26, -1, -1, -1, -1, -1, -1}, /* 38: OX.O */
{ 4,  0, -1, -1, -1, -1, -1, -1}, /* 39: O.OO */
{35, 26, -1, -1, -1, -1, -1, -1}, /* 40: O.XO */
{56,  9, -1, -1, -1, -1, -1, -1}, /* 41: O.XX */
{51, 20, -1, -1, -1, -1, -1, -1}, /* 42: XOO. */
{50, 21, -1, -1, -1, -1, -1, -1}, /* 43: XO.X */
{47, 29, -1, -1, -1, -1, -1, -1}, /* 44: XXO. */
{ 7,  0, -1, -1, -1, -1, -1, -1}, /* 45: XXX. */
{45, 29, -1, -1, -1, -1, -1, -1}, /* 46: XX.O */
{ 5,  0, -1, -1, -1, -1, -1, -1}, /* 47: XX.X */
{51, 16, -1, -1, -1, -1, -1, -1}, /* 48: X.OO */
{47, 21, -1, -1, -1, -1, -1, -1}, /* 49: X.OX */
{ 3,  0, -1, -1, -1, -1, -1, -1}, /* 50: X.XX */
{ 2,  0, -1, -1, -1, -1, -1, -1}, /* 51: .OOO */
{33, 20, -1, -1, -1, -1, -1, -1}, /* 52: .OOX */
{50,  9, -1, -1, -1, -1, -1, -1}, /* 53: .OXX */
{39, 16, -1, -1, -1, -1, -1, -1}, /* 54: .XOO */
{45, 13, -1, -1, -1, -1, -1, -1}, /* 55: .XXO */
{ 1,  0, -1, -1, -1, -1, -1, -1}, /* 56: .XXX */
};
#endif

unsigned long long distribution[NUMBER_OF_STATES];

void play_games(int state, int *visited_states, unsigned long long *n,
		int depth)
{
  int k;
  visited_states[state] = 1;
  (*n)++;
  distribution[depth]++;
  for (k = 0; k < 2 * NUMBER_OF_POINTS; k++) {
    int next_state = transformations[state][k];
    if (next_state >= 0
	&& !visited_states[next_state])
      play_games(next_state, visited_states, n, depth+1);
  }
  visited_states[state] = 0;
}

int main(int argc, char **argv)
{
  unsigned long long n = 0;
  int visited_states[NUMBER_OF_STATES];
  int k;

  for (k = 0; k < NUMBER_OF_STATES; k++) {
    visited_states[k] = 0;
    distribution[k] = 0;
  }
  
  play_games(0, visited_states, &n, 0);
  
  for (k = 0; k < NUMBER_OF_STATES; k++)
    printf("depth %3d: %Lu\n", k + 1, distribution[k]);

  printf("\nNumber of games: %Lu\n", n);
  return 0;
}