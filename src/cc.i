# 1 "cc.c"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "cc.c"
# 1 "common.c" 1
# 9 "common.c"
int fd;
char *iFile, *oFile;
int src,
    debug,
    run,
    o_run,
    o_save,
    o_dump;
int argc0;
char **argv0;

int *idmain,
    ty,
    loc;

int arg_handle(int argc, char **argv) {
  char *narg;

  src = 0;
  debug = 0;
  run = 1;
  o_run = 0;
  o_save = 0;
  o_dump = 0;


  --argc; ++argv;
  if (argc > 0 && **argv == '-' && (*argv)[1] == 's') { src = 1; --argc; ++argv; }
  if (argc > 0 && **argv == '-' && (*argv)[1] == 'd') { debug = 1; --argc; ++argv; }
  if (argc > 0 && **argv == '-' && (*argv)[1] == 'r') { o_run = 1; --argc; ++argv; }
  if (argc > 0 && **argv == '-' && (*argv)[1] == 'n') { run = 0; --argc; ++argv; }
  if (argc > 0 && **argv == '-' && (*argv)[1] == 'u') { o_dump = 1; --argc; ++argv; }
  if (argc < 1) { printf("usage: c6 [-s] [-d] [-r] [-u] in_file [-o] out_file...\n"); return -1; }
  iFile = *argv;
  if (argc > 1) {
    narg = *(argv+1);
    if (*narg == '-' && narg[1] == 'o') {
      o_save = 1;
      oFile = *(argv+2);
    }
  }
  if ((fd = open(iFile, 0100000)) < 0) {
    printf("could not open(%s)\n", iFile);
    return -1;
  }

  argc0 = argc;
  argv0 = argv;
}
# 2 "cc.c" 2
# 1 "obj.c" 1
int *code,
    *stack,
    *sym,
    *entry,
    codeLen,
    dataLen,
    poolsz;

char *data,
     *op;


enum { LEA ,IMM ,ADDR,JMP ,JSR ,BZ ,BNZ ,ENT ,ADJ ,LEV ,LI ,LC ,SI ,SC ,PSH ,
       OR ,XOR ,AND ,EQ ,NE ,LT ,GT ,LE ,GE ,SHL ,SHR ,ADD ,SUB ,MUL ,DIV ,MOD ,
       OPEN,READ,WRIT,CLOS,PRTF,MALC,FREE,MSET,MCMP,EXIT };

int obj_init() {
  poolsz = 256*1024;
  if (!(code = malloc(poolsz))) { printf("could not malloc(%d) text area\n", poolsz); return -1; }
  if (!(data = malloc(poolsz))) { printf("could not malloc(%d) data area\n", poolsz); return -1; }
  if (!(stack = malloc(poolsz))) { printf("could not malloc(%d) stack area\n", poolsz); return -1; }
  if (!(sym = malloc(poolsz))) { printf("could not malloc(%d) symbol area\n", poolsz); return -1; }

  memset(code, 0, poolsz);
  memset(data, 0, poolsz);
  memset(sym, 0, poolsz);

  op = "LEA ,IMM ,ADDR,JMP ,JSR ,BZ  ,BNZ ,ENT ,ADJ ,LEV ,LI  ,LC  ,SI  ,SC  ,PSH ,"
       "OR  ,XOR ,AND ,EQ  ,NE  ,LT  ,GT  ,LE  ,GE  ,SHL ,SHR ,ADD ,SUB ,MUL ,DIV ,MOD ,"
       "OPEN,READ,WRIT,CLOS,PRTF,MALC,FREE,MSET,MCMP,EXIT,";

}

int stepInstr(int *p) {

  if (*++p <= ADJ) return 2; else return 1;
}

void printInstr(int *p, int *code, char *data) {
  int ir, arg;

  ir = *++p;
  printf(" %4d:%X %8.4s", p-code, p, &op[ir * 5]);
  if (ir <= ADJ) {
    arg = *++p;
    if (ir==JSR || ir==JMP || ir==BZ || ir==BNZ) {
      if (arg==0) printf("0?\n"); else printf(" %d:%X\n", (int*)arg-code, (int*)arg);
    } else if (ir==ADDR)
      printf(" %d:%X\n", (char*)arg-data, arg);
    else
      printf(" %d\n", arg);
  } else {
    printf("\n");
  }
}

