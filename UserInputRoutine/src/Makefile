
include ../../build/rules.mak

CONUIR_EXT := \#064000
CONDAMP_EXT := \#fe2000

all:  CONUIR.OBJ$(CONUIR_EXT) CONDAMP.REL$(CONDAMP_EXT)

CONUIR.OBJ$(CONUIR_EXT): ConsoleDriverAndUserInputRoutine.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/CONUIR.OBJ$(CONUIR_EXT) $@

CONDAMP.REL$(CONDAMP_EXT): ConsoleDriverAndUserInputRoutineAmpersand.o
	ld65 $(LDFLAGS) -o $@ $<
	diff ../obj/CONDAMP.REL$(CONDAMP_EXT) $@


listings: ConsoleDriverAndUserInputRoutine.list.pdf

clean:
	rm -f *.o
