#!/usr/bin/env pike

//        legal.pike - Count the number of legal go boards.
//        Copyright 2005 by Gunnar Farnebäck
//        gunnar@lysator.liu.se
//
//        You are free to do whatever you want with this code.
//
//
// This program computes the number of legal go board configurations
// for a rectangular board of a given size. It is efficient enough to
// handle boards up to 8x8 within minutes and up to 11x11 in less than
// 24 hours (on a fast computer). For rectangular boards MxN, large N
// can be handled efficiently as long as M is kept small.
//
// The program is inspired by the Computer Go List postings of Jeffrey
// Rainy,
//
//   Is there any published articles or websites stating the exact number of
//   legal goban configurations that are possible for a given goban size ?
//   
//   The best I found, from Sensei's Library is :
//   
//   1x1: 1 legal, 2 illegal, prob 0.333333
//   2x2: 57 legal, 24 illegal, prob 0.703704
//   3x3: 12675 legal, 7008 illegal, prob 0.643957
//   4x4: 24318165 legal, 18728556 illegal, prob 0.564925
//   4x5: 1840058693 legal, 1646725708 illegal, prob 0.527724
//   
//   I realise this is of no interest except from a purely
//   theoretical/combinatorial viewpoint. However, I think I could come up with
//   the exact values up to at least 9x9. Was this done before ? Would anyone
//   find it useful or at least somehow interesting ?
//
// and the response from Eric Boesch,
//
//   >Would anyone find it useful or at least somehow interesting ?
//
//   Yes, I think the answer would be interesting, and the method used to
//   arrive at numbers for such large boards would be even more
//   interesting. At first I thought you were crazy to think the
//   computation was practical for 9x9, but after considerable thought, I'm
//   not so sure. I think I've finally worked out an angle. In any case, it
//   sounds like not only did you find an angle first, but you also had the
//   insight to realize an answer might be possible in the first place,
//   which I did not. Considering where you say Sensei's left off (5x4), I
//   bet they used brute force, which isn't very interesting.
//   
//   Here are my thoughts on the problem. I have not actually worked out
//   the solution -- I figure you have dibs on this problem anyway :)
//   Possible spoiler?
//   
//   Bisection and divide-and-conquer, while (I think) straightforward
//   enough for 1-dimensional boards, seemed very difficult to do for
//   2-dimensional ones. Hmm...
//   
//   Instead of divide-and-conquer, I think you should work out from the
//   corner, adding stones one at a time, column by column, keeping an
//   array mapping all possible border states to the number of different
//   overall region states that share that same border state. The border is
//   the set of intersections that are inside the region that are adjacent
//   to intersections outside the region. The border state is not only the
//   color of the border intersections, but also whether those stones
//   already have liberties, or whether they need to connect to outside
//   liberties, and also whether those stones are connected to each other.
//   For example:
//   
//   -----
//   | #
//   | # O
//   | # #
//   | # O
//   | O .
//   -----
//   
//   If this is our region, then the border consists of the four rightmost
//   intersections (the rightmost ones in each row). The border colors are
//   #,O,#,O, and "." (empty), but the border state is more than just the
//   colors of the border stones. It's also important to know that the
//   topmost O stone needs to connect (directly or indirectly) to an
//   outside liberty. The two # stones on the border also need to connect
//   to a liberty, but since they are already connected to each other, a
//   single liberty at either end suffices.
//   
//   So the number of possible border configurations is strictly greater
//   than 3^(# of border intersections). I have no idea what the exact
//   number would be, but as long as the effective exponent base isn't too
//   big, the space demands for 9x9 should be manageable. For example, 4^9
//   is just a quarter million.
//   
//   In sum, when you're adding a new intersection to the region, you
//   iterate through all of the old border states, and through all of the
//   possible colors for that new intersection (black, white, empty). For
//   each old border state, you compute the new border state that results
//   from adding the given stone to the old border, and you add the number
//   of positions having the old border state to the number of positions
//   having the new border state. Once you have added all 81 stones, the
//   single (null) border state number will equal the total number of valid
//   positions -- make sure to use either floating point or bignums.
//
// For the full postings, see
// http://computer-go.org/pipermail/computer-go/2005-January/002387.html
// http://computer-go.org/pipermail/computer-go/2005-January/002412.html
//
//
// This program implements the algorithm as outlined by Eric.
// It is written in Pike. See http://pike.ida.liu.se for documentation
// and download. It should be noted that the "int" type in Pike
// automatically switches to bignums when the values become too large
// for the native integers on the platform.
//
// The internal representation of the border state is an integer where
// each vertex along the border is represented by 4 bits, below given
// in hexadecimal notation.
//
// 2: A black stone with at least one liberty guaranteed.
// 1: A white stone with at least one liberty guaranteed.
// 0: An empty vertex.
// 3: An edge vertex, only used initially while traversing the first column.
// 9: White string without liberty and no other stones on the border
// b: White string without liberty and further stones higher
//     up on the border, but not further down.
// d: White string without liberty and further stones lower
//     down on the border, but but further up.
// f: White string without liberty and further stones both lower down
//     and higher up on the border.
// 8, a, c, e: Corresponding for black.
//
// For strings without liberties the connectivity between the border
// stones can be determined from the symbols in the state and from the
// non-crossing property of strings.
//
// There is clearly no need to keep track of connectivity for stones
// with liberties.
//
// The state is recorded from the bottom and up, with the first vertex
// in the least significant bits of the state integer. The position in
// Eric's example above is represented by the hexadecimal number
// c9a10.
//
// Results for quadratic boards computed by this program:
//
// 1x1   1
// 2x2   57
// 3x3   12675
// 4x4   24318165
// 5x5   414295148741
// 6x6   62567386502084877
// 7x7   83677847847984287628595
// 8x8   990966953618170260281935463385
// 9x9   103919148791293834318983090438798793469
// 10x10 96498428501909654589630887978835098088148177857
//
// The time complexity seems to increase roughly by 7^N which means
// that 11x11 should be solvable in about 24 hours, 12x12 in a week,
// and 13x13 in less than two months. Please report the results if you
// find the computer time to do this.

