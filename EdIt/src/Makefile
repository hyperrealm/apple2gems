
disasm:
	da65 --info info.txt EDIT#ff2000

disasm2:
	da65 --info info2.txt EDIT_MAIN

listing: EdIt.s
	enscript $< -2r -G -E -C -H3 -M Letter -o $*.list.ps
	ps2pdf $*.list.ps
	rm -f $*.list.ps
