#include "common.h"

int codeLen, dataLen;

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
  int *codex, *entry, len;
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
  pc = code + (entry-codex);
}
