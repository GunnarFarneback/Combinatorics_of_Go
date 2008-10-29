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
// The internal representation of the border state is a string with a
// length equaling the height of the board and containing the
// following characters:
//
// X: A black stone with at least one liberty guaranteed.
// O: A white stone with at least one liberty guaranteed.
// .: An empty vertex.
// |: An edge vertex, only used initially while traversing the first column.
// s: White string without liberty and no other stones on the border
// u: White string without liberty and further stones higher
//    up on the border, but not further down.
// d: White string without liberty and further stones lower
//    down on the border, but but further up.
// b: White string without liberty and further stones both lower down
//    and higher up on the border.
// S, U, D, B: Corresponding for black.
//
// For strings without liberties the connectivity between the border
// stones can be determined from the symbols in the state and from the
// non-crossing property of strings.
//
// There is clearly no need to keep track of connectivity for stones
// with liberties.
//
// The state is recorded from the bottom and up. The position in
// Eric's example above is represented by the state string ".OUsD".
//
// During the computation of new state the state string is converted
// into an array of single-character strings. This is because strings
// are immutable in Pike but arrays can be destructively modified.
//
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

// Letters used for strings without liberties.
//
// The division by "" (the empty string) splits the string into an
// array of one-character strings.
array(string) white_strings = "sudb" / "";
array(string) black_strings = "SUDB" / "";

