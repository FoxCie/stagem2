#include <stdlib.h>


void fonction(int tab[], int n)
{
	tab[5] = 10;
}

int main(int argc, char *argv[])
{
	int tab[10];

	fonction(tab, 10);

	tab[3] = 4;

	return EXIT_SUCCESS;
}
