#include "common.h"

int *code,  // 機器碼
    *sym,   // symbol table (simple list of identifiers) (符號表)
    poolsz; // 分配空間大小
char *data, *op;
int src,      // print source and assembly flag (印出原始碼)
    debug;    // print executed instructions (印出執行指令 -- 除錯模式)

void init() {
  poolsz = 256*1024; // 最大記憶體大小 (程式碼/資料/堆疊/符號表)
  if (!(code = malloc(poolsz))) { printf("could not malloc(%d) text area\n", poolsz); return -1; } // 程式段
  if (!(data = malloc(poolsz))) { printf("could not malloc(%d) data area\n", poolsz); return -1; } // 資料段
  if (!(stack = malloc(poolsz))) { printf("could not malloc(%d) stack area\n", poolsz); return -1; }  // 堆疊段

  memset(code, 0, poolsz);
  memset(data, 0, poolsz);

  op = "LEA ,IMM ,ADDR,JMP ,JSR ,BZ  ,BNZ ,ENT ,ADJ ,LEV ,LI  ,LC  ,SI  ,SC  ,PSH ,"
       "OR  ,XOR ,AND ,EQ  ,NE  ,LT  ,GT  ,LE  ,GE  ,SHL ,SHR ,ADD ,SUB ,MUL ,DIV ,MOD ,"
       "OPEN,READ,WRIT,CLOS,PRTF,MALC,FREE,MSET,MCMP,EXIT,";
}
