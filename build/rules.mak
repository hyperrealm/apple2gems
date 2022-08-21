
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

BUILD_DIR:=$(shell echo $(ROOT_DIR) | sed -E 's@(apple2gems)/.*@\1/build@' )
ASMINC_DIR:=$(shell echo $(ROOT_DIR) | sed -E 's@(apple2gems)/.*@\1/asminc@' )

ASFLAGS := -I $(ASMINC_DIR) -t apple2
LDFLAGS := -C $(BUILD_DIR)/apple.cfg


%.o: %.s
	ca65 $(ASFLAGS) -o $@ -l $*.list $<

%.list.pdf: %.s
	enscript $< -2r -G -E -C -H3 -M Letter -o $*.list.ps
	ps2pdf $*.list.ps
	rm -f $*.list.ps
