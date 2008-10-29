#!/usr/bin/env pike

//        legal5.pike - Count the number of legal go boards.
//        Copyright 2005 by Gunnar Farnebäck
//        gunnar@lysator.liu.se
//
//        You are free to do whatever you want with this code.
//
//
// This program computes the number of legal go board configurations
// for a quadratic board of odd size. It is efficient enough to
// handle boards up to 8x8 within minutes and up to 11x11 in less than
// 24 hours (on a fast computer).
//
// This program is written in Pike. See http://pike.ida.liu.se for
// documentation and download. It should be noted that the "int" type
// in Pike automatically switches to bignums when the values become
// too large for the native integers on the platform.
//
// The algorithm uses a rotating border approach. It starts with a
// fixed configuration on the ray from the center point out to the
// right edge. Then it add vertices according to a scheme which for
// 7x7 looks like:
//
// 18 17 15 12  9  7  6
// 19 16 14 11  8  4  5
// 21 20 13 10  1  2  3
// 24 23 22  X  X  X  X
// 27 26 25 34 37 44 45
// 29 28 32 35 38 40 43
// 30 31 33 36 39 41 42
//
// Finally it revisits the vertices on the ray (except for the center
// which is part of the border at all times). In order to determine
// whether the final configurations are legal, it is necessary to keep
// track of the fate of the strings on the initial ray which lack
// liberties. The possible outcomes for each string is that it found a
// liberty, that it disappeared without finding a liberty, or that it
// remains on the border. In the latter case it is also necessary to
// know where on the border it is. Naturally there will also be an
// outer loop over all initial ray configurations.
//
// The internal representation of the border state is a string in two
// parts. The first part has the same length as the initial ray, i.e.
// N for a (2N-1)x(2N-1) board. It contains the following characters:
//
// X: A black stone with at least one liberty guaranteed.
// O: A white stone with at least one liberty guaranteed.
// .: An empty vertex.
// |: An edge vertex, only used while creating the initial ray
//    configurations.
// s: White string without liberty and no other stones on the border
// u: White string without liberty and more stones further out
//    on the border, but none closer to the center.
// d: White string without liberty and more stones closer to the center
//    but none further out.
// b: White string without liberty and more stones both closer to the
//    center and further out on the border.
// S, U, D, B: Corresponding for black.
//
// (The symbols are somewhat historic, related to an earlier vertical
// scanning algorithm, "single", "up", "down", "both".)
//
// For strings without liberties the connectivity between the border
// stones can be determined from the symbols in the state and from the
// non-crossing property of strings.
//
// There is clearly no need to keep track of connectivity for stones
// with liberties.
//
// The second part of the state consists of M characters, where M is
// the number of strings without liberties in the initial ray. M can
// easily be determined by summing the number of "s", "S", "u", and
// "U". The symbols are:
//
// .: The string found a liberty.
// !: The string ended without finding a liberty.
// a,b,c,...: The string has not found a liberty and is still part of
//    the border, with the first (counting from the center) stone found
//    at the center if "a", one step out from the center if "b", and so
//    on.
//
// Examples:
//
// O O O O O O O O O O O
// O O O O O O O O O O O
// O O O X X X X X X O O
// O O O X O O O O X O .
// O O O X O O X O X O X
// O O O X O O-X-O-X-O-X
// O O O X O O X O X O X
// O O O X O O X X X O X
// O O O X O O O O O O X
// O O O X X X X X X X X
// O O O O O O O O O O O
//
// The initial state would be "sSsSsSabcdef". When the upper vertical
// ray has been reached, the state would be "ubdSOOa|ad..". After 180
// degrees "udSOOOa|ac..", after 270 degrees "ubbdSOa|ae..", and after
// having traversed the initial ray a second time "uUsDdSa|af..".
//
// O O O O O O O O O O O
// O O O O O O O O O O O
// O O O X X X X X X O O
// O O O X O O O O X O .
// O O O X O O X O X O X
// O O O X O O-X-O-X-O-X
// O O O X O O X O X O X
// O O O X X X X O X X X
// O O O O O O O O O O O
// O O O O O O O O O O O
// O O O O O O O O O O O
//
// This would also start as "sSsSsSabcdef", and finish as "sSOUsDa|ab..".
//
// In both cases the second initial string has disappeared without
// liberties, but that is not fatal as they can be provided "from below".
// In general it can be determined from the starting and finishing states
// whether the board is legal.
//
// It should be noted that all possible board configurations outside
// of the starting ray are analyzed in parallel while scanning over
// the board, by maintaining a count of the number of board
// configurations giving rise to each border state.
//
// During the computation of new state the state string is converted
// into an array of single-character strings. This is because strings
// are immutable in Pike but arrays can be destructively modified.
//
// Results for quadratic boards computed by this program:
//
// 1x1   1
// 3x3   12675
// 5x5   414295148741
// 7x7   83677847847984287628595
// 9x9   103919148791293834318983090438798793469
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

