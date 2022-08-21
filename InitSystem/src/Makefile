include ../../build/rules.mak

SYS_EXT := \#FF2000
INIT_EXT := \#2E4000


all: InitSystem$(SYS_EXT) Dummy.Init$(INIT_EXT) DClock.Init$(INIT_EXT) \
	SerialPort.Init$(INIT_EXT)

InitSystem$(SYS_EXT): InitSystem.o
	ld65 $(LDFLAGS) -o $@ $<

Dummy.Init$(INIT_EXT): Dummy.Init.o
	ld65 $(LDFLAGS) -o $@ $<

DClock.Init$(INIT_EXT): DClock.Init.o
	ld65 $(LDFLAGS) -o $@ $<

SerialPort.Init$(INIT_EXT): SerialPort.Init.o
	ld65 $(LDFLAGS) -o $@ $<

clean:
	echo	rm -f *.o *.list *$(INIT_EXT) *$(SYS_EXT) *.list.pdf

listings: InitSystem.list.pdf Dummy.Init.list.pdf DClock.Init.list.pdf \
	SerialPort.Init.list.pdf

