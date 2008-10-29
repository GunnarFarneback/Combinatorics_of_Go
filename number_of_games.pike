#!/usr/bin/env pike

#if 0
// 3x3
mapping(int:array(int)) connections = ([0:({1,3}),
					1:({0,2,4}),
					2:({1,5}),
					3:({0,4,6}),
					4:({1,3,5,7}),
					5:({4,2,8}),
					6:({3,7}),
					7:({6,4,8}),
					8:({7,5})
]);
#endif
#if 0
// 2x2
mapping(int:array(int)) connections = ([0:({1,3}),
					1:({2,0}),
					2:({3,1}),
					3:({0,2})]);
#endif
#if 0
// 2x3
mapping(int:array(int)) connections = ([0:({1,2}),
					1:({0,3}),
					2:({0,3,4}),
					3:({1,2,5}),
					4:({2,5}),
					5:({3,4})]);
#endif
#if 0
// 2x4
mapping(int:array(int)) connections = ([0:({1,2}),
					1:({0,3}),
					2:({0,3,4}),
					3:({1,2,5}),
					4:({2,5,6}),
					5:({3,4,7}),
					6:({4,7}),
					7:({5,6})]);
#endif
#if 0
// 1x8
mapping(int:array(int)) connections = ([0:({1}),
					1:({2,0}),
					2:({3,1}),
					3:({4,2}),
					4:({5,3}),
					5:({6,4}),
					6:({7,5}),
					7:({6})]);
#endif
#if 1
// 1x7
mapping(int:array(int)) connections = ([0:({1}),
					1:({2,0}),
					2:({3,1}),
					3:({4,2}),
					4:({5,3}),
					5:({6,4}),
					6:({5})]);
#endif
#if 0
// 1x6
mapping(int:array(int)) connections = ([0:({1}),
					1:({2,0}),
					2:({3,1}),
					3:({4,2}),
					4:({5,3}),
					5:({4})]);
#endif
#if 0
// 1x5
mapping(int:array(int)) connections = ([0:({1}),
					1:({2,0}),
					2:({3,1}),
					3:({4,2}),
					4:({3})]);
#endif
#if 0
// 1x4
mapping(int:array(int)) connections = ([0:({1}),
					1:({2,0}),
					2:({3,1}),
					3:({2})]);
#endif
#if 0
// 1x3
mapping(int:array(int)) connections = ([0:({1}),
					1:({2,0}),
					2:({1})]);
#endif
#if 0
// cyclic 1x3
mapping(int:array(int)) connections = ([0:({1,2}),
					1:({2,0}),
					2:({1,0})]);
#endif
#if 0
// 1x2
mapping(int:array(int)) connections = ([0:({1}),
					1:({0})]);
#endif

int suicide_prohibited = 1;
int use_color_symmetry_equivalence_classes = 1;
int encode_parity = 1;

array(int) find_string(array(string) position, int n)
{
  array(int) stones = ({n});
  string color = position[n];
  for (int k = 0; k < sizeof(stones); k++) {
    foreach (connections[stones[k]] - stones, int neighbor) {
      if (position[neighbor] == color)
	stones += ({neighbor});
    }
  }
  
  return stones;
}

int find_liberty(array(string) position, array(int) stones)
{
  foreach (stones, int stone) {
    foreach (connections[stone], int neighbor) {
      if (position[neighbor] == ".")
	return 1;
    }
  }
  
  return 0;
}

void remove_string(array(string) position, array(int) stones)
{
  foreach (stones, int stone)
    position[stone] = ".";
}

string play_move(string position, int n, string color)
{
  array(string) new_position = position / "";
  if (new_position[n] != ".")
    return "";
  new_position[n] = color;
  array(int) connected_stones;
  foreach (connections[n], int neighbor) {
    if (new_position[neighbor] != "."
	&& new_position[neighbor] != color) {
      connected_stones = find_string(new_position, neighbor);
      if (!find_liberty(new_position, connected_stones))
	remove_string(new_position, connected_stones);
    }
  }
  connected_stones = find_string(new_position, n);
  if (!find_liberty(new_position, connected_stones)) {
    if (sizeof(connected_stones) == 1 || suicide_prohibited)
      return "";
    else
      remove_string(new_position, connected_stones);
  }
  return new_position * "";
}

