include ../../build/rules.mak

EXT := \#062000

all: SU2.OBJ$(EXT)

SU2.OBJ$(EXT): SU2.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/SU2.OBJ $@

clean:
#	rm -f *.o *.list *$(EXT) *.list.pdf

listing: SU2.list.pdf
