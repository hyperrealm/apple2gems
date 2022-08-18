
asm:
	ca65 -I ../../asminc -o InitSystem.o -l InitSystem.list -t apple2 InitSystem.s 
	ld65 -o InitSystem.sys -C apple.cfg InitSystem.o

listing:
	enscript InitSystem.s -2r -G -E -C -H3 -M Letter -o InitSystem.ps
	ps2pdf InitSystem.ps

