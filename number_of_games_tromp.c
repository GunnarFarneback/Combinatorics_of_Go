#include <stdio.h>
#include <stdlib.h>

#define ILLEGAL (-1)

int next[256][8], h[256]; /* bitmap of positions in game history */
unsigned long nodes=0L;

void show(int n, int black, int white) /* print position in 2-line ascii */
{
  int i;
  printf("%d\n", n);
  for (i=0; i<4; i++) {
    printf(" %c", ".XO#"[(black>>i&1)+2*(white>>i&1)]);
    if ((i&1)==1)
      putchar('\n');
  }
  fflush(stdout);
}

void show2(int black, int white) /* print position in 2-line ascii */
{
  int i;
  for (i=0; i<4; i++) {
    printf("%c", ".XO#"[(black>>i&1)+2*(white>>i&1)]);
  }
}

void visit(int pos)
{
  nodes++;
  h[pos] = 1;
}

void unvisit(pos)
{
  h[pos] = 0;
}

int visited(int pos)
{
  return h[pos];
}

int hasmove(int me, int opp, int move, int *newme, int *newopp)
{
  move = 1<<move;
  *newme = me|move;
  if ((me|opp)&move || *newme==15 || opp==6 || opp==9)
    return 0;
  *newopp = (*newme|opp)==15 || *newme==6 || *newme==9 ? 0 : opp;
  return 1;
}

void cnt(int n, int pos)
{
  int i,newpos;

  visit(pos);
  for (i=0; i<2*4; i++) {
    newpos = next[pos][i];
    if (newpos != ILLEGAL && !visited(newpos))
      cnt(n+1, newpos);
  }
  unvisit(pos);
}

int main(int argc, char **argv)
{
  int n,p,w,b,nw,nb,i;
  for (w=0;w<16;w++) {
    for (b=0;b<16;b++) {
      p = b+16*w;
      for (i=0;i<4;i++) {
        next[p][i]= hasmove(b,w,i,&nb,&nw) ? nb+16*nw : ILLEGAL;
        next[p][4+i]= hasmove(w,b,i,&nw,&nb) ? nb+16*nw : ILLEGAL;
      }
    }
  }
  for (n=p=0; n+1<argc; n++) {
    show(n, p&15,p>>4);
    visit(p);
    p = next[p][atoi(argv[n+1])];
  }
  show(n, p&15,p>>4);

  for (i = 0; i < 256; i++) {
      printf("%3d: ", i);
      for (p = 0; p < 8; p++) {
	  printf("%3d ", next[i][p]);
      }
      show2(i & 15, i >> 4);
      printf("\n");
  }
  
  cnt(n, p);
  printf("total: %lu\n", nodes);
  return 0;
}
