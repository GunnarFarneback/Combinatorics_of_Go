#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define MAXSTATEWIDTH 99

typedef struct {
  unsigned char type;
  unsigned char left;
  unsigned char right;
} cell;

//possible cell types
#define EDGE  0
#define EMPTY 1
#define COLOR 1
#define BLACK 0
#define WHITE 1
#define LIBSTONE 2
#define NEEDY 4
#define ISNEEDY(x) ((x) >= NEEDY)
#define CELLCHARS "#.XOxo"

#define NSHOWBUF 4

typedef cell bstate[MAXSTATEWIDTH]; // bstate

int statewidth; // global to save us from passing it to every function

void setwidth(int wd)
{
  if (wd < 0 || wd > MAXSTATEWIDTH) {
    printf ("width %d out of range [0,%d]\n", wd, MAXSTATEWIDTH);
    exit(1);
  }
  statewidth = wd;
}

char *showstate(bstate state)
{
  static char buffers[NSHOWBUF][MAXSTATEWIDTH+1],*buf; // +1 for '\0'
  static int bufnr = 0;
  int type,i,ngroups[2];
                                                                                
  buf = buffers[bufnr++];
  if (bufnr == NSHOWBUF)
    bufnr = 0; // buffer rotation
  for (i = ngroups[0] = ngroups[1] = 0; i < statewidth; i++) {
    type = state[i].type;
    if (!ISNEEDY(type))
      buf[i] = CELLCHARS[type];
    else if (state[i].left < i)
      buf[i] = buf[state[i].left];
    else buf[i] = "Aa"[type&COLOR] + ngroups[type&COLOR]++;
  }
  buf[statewidth] = '\0';
  return buf;
}

void mustliberatecell(bstate state, int x, int nc)
{
  int i = x;

  do state[i].type = nc;
  while ((i = state[i].left) != x);
}

void liberatecell(bstate state, int x)
{
  if (ISNEEDY(state[x].type))
    mustliberatecell(state, x, state[x].type + LIBSTONE-NEEDY);
}
                                                                                
bstate *startstate()
{
  static bstate start;
  int i;

  for (i = 0; i < statewidth; i++)
    start[i].type = EDGE;
  return &start;
}

int finalstate(bstate state)
{
  int i;

  for (i = 0; i < statewidth; i++)
    if (ISNEEDY(state[i].type))
      return 0;
  return 1;
}

int stratify(bstate state)
{
#if 0
  int i,w;

  for (i = w = 0; i < statewidth; i++)
    if (state[i].type < NEEDY)
      w += state[i].type < LIBSTONE ? 2 : 1;
  return w;
#else
  int i,w=statewidth;

  for (i = 0; i < statewidth; i++)
    if (state[i].type >= NEEDY && state[i].left >= i)
      w--;
  return w;
#endif
}

int expandstate(bstate state, int x, bstate *new)
{
  int nnew=0, col;
  cell *stx, left, up, edge;
  bstate t;
                                                                                
  edge.type = EDGE; ; edge.left = edge.right = x;
  up = state[x];
  left = x ? state[x-1] : edge;
  // extend border with liberty at (x,y)
  memcpy(t,state,sizeof(bstate));
  liberatecell(t, x);
  if (x > 0)
    liberatecell(t, x-1);
  t[x].type = EMPTY;
  memcpy(new[nnew++],t,sizeof(bstate));
  for (col=0; col<2; col++) {
    memcpy(t,state,sizeof(bstate));
    stx = &t[x];
    // extend border with stone at (x,y)
    if (up.type == ((NEEDY|col) ^ COLOR)) {
      if (up.left == x) // singleton string
        continue; // don't deprive last liberty
      t[t[up.right].left = up.left].right = up.right; // unlink
    }
    if (left.type == EMPTY || left.type == (LIBSTONE|col)) {
      if (up.type == (NEEDY|col))
        mustliberatecell(t, x, LIBSTONE|col);
      stx->type = LIBSTONE|col;
    } else if (up.type == EMPTY || up.type == (LIBSTONE|col)) {
      if (left.type == (NEEDY|col))
        mustliberatecell(t, x-1, LIBSTONE|col);
      stx->type = LIBSTONE|col;
    } else {
      if (up.type != (NEEDY|col)) { // don't preserve links
        stx->type = NEEDY|col;
        stx->left = stx->right = x;
      }
      if (left.type == (NEEDY|col)) {
        t[t[left.right].left = stx->left].right = left.right;
        t[stx->left = x-1].right = x;
      }
    }
    memcpy(new[nnew++],t,sizeof(bstate));
  }
  return nnew;
}

#ifdef TESTSTATE
unsigned long cnt;

void visit(bstate s, int y, int x)
{
  bstate new[3];
  int i,nnew;
  bstate state;

  if (y == statewidth) {
    cnt += finalstate(s);
    return;
  }
  nnew = expandstate(s, x, new);
  for (i=0; i<nnew; i++)
    visit(new[i], y+(x+1)/statewidth, (x+1)%statewidth);
}

int main()
{
  bstate s,new[3];
  int i,nnew,x;
  bstate state;
 
  setwidth(4);
  visit(*startstate(),0,0);
  printf("cnt = %lu\n", cnt);
}
#endif
