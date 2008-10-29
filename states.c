#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "states.h"

#define MAXSTATEWIDTH 21 // 3 bits per cell fits in 64 bits

typedef struct {
  unsigned char type;
  unsigned char needycolor;
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
#define HASR 1
#define HASL 2
#define SENTINEL (~(~(Word_t)0L >> 1)) // sign bit
#define SENTI(s) (((s) & SENTINEL) != 0)
#define CELLCHARS "#.XO"
#define ISNEEDY(x) (((x) & NEEDY) != 0)
#define ALLONES 01111111111111111111111L
#define NSET(t,x,d) t = ((t) & (~(7L<<(3*(x))))) | ((Word_t)(d)<<(3*(x)))

#define STARTSTATE 0L  // code for array of edgecells
#define NSHOWBUF 4

typedef cell bstate[MAXSTATEWIDTH]; // borderstate

int statewidth; // global to save us from passing it to every function
int thirdwidth,twothirdwidth;
Word_t twothirdmask, thirdmask;

void setwidth(int wd)
{
  if (wd < 0 || wd > MAXSTATEWIDTH) {
    printf ("width %d out of range [0,%d]\n", wd, MAXSTATEWIDTH);
    exit(0);
  }
  statewidth = wd;
  thirdmask = (1L << (3*(thirdwidth = statewidth/3))) - 1L;
  twothirdmask = (1L << (3*(twothirdwidth = statewidth - statewidth/3))) - 1L;
}

void wordtostate(Word_t s, int bump, bstate state)
{
  char stack[MAXSTATEWIDTH];
  int sp,i,type,leftcolor;
  cell *sti;
                                                                                
  leftcolor = SENTI(s); // sentinel
  sti = &state[0];
  for (i = sp = 0; i < statewidth; sti++, i++) {
    sti->type = type = (s >> (3*i)) & 7;
    sti->left = sti->right = i;
    if (ISNEEDY(type)) {
      sti->needycolor = leftcolor ^ COLOR; // assume opposite color
      if (type & HASL) {
        if (!sp) {
          printf("sp=0! i=%d s=%3lo bump=%d\n",i, s, bump);
          exit(0);
        }
        sti->right = state[sti->left = stack[--sp]].right;
        state[sti->left].right = state[sti->right].left = i;
        sti->needycolor ^= (sti->left == i-1); // check color assumption
      }
      if (type & HASR)
        stack[sp++] = i;
      if (i == bump)
        sti->needycolor = BLACK; // color normalization
      leftcolor = sti->needycolor;
    } else leftcolor = type & 1;
  }
  if (sp) {
    printf("sp=%d s=%3lo bump=%d\n",sp, s, bump);
    exit(0);
  }
}

char *showstate(Word_t s, int bump)
{
  static char buffers[NSHOWBUF][MAXSTATEWIDTH+1],*buf; // +1 for '\0'
  static int bufnr = 0;
  int nc,type,i,ngroups[2];
  bstate state;
  Word_t decode(Word_t, int);
                                                                                
  s = decode(s, bump);
  wordtostate(s, bump, state);
  buf = buffers[bufnr++];
  if (bufnr == NSHOWBUF)
    bufnr = 0; // buffer rotation
  for (i = ngroups[0] = ngroups[1] = 0; i < statewidth; i++) {
    type = state[i].type;
    if (!ISNEEDY(type))
      buf[i] = CELLCHARS[type];
    else if (type & HASL)
      buf[i] = buf[state[i].left];
    else { nc= state[i].needycolor; buf[i] = "Aa"[nc] + ngroups[nc]++; }
  }
  buf[statewidth] = '\0';
  return buf;
}

Word_t mustliberatecell(Word_t t, bstate state, int x, int nc)
{
  int i = x, libtype = LIBSTONE | nc;

  do NSET(t,i,libtype);
  while ((i = state[i].left) != x);
  return t;
}

Word_t liberatecell(Word_t t, bstate state, int x)
{
  return ISNEEDY(state[x].type) ?
    mustliberatecell(t, state, x, state[x].needycolor) : t;
}
                                                                                
Word_t flipstones(Word_t t)
{
  t ^= (((~t) >> 2) & (t >> 1) & ALLONES);
  if (t & NEEDY)
    t ^= SENTINEL;
  return t;
}

Word_t encode(Word_t t, int bump, bstate state)
{
  Word_t t1;

  if (bump == statewidth)
    bump = 0;
  if (!(t & NEEDY))
    t &= ~SENTINEL;
  if (ISNEEDY(t >> (3*bump))) {
    if (state[bump].needycolor == WHITE)
      t = flipstones(t);
  } else if ((t1 = flipstones(t)) < t)
    t = t1;
  if (SENTI(t))
    t = (t | HASL) & ~SENTINEL; // put sentinel bit in HASL if cell 0 needy
  if (bump >= twothirdwidth)
    t = (t >> 3*thirdwidth) | ((t & thirdmask) << 3*twothirdwidth);
  return t;
}

Word_t decode(Word_t s, int bump)
{
  if (bump >= twothirdwidth)
    s = (s >> 3*twothirdwidth) | ((s & twothirdmask) << 3*thirdwidth);
  if ((s & (NEEDY|HASL)) == (NEEDY|HASL))
    s = (s & ~HASL) | SENTINEL;
  return s;
}

int finalstate(Word_t s)
{
  return !(s & (NEEDY * ALLONES));
}

int expandstate(Word_t s, int x, Word_t *new)
{
  int nnew=0, col;
  cell left, up, edge;
  bstate state;
  Word_t t;
                                                                                
#ifdef SHOWEXPAND
  printf("exp(s=%3lo (%s), x=%d, new)\n",0*s, showstate(s,x), x);
#endif
  s = decode(s, x);
  wordtostate(s, x, state);
  edge.type = EDGE; ; edge.left = edge.right = x;
  up = state[x];
  left = x ? state[x-1] : edge;
  // extend border with liberty at (x,y)
  t = liberatecell(s, state, x);
  if (x > 0)
    t = liberatecell(t, state, x-1);
  NSET(t,x,EMPTY);
  new[nnew++] = encode(t, x+1, state);
  for (col=0; col<2; col++) {
    t = s; up = state[x];
    // extend border with stone at (x,y)
    if (ISNEEDY(up.type) && up.needycolor != col) {
      if (up.left == x) // singleton string
        continue; // don't deprive last liberty
      if (up.type & HASL) { // unlink
        if (!(up.type & HASR))
          t ^= (Word_t)HASR << (3*up.left);
      } else if (up.type & HASR)
        t ^= (Word_t)HASL << (3*up.right);
      up = edge;
    }
    if (left.type == EMPTY || left.type == (LIBSTONE|col)) {
      if (ISNEEDY(up.type)) // don't liberate edge shielded opposite
        t = mustliberatecell(t, state, x, col);
      NSET(t,x,LIBSTONE|col);
    } else if (up.type == EMPTY || up.type == (LIBSTONE|col)) {
      if (ISNEEDY(left.type) && left.needycolor == col)
        t = mustliberatecell(t, state, x-1, col);
      NSET(t,x,(LIBSTONE|col));
    } else {
      if (!(ISNEEDY(up.type)))
        NSET(t,x,up.type = NEEDY);
      if (ISNEEDY(left.type) && left.needycolor == col) {
        if (up.type & HASL) {
          if (!(left.type & HASR)) // not already merged
            t |= (Word_t)HASL << (3*left.right);
        } else if (left.type & HASR)
          t |= (Word_t)HASR << (3*up.left);
        t |= ((Word_t)((HASL<<3)|HASR) << (3*(x-1)));
      } else if (x == 0 && SENTI(t) == col)
        t ^= SENTINEL;
    }
    new[nnew++] = encode(t, x+1, state);
  }
  return nnew;
}
