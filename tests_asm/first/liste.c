#include <stdio.h>
#include <stdlib.h>


struct Element
{
	void *value;
	struct Element *next;
	struct Element *prev;
};

struct List
{
	struct Element *head;
	struct Element *tail;
};


struct List *emptyList()
{
	struct List *ret = malloc(sizeof *ret);

	ret->head = NULL;
	ret->tail = NULL;

	return ret;
}

void deleteList(struct List **pl)
{
	struct List *l;
	struct Element *e, *prev;
	if (pl == NULL)
		return;

	l = *pl;

	if (l == NULL)
		return;

	e = l->head;
	prev = NULL;

	while (e != NULL)
	{
		prev = e;
		e = e->next;
		free(prev);
	}

	free(l);
	*pl = NULL;
}


void addFirstElement(struct List *l, struct Element *e)
{
	if (l == NULL)
		return;

	if (l->head == NULL)
	{
		l->head = e;
		l->tail = e;
		e->prev = NULL;
		e->next = NULL;
	}
	else
	{
		e->next = l->head;
		e->prev = NULL;
		l->head->prev = e;
		l->head = e;
	}
}

void addLastElement(struct List *l, struct Element *e)
{
	if (l == NULL)
		return;

	if (l->head == NULL)
		addFirstElement(l, e);
	else
	{
		e->prev = l->tail;
		e->next = NULL;
		l->tail->next = e;
		l->tail = e;
	}
}

void addFirstValue(struct List *l, void *value)
{
	struct Element *e = malloc(sizeof *e);

	e->value = value;
	addFirstElement(l, e);
}

void addLastValue(struct List *l, void *value)
{
	struct Element *e = malloc(sizeof *e);

	e->value = value;
	addLastElement(l, e);
}
	
int deleteValue(struct List *l, void *value, int (*cmp)(void *, void *))
{
	struct Element *e;

	if (l == NULL)
		return 0;

	e = l->head;

	while (e != NULL)
	{
		if (cmp(e->value, value) == 0)
		{
			if (e->next == NULL && e->prev == NULL)
			{
				l->head = NULL;
				l->tail = NULL;
			}
			else if (e->next == NULL)
			{
				e->prev->next = NULL;
				l->tail = e->prev;
			}
			else if (e->prev == NULL)
			{
				e->next->prev = NULL;
				l->head = e->next;
			}
			else
			{
				e->next->prev = e->prev;
				e->prev->next = e->next;
			}

			free(e);

			return 1;
		}

		e = e->next;
	}

	return 0;
}

void printList(struct List *l, void (*printValue)(void *))
{
	struct Element *e;

	if (l == NULL)
		return;

	e = l->head;

	printf("[");

	while (e != NULL)
	{
		printValue(e->value);

		e = e->next;
		if (e != NULL)
			printf(" ; ");
	}

	printf("]\n");
}
	
int cmpInt(int *i1, int *i2)
{
	return *i1 - *i2;
}

void printInt(int *value)
{
	printf("%d", *value);
}

int main(int argc, char *argv[])
{
	int i, n;
	struct List *l;
	int *values;

	if (argc < 2)
	{
		printf("usage : %s <n>\n", argv[0]);
		return EXIT_FAILURE;
	}

	n = atoi(argv[1]);
	l = emptyList();
	values = malloc(n * sizeof *values);

	for (i = 0 ; i < n ; i++)
	{
		values[i] = i+1;
	}

	printList(l, (void (*)(void *))printInt);
	for (i = 0 ; i < n ; i++)
	{
		addLastValue(l, &values[i]);
		printList(l, (void (*)(void *))printInt);
	}

	printList(l, (void (*)(void *))printInt);
	for (i = n ; i > 0 ; i--)
	{
		deleteValue(l, &i, (int (*)(void *, void *))cmpInt);
		printList(l, (void (*)(void *))printInt);
	}

	free(values);
	deleteList(&l);

	return EXIT_SUCCESS;
}

	
	

