#include "common.h"

int run(int *pc, int *bp, int *sp) {
  int a, cycle; // a: 累積器, cycle: 執行指令數
  int i, *t;    // temps
  // 虛擬機 => pc: 程式計數器, sp: 堆疊暫存器, bp: 框架暫存器
  cycle = 0;
  while (1) {
    i = *pc++; ++cycle;
    if (debug) {
      printInstr(pc-2, code, data); // pc-2, 因為已經 pc++ 過了，而 printInstr 又是落後一個的情況。
    }
    if      (i == LEA) a = (int)(bp + *pc++);                             // load local address 載入區域變數
    else if (i == IMM) a = *pc++;                                         // load immediate 載入立即值
    else if (i == ADDR) { a = *pc; pc++; }                                // load address 載入位址
    else if (i == JMP) pc = (int *)*pc;                                   // jump               躍躍指令
    else if (i == JSR) { *--sp = (int)(pc + 1); pc = (int *)*pc; }        // jump to subroutine 跳到副程式
    else if (i == BZ)  pc = a ? pc + 1 : (int *)*pc;                      // branch if zero     if (a==0) goto m[pc]
    else if (i == BNZ) pc = a ? (int *)*pc : pc + 1;                      // branch if not zero if (a!=0) goto m[pc]
    else if (i == ENT) { *--sp = (int)bp; bp = sp; sp = sp - *pc++; }     // enter subroutine   進入副程式
    else if (i == ADJ) sp = sp + *pc++;                                   // stack adjust       調整堆疊
    else if (i == LEV) { sp = bp; bp = (int *)*sp++; pc = (int *)*sp++; } // leave subroutine   離開副程式
    else if (i == LI)  a = *(int *)a;                                     // load int           載入整數
    else if (i == LC)  a = *(char *)a;                                    // load char          載入字元
    else if (i == SI)  *(int *)*sp++ = a;                                 // store int          儲存整數
    else if (i == SC)  a = *(char *)*sp++ = a;                            // store char         儲存字元
    else if (i == PSH) *--sp = a;                                         // push               推入堆疊

    else if (i == OR)  a = *sp++ |  a; // a = a OR *sp
    else if (i == XOR) a = *sp++ ^  a; // a = a XOR *sp
    else if (i == AND) a = *sp++ &  a; // ...
    else if (i == EQ)  a = *sp++ == a;
    else if (i == NE)  a = *sp++ != a;
    else if (i == LT)  a = *sp++ <  a;
    else if (i == GT)  a = *sp++ >  a;
    else if (i == LE)  a = *sp++ <= a;
    else if (i == GE)  a = *sp++ >= a;
    else if (i == SHL) a = *sp++ << a;
    else if (i == SHR) a = *sp++ >> a;
    else if (i == ADD) a = *sp++ +  a;
    else if (i == SUB) a = *sp++ -  a;
    else if (i == MUL) a = *sp++ *  a;
    else if (i == DIV) a = *sp++ /  a;
    else if (i == MOD) a = *sp++ %  a;

    else if (i == OPEN) a = open((char *)sp[1], *sp); // 開檔
    else if (i == READ) a = read(sp[2], (char *)sp[1], *sp); // 讀檔
    else if (i == WRIT) a = write(sp[2], (char *)sp[1], *sp); // 寫檔
    else if (i == CLOS) a = close(*sp); // 關檔
    else if (i == PRTF) { // PRTF 後面都跟著 ADJ #參數個數
      t = sp + pc[1]; // pc[1] 就是取得 #參數個數，於是 t 指向堆疊參數尾端
      a = printf((char *)t[-1], t[-2], t[-3], t[-4], t[-5], t[-6]);  // printf("....", a, b, c, d, e)
    }
    else if (i == MALC) a = (int)malloc(*sp); // 分配記憶體
    else if (i == FREE) free((void *)*sp); // 釋放記憶體
    else if (i == MSET) a = (int)memset((char *)sp[2], sp[1], *sp); // 設定記憶體
    else if (i == MCMP) a = memcmp((char *)sp[2], (char *)sp[1], *sp); // 比較記憶體
    else if (i == EXIT) { printf("exit(%d) cycle = %d\n", *sp, cycle); return *sp; } // EXIT 離開
    else { printf("unknown instruction = %d! cycle = %d\n", i, cycle); return -1; } // 錯誤處理
  }
}

int vm(int argc, char **argv) {
  int *t;
  // 虛擬機: setup stack
  bp = sp = (int *)((int)stack + poolsz);
  *--sp = EXIT;     // call exit if main returns
  *--sp = PSH; t = sp;
  *--sp = argc;     // 把 argc,argv 放入堆疊，這樣 main(argc,argv) 才能取得到
  *--sp = (int)argv; 
  *--sp = (int)t;   // 推入返回點，於是最後 RET 時會跳回 t=sp 指定的位址，接著呼叫 EXIT 離開。
  return run(pc, bp, sp);
}
