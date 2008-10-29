#define MAXSTATEWIDTH 99
#define NSHOWBUF 4

typedef struct {
  unsigned char type;
  unsigned char left;
  unsigned char right;
} cell;

typedef cell bstate[MAXSTATEWIDTH]; // borderstate

void setwidth(int statewidth);

bstate *startstate();

int stratify(bstate state);

// rotates through NSHOWBUF output buffers
// so it can be called multiple times in printf
char *showstate(bstate s, int x);

// return whether s encodes a legal final state or not
int finalstate(bstate s);

// fill new with successor states of s
// return number of new states, up to 3
int expandstate(bstate s, int x, bstate *new);