/**********************************************************/

// Useful constants
#define EMPTY     2
#define WHITE     1
#define BLACK     0
#define EDGE      3
#define COLOR     1
#define CONT_UP   2
#define CONT_DOWN 4
#define CONT_BOTH 6
#define LACKS_LIB 8
#define GET(x,i) (((x) >> (4*(i)))&0xf)
#define SET(x,i,d) x = ((x & ~(15 << (4*(i)))) | (d << (4*(i))))
#define ONBIT(x,i,b) x |= ((b) << (4*(i)))
#define OFFBIT(x,i,b) x &= ~((b) << (4*(i)))

array(string) translations = "XO.|????SsUuDdBb" / "";

string state_to_string(int state, int height)
{
  string s = "";
  for (int i = 0; i < height; i++)
    s += translations[GET(state, i)];
  return s;
}

int string_obtained_liberty(int state, int i, int color, int height)
{
  int nesting = 0;
  int k;
  int state_i = GET(state, i);
  if (state_i & CONT_UP)
    for (k = i + 1; k < height; k++) {
      int state_k = GET(state, k);
      if (state_k == (LACKS_LIB | CONT_UP | color))
	nesting++;
      else if (state_k == (LACKS_LIB | CONT_DOWN | color)) {
	if (nesting == 0) {
	  SET(state, k, color);
	  break;
	}
	else
	  nesting--;
      }
      else if (state_k == (LACKS_LIB | CONT_BOTH | color) && nesting == 0)
	SET(state, k, color);
    }

  if (state_i & CONT_DOWN)
    for (k = i - 1; k >= 0; k--) {
      int state_k = GET(state, k);
      if (state_k == (LACKS_LIB | CONT_DOWN | color))
	nesting++;
      else if (state_k == (LACKS_LIB | CONT_UP | color)) {
	if (nesting == 0) {
	  SET(state, k, color);
	  break;
	}
	else
	  nesting--;
      }
      else if (state_k == (LACKS_LIB | CONT_BOTH | color) && nesting == 0)
	SET(state, k, color);
    }

  SET(state, i, color);
  
  return state;
}

int remove_from_string(int state, int i, int height)
{
  int k;
  int nesting = 0;
  int state_i = GET(state, i);
  int color = state_i & COLOR;
  if (state_i == (LACKS_LIB | CONT_UP | color))
    for (k = i + 1; k < height; k++) {
      int state_k = GET(state, k);
      if (state_k == (LACKS_LIB | CONT_UP | color))
	nesting++;
      else if (state_k == (LACKS_LIB | CONT_DOWN | color)) {
	if (nesting == 0) {
	  SET(state, k, (LACKS_LIB | color));
	  return state;
	}
	else
	  nesting--;
      }
      else if (state_k == (LACKS_LIB | CONT_BOTH | color) && nesting == 0) {
	SET(state, k, (LACKS_LIB | CONT_UP | color));
	return state;
      }
    }

  if (state_i == (LACKS_LIB | CONT_DOWN | color))
    for (k = i - 1; k >= 0; k--) {
      int state_k = GET(state, k);
      if (state_k == (LACKS_LIB | CONT_DOWN | color))
	nesting++;
      else if (state_k == (LACKS_LIB | CONT_UP | color)) {
	if (nesting == 0) {
	  SET(state, k, (LACKS_LIB | color));
	  return state;
	}
	else
	  nesting--;
      }
      else if (state_k == (LACKS_LIB | CONT_BOTH | color) && nesting == 0) {
	SET(state, k, (LACKS_LIB | CONT_DOWN | color));
	return state;
      }
    }

  return state;
}

