all:
	bison -v -d parser.y
	flex lex.l
	gcc -o parser lex.yy.c parser.tab.c -ly -ll
clean:
	rm -f parser.tab.c
	rm -f parser.tab.h
	rm -f parser.output
	rm -f parser
	rm -f lex.yy.c
