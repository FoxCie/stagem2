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

void g(struct S *s)
{
	s->a = 0;
	s->b = NULL;
}

void f(struct T *t)
{
	g(&(t->s));
	t->c = 0;
}

void i(struct U *u)
{
	u->a = 0;
	u->b = NULL;
}

void h(struct U *u)
{
	i(u);
	u->c = 0;
}

