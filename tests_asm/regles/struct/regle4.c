#include <stdlib.h>


struct S
{
	int a;
	int *b;
};

int main(int argc, char*argv[])
{
	struct S tab[10];
	int i;

	for (i = 0 ; i < 10 ; i++)
	{
		tab[i].a = 0;
		tab[i].b = NULL;
	}

	return EXIT_SUCCESS;
}

