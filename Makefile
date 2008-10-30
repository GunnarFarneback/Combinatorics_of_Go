estimate_number_of_games_stratified2: estimate_number_of_games_stratified2.c random.o
	gcc -o estimate_number_of_games_stratified2 estimate_number_of_games_stratified2.c -O3 random.o -lm -Wall

estimate_number_of_games_stratified: estimate_number_of_games_stratified.c random.o
	gcc -o estimate_number_of_games_stratified estimate_number_of_games_stratified.c -O3 random.o -lm -Wall

estimate_number_of_games3: estimate_number_of_games3.c random.o
	gcc -o estimate_number_of_games3 estimate_number_of_games3.c -O3 random.o -lm -Wall

number_of_games_distribution: number_of_games_distribution.c random.o
	gcc -o number_of_games_distribution number_of_games_distribution.c -O3 random.o -lm -Wall

estimate_number_of_games2: estimate_number_of_games2.c random.o
	gcc -o estimate_number_of_games2 estimate_number_of_games2.c -O3 random.o -lm -Wall

estimate_number_of_games: estimate_number_of_games.c random.o
	gcc -o estimate_number_of_games estimate_number_of_games.c -O3 random.o -lm -Wall

random.o: random.c random.h
	gcc -c random.c -O3 -Wall