int find_lower_end(int state, int i)
{
  int k;
  int nesting = 0;
  int color = GET(state, i) & COLOR;
  for (k = i - 1; k >= 0; k--) {
    int state_k = GET(state, k);
    if (state_k == (LACKS_LIB | CONT_DOWN | color))
      nesting++;
    else if (state_k == (LACKS_LIB | CONT_UP | color)) {
      if (nesting == 0) {
	return k;
      }
      else
	nesting--;
    }
  }
  
  // We should never come here
  werror("Impossible situation - B: %x %d\n", state, i);
  exit(1);
}

int find_upper_end(int state, int i, int height)
{
  int k;
  int nesting = 0;
  int color = GET(state, i) & COLOR;
  for (k = i + 1; k < height; k++) {
    int state_k = GET(state, k);
    if (state_k == (LACKS_LIB | CONT_UP | color))
      nesting++;
    else if (state_k == (LACKS_LIB | CONT_DOWN | color)) {
      if (nesting == 0) {
	return k;
      }
      else
	nesting--;
    }
  }
  
  // We should never come here
  werror("Impossible situation - C: %O %d\n", state, i);
  exit(1);
}

mapping(int:int) add_one_vertex(mapping(int:int) old_state_count,
				int i, int height)
{
  mapping(int:int) new_state_count = ([]);
  
  // Loop over the previous states.
  foreach (indices(old_state_count), int state)
    // Add an empty vertex, a black stone, and a white stone in turn.
    foreach (({"empty", "black", "white"}), string new_stone) {
      // Start with the existing state.
      int new_state = state;
      
      // What matters in the computation of the new state is what
      // we have to the left and below. If we are at the bottom of
      // the column the neighbor below is the edge symbol "|".
      int left = GET(new_state, i);
      int down = (i == 0) ? EDGE : GET(new_state, i-1);
      
      // Of particular interest is whether we have a string
      // without liberties of one of the colors to the left or
      // below.
      int black_string_left = (left & LACKS_LIB) && (left & COLOR) == BLACK;
      int black_string_down = (down & LACKS_LIB) && (down & COLOR) == BLACK;
      int white_string_left = (left & LACKS_LIB) && (left & COLOR) == WHITE;
      int white_string_down = (down & LACKS_LIB) && (down & COLOR) == WHITE;
      
      // If we find that the new configuration is illegal we set
      // this variable to 1 to mark that it should be discarded.
      int bad_state = 0;
      
      // Handle each addition case by case.
      switch (new_stone) {
      case "empty":
	// When we add an empty vertex, the configuration is
	// guaranteed to be valid and the new state at the current
	// position will definitely be EMPTY. If we have a string
	// without liberties to the left or below it has now
	// received a liberty and its stones should be converted
	// either to BLACK or WHITE.
	if (black_string_left)
	  new_state = string_obtained_liberty(new_state, i, BLACK, height);
	if (black_string_down)
	  new_state = string_obtained_liberty(new_state, i-1, BLACK, height);
	if (white_string_left)
	  new_state = string_obtained_liberty(new_state, i, WHITE, height);
	if (white_string_down)
	  new_state = string_obtained_liberty(new_state, i-1, WHITE, height);
	SET(new_state, i, EMPTY);
	break;
	
      case "black":
	// If we have a white string without liberties to the left
	// and this was its last stone on the border, it can no
	// longer get any liberty and thus the configuration is
	// illegal.
	if (left == (LACKS_LIB | WHITE)) {
	  bad_state = 1;
	  break;
	}

	if (white_string_left)
	  new_state = remove_from_string(new_state, i, height);
	
	// If we have at least one empty vertex or a black stone
	// with liberty to the left or to the right, the new stone
	// will also have at least one liberty.
	if (left == BLACK || left == EMPTY || down == BLACK || down == EMPTY) {
	  // Furthermore, if the other neighbor was a black string
	  // without liberties, it has also received a liberty
	  // now.
	  if (black_string_left)
	    new_state = string_obtained_liberty(new_state, i, BLACK, height);
	  else if (black_string_down)
	    new_state = string_obtained_liberty(new_state, i-1, BLACK, height);
	  SET(new_state, i, BLACK);
	}
	else if (black_string_left && black_string_down) {
	  // Both neighbors are black strings without liberties.
	  // These need to be merged and the new string will also
	  // lack liberties. There is no need to set the state at
	  // the current position explicitly as it will be part of
	  // the string inherited from the left.

	  if ((down & CONT_BOTH) == CONT_DOWN) {
	    if (left & CONT_DOWN) {
	      int j = find_lower_end(new_state, i-1);
	      ONBIT(new_state, j, CONT_DOWN);
	    }
	  }
	  else if (down & CONT_UP) {
	    if ((left & CONT_BOTH) == CONT_UP) {
	      int j = find_upper_end(new_state, i, height);
	      ONBIT(new_state, j, CONT_UP);
	    }
	  }
	  
	  if (!(down & CONT_BOTH) && (left & CONT_DOWN)) {
	    ONBIT(new_state, i-1, CONT_DOWN);
	  }
	  ONBIT(new_state, i-1, CONT_UP);
	
	  if (!(left & CONT_BOTH) && (down & CONT_UP)) {
	    ONBIT(new_state, i, CONT_UP);
	  }
	  ONBIT(new_state, i, CONT_DOWN);
	}
	else if (black_string_down) {
	  // Black string without liberties below and a white
	  // stone (with or without liberties) or the edge to the
	  // left. Extend the string below to the current
	  // position.
	  if (!(down & CONT_UP)) {
	    SET(new_state, i, (LACKS_LIB | CONT_DOWN | BLACK));
	    if (!(down & CONT_BOTH))
	      SET(new_state, i-1, (LACKS_LIB | CONT_UP | BLACK));
	    else
	      SET(new_state, i-1, (LACKS_LIB | CONT_BOTH | BLACK));
	  }
	  else
	    SET(new_state, i, (LACKS_LIB | CONT_BOTH | BLACK));
	}
	else if (!black_string_left) {
	  // If we have a black string without liberties to the
	  // left and a white stone or the edge below we do not
	  // need to do anything as the border state remains
	  // unchanged by adding the new stone to the string to
	  // the left.
	  //
	  // If we have white stones or edges both to the left and
	  // below we get a new string without liberties now.
	  SET(new_state, i, (LACKS_LIB | BLACK));
	}
	break;
	
      case "white":
	// This code is identical to the "black" case above but
	// with reversed roles for black and white. We do not
	// repeat the comments above.
	if (left == (LACKS_LIB | BLACK)) {
	  bad_state = 1;
	  break;
	}

	if (black_string_left)
	  new_state = remove_from_string(new_state, i, height);
	
	if (left == WHITE || left == EMPTY || down == WHITE || down == EMPTY) {
	  if (white_string_left)
	    new_state = string_obtained_liberty(new_state, i, WHITE, height);
	  else if (white_string_down)
	    new_state = string_obtained_liberty(new_state, i-1, WHITE, height);
	  SET(new_state, i, WHITE);
	}
	else if (white_string_left && white_string_down) {
	  if ((down & CONT_BOTH) == CONT_DOWN) {
	    if (left & CONT_DOWN) {
	      int j = find_lower_end(new_state, i-1);
	      ONBIT(new_state, j, CONT_DOWN);
	    }
	  }
	  else if (down & CONT_UP) {
	    if ((left & CONT_BOTH) == CONT_UP) {
	      int j = find_upper_end(new_state, i, height);
	      ONBIT(new_state, j, CONT_UP);
	    }
	  }
	  if (!(down & CONT_BOTH) && (left & CONT_DOWN))
	    ONBIT(new_state, i-1, CONT_DOWN);
	  ONBIT(new_state, i-1, CONT_UP);
	
	  if (!(left & CONT_BOTH) && (down & CONT_UP))
	    ONBIT(new_state, i, CONT_UP);
	  ONBIT(new_state, i, CONT_DOWN);
	}
	else if (white_string_down) {
	  if (!(down & CONT_UP)) {
	    SET(new_state, i, (LACKS_LIB | CONT_DOWN | WHITE));
	    if (!(down & CONT_BOTH))
	      SET(new_state, i-1, (LACKS_LIB | CONT_UP | WHITE));
	    else
	      SET(new_state, i-1, (LACKS_LIB | CONT_BOTH | WHITE));
	  }
	  else
	    SET(new_state, i, (LACKS_LIB | CONT_BOTH | WHITE));
	}
	else if (!white_string_left) {
	  SET(new_state, i, (LACKS_LIB | WHITE));
	}
	break;
      }

      // Throw away bad configurations. Add good ones to the state count.
      if (!bad_state)
	new_state_count[new_state] += old_state_count[state];
    }

  return new_state_count;
}



