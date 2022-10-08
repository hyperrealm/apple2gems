
include ../../build/rules.mak

EXT := \#ff2000

all : EDIT$(EXT)

LDFLAGS := -C ./apple.cfg


EDIT$(EXT): EdIt.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/EDIT#ff2000 $@

listing: EdIt.list.pdf

clean:
	rm -f *.o *.list *.list.pdf
