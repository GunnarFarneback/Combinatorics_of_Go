#!/usr/bin/env pike

//    max_liberties.pike - Count the maximum number of liberties for a
//    single string on a go board.
//
//    Copyright 2006 by Gunnar Farnebäck
//    gunnar@lysator.liu.se
//
//    You are free to do whatever you want with this code.
//
//
// This program computes the maximum number of liberties for a single
// string on a rectangular go board of a given size. It is efficient
// enough to handle boards up to 13x13 in less than an hour. For
// rectangular boards MxN, large N can be handled efficiently as long
// as M is kept small.
//
// The internal representation of the border state is a string with a
// length equaling the height of the board and containing the
// following characters:
//
// .: An empty vertex.
// _: An empty vertex that is a liberty of some stone.
// |: An edge vertex, only used initially while traversing the first column.
// (: Start of a string.
// -: Continuation of a string.
// ): End of a string.
// *: Single stone string.
//
// The key observation for counting the maximum number of liberties of
// a single string efficiently is that there is no need to consider
// boards with multiple strings. Thus we keep track of which empty
// points are adjacent to some stone (i.e. liberties) and throw away
// boards where not all stones are eventually joined into a single
// string.
//
// Results obtained with this code:
// size  max liberties   max states
// 1x1          0                 2
// 2x2          2                 7
// 3x3          6                17
// 4x4          9                46
// 5x5         14               129
// 6x6         22               367
// 7x7         29              1051
// 8x8         38              3022
// 9x9         51              8727
// 10x10       61             25316
// 11x11       74             73794
// 12x12       92            216158
// 13x13      105            636246
// 14x14      122           1881523
// 15x15      145           5588885
//
// The max states count is roughly increasing as 3^N on an NxN board
// around N=15, so for 19x19 this would be about 450 million states. A
// higher order approximation of the state count is
// 0.74021 * 2.77419^N * 1.0023664^(N^2)
// which predicts 457 million states for 19x19.

// Count the maximum number of liberties of a single string on a board
// of the given size.
int count_maximum_liberties_of_single_string(int height, int width)
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

  // Biggest number of liberties found for a finished string so far.
  int max_liberties = 0;
  
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
	foreach (({"empty", "black"}), string new_stone) {
	  // Convert the state string to a state array.
	  array(string) new_state = state / "";

	  // Newly found liberties;
	  int new_liberties = 0;

	  // What matters in the computation of the new state is what
	  // we have to the left and below. If we are at the bottom of
	  // the column the neighbor below is the edge symbol "|".
	  string left = new_state[i];
	  string down = (i == 0) ? "|" : new_state[i-1];
	  int left_is_stone = has_value("(-)*", left);
	  int down_is_stone = has_value("(-)*", down);

	  // If we find that a string has been finished we set this to
	  // one. If that was the only string on the board its
	  // liberties are recorded.
	  int bad_state = 0;

	  // Handle each addition case by case.
	  switch (new_stone) {
	  case "empty":
	    new_state[i] = ".";
	    if (left_is_stone || down_is_stone) {
	      // This is a liberty.
	      new_state[i] = "_";
	      new_liberties++;
	    }
	    if (left == "*") {
	      // A string was finished.
	      if (state - "." - "_" - "|" == "*"
		  && old_state_count[state] + new_liberties > max_liberties)
		max_liberties = old_state_count[state] + new_liberties;
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
	    if (down == ".") {
	      new_state[i - 1] = "_";
	      new_liberties++;
	    }
	    if (left == ".")
	      new_liberties++;

	    if (!left_is_stone && !down_is_stone)
	      new_state[i] = "*";
	    else if (!left_is_stone && down_is_stone) {
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
	    else if (left_is_stone && down_is_stone) {
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
	  }

	  // Throw away bad configurations. Add good ones to the state
	  // count if they increase the maximum number of liberties.
	  if (!bad_state) {
	    int number_of_liberties = old_state_count[state] + new_liberties;
	    if (new_state_count[new_state * ""] <= number_of_liberties)
	      new_state_count[new_state * ""] = number_of_liberties;
	  }
	}

      // Update statistics.
      if (sizeof(new_state_count) > max_number_of_border_states)
	max_number_of_border_states = sizeof(new_state_count);
      write("num_states: %d %d %d\n", i, j, sizeof(new_state_count));
      if (i == 5 && j == 2) {
	write("foo\n%O\n", new_state_count);
	mapping(int:int) foo = ([]);
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

  // The board has been traversed. The final border states which
  // include multiple strings must be excluded. We do this by
  // finding the maximum state count for state strings only containing
  // a single "(" or "*" character.
  foreach (indices(new_state_count), string state) {
    if (sizeof(state - "." - "_" - "-" - ")") == 1)
      if (new_state_count[state] > max_liberties)
	max_liberties = new_state_count[state];
  }

  // Print statistics.
  write("Max number of border states: %d\n",
	max_number_of_border_states);
  
  return max_liberties;
}


int main(int argc, array(string) argv)
{
  if (argc < 3) {
    werror("Usage: pike legal.pike height width\n");
    exit(1);
  }
  
  int height = (int) argv[1];
  int width = (int) argv[2];
  
  int max_liberties = count_maximum_liberties_of_single_string(height, width);

  write("%dx%d: %d liberties\n", height, width, max_liberties);

  // Signal successful execution.
  return 0;
}
