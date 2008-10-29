#include <stdlib.h>
#include <stdio.h>
#include <Judy.h>
#include <assert.h>
#include <mpi.h>
#include "states.h"

Word_t moduli[11]={
0L, // 2^64                      // use up to  6x 6 for  64 bit precision
-3L, // 13 3889 364870227143809  // use up to  9x 9 for 128 bit precision
-5L, // 11 59 98818999 287630261 // use up to 11x11 for 192 bit precision
-7L, // 3^2 818923289 2502845209 // use up to 12x12 for 256 bit precision
-9L, // 7 9241 464773 613566757  // use up to 14x14 for 320 bit precision
-11L, // 5 2551 1446236305269271 // use up to 15x15 for 384 bit precision
-15L, // 53 348051774975651917   // use up to 16x16 for 448 bit precision
-17L, // 19 67 14490765179661863 // use up to 18x18 for 512 bit precision
-33L, // 827 3894899 5726879071  // use up to 19x19 for 576 bit precision
-35L, // 17 72786899 14907938207 // use up to 20x20 for 640 bit precision
-39L // 139646831 132095686967   // use up to 21x21 for 704 bit precision
};

Word_t modulus = 0L;

void mod_add(Word_t *a, Word_t b) {
  Word_t c = *a+b;
  if (c < b || c >= modulus)
    c -= modulus;
  *a = c;
}

Word_t cntlegal(int wd, int ht) {
  Pvoid_t oldt = (Pvoid_t)NULL, newt = (Pvoid_t)NULL;
  Word_t *PValue,*QValue,s,news[3],Rc_word,tot; 
  int i,nnew,x,y;

  JLI(PValue,newt,STARTSTATE);
  *PValue = 1L;
  for (y=0; y<ht; y++) {
    for (x=0; x<wd; x++) {
      JLC(Rc_word, newt, 0L, -1L);
      printf("(%d,%d) size %ld\n",y,x,Rc_word);
      fflush(stdout);
      JLFA(Rc_word,oldt); oldt = newt; newt = NULL;
      s = 0L;
      JLF(PValue,oldt,s);
      while (PValue!=NULL) {
        nnew = expandstate(s, x, news);
        for (i=0; i<nnew; i++) {
          JLI(QValue,newt,news[i]);
          if (!*QValue) *QValue = *PValue; else mod_add(QValue,*PValue);
        }
        JLN(PValue,oldt,s);
      }
    }
  }
  JLC(Rc_word, newt, 0L, -1L);
  printf("(%d,0) size %ld\n",ht,Rc_word);
  JLFA(Rc_word,oldt);
  s = tot = 0L;
  JLF(PValue,newt,s);
  while (PValue!=NULL) {
    if (finalstate(s))
      mod_add(&tot,*PValue);
    JLN(PValue,newt,s);
  }
  JLFA(Rc_word,newt);
  return tot;
}

int main(int argc, char *argv[])
{
  int i,wd,ht;
  Word_t tot;

  if (argc==1) {
    printf ("usage: %s width [height [modulo_index (0-9)]]\n", argv[0]);
    exit(0);
  }
  ht = wd = atoi(argv[1]);
  if (argc > 2) {
     if ((i = atoi(argv[2])) < wd)
       wd = i;
     else ht = i; // make width smaller than height
  }
  if (argc > 3)
     modulus = moduli[atoi(argv[3])];
  setwidth(wd);
  tot = cntlegal(wd, ht);
  printf("legal(%dx%d) %% ",ht,wd);
  if (modulus)
    printf("%lu",modulus);
  else printf("18446744073709551616");
  printf(" = %lu\n",tot);
  return 0;
}
