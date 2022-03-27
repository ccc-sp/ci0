CC = gcc
CFLAGS = -w -g -m32
OBJS = cc jit

all: $(OBJS)

cc: cc.c
	$(CC) -E -D__E__ $^ -o cc.i
	$(CC) $(CFLAGS) $^ -o cc

jit: jit.c
	$(CC) $(CFLAGS) $^ -o jit -ldl

clean:
	rm -f $(OBJS)
