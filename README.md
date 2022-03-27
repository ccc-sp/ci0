# ci0 -- A Tiny Compiler Infrastructure

* 原作者 -- Robert Swierczek, https://github.com/rswier/
* 原專案 -- https://github.com/rswier/c4
* 修改者 -- 陳鍾誠

## 使用方式

建議在 Linux 下編譯本專案 (WSL 亦可，Windows 的 MinGW 比較容易有錯)

```
$ sudo apt update
$ sudo apt install gcc-multilib

$ cd src

$ make
gcc -E -D__E__ cc.c -o cc.i
gcc -w -g -m32 cc.c -o cc
gcc -w -g -m32 jit.c -o jit -ldl

$ ./test.sh hello
hello, world
exit(13) cycle = 8
Compile ../test/hello.c success!
Output: ../test/hello.o
hello, world

$ ./test.sh sum
sum(10)=55
exit(0) cycle = 303
Compile ../test/sum.c success!
Output: ../test/sum.o
sum(10)=55

$ ./test.sh fib
f(7)=13
exit(1) cycle = 920
Compile ../test/fib.c success!
Output: ../test/fib.o
f(7)=13
```
