
include ../../build/rules.mak

RLOAD_EXT := \#060800
RBOOT_EXT := \#060218
REL2ABS_EXT := \#060e00

all: RBOOT$(RBOOT_EXT) RLOAD$(RLOAD_EXT) REL2ABS$(REL2ABS_EXT)

RLOAD$(RLOAD_EXT): RLoad.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/RLOAD$(RLOAD_EXT) $@

RBOOT$(RBOOT_EXT): RBoot.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/RBOOT$(RBOOT_EXT) $@

REL2ABS$(REL2ABS_EXT): Rel2Abs.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/REL2ABS$(REL2ABS_EXT) $@


listings: RBoot.list.pdf RLoad.list.pdf Rel2Abs.list.pdf

clean:
	rm -f *.o
