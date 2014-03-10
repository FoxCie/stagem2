#include <stdio.h>
#include <stdlib.h>


int mystrlen(char *s)
{
	char *t = s;

	while (*t++);

	return t-s-1;
}

int main(int argc, char *argv[])
{
	int i;

	for (i = 1 ; i < argc ; i++)
	{
		printf("%s : %i\n", argv[i], mystrlen(argv[i]));
	}

	return EXIT_SUCCESS;
}

