include ../build/rules.mak


all: Formatter.o Relocate.o

clean:
	echo	rm -f *.o *.list *$(INIT_EXT) *$(SYS_EXT) *.list.pdf

listings: InitSystem.list.pdf Dummy.Init.list.pdf DClock.Init.list.pdf \
	SerialPort.Init.list.pdf

