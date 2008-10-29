#define STARTSTATE 0L
#define NSHOWBUF 4

typedef unsigned long Word_t;

void setwidth(int statewidth);

// rotates through NSHOWBUF output buffers
// so it can be called multiple times in printf
char *showstate(Word_t s, int x);

// return whether s encodes a legal final state or not
int finalstate(Word_t s);

// fill new with successor states of s
// return number of new states, up to 3
int expandstate(Word_t s, int x, Word_t *new);
