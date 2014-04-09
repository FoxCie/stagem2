#include <stdlib.h>

struct S
{
	int a;
	int *b;
};

struct T
{
	struct S s;
	int c;
};

struct U
{
	int a;
	int *b;
	int c;
};

void init_S(struct S *s)
{
	s->a = 0;
	s->b = NULL;
}

void init_T(struct T *t)
{
	init_S(&(t->s));
	t->c = 0;
}

void init_U_ab(struct U *u)
{
	u->a = 0;
	u->b = NULL;
}

void init_U(struct U *u)
{
	init_U_ab(u);
	u->c = 0;
}


