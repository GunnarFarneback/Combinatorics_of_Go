#!/usr/bin/env pike

//    max_neighbors.pike - Count the maximum number of neighbor
//    strings for a single string on a go board.
//
//    Copyright 2007 by Gunnar Farnebäck
//    gunnar@lysator.liu.se
//
//    You are free to do whatever you want with this code.
//
//
// This program computes the maximum number of neighbor strings for a
// single string on a rectangular go board of a given size. It is
// efficient enough to handle boards up to 10x10 in less than an hour.
// For rectangular boards MxN, large N can be handled efficiently as
// long as M is kept small.
//
// The internal representation of the border state is a string with a
// length equaling the height of the board and containing the
// following characters:
//
// .: An empty vertex.
// |: An edge vertex, only used initially while traversing the first column.
// (: Start of a black string.
// -: Continuation of a black string.
// ): End of a black string.
// *: Single stone black string.
// o: White stone without empty or black neighbor.
// O: White stone with empty neighbor but without black neighbor.
// n: White stone without empty neighbor but with black neighbor.
// N: White stone with empty and black neighbors.
//
// Additionally the state string is preceded by an L if a liberty for
// a black stone has been found.
//
// The key observation for counting the maximum number of neighbor
// strings of a single string efficiently is that there is no need to
// consider boards with multiple black strings. Thus we throw away
// boards where not all stones are eventually joined into a single
// string. Similarly we only need to consider boards where the white
// strings consist of single stones adjacent to black stones. We keep
// track of the number of white stones placed on the board.
//
// Results obtained with this code:
// size  max neighbors   max states
// 1x1          0                 3
// 2x2          1                14
// 3x3          4                70
// 4x4          6               238
// 5x5         10               834
// 6x6         13              2989
// 7x7         18             11072
// 8x8         24             41908
// 9x9         31            162038
// 10x10       40            636798
// 11x11       46           2538246
//
// The max states count is roughly increasing as 4^N on an NxN board
// around N=11, so for 19x19 this would be about 1.7*10^11 states.

