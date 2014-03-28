#include <stdlib.h>

struct List
{
	void *val;
	struct List *next;
};

void init_list(struct List *l)
{
	l->next = l;
}