// Count the number of legal boards of the given size.
mapping(int:int) count_legal_boards(int height, int width)
{
  // The border state count is represented by a mapping which
  // associates each border state string with the number of
  // configurations of the stones placed on the board so far having
  // that border state.
  mapping(int:int) state_count = ([]);

  mapping(int:int) results = ([]);
  
  // The initial state is EDGE repeated height times, e.g. "0x33333"
  // for 5xN boards.
  int edge;
  sscanf("0x" + ((string) EDGE) * height, "%x", edge);
  state_count[edge] = 1;
  
  // Keep track of the maximum number of border states for statistics.
  int max_number_of_border_states = 0;

  // Used when filtering out libertylacking states.
  int all_liberties;
  sscanf("0x" + ((string) LACKS_LIB) * height, "%x", all_liberties);
  int sum;
  
  // Traverse the board in the order new vertices are added. The outer
  // loop goes from the left to the right and the inner loop from the
  // bottom to the top.
  for (int j = 0; j < width; j++) {
    for (int i = 0; i < height; i++) {
      state_count = add_one_vertex(state_count, i, height);

#if 0
      foreach (sort(indices(state_count)), int state)
	write("%s %d\n", state_to_string(state, height), state_count[state]);
      write("\n");
#endif
      // Update statistics.
      if (sizeof(state_count) > max_number_of_border_states)
	max_number_of_border_states = sizeof(state_count);
    }
    
    // Another column of the board has been traversed. The final
    // border states which include black or white strings without
    // liberties correspond to illegal board configurations and must
    // be excluded. We do this by summing the state counts for state
    // strings only containing the characters ".", "X", and "O".
    sum = 0;
    foreach (indices(state_count), int state) {
	if ((state & all_liberties) == 0)
	    sum += state_count[state];
    }
    results[j+1] = sum;
  }
  
  return results;
}

