
disasm:
	da65 --info info.txt --mnemonic-column 12 --argument-column 18 --comment-column 30 MTXKIT.ABS.bin

asm:
	ca65 -I ../../asminc -o MTTK.o -t apple2 -l MTTK.list MouseTextToolKit.s
	ld65 -o MTTK.obj -C apple.cfg MTTK.o
	diff ../obj/MTXKIT.ABS.bin MTTK.obj

listing:
	enscript MouseTextToolKit.s -2r -G -E -C -H3 -M Letter -o MTTK.ps
	ps2pdf MTTK.ps

listing2:
	enscript MouseTextToolKitDefines.s -2r -G -E -C -H3 -M Letter -o MTTKDef.ps