array(string) string_obtained_liberty(array(string) state, int i, string color)
{
  int height = sizeof(state);
  string single, up, down, both;
  if (color == "O") {
    single = "s";
    up = "u";
    down = "d";
    both = "b";
  }
  else {
    single = "S";
    up = "U";
    down = "D";
    both = "B";
  }

  int nesting = 0;
  int k;
  if (state[i] == up || state[i] == both)
    for (k = i + 1; k < height; k++) {
      if (state[k] == up)
	nesting++;
      else if (state[k] == down) {
	if (nesting == 0) {
	  state[k] = color;
	  break;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0)
	state[k] = color;
    }

  if (state[i] == down || state[i] == both)
    for (k = i - 1; k >= 0; k--) {
      if (state[k] == down)
	nesting++;
      else if (state[k] == up) {
	if (nesting == 0) {
	  state[k] = color;
	  break;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0)
	state[k] = color;
    }

  state[i] = color;
  
  return state;
}

array(string) remove_from_string(array(string) state, int i,
				 array(string) string_symbols)
{
  string single = string_symbols[0];
  string up = string_symbols[1];
  string down = string_symbols[2];
  string both = string_symbols[3];
  int k;
  int height = sizeof(state);

  int nesting = 0;
  if (state[i] == up)
    for (k = i + 1; k < height; k++) {
      if (state[k] == up)
	nesting++;
      else if (state[k] == down) {
	if (nesting == 0) {
	  state[k] = single;
	  return state;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0) {
	state[k] = up;
	return state;
      }
    }

  if (state[i] == down)
    for (k = i - 1; k >= 0; k--) {
      if (state[k] == down)
	nesting++;
      else if (state[k] == up) {
	if (nesting == 0) {
	  state[k] = single;
	  return state;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0) {
	state[k] = down;
	return state;
      }
    }

  return state;
}

int find_lower_end(array(string) state, int i, array(string) string_symbols)
{
  string single = string_symbols[0];
  string up = string_symbols[1];
  string down = string_symbols[2];
  string both = string_symbols[3];
  int height = sizeof(state);

  int k;
  int nesting = 0;
  for (k = i - 1; k >= 0; k--) {
    if (state[k] == down)
      nesting++;
    else if (state[k] == up) {
      if (nesting == 0) {
	return k;
      }
      else
	nesting--;
    }
  }
  
  // We should never come here
  werror("Impossible situation - B: %O %d\n", state, i);
  exit(1);
}

int find_upper_end(array(string) state, int i, array(string) string_symbols)
{
  string single = string_symbols[0];
  string up = string_symbols[1];
  string down = string_symbols[2];
  string both = string_symbols[3];
  int height = sizeof(state);

  int k;
  int nesting = 0;
  for (k = i + 1; k < height; k++) {
    if (state[k] == up)
      nesting++;
    else if (state[k] == down) {
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

mapping(string:int) add_one_vertex(mapping(string:int) old_state_count,
				   int i, int height, string|void color)
{
  mapping(string:int) new_state_count = ([]);
  array(string) colors;
  if (color)
    colors = ({color});
  else
    colors = ({"empty", "black", "white"});
  
  // Loop over the previous states.
  foreach (indices(old_state_count), string state)
    // Add an empty vertex, a black stone, and a white stone in turn.
    foreach (colors, string new_stone) {
      // Convert the state string to a state array.
      array(string) new_state = state / "";
      
      // What matters in the computation of the new state is what
      // we have to the left and below. If we are at the bottom of
      // the column the neighbor below is the edge symbol "|".
      string left = new_state[i];
      string down = (i == 0) ? "|" : new_state[i-1];
      
      // Of particular interest is whether we have a string
      // without liberties of one of the colors to the left or
      // below.
      int black_string_left = has_value(black_strings, left);
      int black_string_down = has_value(black_strings, down);
      int white_string_left = has_value(white_strings, left);
      int white_string_down = has_value(white_strings, down);
      
      // If we find that the new configuration is illegal we set
      // this variable to 1 to mark that it should be discarded.
      int bad_state = 0;
      
      // Handle each addition case by case.
      switch (new_stone) {
      case "empty":
	// When we add an empty vertex, the configuration is
	// guaranteed to be valid and the new state at the current
	// position will definitely be ".". If we have a string
	// without liberties to the left or below it has now
	// received a liberty and its stones should be converted
	// either to "X" or "O".
	if (black_string_left)
	  new_state = string_obtained_liberty(new_state, i, "X");
	if (black_string_down)
	  new_state = string_obtained_liberty(new_state, i-1, "X");
	if (white_string_left)
	  new_state = string_obtained_liberty(new_state, i, "O");
	if (white_string_down)
	  new_state = string_obtained_liberty(new_state, i-1, "O");
	new_state[i] = ".";
	break;
	
      case "black":
	// If we have a white string without liberties to the left
	// and this was its last stone on the border, it can no
	// longer get any liberty and thus the configuration is
	// illegal.
	if (left == "s") {
	  bad_state = 1;
	  break;
	}

	if (white_string_left)
	  new_state = remove_from_string(new_state, i, white_strings);
	
	// If we have at least one empty vertex or a black stone
	// with liberty to the left or to the right, the new stone
	// will also have at least one liberty.
	if (has_value("X.", left) || has_value("X.", down)) {
	  // Furthermore, if the other neighbor was a black string
	  // without liberties, it has also received a liberty
	  // now.
	  if (black_string_left)
	    new_state = string_obtained_liberty(new_state, i, "X");
	  else if (black_string_down)
	    new_state = string_obtained_liberty(new_state, i-1, "X");
	  new_state[i] = "X";
	}
	else if (black_string_left && black_string_down) {
	  // Both neighbors are black strings without liberties.
	  // These need to be merged and the new string will also
	  // lack liberties. There is no need to set the state at
	  // the current position explicitly as it will be part of
	  // the string inherited from the left.
#if 0
	  if (down == "S") {
	    if (left == "S") {
	      new_state[i-1] = "U";
	      new_state[i] = "D";
	    }
	    else if (left == "U") {
	      new_state[i-1] = "U";
	      new_state[i] = "B";
	    }
	    else if (left == "D" || left == "B") {
	      new_state[i-1] = "B";
	    }
	  }
	  else if (down == "D") {
	    if (left == "S") {
	      new_state[i-1] = "B";
	      new_state[i] = "D";
	    }
	    else if (left == "U") {
	      new_state[i-1] = "B";
	      new_state[i] = "B";
	    }
	    else if (left == "D" || left == "B") {
	      int j = find_lower_end(new_state, i-1, black_strings);
	      new_state[i-1] = "B";
	      new_state[j] = "B";
	    }
	  }
	  else if (down == "U" || down == "B") {
	    if (left == "S")
	      new_state[i] = "B";
	    else if (left == "U") {
	      int j = find_upper_end(new_state, i, black_strings);
	      new_state[i] = "B";
	      new_state[j] = "B";
	    }
	  }
#else
	  string downleft = down + left;
	  if (has_value(({"DD", "DB"}), downleft)) {
	    int j = find_lower_end(new_state, i-1, black_strings);
	    new_state[j] = "B";
	  }
	  if (has_value(({"UU", "BU"}), downleft)) {
	    int j = find_upper_end(new_state, i, black_strings);
	    new_state[j] = "B";
	  }
	  new_state[i-1] = (["SS":"U",
			     "SU":"U",
			     "SD":"B",
			     "SB":"B",
			     "US":"U",
			     "UU":"U",
			     "UD":"U",
			     "UB":"U",
			     "DS":"B",
			     "DU":"B",
			     "DD":"B",
			     "DB":"B",
			     "BS":"B",
			     "BU":"B",
			     "BD":"B",
			     "BB":"B"])[downleft];
	  new_state[i] = (["SS":"D",
			   "SU":"B",
			   "SD":"D",
			   "SB":"B",
			   "US":"B",
			   "UU":"B",
			   "UD":"D",
			   "UB":"B",
			   "DS":"D",
			   "DU":"B",
			   "DD":"D",
			   "DB":"B",
			   "BS":"B",
			   "BU":"B",
			   "BD":"D",
			   "BB":"B"])[downleft];
#endif
	}
	else if (black_string_down) {
	  // Black string without liberties below and a white
	  // stone (with or without liberties) or the edge to the
	  // left. Extend the string below to the current
	  // position.
	  if (down == "S" || down == "D") {
	    new_state[i] = "D";
	    if (down == "S")
	      new_state[i-1] = "U";
	    else
	      new_state[i-1] = "B";
	  }
	  else
	    new_state[i] = "B";
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
	  new_state[i] = "S";
	}
	break;
	
      case "white":
	// This code is identical to the "black" case above but
	// with reversed roles for black and white. We do not
	// repeat the comments above.
	if (left == "S") {
	  bad_state = 1;
	  break;
	}

	if (black_string_left)
	  new_state = remove_from_string(new_state, i, black_strings);
	
	if (has_value("O.", left) || has_value("O.", down)) {
	  if (white_string_left)
	    new_state = string_obtained_liberty(new_state, i, "O");
	  else if (white_string_down)
	    new_state = string_obtained_liberty(new_state, i-1, "O");
	  new_state[i] = "O";
	}
	else if (white_string_left && white_string_down) {
	  if (down == "s") {
	    if (left == "s") {
	      new_state[i-1] = "u";
	      new_state[i] = "d";
	    }
	    else if (left == "u") {
	      new_state[i-1] = "u";
	      new_state[i] = "b";
	    }
	    else if (left == "d" || left == "b") {
	      new_state[i-1] = "b";
	    }
	  }
	  else if (down == "d") {
	    if (left == "s") {
	      new_state[i-1] = "b";
	      new_state[i] = "d";
	    }
	    else if (left == "u") {
	      new_state[i-1] = "b";
	      new_state[i] = "b";
	    }
	    else if (left == "d" || left == "b") {
	      int j = find_lower_end(new_state, i-1, white_strings);
	      new_state[i-1] = "b";
	      new_state[j] = "b";
	    }
	  }
	  else if (down == "u" || down == "b") {
	    if (left == "s")
	      new_state[i] = "b";
	    else if (left == "u") {
	      int j = find_upper_end(new_state, i, white_strings);
	      new_state[i] = "b";
	      new_state[j] = "b";
	    }
	  }
	}
	else if (white_string_down) {
	  if (down == "s" || down == "d") {
	    new_state[i] = "d";
	    if (down == "s")
	      new_state[i-1] = "u";
	    else
	      new_state[i-1] = "b";
	  }
	  else
	    new_state[i] = "b";
	}
	else if (!white_string_left) {
	  new_state[i] = "s";
	}
	break;
	
      }

      // Throw away bad configurations. Add good ones to the state count.
      if (!bad_state)
	new_state_count[new_state * ""] += old_state_count[state];
    }

  return new_state_count;
}


array(string) col;

// Count the number of legal boards of the given size.
int count_legal_boards(int height, int width)
{
  // The border state count is represented by a mapping which
  // associates each border state string with the number of
  // configurations of the stones placed on the board so far having
  // that border state.
  mapping(string:int) state_count = ([]);
  
  // The initial state is "|" repeated height times, e.g. "|||||"
  // for 5xN boards.
  string edge = "|" * height;
  state_count[edge] = 1;
  
  // Keep track of the maximum number of border states for statistics.
  int max_number_of_border_states = 0;
  
  // Traverse the board in the order new vertices are added. The outer
  // loop goes from the left to the right and the inner loop from the
  // bottom to the top.
  for (int j = 0; j < width; j++)
    for (int i = 0; i < height; i++) {
      if (j == width / 2 && i <= height / 2)
	state_count = add_one_vertex(state_count, i, height, col[i]);
      else
	state_count = add_one_vertex(state_count, i, height);
#if 0
      write("foo: %O\n", state_count);
#endif
      // Update statistics.
      if (sizeof(state_count) > max_number_of_border_states)
	max_number_of_border_states = sizeof(state_count);
    }

  // The board has been traversed. The final border states which
  // include black or white strings without liberties correspond to
  // illegal board configurations and must be excluded. We do this by
  // summing the state counts for state strings only containing the
  // characters ".", "X", and "O".
  int sum = 0;
  foreach (indices(state_count), string state) {
    if (sizeof(state - "." - "X" - "O") == 0)
      sum += state_count[state];
  }

  // Print statistics.
  write("Max number of border states: %d\n",
	max_number_of_border_states);
  
  return sum;
}


int main(int argc, array(string) argv)
{
  if (argc < 4) {
    werror("Usage: pike legal.pike height width colors\n");
    exit(1);
  }
  
  int height = (int) argv[1];
  int width = (int) argv[2];

  col = reverse(argv[3] / "");
  replace(col, "x", "black");
  replace(col, "o", "white");
  replace(col, ".", "empty");
  
  int num_legal = count_legal_boards(height, width);

  // If the board is too large, we cannot convert to float before the
  // division to compute the fraction of legal boards since that would
  // cause overflow. With this trick we use bignum integers in the
  // division and get a result that is safe to convert to float.
  write("%dx%d: %d (%2.4f%%) legal boards\n", height, width, num_legal,
	0.000001 * (100000000 * num_legal / pow(3, height*width)));

  // Signal successful execution.
  return 0;
}