// Count the maximum number of neighbor strings of a single string on
// a board of the given size.
int count_maximum_neighbor_strings_of_single_string(int height, int width)
{
  // The border state count is represented by a mapping which
  // associates each border state string with the maximum number of
  // liberties placed on the board so far having that border state.
  mapping(string:int) new_state_count = ([]);
  mapping(string:int) old_state_count = ([]);
  
  // The initial state is "|" repeated height times, e.g. "|||||"
  // for 5xN boards.
  string edge = "|" * height;
  new_state_count[edge] = 0;

  // Biggest number of neighbor strings found for a finished string so far.
  int max_neighbors = 0;
  
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
	// Add an empty vertex and a black stone in turn.
	foreach (({"empty", "black", "white"}), string new_stone) {
	  // Convert the state string to a state array.
	  array(string) new_state = state / "";
	  int black_liberty_found = 0;
	  if (state[0] == 'L') {
	    black_liberty_found = 1;
	    new_state = new_state[1..];
	  }
	  
	  // Newly found liberties;
	  int new_neighbors = 0;

	  // What matters in the computation of the new state is what
	  // we have to the left and below. If we are at the bottom of
	  // the column the neighbor below is the edge symbol "|".
	  string left = new_state[i];
	  string down = (i == 0) ? "|" : new_state[i-1];
	  int left_is_black = has_value("(-)*", left);
	  int left_is_white = has_value("oOnN", left);
	  int left_is_empty = has_value(".", left);
	  int down_is_black = has_value("(-)*", down);
	  int down_is_white = has_value("oOnN", down);
	  int down_is_empty = has_value(".", down);

	  // If we find that a black string has been finished we set
	  // this to one. If that was the only string on the board its
	  // liberties are recorded. This is also done for white
	  // strings that would be extended to multiple stones or not
	  // gain any liberty or black neighbor.
	  int bad_state = 0;

	  // Handle each addition case by case.
	  switch (new_stone) {
	  case "empty":
	    new_state[i] = ".";
	    if (down == "o")
	      new_state[i-1] = "O";
	    else if (down == "n")
	      new_state[i-1] = "N";
	    if (down_is_black || left_is_black)
	      black_liberty_found = 1;
	    if (left == "o" || left == "O") {
	      bad_state = 1;
	    }
	    else if (left == "*") {
	      // A string was finished.
	      if (state - "." - "|" - "o" - "O" - "n" - "N" -"L" == "*"
		  && black_liberty_found
		  && !has_value(state, "o")
		  && !has_value(state, "O")
		  && !has_value(state, "n")
		  && old_state_count[state] > max_neighbors) {
		max_neighbors = old_state_count[state];
//		write("bax %s %d\n", state, max_neighbors);
	      }
	      bad_state = 1;
	    }
	    else if (left == "(") {
	      int depth = 0;
	      for (int m = i + 1; m < height; m++) {
		if (new_state[m] == "(")
		  depth++;
		else if (new_state[m] == ")") {
		  if (depth > 0)
		    depth--;
		  else {
		    new_state[m] = "*";
		    break;
		  }
		}
		else if (new_state[m] == "-") {
		  if (depth == 0) {
		    new_state[m] = "(";
		    break;
		  }
		}
	      }
	      if (depth > 0) {
		werror("Assertion failed.\n");
		exit(1);
	      }
	    }
	    else if (left == ")") {
	      int depth = 0;
	      for (int m = i - 1; m >= 0; m--) {
		if (new_state[m] == ")")
		  depth++;
		else if (new_state[m] == "(") {
		  if (depth > 0)
		    depth--;
		  else {
		    new_state[m] = "*";
		    break;
		  }
		}
		else if (new_state[m] == "-") {
		  if (depth == 0) {
		    new_state[m] = ")";
		    break;
		  }
		}
	      }
	      if (depth > 0) {
		werror("Assertion failed.\n");
		exit(1);
	      }
	    }
	    break;
	    
	  case "black":
	    if (down == "o")
	      new_state[i - 1] = "n";
	    else if (down == "O")
	      new_state[i - 1] = "N";
	    if (left == "o" || left == "n")
	      bad_state = 1;

	    if (left == "." || down == ".")
	      black_liberty_found = 1;

	    if (!left_is_black && !down_is_black)
	      new_state[i] = "*";
	    else if (!left_is_black && down_is_black) {
	      if (down == "*") {
		new_state[i - 1] = "(";
		new_state[i] = ")";
	      }
	      else if (down == ")") {
		new_state[i - 1] = "-";
		new_state[i] = ")";
	      }
	      else
		new_state[i] = "-";
	    }
	    else if (left_is_black && down_is_black) {
	      if (down == "*") {
		if (left == "*") {
		  new_state[i - 1] = "(";
		  new_state[i] = ")";
		}
		else if (left == "(") {
		  new_state[i - 1] = "(";
		  new_state[i] = "-";
		}
		else
		  new_state[i - 1] = "-";
	      }
	      else if (left == "*") {
		if (down == ")") {
		  new_state[i - 1] = "-";
		  new_state[i] = ")";
		}
		else
		  new_state[i] = "-";
	      }
	      else if (down == ")" && left == "(") {
		new_state[i - 1] = "-";
		new_state[i] = "-";
	      }
	      else if (left == "(" && (down == "(" || down == "-")) {
		new_state[i] = "-";
		int depth = 0;
		for (int m = i + 1; m < height; m++) {
		  if (new_state[m] == "(")
		    depth++;
		  else if (new_state[m] == ")") {
		    if (depth > 0)
		      depth--;
		    else {
		      new_state[m] = "-";
		      break;
		    }
		  }
		}
		if (depth > 0) {
		  werror("Assertion failed.\n");
		  exit(1);
		}
	      }
	      else if (down == ")" && (left == ")" || left == "-")) {
		new_state[i - 1] = "-";
		int depth = 0;
		for (int m = i - 2; m >= 0; m--) {
		  if (new_state[m] == ")")
		    depth++;
		  else if (new_state[m] == "(") {
		    if (depth > 0)
		      depth--;
		    else {
		      new_state[m] = "-";
		      break;
		    }
		  }
		}
		if (depth > 0) {
		  werror("Assertion failed.\n");
		  exit(1);
		}
	      }
	    }
	    break;
	  case "white":
	    new_neighbors = 1;
	    
	    int has_liberty = down_is_empty || left_is_empty;
	    int has_neighbor = down_is_black || left_is_black;
	    if (!has_liberty && !has_neighbor)
	      new_state[i] = "o";
	    else if (has_liberty && !has_neighbor)
	      new_state[i] = "O";
	    else if (!has_liberty && has_neighbor)
	      new_state[i] = "n";
	    else if (has_liberty && has_neighbor)
	      new_state[i] = "N";
	    
	    if (down_is_white || left_is_white)
	      bad_state = 1;
	    else if (left == "*") {
	      // A string was finished.
	      if (state - "." - "|" - "o" - "O" - "n" - "N" - "L" == "*"
		  && black_liberty_found
		  && new_state[i] == "N"
		  && !has_value(state, "o")
		  && !has_value(state, "O")
		  && !has_value(state, "n")
		  && old_state_count[state] + new_neighbors > max_neighbors) {
		max_neighbors = old_state_count[state] + new_neighbors;
//		write("baz %s %d\n", state, max_neighbors);
	      }
	      bad_state = 1;
	    }
	    else if (left == "(") {
	      int depth = 0;
	      for (int m = i + 1; m < height; m++) {
		if (new_state[m] == "(")
		  depth++;
		else if (new_state[m] == ")") {
		  if (depth > 0)
		    depth--;
		  else {
		    new_state[m] = "*";
		    break;
		  }
		}
		else if (new_state[m] == "-") {
		  if (depth == 0) {
		    new_state[m] = "(";
		    break;
		  }
		}
	      }
	      if (depth > 0) {
		werror("Assertion failed.\n");
		exit(1);
	      }
	    }
	    else if (left == ")") {
	      int depth = 0;
	      for (int m = i - 1; m >= 0; m--) {
		if (new_state[m] == ")")
		  depth++;
		else if (new_state[m] == "(") {
		  if (depth > 0)
		    depth--;
		  else {
		    new_state[m] = "*";
		    break;
		  }
		}
		else if (new_state[m] == "-") {
		  if (depth == 0) {
		    new_state[m] = ")";
		    break;
		  }
		}
	      }
	      if (depth > 0) {
		werror("Assertion failed.\n");
		exit(1);
	      }
	    }
	    break;
	  }

	  // Throw away bad configurations. Add good ones to the state
	  // count if they increase the maximum number of liberties.
	  if (!bad_state) {
	    int number_of_neighbors = old_state_count[state] + new_neighbors;
	    string new_state_string = new_state * "";
	    if (black_liberty_found)
	      new_state_string = "L" + new_state_string;
	    if (new_state_count[new_state_string] <= number_of_neighbors)
	      new_state_count[new_state_string] = number_of_neighbors;
	  }
	}

      // Update statistics.
      if (sizeof(new_state_count) > max_number_of_border_states)
	max_number_of_border_states = sizeof(new_state_count);
//      write("num_states: %d %d %d\n", i, j, sizeof(new_state_count));
      if (0) {
	write("foo\n%O\n", new_state_count);
	mapping(int:int) foo = ([]);
	if (0) {
	  mapping(string:string) translation = (["." : "2",
						 "_" : "3",
						 "|" : "0",
						 "*" : "7",
						 "(" : "6",
						 "-" : "4",
						 ")" : "5"]);
	  foreach (indices(new_state_count), string index) {
	    string new = translation[(reverse(index)/"")[*]] * "";
	    int new2;
	    sscanf(new, "%o", new2);
	    foo[new2] = new_state_count[index];
	  }
	  foreach (reverse(sort(indices(foo))), int index)
	    write("%o %d\n", index, foo[index]);
	}
      }
    }

  // The board has been traversed. The final border states which
  // include multiple strings must be excluded. We do this by finding
  // the maximum state count for state strings only containing a
  // single "(" or "*" character. Neither must there be any "o", "O",
  // or "n" remaining. There must be an initial "L", however.
  foreach (indices(new_state_count), string state) {
    if (sizeof(state - "." - "N" - "-" - ")" - "L") == 1
	&& has_value(state, "L"))
      if (new_state_count[state] >= max_neighbors) {
//	write("bar %s %d\n", state, new_state_count[state]);
	max_neighbors = new_state_count[state];
      }
  }

  // Print statistics.
  write("Max number of border states: %d\n",
	max_number_of_border_states);
  
  return max_neighbors;
}


int main(int argc, array(string) argv)
{
  if (argc < 3) {
    werror("Usage: pike legal.pike height width\n");
    exit(1);
  }
  
  int height = (int) argv[1];
  int width = (int) argv[2];
  
  int max_neighbors = count_maximum_neighbor_strings_of_single_string(height, width);

  write("%dx%d: %d neighbors\n", height, width, max_neighbors);

  // Signal successful execution.
  return 0;
}