int obj_relocate(int *code, int codeLen, int *pcode1, char *pdata1, int *pcode2, char *pdata2) {
  int *p, ir;

  p=code;
  while (p<code+codeLen) {
    ir=*++p;
    if (ir <= ADJ) {
      ++p;
      if (ir == ADDR)
        *p = (int)(pdata2+((char*)*p-pdata1));
      else if (ir==JSR || ir==JMP || ir==BZ || ir==BNZ)
        *p = (int)(pcode2+((int*)*p-pcode1));
    }
  }
}

int obj_dump(int *entry, int *code, int codeLen, char *data, int dataLen) {
  int *p, ir, arg, step;
  char *dp;

  printf("entry: 0x%X\n", entry);
  printf("code: start=0x%X length=0x%X\n", code, codeLen);
  p=code;
  while (p<code+codeLen-1) {
    printInstr(p, code, data);
    p = p+stepInstr(p);
  }

  printf("data: start=0x%X length=0x%X\n", data, dataLen);
  dp = data;
  while (dp<data+dataLen) {
    printf("%c", *dp++);
  }
  printf("\n");
}

int obj_save(char *oFile, int *entry, int *code, int codeLen, char *data, int dataLen) {
  int fd, len;


  fd = open(oFile, 0101501, 0666);
  if (fd == -1) { printf("error: obj_save: open fail!\n"); exit(1); }
  write(fd, &entry, sizeof(int));
  write(fd, &code, sizeof(int));
  write(fd, &codeLen, sizeof(int));
  write(fd, &data, sizeof(int));
  write(fd, &dataLen, sizeof(int));
  write(fd, code, codeLen*sizeof(int));
  write(fd, data, dataLen);
  close(fd);
}

int obj_load(int fd) {
  int *codex, len;
  char *datax;

  read(fd, &entry, sizeof(int));
  read(fd, &codex, sizeof(int));
  read(fd, &codeLen, sizeof(int));
  read(fd, &datax, sizeof(int));
  read(fd, &dataLen, sizeof(int));
  len = read(fd, code, codeLen*sizeof(int));
  if (len != codeLen*sizeof(int)) {
    printf("obj_load:read code fail, len(%d)!=size(%d)\n", len, codeLen*sizeof(int));
    exit(1);
  }
  len = read(fd, data, dataLen);
  obj_relocate(code, codeLen, codex, datax, code, data);
  entry = code + (entry-codex);
}
# 3 "cc.c" 2
# 1 "vm.c" 1


int vm_run(int *pc, int *bp, int *sp) {
  int a, cycle;
  int i, *t;

  cycle = 0;
  while (1) {
    i = *pc++; ++cycle;
    if (debug) {
      printInstr(pc-2, code, data);
    }
    if (i == LEA) a = (int)(bp + *pc++);
    else if (i == IMM) a = *pc++;
    else if (i == ADDR) { a = *pc; pc++; }
    else if (i == JMP) pc = (int *)*pc;
    else if (i == JSR) { *--sp = (int)(pc + 1); pc = (int *)*pc; }
    else if (i == BZ) pc = a ? pc + 1 : (int *)*pc;
    else if (i == BNZ) pc = a ? (int *)*pc : pc + 1;
    else if (i == ENT) { *--sp = (int)bp; bp = sp; sp = sp - *pc++; }
    else if (i == ADJ) sp = sp + *pc++;
    else if (i == LEV) { sp = bp; bp = (int *)*sp++; pc = (int *)*sp++; }
    else if (i == LI) a = *(int *)a;
    else if (i == LC) a = *(char *)a;
    else if (i == SI) *(int *)*sp++ = a;
    else if (i == SC) a = *(char *)*sp++ = a;
    else if (i == PSH) *--sp = a;

    else if (i == OR) a = *sp++ | a;
    else if (i == XOR) a = *sp++ ^ a;
    else if (i == AND) a = *sp++ & a;
    else if (i == EQ) a = *sp++ == a;
    else if (i == NE) a = *sp++ != a;
    else if (i == LT) a = *sp++ < a;
    else if (i == GT) a = *sp++ > a;
    else if (i == LE) a = *sp++ <= a;
    else if (i == GE) a = *sp++ >= a;
    else if (i == SHL) a = *sp++ << a;
    else if (i == SHR) a = *sp++ >> a;
    else if (i == ADD) a = *sp++ + a;
    else if (i == SUB) a = *sp++ - a;
    else if (i == MUL) a = *sp++ * a;
    else if (i == DIV) a = *sp++ / a;
    else if (i == MOD) a = *sp++ % a;

    else if (i == OPEN) a = open((char *)sp[1], *sp);
    else if (i == READ) a = read(sp[2], (char *)sp[1], *sp);
    else if (i == WRIT) a = write(sp[2], (char *)sp[1], *sp);
    else if (i == CLOS) a = close(*sp);
    else if (i == PRTF) {
      t = sp + pc[1];
      a = printf((char *)t[-1], t[-2], t[-3], t[-4], t[-5], t[-6]);
    }
    else if (i == MALC) a = (int)malloc(*sp);
    else if (i == FREE) free((void *)*sp);
    else if (i == MSET) a = (int)memset((char *)sp[2], sp[1], *sp);
    else if (i == MCMP) a = memcmp((char *)sp[2], (char *)sp[1], *sp);
    else if (i == EXIT) { printf("exit(%d) cycle = %d\n", *sp, cycle); return *sp; }
    else { printf("unknown instruction = %d! cycle = %d\n", i, cycle); return -1; }
  }
}

