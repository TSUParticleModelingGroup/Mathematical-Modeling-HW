//nvcc RandomStudent.cu -o RandomStudent -lglut -lm -lGLU -lGL																													
//To stop hit "control c" in the window you launched it from.
#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>


int main(int argc, char** argv)
{
	
	time_t t;
	int id;
	
	// Seeding the random number generater.
	srand((unsigned) time(&t));
	
	id = rand()%9 + 1;
		
	if(id == 1) printf("\n\n   Mason\n\n");
	if(id == 2) printf("\n\n   Leah\n\n");
	if(id == 3) printf("\n\n   Jamie\n\n");
	if(id == 4) printf("\n\n   Kyle\n\n");
	if(id == 5) printf("\n\n   Veronica\n\n");
	if(id == 6) printf("\n\n   Aron\n\n");
	if(id == 7) printf("\n\n   Kyla\n\n");
	if(id == 8) printf("\n\n   Trevor\n\n");
	if(id == 9) printf("\n\n   Shelby\n\n");
	
	return 0;
}