array(Gmp.mpz) berlekamp_massey(array(int) v, Gmp.mpz m)
{
    int n = sizeof(v) / 2;
    v = v[*] % m;
    array(Gmp.mpz) Lambda = ({Gmp.mpz(0)}) * n + ({Gmp.mpz(1)});
    array(Gmp.mpz) B = copy_value(Lambda);
    int L = 0;
    Gmp.mpz delta;

    for (int r = 0; r < 2 * n; r++)
    {
	if (r <= n)
	    delta = Array.sum(Lambda[n-r..n][*] * v[0..r][*]) % m;
	else
	    delta = Array.sum(Lambda[*] * v[r-n..r][*]) % m;

	if (delta != 0 && 2*L <= r)
	{
	    L = r + 1 - L;
	    array(Gmp.mpz) Lambda0 = copy_value(Lambda);
	    Lambda = Lambda[*] - (delta*(B[1..] + ({Gmp.mpz(0)}))[*])[*];
	    Lambda = Lambda[*] % m;
	    B = Lambda0[*] * delta->invert(m);
	    B = B[*] % m;
	}
	else
	{
	    B = B[1..] + ({Gmp.mpz(0)});
	    Lambda = Lambda[*] - (delta * B[*])[*];
	    Lambda = Lambda[*] % m;
	}
    }
    return Lambda;
}

int main(int argc, array(string) argv)
{
  if (argc < 4) {
    werror("Usage: pike legal.pike height width modulo\n");
    exit(1);
  }
  
  int height = (int) argv[1];
  int width = (int) argv[2];
  Gmp.mpz m = Gmp.mpz(argv[3]);
  
  mapping(int:int) num_legal = count_legal_boards(height, width);

  // If the board is too large, we cannot convert to float before the
  // division to compute the fraction of legal boards since that would
  // cause overflow. With this trick we use bignum integers in the
  // division and get a result that is safe to convert to float.
  for (int k = 1; k <= width; k++)
      write("%dx%d: %d (%2.4f%%) legal boards\n", height, k, num_legal[k],
	    0.000001 * (100000000 * num_legal[k] / pow(3, height*k)));

  write("%O\n", berlekamp_massey(num_legal[sort(indices(num_legal))[*]],m)[*]%m);
  
  // Signal successful execution.
  return 0;
}