int vm(int argc, char **argv) {
  int *t;
  int *bp, *sp;

  bp = sp = (int *)((int)stack + poolsz);
  *--sp = EXIT;
  *--sp = PSH; t = sp;
  *--sp = argc;
  *--sp = (int)argv;
  *--sp = (int)t;
  return vm_run(entry, bp, sp);
}
# 4 "cc.c" 2
# 1 "lex.c" 1
char *source, *p, *lp, *token;
int *id,
    tk,
    ival,
    line;
char *datap;
int *e, *le;
# 16 "lex.c"
enum {
  Num = 128, Fun, Sys, Glo, Loc, Id,
  Assign, Cond, Lor, Lan, Or, Xor, And, Eq, Ne, Lt, Gt, Le, Ge, Shl, Shr, Add, Sub, Mul, Div, Mod, Inc, Dec, Brak
};



enum { Tk, Hash, Name, Class, Type, Val, HClass, HType, HVal, Idsz };


enum { CHAR, INT, PTR };

void next() {
  char *pp;

  while (tk = *p) {
    token = p;
    ++p;
    if (tk == '\n') {
      if (src) {
        printf("%d: %.*s", line, p - lp, lp);
        lp = p;
        while (le < e) {
          printInstr(le, code, data);
          le = le + stepInstr(le);
        }
      }
      ++line;
    }
    else if (tk == '#') {
      while (*p != 0 && *p != '\n') ++p;
    }
    else if ((tk >= 'a' && tk <= 'z') || (tk >= 'A' && tk <= 'Z') || tk == '_') {
      token = pp = p - 1;
      while ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || (*p >= '0' && *p <= '9') || *p == '_')
        tk = tk * 147 + *p++;
      tk = (tk << 6) + (p - pp);
      id = sym;
      while (id[Tk]) {
        if (tk == id[Hash] && !memcmp((char *)id[Name], pp, p - pp)) { tk = id[Tk]; return; }
        id = id + Idsz;
      }
      id[Name] = (int)pp;
      id[Hash] = tk;
      tk = id[Tk] = Id;
      return;
    }
    else if (tk >= '0' && tk <= '9') {
      if (ival = tk - '0') { while (*p >= '0' && *p <= '9') ival = ival * 10 + *p++ - '0'; }
      else if (*p == 'x' || *p == 'X') {
        while ((tk = *++p) && ((tk >= '0' && tk <= '9') || (tk >= 'a' && tk <= 'f') || (tk >= 'A' && tk <= 'F')))
          ival = ival * 16 + (tk & 15) + (tk >= 'A' ? 9 : 0);
      }
      else { while (*p >= '0' && *p <= '7') ival = ival * 8 + *p++ - '0'; }
      tk = Num;
      return;
    }
    else if (tk == '/') {
      if (*p == '/') {
        ++p;
        while (*p != 0 && *p != '\n') ++p;
      }
      else {
        tk = Div;
        return;
      }
    }
    else if (tk == '\'' || tk == '"') {
      pp = datap;
      while (*p != 0 && *p != tk) {
        if ((ival = *p++) == '\\') {
          if ((ival = *p++) == 'n') ival = '\n';
        }
        if (tk == '"') *datap++ = ival;
      }
      ++p;
      if (tk == '"') ival = (int)pp; else tk = Num;
      return;
    }
    else if (tk == '=') { if (*p == '=') { ++p; tk = Eq; } else tk = Assign; return; }
    else if (tk == '+') { if (*p == '+') { ++p; tk = Inc; } else tk = Add; return; }
    else if (tk == '-') { if (*p == '-') { ++p; tk = Dec; } else tk = Sub; return; }
    else if (tk == '!') { if (*p == '=') { ++p; tk = Ne; } return; }
    else if (tk == '<') { if (*p == '=') { ++p; tk = Le; } else if (*p == '<') { ++p; tk = Shl; } else tk = Lt; return; }
    else if (tk == '>') { if (*p == '=') { ++p; tk = Ge; } else if (*p == '>') { ++p; tk = Shr; } else tk = Gt; return; }
    else if (tk == '|') { if (*p == '|') { ++p; tk = Lor; } else tk = Or; return; }
    else if (tk == '&') { if (*p == '&') { ++p; tk = Lan; } else tk = And; return; }
    else if (tk == '^') { tk = Xor; return; }
    else if (tk == '%') { tk = Mod; return; }
    else if (tk == '*') { tk = Mul; return; }
    else if (tk == '[') { tk = Brak; return; }
    else if (tk == '?') { tk = Cond; return; }
    else if (tk == '~' || tk == ';' || tk == '{' || tk == '}' || tk == '(' || tk == ')' || tk == ']' || tk == ',' || tk == ':') return;
  }
}

