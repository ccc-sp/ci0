#ifndef NO_INCLUDE
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <unistd.h>
#include <fcntl.h>
#endif

int fd;
char *iFile, *oFile;
int src,     // print source and assembly flag (印出原始碼)
    debug,   // print executed instructions (印出執行指令 -- 除錯模式)
    run,     // 編譯後執行
    o_run,   // 執行目的檔
    o_save,  // 儲存目的檔
    o_dump;  // 傾印目的檔
int argc0;
char **argv0; 

int *idmain,
    ty,       // current expression type (目前的運算式型態)
    loc;      // local variable offset (區域變數的位移)

int arg_handle(int argc, char **argv) {
  char *narg;

  src = 0; 
  debug = 0;
  run = 1; // 預設要執行
  o_run = 0;
  o_save = 0;
  o_dump = 0;

  // 主程式
  --argc; ++argv; // 略過程式名稱 ./c6
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
  if ((fd = open(iFile, 0100000)) < 0) { // 0100000 代表以 BINARY mode 開啟 (Windows 中預設為 TEXT mode)
    printf("could not open(%s)\n", iFile);
    return -1;
  }

  argc0 = argc;
  argv0 = argv;
}
