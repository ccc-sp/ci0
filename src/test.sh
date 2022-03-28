set -x
./run.sh hello
./run.sh sum
./run.sh fib
./cc cc.i ../test/fib.c
./jc -n ../test/hello.j
set -x