int skip(int t) {
  if (tk == t) next(); else { printf("%d: %c expected\n", line); exit(-1); }
}

void lex_init(int fd) {
  int i, *t;

  p = "open read write close printf malloc free memset memcmp exit";
  i = OPEN; while (i <= EXIT) { next(); id[Class] = Sys; id[Type] = INT; id[Val] = i++; }

  if (!(source = malloc(poolsz))) { printf("could not malloc(%d) source area\n", poolsz); return -1; }
  if ((i = read(fd, source, poolsz-1)) <= 0) { printf("read() returned %d\n", i); return -1; }
  source[i] = 0;
}

int lex() {
  int bt, i;


  line = 1;
  next();
  while (tk) {
      printf("%04d:%.*s\n", tk, p-token, token);
      next();
  }
}
# 5 "cc.c" 2

enum { Char=256, Else, Enum, If, Int, Return, Sizeof, While };

void expr(int lev) {
  int t, *d;

  if (!tk) { printf("%d: unexpected eof in expression\n", line); exit(-1); }
  else if (tk == Num) { *++e = IMM; *++e = ival; next(); ty = INT; }
  else if (tk == '"') {
    *++e = ADDR; *++e = ival; next();
    while (tk == '"') next();
    datap = (char *)((int)datap + sizeof(int) & -sizeof(int)); ty = PTR;
  }
  else if (tk == Sizeof) {
    next(); if (tk == '(') next(); else { printf("%d: open paren expected in sizeof\n", line); exit(-1); }
    ty = INT; if (tk == Int) next(); else if (tk == Char) { next(); ty = CHAR; }
    while (tk == Mul) { next(); ty = ty + PTR; }
    if (tk == ')') next(); else { printf("%d: close paren expected in sizeof\n", line); exit(-1); }
    *++e = IMM; *++e = (ty == CHAR) ? sizeof(char) : sizeof(int);
    ty = INT;
  }
  else if (tk == Id) {
    d = id; next();
    if (tk == '(') {
      next();
      t = 0;
      while (tk != ')') { expr(Assign); *++e = PSH; ++t; if (tk == ',') next(); }
      next();

      if (d[Class] == Sys) *++e = d[Val];
      else if (d[Class] == Fun) { *++e = JSR; *++e = d[Val]; }
      else { printf("%d: bad function call\n", line); exit(-1); }
      if (t) { *++e = ADJ; *++e = t; }
      ty = d[Type];
    }
    else if (d[Class] == Num) { *++e = IMM; *++e = d[Val]; ty = INT; }
    else {
      if (d[Class] == Loc) { *++e = LEA; *++e = loc - d[Val]; }
      else if (d[Class] == Glo) { *++e = IMM; *++e = d[Val]; }
      else { printf("%d: undefined variable\n", line); exit(-1); }
      *++e = ((ty = d[Type]) == CHAR) ? LC : LI;
    }
  }
  else if (tk == '(') {
    next();
    if (tk == Int || tk == Char) {
      t = (tk == Int) ? INT : CHAR; next();
      while (tk == Mul) { next(); t = t + PTR; }
      if (tk == ')') next(); else { printf("%d: bad cast\n", line); exit(-1); }
      expr(Inc);
      ty = t;
    }
    else {
      expr(Assign);
      if (tk == ')') next(); else { printf("%d: close paren expected\n", line); exit(-1); }
    }
  }
  else if (tk == Mul) {
    next(); expr(Inc);
    if (ty > INT) ty = ty - PTR; else { printf("%d: bad dereference\n", line); exit(-1); }
    *++e = (ty == CHAR) ? LC : LI;
  }
  else if (tk == And) {
    next(); expr(Inc);
    if (*e == LC || *e == LI) --e; else { printf("%d: bad address-of\n", line); exit(-1); }
    ty = ty + PTR;
  }
  else if (tk == '!') { next(); expr(Inc); *++e = PSH; *++e = IMM; *++e = 0; *++e = EQ; ty = INT; }
  else if (tk == '~') { next(); expr(Inc); *++e = PSH; *++e = IMM; *++e = -1; *++e = XOR; ty = INT; }
  else if (tk == Add) { next(); expr(Inc); ty = INT; }
  else if (tk == Sub) {
    next(); *++e = IMM;
    if (tk == Num) { *++e = -ival; next(); } else { *++e = -1; *++e = PSH; expr(Inc); *++e = MUL; }
    ty = INT;
  }
  else if (tk == Inc || tk == Dec) {
    t = tk; next(); expr(Inc);
    if (*e == LC) { *e = PSH; *++e = LC; }
    else if (*e == LI) { *e = PSH; *++e = LI; }
    else { printf("%d: bad lvalue in pre-increment\n", line); exit(-1); }
    *++e = PSH;
    *++e = IMM; *++e = (ty > PTR) ? sizeof(int) : sizeof(char);
    *++e = (t == Inc) ? ADD : SUB;
    *++e = (ty == CHAR) ? SC : SI;
  }
  else { printf("%d: bad expression\n", line); exit(-1); }

  while (tk >= lev) {
    t = ty;
    if (tk == Assign) {
      next();
      if (*e == LC || *e == LI) *e = PSH; else { printf("%d: bad lvalue in assignment\n", line); exit(-1); }
      expr(Assign); *++e = ((ty = t) == CHAR) ? SC : SI;
    }
    else if (tk == Cond) {
      next();
      *++e = BZ; d = ++e;
      expr(Assign);
      if (tk == ':') next(); else { printf("%d: conditional missing colon\n", line); exit(-1); }
      *d = (int)(e + 3); *++e = JMP; d = ++e;
      expr(Cond);
      *d = (int)(e + 1);
    }
    else if (tk == Lor) { next(); *++e = BNZ; d = ++e; expr(Lan); *d = (int)(e + 1); ty = INT; }
    else if (tk == Lan) { next(); *++e = BZ; d = ++e; expr(Or); *d = (int)(e + 1); ty = INT; }
    else if (tk == Or) { next(); *++e = PSH; expr(Xor); *++e = OR; ty = INT; }
    else if (tk == Xor) { next(); *++e = PSH; expr(And); *++e = XOR; ty = INT; }
    else if (tk == And) { next(); *++e = PSH; expr(Eq); *++e = AND; ty = INT; }
    else if (tk == Eq) { next(); *++e = PSH; expr(Lt); *++e = EQ; ty = INT; }
    else if (tk == Ne) { next(); *++e = PSH; expr(Lt); *++e = NE; ty = INT; }
    else if (tk == Lt) { next(); *++e = PSH; expr(Shl); *++e = LT; ty = INT; }
    else if (tk == Gt) { next(); *++e = PSH; expr(Shl); *++e = GT; ty = INT; }
    else if (tk == Le) { next(); *++e = PSH; expr(Shl); *++e = LE; ty = INT; }
    else if (tk == Ge) { next(); *++e = PSH; expr(Shl); *++e = GE; ty = INT; }
    else if (tk == Shl) { next(); *++e = PSH; expr(Add); *++e = SHL; ty = INT; }
    else if (tk == Shr) { next(); *++e = PSH; expr(Add); *++e = SHR; ty = INT; }
    else if (tk == Add) {
      next(); *++e = PSH; expr(Mul);
      if ((ty = t) > PTR) { *++e = PSH; *++e = IMM; *++e = sizeof(int); *++e = MUL; }
      *++e = ADD;
    }
    else if (tk == Sub) {
      next(); *++e = PSH; expr(Mul);
      if (t > PTR && t == ty) { *++e = SUB; *++e = PSH; *++e = IMM; *++e = sizeof(int); *++e = DIV; ty = INT; }
      else if ((ty = t) > PTR) { *++e = PSH; *++e = IMM; *++e = sizeof(int); *++e = MUL; *++e = SUB; }
      else *++e = SUB;
    }
    else if (tk == Mul) { next(); *++e = PSH; expr(Inc); *++e = MUL; ty = INT; }
    else if (tk == Div) { next(); *++e = PSH; expr(Inc); *++e = DIV; ty = INT; }
    else if (tk == Mod) { next(); *++e = PSH; expr(Inc); *++e = MOD; ty = INT; }
    else if (tk == Inc || tk == Dec) {
      if (*e == LC) { *e = PSH; *++e = LC; }
      else if (*e == LI) { *e = PSH; *++e = LI; }
      else { printf("%d: bad lvalue in post-increment\n", line); exit(-1); }
      *++e = PSH; *++e = IMM; *++e = (ty > PTR) ? sizeof(int) : sizeof(char);
      *++e = (tk == Inc) ? ADD : SUB;
      *++e = (ty == CHAR) ? SC : SI;
      *++e = PSH; *++e = IMM; *++e = (ty > PTR) ? sizeof(int) : sizeof(char);
      *++e = (tk == Inc) ? SUB : ADD;
      next();
    }
    else if (tk == Brak) {
      next(); *++e = PSH; expr(Assign);
      if (tk == ']') next(); else { printf("%d: close bracket expected\n", line); exit(-1); }
      if (t > PTR) { *++e = PSH; *++e = IMM; *++e = sizeof(int); *++e = MUL; }
      else if (t < PTR) { printf("%d: pointer type expected\n", line); exit(-1); }
      *++e = ADD;
      *++e = ((ty = t - PTR) == CHAR) ? LC : LI;
    }
    else { printf("%d: compiler error tk=%d\n", line, tk); exit(-1); }
  }
}

