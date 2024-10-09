
include ../../build/rules.mak

EXT := \#066100

all: MTTK$(EXT) MTTK.AMP

MTTK$(EXT): MouseTextToolKit.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/MTXKIT.ABS.bin $@

MTTK.AMP: MouseTextAmpersand.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/MTXAMP.OBJ.bin $@

listings: MouseTextToolKit.list.pdf MouseTextToolKitDefines.list.pdf MouseTextAmpersand.list.pdf

clean:
	rm -f *.o
