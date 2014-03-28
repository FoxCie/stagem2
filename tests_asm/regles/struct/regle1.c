#include <stdlib.h>

struct S
{
	int a;
	int *b;
};

void init_struct(struct S *s)
{
	s->a = 0;
	s->b = NULL;
}

int main(int argc, char *argv[])
{
	struct S s;

	init_struct(&s);

	return EXIT_SUCCESS;
}

