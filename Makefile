all:
	yacc -v -d parser.y
	lex lex.l
	gcc -o parser lex.yy.c y.tab.c -ly -ll
clean:
	rm -f y.tab.c
	rm -f y.tab.h
	rm -f y.output
	rm -f parser
	rm -f lex.yy.c
