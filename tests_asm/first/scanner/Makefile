CC = gcc
CFLAGS  = -g
LDFLAGS = -ll
LEX = lex
YACC = bison -y -d

all: intel_scanner

lex.yy.c: scanner_intel.l y.tab.h
	$(LEX) $<

y.tab.c: parse.y
	$(YACC) $<
y.tab.h: y.tab.c

y.tab.o: y.tab.c
	$(CC) $(CFLAGS) -c $<
lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) -c $<

intel_scanner: y.tab.o lex.yy.o
	$(CC) -o $@ $^ $(LDFLAGS)

