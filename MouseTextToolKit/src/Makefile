
include ../../build/rules.mak

EXT := \#066100

all: MTTK$(EXT)

MTTK$(EXT): MouseTextToolKit.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/MTXKIT.ABS.bin $@

listings: MouseTextToolKit.list.pdf MouseTextToolKitDefines.list.pdf
