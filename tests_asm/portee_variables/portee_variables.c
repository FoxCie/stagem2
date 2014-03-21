#include <stdio.h>

int fonction(int arg1, char arg2)
{
	static int n = 0;
	int i;

	if (n == 0)
		i = 1;
	else
		i = 0;

	n++;
	if (i == 1)
	{
		printf("Initializing...\n");
	}
	else
	{
		int j = n - 1;
		printf("fonction has been called %d times.\n", j);
	}

	return n;
}

