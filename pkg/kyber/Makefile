# Makefile para compilar KyberDB B-tree

CC = gcc
CFLAGS = -std=c11 -O2 -Wall -Wextra -fPIC -I.
AR = ar
ARFLAGS = rcs

SOURCES = btree.c wal.c
OBJECTS = $(SOURCES:.c=.o)
LIBRARY = lib/libkyber.a

all: $(LIBRARY)

$(LIBRARY): $(OBJECTS)
	@mkdir -p lib
	$(AR) $(ARFLAGS) $@ $^

%.o: %.c kyber_btree.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(LIBRARY)

.PHONY: all clean
