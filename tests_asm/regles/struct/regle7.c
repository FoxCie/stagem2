#include <stdlib.h>

struct S
{
	int a;
	int *b;
};

struct T1
{
	struct S s;
	int c;
};

struct T2
{
	struct S s;
	int *c;
};

void init_S(struct S *s)
{
	s->a = 0;
	s->b = NULL;
}

void init_T1(struct T1 *t)
{
	init_S(&(t->s));
	t->c = 0;
}

void init_T2(struct T2 *t)
{
	init_S(&(t->s));
	t->c = NULL;
}

