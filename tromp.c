#include "stdio.h"
#include "stdlib.h"

int ht,wd,l[10],r[10],cl[10];

/* count #legal completions with rows filled upto row y, col x */
unsigned long long legal(int y, int x)
{
   int i,c,lx,rx,rlx,lrx,rx1,lrx1,bc;
   unsigned long long cnt;


   if (x > wd) {
     x = 1;
     if (++y > ht) {
       for (x=wd; x; x--)
         for (i=x; (i=l[i]);)
           if (i==x) return 0L;
       return 1L;
     }
   }
   bc=cl[x]; rlx=r[lx=l[x]]; lrx=l[rx=r[x]]; lrx1=l[rx1=r[x-1]];
   r[lx] = l[rx] = 0; /* lib for top neighbour */
   r[x-1] = l[rx1] = 0; /* lib for left neighbour */
   cl[x] = l[x] = r[x] = 0;
   cnt = legal(y,x+1);  /* cnt for setting x empty */
   for (c = 1; ; c++) {
     cl[x]=bc; r[l[x]=lx]=rlx; l[r[x]=rx]=lrx; l[r[x-1]=rx1]=lrx1;
     /* undo changes */
     if (c == 3) return cnt;
     if (bc != 0 && bc != c) { /* other color than top neighbr, who needs lib */
       if (bc < 3 && rx == x) continue; /* illegal if he had none */
       l[r[lx] = rx] = lx;
       l[x] = r[x] = x; /* temporarily set to 1 stone string */
     } /* else inherit from top neighbour in same string (or edge or empty) */
     if (cl[x-1] == c && l[x]|r[x-1]) {
       /* in same string as left neighbour and links not used for libs */
       l[r[l[x]]=r[x-1]] = l[x];
       l[r[x-1] = x] = x-1;
     }
     if (cl[x-1] == 0) /* lib to left */
       r[x] = l[r[x]] = 0;
     cl[x] = c;
     cnt += legal(y,x+1);
   }
}

int
main(int argc, char *argv[])
{
   int i;
   unsigned long long cnt,tot;

   if (argc==1) {
     printf ("usage: %s width [height]\n", argv[0]);
     exit(0);
   }
   ht = wd = atoi(argv[1]);
   if (argc > 2) {
       if ((i = atoi(argv[2])) < wd)
	   wd = i;
       else ht = i;
   }
   if (wd > 9) {
     printf ("minimum dimension %d too large\n", wd);
     exit(0);
   }
   for (i=0; i<=wd; i++)
     cl[l[i] = r[i] = i] = 3;
   cnt = legal(1,1);
   for (i=wd*ht,tot=3L; --i; tot *= 3L) ;
   printf("%lld legal, %lld illegal, prob %.6f\n",cnt,tot-cnt,cnt/(float)tot);
   return 0;
}
