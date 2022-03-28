#include "common.c"
#include "obj.c"
#include "vm.c"
#include "lex.c"

enum { If, Else, Return, While };

int compile(int fd) {
  int i;

  lex_init(fd);

  p = "if else return while ";
  i = If; while (i <= While) { next(); id[Tk] = i++; } // add keywords to symbol table

  lp = p = source;
  lex();
  entry = code+1;
}

#include "main.c"