void stmt() {
  int *a, *b;

  if (tk == If) {
    next();
    skip('(');
    expr(Assign);
    skip(')');
    *++e = BZ; b = ++e;
    stmt();
    if (tk == Else) {
      *b = (int)(e + 3); *++e = JMP; b = ++e;
      next();
      stmt();
    }
    *b = (int)(e + 1);
  }
  else if (tk == While) {
    next();
    a = e + 1;
    skip('(');
    expr(Assign);
    skip(')');
    *++e = BZ; b = ++e;
    stmt();
    *++e = JMP; *++e = (int)a;
    *b = (int)(e + 1);
  }
  else if (tk == Return) {
    next();
    if (tk != ';') expr(Assign);
    *++e = LEV;
    skip(';');
  }
  else if (tk == '{') {
    next();
    while (tk != '}') stmt();
    next();
  }
  else if (tk == ';') {
    next();
  }
  else {
    expr(Assign);
    skip(';');
  }
}

int prog() {
  int bt, i;

  line = 1;
  next();
  while (tk) {
    bt = INT;
    if (tk == Int) next();
    else if (tk == Char) { next(); bt = CHAR; }
    else if (tk == Enum) {
      next();
      if (tk != '{') next();
      if (tk == '{') {
        next();
        i = 0;
        while (tk != '}') {
          if (tk != Id) { printf("%d: bad enum identifier %d\n", line, tk); return -1; }
          next();
          if (tk == Assign) {
            next();
            if (tk != Num) { printf("%d: bad enum initializer\n", line); return -1; }
            i = ival;
            next();
          }
          id[Class] = Num; id[Type] = INT; id[Val] = i++;
          if (tk == ',') next();
        }
        next();
      }
    }
    while (tk != ';' && tk != '}') {
      ty = bt;
      while (tk == Mul) { next(); ty = ty + PTR; }
      if (tk != Id) { printf("%d: bad global declaration\n", line); return -1; }
      if (id[Class]) { printf("%d: duplicate global definition\n", line); return -1; }
      next();
      id[Type] = ty;
      if (tk == '(') {
        id[Class] = Fun;
        id[Val] = (int)(e + 1);
        next(); i = 0;
        while (tk != ')') {
          ty = INT;
          if (tk == Int) next();
          else if (tk == Char) { next(); ty = CHAR; }
          while (tk == Mul) { next(); ty = ty + PTR; }
          if (tk != Id) { printf("%d: bad parameter declaration\n", line); return -1; }
          if (id[Class] == Loc) { printf("%d: duplicate parameter definition\n", line); return -1; }

          id[HClass] = id[Class]; id[Class] = Loc;
          id[HType] = id[Type]; id[Type] = ty;
          id[HVal] = id[Val]; id[Val] = i++;
          next();
          if (tk == ',') next();
        }
        next();
        if (tk != '{') { printf("%d: bad function definition\n", line); return -1; }
        loc = ++i;
        next();
        while (tk == Int || tk == Char) {
          bt = (tk == Int) ? INT : CHAR;
          next();
          while (tk != ';') {
            ty = bt;
            while (tk == Mul) { next(); ty = ty + PTR; }
            if (tk != Id) { printf("%d: bad local declaration\n", line); return -1; }
            if (id[Class] == Loc) { printf("%d: duplicate local definition\n", line); return -1; }

            id[HClass] = id[Class]; id[Class] = Loc;
            id[HType] = id[Type]; id[Type] = ty;
            id[HVal] = id[Val]; id[Val] = ++i;
            next();
            if (tk == ',') next();
          }
          next();
        }
        *++e = ENT; *++e = i - loc;
        while (tk != '}') stmt();
        *++e = LEV;
        id = sym;
        while (id[Tk]) {
          if (id[Class] == Loc) {
            id[Class] = id[HClass];
            id[Type] = id[HType];
            id[Val] = id[HVal];
          }
          id = id + Idsz;
        }
      }
      else {
        id[Class] = Glo;
        id[Val] = (int)datap;
        datap = datap + sizeof(int);
      }
      if (tk == ',') next();
    }
    next();
  }
  return 0;
}

int compile(int fd) {
  int i;

  lex_init(fd);

  p = "char else enum if int return sizeof while ";
  i = Char; while (i <= While) { next(); id[Tk] = i++; }

  p = "void main";
  next(); id[Tk] = Char;
  next(); idmain = id;

  lp = p = source;

  if (prog()==-1) return -1;

  if (!(entry = (int *)idmain[Val])) { printf("main() not defined\n"); return -1; }
}

# 1 "main.c" 1
int main(int argc, char **argv) {
  arg_handle(argc, argv);
  obj_init();
  le = e = code; datap = data;
  if (o_dump) {
    obj_load(fd);
    obj_dump(entry, code, codeLen, data, dataLen);
    return 0;
  }
  if (o_run) {
    obj_load(fd);
    vm(argc, argv);
    return 0;
  }

  if (compile(fd)==-1) return -1;

  if (src) return 0;
  if (o_save) {
    obj_save(oFile, entry, code, e-code+1, data, datap-data);
    printf("Compile %s success!\nOutput: %s\n", iFile, oFile);
    return 0;
  }
  close(fd);
  if (run) {
    vm(argc0, argv0);
  }
}
# 327 "cc.c" 2
