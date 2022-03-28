#ifndef NO_INCLUDE
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <unistd.h>
#include <fcntl.h>
#endif

int *code,   // 機器碼
    *stack,  // 堆疊段
    *entry,  // 進入點
    codeLen, // 程式段長度
    dataLen, // 資料段長度
    poolsz;  // 分配空間大小
int src,     // print source and assembly flag (印出原始碼)
    debug;   // print executed instructions (印出執行指令 -- 除錯模式)
char *data,  // 資料段 
     *op;    // 虛擬機指令列表

// opcodes (機器碼的 op 代號)
enum { LEA ,IMM ,ADDR,JMP ,JSR ,BZ  ,BNZ ,ENT ,ADJ ,LEV ,LI  ,LC  ,SI  ,SC  ,PSH ,
       OR  ,XOR ,AND ,EQ  ,NE  ,LT  ,GT  ,LE  ,GE  ,SHL ,SHR ,ADD ,SUB ,MUL ,DIV ,MOD ,
       OPEN,READ,WRIT,CLOS,PRTF,MALC,FREE,MSET,MCMP,EXIT };

int init() {
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

int stepInstr(int *p) {
  // 傳回下一個指令大小：ADJ 之前有一個參數，之後沒有參數。
  if (*++p <= ADJ) return 2; else return 1;
}

void printInstr(int *p, int *code, char *data) {
  int ir, arg;
  // 印出下一個指令
  ir = *++p;
  printf(" %4d:%X %8.4s", p-code, p, &op[ir * 5]);
  if (ir <= ADJ) { // ADJ 之前的指令有一個參數
    arg = *++p;
    if (ir==JSR || ir==JMP || ir==BZ || ir==BNZ) {
      if (arg==0) printf("0?\n"); else printf(" %d:%X\n", (int*)arg-code, (int*)arg);
    } else if (ir==ADDR)
      printf(" %d:%X\n", (char*)arg-data, arg);
    else 
      printf(" %d\n", arg);
  } else { // ADJ 之後的指令沒有任何參數
    printf("\n");
  }
}

int obj_relocate(int *code, int codeLen, int *pcode1, char *pdata1, int *pcode2, char *pdata2) {
  int *p, ir;
  // 程式段機器碼重定位
  p=code;
  while (p<code+codeLen) {
    ir=*++p;
    if (ir <= ADJ) { // ADJ 之前的指令，有一個參數
      ++p;
      if (ir == ADDR) // 資料位址，重定位
        *p = (int)(pdata2+((char*)*p-pdata1));
      else if (ir==JSR || ir==JMP || ir==BZ  || ir==BNZ) // 跳躍指令，重定位
        *p = (int)(pcode2+((int*)*p-pcode1));
    }
  }
}

int obj_dump(int *entry, int *code, int codeLen, char *data, int dataLen) {
  int *p, ir, arg, step;
  char *dp;
  // 印出目的碼
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
  // 儲存目的檔
  // fd = open(oFile, 0101401, 0666); // Windows: O_BINARY|O_CREAT|O_WRONLY|O_TRUNC=0101401
  fd = open(oFile, 0101501, 0666); // Windows: O_BINARY|O_CREAT|O_WRONLY|O_TRUNC=0101401
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
  int *codex, len; // *entry, 
  char *datax;
  // 載入目的檔
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