int main(int argc, array(string) argv)
{
  array(string) positions = ({"." * sizeof(indices(connections))});
  mapping(string:array(string)) transformations = ([]);
  multiset(string) odd_edges = (<>);
  
  for (int k = 0; k < sizeof(positions); k++) {
    string position = positions[k];
    transformations[position] = ({});
    foreach (indices(connections), int j) {
      foreach ("OX" / "", string color) {
	string new_position = play_move(position, j, color);
	if (new_position != "") {
	  if (!has_value(positions, new_position))
	    positions += ({new_position});
	}
	transformations[position] += ({new_position});
      }
    }
  }

  if (use_color_symmetry_equivalence_classes) {
    mapping(string:string) equivalence_classes = ([]);
    mapping(string:array(string)) new_transformations = ([]);

    foreach (positions, string position) {
      if (!equivalence_classes[position]) {
	string companion = replace(position, "OX" / "", "XO" / "");
	string equivalence_class;
	if (position == companion)
	  equivalence_class = position;
	else
	  equivalence_class = position + " + " + companion;
	equivalence_classes[position] = equivalence_class;
	equivalence_classes[companion] = equivalence_class;
      }
    }
    equivalence_classes[""] = "";
    
    foreach (positions, string position) {
      string equivalence_class = equivalence_classes[position];
      if (!new_transformations[equivalence_class]) {
	new_transformations[equivalence_class] = equivalence_classes[transformations[position][*]];
	for (int k = 0; k < sizeof(transformations[position]); k++) {
	  if (has_value(new_transformations[equivalence_class][0..k-1],
			new_transformations[equivalence_class][k]))
	    new_transformations[equivalence_class][k] = "";
	  else if (encode_parity) {
	    int p = (has_prefix(equivalence_class, position)
		     ^ has_prefix(new_transformations[equivalence_class][k],
				  transformations[position][k]));
	    odd_edges[equivalence_class + "->" + new_transformations[equivalence_class][k]] = p;
	  }
	}
	new_transformations[equivalence_class] += ({""}) * (sizeof(transformations[position]) - sizeof(new_transformations[equivalence_class]));
      }
    }
    positions = Array.uniq(equivalence_classes[positions[*]]);
    transformations = new_transformations;
  }

  string connections_table = "";
  for (int k = 0; k < sizeof(positions); k++) {
    string position = positions[k];
    array(int) position_numbers = ({});
    
    foreach (transformations[position], string new_position) {
      int n = search(positions, new_position);
      if (encode_parity && n == -1)
	n = -10000000;
      if (encode_parity && odd_edges[position + "->" + new_position])
	n = -n;
      position_numbers += ({n});
    }
    sort(position_numbers);
    if (encode_parity)
      position_numbers = replace(position_numbers, -10000000, 0);
    connections_table += sprintf("{%s}, /* %2d: %s */\n",
				 sprintf("%2d",
					 reverse(position_numbers)[*]) * ", ",
				 k, position);
  }

  write(c_code, sizeof(positions), sizeof(connections),
	connections_table);
  return 0;
}

string c_code = "\
#include <stdio.h>\n\
\n\
#define NUMBER_OF_STATES %d\n\
#define NUMBER_OF_POINTS %d\n\
\n\
int transformations[NUMBER_OF_STATES][2 * NUMBER_OF_POINTS] = {\n\
%s};\n\
\n\
void play_games(int state, int *visited_states, unsigned long long *n)\n\
{\n\
  int k;\n\
  visited_states[state] = 1;\n\
  (*n)++;\n\
  for (k = 0; k < 2 * NUMBER_OF_POINTS; k++) {\n\
    int next_state = transformations[state][k];\n\
    if (next_state >= 0\n\
	&& !visited_states[next_state])\n\
      play_games(next_state, visited_states, n);\n\
  }\n\
  visited_states[state] = 0;\n\
}\n\
\n\
int main(int argc, char **argv)\n\
{\n\
  unsigned long long n = 0;\n\
  int visited_states[NUMBER_OF_STATES];\n\
  int k;\n\
\n\
  for (k = 0; k < NUMBER_OF_STATES; k++)\n\
    visited_states[k] = 0;\n\
\n\
  play_games(0, visited_states, &n);\n\
  \n\
  printf(\"Number of games: %%Lu\\n\", n);\n\
  return 0;\n\
}\n\
";
