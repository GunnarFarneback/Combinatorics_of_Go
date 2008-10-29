#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <ctype.h>
#include <string.h>
#include <Judy.h>
#include <assert.h>
#include "states.h"

#define NSIGNIFICANTSTATEBYTES 6
#define STATECNTSIZE (NSIGNIFICANTSTATEBYTES+(int)sizeof(Word_t))

Word_t moduli[]={
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

#define NMODULI (int)(((sizeof moduli)/(sizeof(Word_t))))

Word_t modulus = 0L;

void mod_add(Word_t *a, Word_t b) {
  Word_t c = *a+b;
  if (c < b || c >= modulus)
    c -= modulus;
  *a = c;
}

Word_t tsize = 0L, nlegal = 0L, nout = 0L;
int ncpus, cpuid;

#define MAXCPUS 4

Word_t splits[19][MAXCPUS];

void initsplit(int wd)
{
  int b,i,d;
  FILE *fp;
  char fname[64];

  for (b=0; b<wd; b++)
    splits[b][ncpus-1] = -1L;
  if (ncpus == 1)
    return;
  sprintf(fname, "split.%d.%d",wd, ncpus);
  fp = fopen(fname, "r");
  assert(fp);
  for (b=0; b<wd; b++) {
    fscanf(fp, "bump %d\n", &d);
    assert(d==b);
    fscanf(fp, "#borders %d\n", &d);
    for (i=0; i<ncpus-1; i++) {
      fscanf(fp, "%lo\n",&splits[b][i]);
    }
  }
  fclose(fp);
}

void dumptree(Pvoid_t newt, char *basename, int extension, Word_t *splitit)
{
  Word_t Rc_word,t,*PValue;
  char outname[64];
  FILE *fp;
  int i;

  t = 0L;
  JLF(PValue,newt,t);
  for (i=0; i<ncpus; i++) {
    sprintf(outname,"%s.%d.%d.%d", basename, cpuid, extension, i);
    fp = fopen(outname, "w");
    while (PValue && t < splitit[i]) {
      if (*PValue) {
        if (finalstate(t))
          mod_add(&nlegal, *PValue);
        assert(fwrite(    &t,NSIGNIFICANTSTATEBYTES,1,fp));
        assert(fwrite(PValue,sizeof(Word_t),1,fp));
        nout++;
      } else printf("Not saving state %lo with count 0\n", t);
      JLN(PValue,newt,t);
    }
    fclose(fp);
  }
  assert(PValue==NULL);
  JLFA(Rc_word,newt);
}

typedef struct {
  FILE *fp;
  Word_t state;
  Word_t cnt;
} statebuf;
statebuf startbuf = {NULL,STARTSTATE, 1L};

#define MAXINFILES 99
#define EMPTYBUF (-1L)
#define ISEMPTYBUF(b) ((b)->state == EMPTYBUF)

statebuf buf[MAXINFILES];
Word_t nin = 0L, noldin = 0L;;
int nbuf = 0;

void fillbuf(statebuf *sb)
{
  if (fread(&sb->state,NSIGNIFICANTSTATEBYTES,1,sb->fp)) {
   assert(fread(&sb->cnt,sizeof(Word_t),1,sb->fp));
   nin++;
  } else sb->state = EMPTYBUF;
}

statebuf *minbuf()
{
  statebuf *sb, *mb = &buf[0];

  for (sb=&buf[1]; sb < &buf[nbuf]; sb++) {
    if (sb->state < mb->state) // avoided for EMPTYBUF(rising i)
      mb = sb;
    else if (sb->state == mb->state && sb->state != EMPTYBUF) {
      mod_add(&mb->cnt, sb->cnt);
      fillbuf(sb);
      noldin++;
    }
  }
  return mb;
}

void cntlegal(Word_t maxtsize, char *inbase, char *outbase, int x) {
  Pvoid_t newt = (Pvoid_t)NULL;
  Word_t mins,mincnt,*PValue, news[3]; 
  int i,j,nnew,noutfiles=0;
  char inname[64];
  statebuf *mb;

  for (i=nbuf=0; i<ncpus; i++) {
    for (j=0; ; j++) {
      sprintf(inname,"%s.%d.%d.%d",inbase,i,j,cpuid); 
      if (!(buf[nbuf].fp = fopen(inname, "r")))
        break;
      fillbuf(&buf[nbuf++]);
      if (nbuf == MAXINFILES) {
        printf ("MAXINFILES (%d) should exceed #inputfiles\n", MAXINFILES);
        exit(0);
      }
    }
  }
  if (!nbuf)
    return;
  for (tsize = 0L; !ISEMPTYBUF(mb = minbuf()); ) {
    mins = mb->state; mincnt = mb->cnt; fillbuf(mb);
    //printf("state %lx count %lu\n", mins, mincnt);
    nnew = expandstate(mins, x, news);
    for (i=0; i<nnew; i++) {
      JLI(PValue, newt, news[i]);
      if (!*PValue) { // new tree entry
        *PValue = mincnt;
        if (++tsize == maxtsize) {
          dumptree(newt, outbase, noutfiles++, splits[x]);
          newt = (Pvoid_t)NULL; tsize = 0L;
        }
      } else mod_add(PValue,mincnt);
    }
  }
  if (tsize)
    dumptree(newt, outbase, noutfiles++, splits[x]);
  for (i=0; i<nbuf ; i++)
    fclose(buf[i].fp);
}

int main(int argc, char *argv[])
{
  int modidx,wd,y,x,tsizelen;
  Word_t maxtsize;
  char c,*tsizearg,inbase[64],inname[64],outbase[64];

  if (argc!=6) {
    printf ("usage: %s width modulo_index maxtreesize[kKmM] y x\n", argv[0]);
    exit(0);
  }
  setwidth(wd = atoi(argv[1]));
  modidx = atoi(argv[2]);
  if (modidx < 0 || modidx >= NMODULI) {
    printf ("modulo_index %d not in range [0,%d)\n", modidx, NMODULI);
    exit(0);
  }
  modulus = moduli[modidx];
  ncpus = 1; // atoi(argv[3]);
  if (ncpus < 1 || ncpus > MAXCPUS) {
    printf ("#cpus %d not in range [0,%d]\n", ncpus, MAXCPUS);
    exit(0);
  }
  initsplit(wd);
  cpuid = 0; // atoi(argv[4]);
  tsizelen = strlen(tsizearg = argv[3]);
  if (!isdigit(c = tsizearg[tsizelen-1]))
    tsizearg[tsizelen-1] = '\0';
   maxtsize = atol(tsizearg);
  if (c == 'k' || c == 'K')
    maxtsize *= 1000L;
  if (c == 'm' || c == 'M')
    maxtsize *= 1000000L;
  y = atoi(argv[4]);
  x = atoi(argv[5]);
  sprintf(inbase,"state.%d.%d.%d.%d",wd,modidx,y,x); 
  if (x==0 && y==0 && cpuid==0) {
    FILE *fp;
    sprintf(inname,"%s.0.0.%d",inbase,cpuid); 
    fp = fopen(inname, "w");
    assert(fwrite(&startbuf.state,NSIGNIFICANTSTATEBYTES,1,fp));
    assert(fwrite(&startbuf.cnt,sizeof(Word_t),1,fp));
    fclose(fp);
  }
  printf("reading from %s.*.%d\n",inbase,cpuid);
  sprintf(outbase,"state.%d.%d.%d.%d",wd,modidx,y+(x+1)/wd,(x+1)%wd); 

  cntlegal(maxtsize, inbase, outbase, x);

  printf("%lu states read with avg multiplicity %1.3lf\n",
          nin-noldin,nin/(double)(nin-noldin));
  printf("%lu states written to %s.*.*\n",nout,outbase);
  if (x==wd-1) {
    printf("legal(%dx%d) %% ",y+1,wd);
    if (modulus)
      printf("%lu",modulus);
    else printf("18446744073709551616");
    printf(" = %lu\n",nlegal);
  }
  return 0;
}
