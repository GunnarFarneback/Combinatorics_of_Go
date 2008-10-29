#!/usr/bin/env pike

//    maxstrings2.pike - Count the maximum number of strings on a  go board.
//    Copyright 2006 by Gunnar Farnebäck
//    gunnar@lysator.liu.se
//
//    You are free to do whatever you want with this code.
//
//
// This program computes the maximum number of strings on a
// rectangular go board of a given size. It is efficient enough to
// handle boards up to 13x13 within about an hour. For rectangular
// boards MxN, large N can be handled efficiently as long as M is kept
// small.
//
// The internal representation of the border state is a string with a
// length equaling the height of the board and containing the
// following characters:
//
// X: A black stone with at least one liberty guaranteed.
// O: A white stone with at least one liberty guaranteed.
// x: A black stone with no liberty guaranteed.
// o: A white stone with no liberty guaranteed.
// .: An empty vertex.
// |: An edge vertex, only used initially while traversing the first column.
//
// The key observation for counting the maximum number of strings
// efficiently is that there is no need to consider boards with
// multiple-stone strings (just shorten the string to a single stone
// for an equivalent board). This has two implications. First we can
// throw away any board with adjacent stones of the same color. Second
// there is no need to keep track of connectivity for libertyless
// stones since single stones are never connected. This significantly
// reduces the state space compared to counting of legal boards.
//
// This algoritm differs from maxstrings.pike in only allowing boards
// where the stones are subsets of a checkerboard-pattern.
//
// Results obtained with this code:
// size    max strings   max states
// 1x1          0                 2
// 2x2          2                 7
// 3x3          6                41
// 4x4         12               129
// 5x5         18               353
// 6x6         26               965
// 7x7         37              2637
// 8x8         48              7205
// 9x9         61             19685
// 10x10       76             53781
// 11x11       92            146933
// 12x12      109            401429
// 13x13      129           1096725
//
// The max states count seems to asymptotically approach
// 2.3214*(1+sqrt(3))^N for an NxN board, so for 19x19 this would be
// 456 million states.

// Count the maximum number of strings on a board of the given size.
int count_maximum_number_of_strings(int height, int width)
{
  // The border state count is represented by a mapping which
  // associates each border state string with the maximum number of
  // strings placed on the board so far having that border state.
  mapping(string:int) new_state_count = ([]);
  mapping(string:int) old_state_count = ([]);
  
  // The initial state is "|" repeated height times, e.g. "|||||"
  // for 5xN boards.
  string edge = "|" * height;
  new_state_count[edge] = 0;
  
  // Keep track of the maximum number of border states for statistics.
  int max_number_of_border_states = 0;
  
  // Traverse the board in the order new vertices are added. The outer
  // loop goes from the left to the right and the inner loop from the
  // bottom to the top.
  for (int j = 0; j < width; j++)
    for (int i = 0; i < height; i++) {
      // Move the previous new state count to old_state_count and
      // start over with an empty new_state_count.
      old_state_count = new_state_count;
      new_state_count = ([]);

      // Loop over the previous states.
      foreach (indices(old_state_count), string state)
	// Add an empty vertex, a black stone, and a white stone in turn.
	foreach (({"empty", "black", "white"}), string new_stone) {
	  // Convert the state string to a state array.
	  array(string) new_state = state / "";

	  // What matters in the computation of the new state is what
	  // we have to the left and below. If we are at the bottom of
	  // the column the neighbor below is the edge symbol "|".
	  string left = new_state[i];
	  string down = (i == 0) ? "|" : new_state[i-1];

	  // If we find that the new configuration is illegal we set
	  // this variable to 1 to mark that it should be discarded.
	  // This is also done as soon as a multiple stone string
	  // appears.
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
	    new_state[i] = ".";
	    if (down == "x")
	      new_state[i-1] = "X";
	    else if (down == "o")
	      new_state[i-1] = "O";
	    break;
	    
	  case "black":
	    if ((i + j) % 2 == 0) {
	      bad_state = 1;
	      break;
	    }
	    
	    // If we have a white string without liberties to the
	    // left, it can no longer get any liberty and thus the
	    // configuration is illegal.
	    if (left == "o") {
	      bad_state = 1;
	      break;
	    }

	    // If we have a black stone, with or without liberties, to
	    // the left or down, adding this stone will create a
	    // multiple stone string, and we can discard the state.
	    if (has_value("Xx", left) || has_value("Xx", down)) {
	      bad_state = 1;
	      break;
	    }
	    
	    // If we have an empty vertex to the left or down, the new
	    // stone will have at least one liberty.
	    if (left == "." || down == ".")
	      new_state[i] = "X";
	    else
	      new_state[i] = "x";
	    break;
	    
	  case "white":
	    if ((i + j) % 2 == 1) {
	      bad_state = 1;
	      break;
	    }
	    
	    // This code is identical to the "black" case above but
	    // with reversed roles for black and white. We do not
	    // repeat the comments above.
	    if (left == "x") {
	      bad_state = 1;
	      break;
	    }

	    if (has_value("Oo", left) || has_value("Oo", down)) {
	      bad_state = 1;
	      break;
	    }

	    if (left == "." || down == ".")
	      new_state[i] = "O";
	    else
	      new_state[i] = "o";
	    break;
	  }

	  // Throw away bad configurations. Add good ones to the state
	  // count if they increase the maximum number of strings.
	  if (!bad_state) {
	    int number_of_strings = old_state_count[state] + (new_stone != "empty");
	    if (new_state_count[new_state * ""] < number_of_strings)
	      new_state_count[new_state * ""] = number_of_strings;
	  }
	}

      // Update statistics.
      if (sizeof(new_state_count) > max_number_of_border_states)
	max_number_of_border_states = sizeof(new_state_count);
    }

  // The board has been traversed. The final border states which
  // include black or white strings without liberties correspond to
  // illegal board configurations and must be excluded. We do this by
  // finding the maximum state count for state strings only containing
  // the characters ".", "X", and "O".
  int maximum_number_of_strings = 0;
  string best_state = "";
  foreach (indices(new_state_count), string state) {
    if (sizeof(state - "." - "X" - "O") == 0)
      if (new_state_count[state] > maximum_number_of_strings) {
	maximum_number_of_strings = new_state_count[state];
	best_state = state;
      }
  }

  // Print statistics.
  write("Max number of border states: %d\n",
	max_number_of_border_states);

  write("Best border state: %s\n", best_state);
  
  return maximum_number_of_strings;
}


int main(int argc, array(string) argv)
{
  if (argc < 3) {
    werror("Usage: pike legal.pike height width\n");
    exit(1);
  }
  
  int height = (int) argv[1];
  int width = (int) argv[2];
  
  int max_number_of_strings = count_maximum_number_of_strings(height, width);

  write("%dx%d: %d strings\n", height, width, max_number_of_strings);

  // Signal successful execution.
  return 0;
}