void change_state(array(string) state, int k, string s, int N)
{
  if (!has_value("sSuU", state[k])) {
    state[k] = s;
    return;
  }

  if (has_value("OX.", s))
  {
    string position = sprintf("%c", 'a' + k);
    for (int j = N; j < sizeof(state); j++)
      if (state[j] == position)
	state[j] = ".";
  }
  state[k] = s;
}

void move_origin(array(string) state, int from, int to, int N)
{
  string from_pos = sprintf("%c", 'a' + from);
  string to_pos;
  if (to < 0)
    to_pos = "|";
  else
    to_pos = sprintf("%c", 'a' + to);
  
  for (int j = N; j < sizeof(state); j++)
    if (state[j] == from_pos)
      state[j] = to_pos;
}
  

array(string) string_obtained_liberty(array(string) state, int i,
				      string color, int N)
{
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
    for (k = i + 1; k < N; k++) {
      if (state[k] == up)
	nesting++;
      else if (state[k] == down) {
	if (nesting == 0) {
	  change_state(state, k, color, N);
	  break;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0)
	change_state(state, k, color, N);
    }

  if (state[i] == down || state[i] == both)
    for (k = i - 1; k >= 0; k--) {
      if (state[k] == down)
	nesting++;
      else if (state[k] == up) {
	if (nesting == 0) {
	  change_state(state, k, color, N);
	  break;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0)
	change_state(state, k, color, N);
    }

  change_state(state, i, color, N);
  
  return state;
}

array(string) remove_from_string(array(string) state, int i,
				 array(string) string_symbols, int N)
{
  string single = string_symbols[0];
  string up = string_symbols[1];
  string down = string_symbols[2];
  string both = string_symbols[3];
  int k;

  int nesting = 0;
  if (state[i] == up)
    for (k = i + 1; k < N; k++) {
      if (state[k] == up)
	nesting++;
      else if (state[k] == down) {
	if (nesting == 0) {
	  state[k] = single;
	  move_origin(state, i, k, N);
	  return state;
	}
	else
	  nesting--;
      }
      else if (state[k] == both && nesting == 0) {
	state[k] = up;
	move_origin(state, i, k, N);
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

  if (state[i] == single)
    move_origin(state, i, -1, N);
    
  return state;
}

int find_lower_end(array(string) state, int i, array(string) string_symbols)
{
  string single = string_symbols[0];
  string up = string_symbols[1];
  string down = string_symbols[2];
  string both = string_symbols[3];

  if (state[i] == single || state[i] == up)
    return i;
  
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

int find_upper_end(array(string) state, int i, array(string) string_symbols,
		   int N)
{
  string single = string_symbols[0];
  string up = string_symbols[1];
  string down = string_symbols[2];
  string both = string_symbols[3];

  int k;
  int nesting = 0;
  for (k = i + 1; k < N; k++) {
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
				   int i, int N, int single_neighbor,
				   string|void allowed_value)
{
  mapping(string:int) new_state_count = ([]);
  array(string) allowed_values;
  if (allowed_value)
    allowed_values = ({allowed_value});
  else
    allowed_values = ({"empty", "black", "white"});

  string position = sprintf("%c", 'a' + i);
  
  // Loop over the previous states.
  foreach (indices(old_state_count), string state)
    // Add an empty vertex, a black stone, and a white stone in turn.
    foreach (allowed_values, string new_stone) {
      // Convert the state string to a state array.
      array(string) new_state = state / "";
      
      // What matters in the computation of the new state is what
      // we have to the left and below. If we are at the bottom of
      // the column the neighbor below is the edge symbol "|".
      string left = new_state[i];
      string down = single_neighbor ? "|" : new_state[i-1];
      
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
	  new_state = string_obtained_liberty(new_state, i, "X", N);
	if (black_string_down)
	  new_state = string_obtained_liberty(new_state, i-1, "X", N);
	if (white_string_left)
	  new_state = string_obtained_liberty(new_state, i, "O", N);
	if (white_string_down)
	  new_state = string_obtained_liberty(new_state, i-1, "O", N);
	new_state[i] = ".";
	break;
	
      case "black":
	// If we have a white string without liberties to the left and
	// this was its last stone on the border, it can no longer get
	// any liberty and thus the configuration is illegal. However,
	// if this was one of the inital strings, we are still in the
	// game.
	if (left == "s") {
	  if (!has_value(new_state[N..], position)) {
	    bad_state = 1;
	    break;
	  }
	}

	if (white_string_left)
	  new_state = remove_from_string(new_state, i, white_strings, N);
	
	// If we have at least one empty vertex or a black stone
	// with liberty to the left or to the right, the new stone
	// will also have at least one liberty.
	if (has_value("X.", left) || has_value("X.", down)) {
	  // Furthermore, if the other neighbor was a black string
	  // without liberties, it has also received a liberty
	  // now.
	  if (black_string_left)
	    new_state = string_obtained_liberty(new_state, i, "X", N);
	  else if (black_string_down)
	    new_state = string_obtained_liberty(new_state, i-1, "X", N);
	  new_state[i] = "X";
	}
	else if (black_string_left && black_string_down) {
	  // Both neighbors are black strings without liberties.
	  // These need to be merged and the new string will also
	  // lack liberties. There is no need to set the state at
	  // the current position explicitly as it will be part of
	  // the string inherited from the left.
	  if (down == "S") {
	    if (left == "S") {
	      new_state[i-1] = "U";
	      new_state[i] = "D";
	      move_origin(new_state, i, i-1, N);
	    }
	    else if (left == "U") {
	      new_state[i-1] = "U";
	      new_state[i] = "B";
	      move_origin(new_state, i, i-1, N);
	    }
	    else if (left == "D" || left == "B") {
	      new_state[i-1] = "B";
	    }
	  }
	  else if (down == "D") {
	    if (left == "S") {
	      int j = find_lower_end(new_state, i-1, black_strings);
	      new_state[i-1] = "B";
	      new_state[i] = "D";
	      move_origin(new_state, i, j, N);
	    }
	    else if (left == "U") {
	      int j = find_lower_end(new_state, i-1, black_strings);
	      new_state[i-1] = "B";
	      new_state[i] = "B";
	      move_origin(new_state, i, j, N);
	    }
	    else if (left == "D" || left == "B") {
	      int j = find_lower_end(new_state, i-1, black_strings);
	      new_state[i-1] = "B";
	      new_state[j] = "B";
	    }
	  }
	  else if (down == "U" || down == "B") {
	    if (left == "S") {
	      int j = find_lower_end(new_state, i-1, black_strings);
	      new_state[i] = "B";
	      move_origin(new_state, i, j, N);
	    }
	    else if (left == "U") {
	      int j = find_upper_end(new_state, i, black_strings, N);
	      int k = find_lower_end(new_state, i-1, black_strings);
	      new_state[i] = "B";
	      new_state[j] = "B";
	      move_origin(new_state, i, k, N);
	    }
	  }
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
	  if (!has_value(new_state[N..], position)) {
	    bad_state = 1;
	    break;
	  }
	}

	if (black_string_left)
	  new_state = remove_from_string(new_state, i, black_strings, N);
	
	if (has_value("O.", left) || has_value("O.", down)) {
	  if (white_string_left)
	    new_state = string_obtained_liberty(new_state, i, "O", N);
	  else if (white_string_down)
	    new_state = string_obtained_liberty(new_state, i-1, "O", N);
	  new_state[i] = "O";
	}
	else if (white_string_left && white_string_down) {
	  if (down == "s") {
	    if (left == "s") {
	      new_state[i-1] = "u";
	      new_state[i] = "d";
	      move_origin(new_state, i, i-1, N);
	    }
	    else if (left == "u") {
	      new_state[i-1] = "u";
	      new_state[i] = "b";
	      move_origin(new_state, i, i-1, N);
	    }
	    else if (left == "d" || left == "b") {
	      new_state[i-1] = "b";
	    }
	  }
	  else if (down == "d") {
	    if (left == "s") {
	      int j = find_lower_end(new_state, i-1, white_strings);
	      new_state[i-1] = "b";
	      new_state[i] = "d";
	      move_origin(new_state, i, j, N);
	    }
	    else if (left == "u") {
	      int j = find_lower_end(new_state, i-1, white_strings);
	      new_state[i-1] = "b";
	      new_state[i] = "b";
	      move_origin(new_state, i, j, N);
	    }
	    else if (left == "d" || left == "b") {
	      int j = find_lower_end(new_state, i-1, white_strings);
	      new_state[i-1] = "b";
	      new_state[j] = "b";
	    }
	  }
	  else if (down == "u" || down == "b") {
	    if (left == "s") {
	      int j = find_lower_end(new_state, i-1, white_strings);
	      new_state[i] = "b";
	      move_origin(new_state, i, j, N);
	    }
	    else if (left == "u") {
	      int j = find_upper_end(new_state, i, white_strings, N);
	      int k = find_lower_end(new_state, i-1, white_strings);
	      new_state[i] = "b";
	      new_state[j] = "b";
	      move_origin(new_state, i, k, N);
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

//      write("foo: %s  %s %d %s %s %s %d\n", state, new_state*"",i,new_stone,left,down, bad_state);
      // Throw away bad configurations. Add good ones to the state count.
      if (!bad_state)
	new_state_count[new_state * ""] += old_state_count[state];
    }

  write("state size: %d\n", sizeof(new_state_count));
  
  return new_state_count;
}

int legal_starting_and_finishing_states(string initial_state,
					string state, int N)
{
  array(string) state_array = state / "";

  int found_one = 1;

  while (found_one) {
    found_one = 0;
//    write("foo1: %s\n", state_array * "");
    for (int k = 0; k < N; k++) {
      if (has_value("OX.", state_array[k])) {
	string position = sprintf("%c", 'a' + k);
	int j = search(initial_state[N..], position);
	if (j >= 0) {
	  if (state_array[N + j] != ".") {
	    found_one = 1;
	    if (state_array[N + j] == "|")
	      state_array[N + j] = ".";
	    else {
	      int i = state_array[N + j][0] - 'a';
	      string color = "";
	      if (has_value("sudb", state_array[i]))
		color = "O";
	      else if (has_value("SUDB", state_array[i]))
		color = "X";

	      if (color != "")
		state_array = string_obtained_liberty(state_array, i,
						      color, N);
	      else
		state_array[N + j] = ".";
	    }
	  }
	}
      }
    }
//    write("foo2: %s\n", state_array * "");
    for (int k = N; k < sizeof(state_array); k++) {
      if (state_array[k] == ".") {
	int j = initial_state[k] - 'a';
	string color;
	if (has_value("sudb", state_array[j]))
	  color = "O";
	else if (has_value("SUDB", state_array[j]))
	  color = "X";
	else
	  continue;
	
	state_array = string_obtained_liberty(state_array, j, color, N);
	found_one = 1;
      }
    }
  }
  
  return (state_array * "" - "." - "X" - "O" == "");
}
  
int rotating_border_analysis(string initial_state, int N)
{
  mapping(string:int) state_count = ([initial_state:1]);
  for (int k = 0; k < 4; k++) {
    for (int j = 1; j < N; j++)
      for (int i = j; i < N; i++)
	state_count = add_one_vertex(state_count, i, N, i == j);
    
    for (int j = N-1; j >= 1; j--)
      for (int i = j; i < N; i++) {
	if (k == 3 && j == 1) {
	  string color;
	  if (has_value("Osudb", initial_state[i..i]))
	    color = "white";
	  else if (has_value("XSUDB", initial_state[i..i]))
	    color = "black";
	  else
	    color = "empty";
	  
	  state_count = add_one_vertex(state_count, i, N, 0, color);
	}
	else
	  state_count = add_one_vertex(state_count, i, N, 0);
      }
  }
  // Determine which states are legal.
  int sum = 0;
  foreach (indices(state_count), string state)
    if (legal_starting_and_finishing_states(initial_state, state, N))
      sum += state_count[state];
#if 0
    else
      write("foo: %s %s %d\n", initial_state, state, state_count[state]);
#endif

#if 0
  foreach (state_count;string state;int n)
    write("  %s: %d\n", state, n);
#endif
  return sum;
}

// Count the number of legal boards of the given size.
int count_legal_boards(int side)
{
  if (!(side % 2)) {
    werror("The size must be odd.");
    exit(1);
  }
    
  // The border state count is represented by a mapping which
  // associates each border state string with the number of
  // configurations of the stones placed on the board so far having
  // that border state.
  mapping(string:int) initial_states = ([]);

  int N = (side + 1) / 2;
  
  // The initial state is "|" repeated height times, e.g. "|||||"
  // for 5xN boards.
  string edge = "|" * N;
  initial_states[edge] = 1;
  
  // Keep track of the maximum number of border states for statistics.
  int max_number_of_border_states = 0;

#if 1
  // Traverse the initial ray.
  for (int i = 0; i < N; i++) {
    initial_states = add_one_vertex(initial_states, i, N, i == 0);
  }
#else
  initial_states = (["sSsS":1]);
#endif
  
  // Now loop over the initial ray configurations.
  int sum = 0;
  foreach (indices(initial_states), string initial_state) {
    // Add positions for liberty-less strings to the state.
    for (int k = 0; k < N; k++)
      if (has_value("sSuU", initial_state[k..k]))
	initial_state += sprintf("%c", 'a' + k);
    
    int n = rotating_border_analysis(initial_state, N);
#if 0
    write("%s: %d\n", initial_state, n);
#endif
    sum += n;
  }

#if 0
  // Print statistics.
  write("Max number of border states: %d\n",
	max_number_of_border_states);
#endif
  return sum;
}


int main(int argc, array(string) argv)
{
  if (argc < 2) {
    werror("Usage: pike legal5.pike side\n");
    exit(1);
  }
  
  int side = (int) argv[1];
  
  int num_legal = count_legal_boards(side);

  // If the board is too large, we cannot convert to float before the
  // division to compute the fraction of legal boards since that would
  // cause overflow. With this trick we use bignum integers in the
  // division and get a result that is safe to convert to float.
  write("%dx%d: %d (%2.4f%%) legal boards\n", side, side, num_legal,
	0.000001 * (100000000 * num_legal / pow(3, side*side)));

  // Signal successful execution.
  return 0;
}
