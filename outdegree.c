#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define EMPTY 0
#define BLACK 1
#define WHITE 2

#define MAXSIZE 8

int height;
int width;
int board[MAXSIZE][MAXSIZE];
int mark[MAXSIZE][MAXSIZE];
int not_suicide_colors[MAXSIZE][MAXSIZE];

static void
find_string(int i, int j, int *libi, int *libj, int color)
{
  mark[i][j] = 1;

  if (i > 0) {
    if (board[i-1][j] == color && !mark[i-1][j])
      find_string(i-1, j, libi, libj, color);
    else if (board[i-1][j] == EMPTY) {
      if (*libi == -1) {
	*libi = i-1;
	*libj = j;
      }
      else {
	if (*libi != i-1 || *libj != j) {
	  if (*libi != MAXSIZE) {
	    not_suicide_colors[*libi][*libj] |= color;
	    *libi = MAXSIZE;
	  }
	  not_suicide_colors[i-1][j] |= color;
	}
      }
    }
  }

  if (i < height - 1) {
    if (board[i+1][j] == color && !mark[i+1][j])
      find_string(i+1, j, libi, libj, color);
    else if (board[i+1][j] == EMPTY) {
      if (*libi == -1) {
	*libi = i+1;
	*libj = j;
      }
      else {
	if (*libi != i+1 || *libj != j) {
	  if (*libi != MAXSIZE) {
	    not_suicide_colors[*libi][*libj] |= color;
	    *libi = MAXSIZE;
	  }
	  not_suicide_colors[i+1][j] |= color;
	}
      }
    }
  }

  if (j > 0) {
    if (board[i][j-1] == color && !mark[i][j-1])
      find_string(i, j-1, libi, libj, color);
    else if (board[i][j-1] == EMPTY) {
      if (*libi == -1) {
	*libi = i;
	*libj = j-1;
      }
      else {
	if (*libi != i || *libj != j-1) {
	  if (*libi != MAXSIZE) {
	    not_suicide_colors[*libi][*libj] |= color;
	    *libi = MAXSIZE;
	  }
	  not_suicide_colors[i][j-1] |= color;
	}
      }
    }
  }

  if (j < width - 1) {
    if (board[i][j+1] == color && !mark[i][j+1])
      find_string(i, j+1, libi, libj, color);
    else if (board[i][j+1] == EMPTY) {
      if (*libi == -1) {
	*libi = i;
	*libj = j+1;
      }
      else {
	if (*libi != i || *libj != j+1) {
	  if (*libi != MAXSIZE) {
	    not_suicide_colors[*libi][*libj] |= color;
	    *libi = MAXSIZE;
	  }
	  not_suicide_colors[i][j+1] |= color;
	}
      }
    }
  }
}

static int
test_legal()
{
  int i, j;
  int outdegree = 0;
  
  for (j = 0; j < width; j++)
    for (i = 0; i < height; i++) {
      mark[i][j] = 0;
      not_suicide_colors[i][j] = 0;
    }

  for (j = 0; j < width; j++)
    for (i = 0; i < height; i++) {
      if (board[i][j] == EMPTY) {
	if (i > 0 && board[i-1][j] == EMPTY)
	  not_suicide_colors[i-1][j] = BLACK | WHITE;
	if (i < height - 1 && board[i+1][j] == EMPTY)
	  not_suicide_colors[i+1][j] = BLACK | WHITE;
	if (j > 0 && board[i][j-1] == EMPTY)
	  not_suicide_colors[i][j-1] = BLACK | WHITE;
	if (j < width - 1 && board[i][j+1] == EMPTY)
	  not_suicide_colors[i][j+1] = BLACK | WHITE;
      }
      else if (mark[i][j] == 0) {
	int libi = -1;
	int libj = -1;
	find_string(i, j, &libi, &libj, board[i][j]);
#if 0
	printf("find_string: %d %d %d %d\n", i, j, libi, libj);
#endif
	if (libi == -1)
	  return -1;
	else if (libi != MAXSIZE)
	  not_suicide_colors[libi][libj] |= BLACK + WHITE - board[i][j];
      }
    }

  for (j = 0; j < width; j++)
    for (i = 0; i < height; i++)
      if (board[i][j] == EMPTY) {
	if (not_suicide_colors[i][j] & BLACK)
	  outdegree++;
	else {
	  if ((i > 0 && board[i-1][j] == BLACK)
	      || (i < height - 1 && board[i+1][j] == BLACK)
	      || (j > 0 && board[i][j-1] == BLACK)
	      || (j < width - 1 && board[i][j+1] == BLACK))
	    outdegree++;
	}
	if (not_suicide_colors[i][j] & WHITE)
	  outdegree++;
	else {
	  if ((i > 0 && board[i-1][j] == WHITE)
	      || (i < height - 1 && board[i+1][j] == WHITE)
	      || (j > 0 && board[i][j-1] == WHITE)
	      || (j < width - 1 && board[i][j+1] == WHITE))
	    outdegree++;
	}
      }

  return outdegree;
}

int
main(int argc, char **argv)
{
  int i, j;
  int k;
  int m;
  int N;
  int outdegree;
  int num_legal = 0;
  int sum_outdegrees = 0;
  double sum_log_outdegrees = 0.0;
  
  if (argc < 3) {
    fprintf(stderr, "Too few arguments.\n");
    return 1;
  }
  height = atoi(argv[1]);
  width = atoi(argv[2]);

  if (height > MAXSIZE || width > MAXSIZE) {
    fprintf(stderr, "Too large board.\n");
    return 1;
  }

  N = 1;
  for (k = 0; k < height * width; k++)
    N *= 3;

  for (k = 0; k < N; k++) {
    m = k;
    for (j = 0; j < width; j++)
      for (i = 0; i < height; i++) {
	board[i][j] = m % 3;
	m /= 3;
      }

    outdegree = test_legal();

#if 0
    for (i = 0; i < height; i++) {
      for (j = 0; j < width; j++) {
	printf("%c", ".XO"[board[i][j]]);
      }
      printf(" ");
    }
    printf("%d\n", outdegree);
#endif
	
    if (outdegree >= 0) {
      num_legal++;
      sum_outdegrees += outdegree;
      if (outdegree > 0)
	sum_log_outdegrees += log((double) outdegree);
    }
  }

  printf("Size: %dx%d\n", height, width);
  printf("Number legal: %d\n", num_legal);
  printf("Sum outdegree: %d\n", sum_outdegrees);
  printf("Average outdegree: %f\n",
	 (float) sum_outdegrees / (float) num_legal);
  printf("Average outdegree per point: %f\n",
	 (float) sum_outdegrees / (float) num_legal / height / width);
  printf("Sum logarithmic outdegree: %f\n",
	 (float) sum_log_outdegrees / log(2));
  printf("Average logarithmic outdegree: %f\n",
	 (float) sum_log_outdegrees / (float) num_legal / log(2));
  printf("Geometric average outdegree: %f\n",
	 exp((float) sum_log_outdegrees / (float) num_legal));
  printf("Geometric average outdegree per point: %f\n",
	 exp((float) sum_log_outdegrees / (float) num_legal) / height / width);
  
  return 0;
}
