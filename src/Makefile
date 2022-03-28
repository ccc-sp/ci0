CC = gcc
CFLAGS = -w -g -m32
OBJS = cc jit jc

all: $(OBJS)

jc: jc.c
	$(CC) $(CFLAGS) $^ -o jc

cc: cc.c
	$(CC) -E -DNO_INCLUDE $^ -o cc.i
	$(CC) $(CFLAGS) $^ -o cc

jit: jit.c
	$(CC) $(CFLAGS) $^ -o jit -ldl

clean:
	rm -f $(OBJS) cc.i
