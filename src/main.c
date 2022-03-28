int main(int argc, char **argv) {
  arg_handle(argc, argv);
  obj_init();
  le = e = code; datap = data;
  if (o_dump) { // -u: 印出目的檔
    obj_load(fd);
    obj_dump(entry, code, codeLen, data, dataLen);
    return 0;
  }
  if (o_run) { // -r: 執行目的檔
    obj_load(fd);
    vm(argc, argv);
    return 0;
  }

  if (compile(fd)==-1) return -1; // 編譯

  if (src) return 0; // 編譯並列印，不執行
  if (o_save) { // -o 輸出目的檔，但不執行
    obj_save(oFile, entry, code, e-code+1, data, datap-data);
    printf("Compile %s success!\nOutput: %s\n", iFile, oFile);
    return 0;
  }
  close(fd);
  if (run) {
    vm(argc0, argv0); // 用虛擬機執行編譯出來的碼
  }
}
