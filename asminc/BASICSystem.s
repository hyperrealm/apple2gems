
.scope BASICSystem

; Command parameter locations
VADDR    := $BE58 ; Address parameter (A).
VBYTE    := $BE5A ; Byte parameter (B).
VDRIV    := $BE62 ; Drive parameter (D).
VENDA    := $BE5D ; End address parameter (E).
VFELD    := $BE63 ; Field parameter (F).
VLNTH    := $BE5F ; Length parameter (L).
VLINE    := $BE68 ; Line number parameter (@).
VPATH2   := $BE6E ; Path 2
VPATH1   := $BE6C ; Path 1
VRECD    := $BE65 ; Record parameter (R).
VSLOT    := $BE61 ; Slot parameter (S).
VTYPE    := $BE6A ; Type parameter (T).

; MLI parameter lists
SCREATE  := $BEA0 ; Param list for CREATE
CRACCESS := $BEA3
CRFILID  := $BEA4
CRAUXID  := $BEA5
CRFKIND  := $BEA7

SSGPRFX  := $BEAC ; Param list for SET_PREFIX, GET_PREFIX.

SDSTROY  := $BEAC ; Param list for DESTROY.

SRENAME  := $BEAF ; Param list for RENAME.

SSGINFO  := $BEB4 ; Param list for SET_FILE_INFO, GET_FILE_INFO.
FIACESS  := $BEB7
FIFILID  := $BEB8
FIAUXID  := $BEB9
FIFKIND  := $BEBB
FIBLOKS  := $BEBC
FIMDATE  := $BEBE
FIMTIME  := $BEC0

SONLINE  := $BEC6 ; Param list for ONLINE.
SSETMRK  := $BEC6 ; Param list for SET_MARK.
SGETMRK  := $BEC6 ; Param list for GET_MARK.
SSETEOF  := $BEC6 ; Param list for SET_EOF.
SGETEOF  := $BEC6 ; Param list for GET_EOF.
SSETBUF  := $BEC6 ; Param list for SET_BUF.
SGETBUF  := $BEC6 ; Param list for GET_BUF.
SREFNUM  := $BEC7
SDATAPTR := $BEC8
SMARK    := $BEC8
SEOF     := $BEC8
SBUFADR  := $BEC8

SOPEN    := $BECB ; Param list for OPEN.
OSYSBUF  := $BECE
OREFNUM  := $BED0

SNEWLIN  := $BED1 ; Param list for NEWLINE.
NEWLREF  := $BED2
NLINEBL  := $BED3

SREAD    := $BED5 ; Param list for READ.
SWRITE   := $BED5 ; Param list for WRITE.
RWREFNUM := $BED6
RWDATA   := $BED7
RWCOUNT  := $BED9
RWTRANS  := $BEDB

SCLOSE   := $BEDD ; Param list for CLOSE.
SFLUSH   := $BEDD ; Param list for FLUSH.
CFREFNUM := $BEDE

;;; Global page variables
PBITS    := $BE54 ; Command parameters to be parsed (mask)
FBITS    := $BE56 ; Command parameters that were present (mask)
XCNUM    := $BE53 ; BASIC command number (0 for external cmd)
XLEN     := $BE52 ; Length of external command minus 1
XRETURN  := $BE9E ; Known RTS instruction
XTRNADDR := $BE50 ; Address of external command handler
EXTRNCMD := $BE06 ; External command handler entry point

;;; Entry points
GOSYSTEM := $BE70 ; Perform MLI call in A via BASIC.SYSTEM.
GETBUFR  := $BEF5 ; Allocate I/O buffer.
FREEBUFR := $BEF8 ; Release I/O buffer.
BADCALL  := $BE8B ; Report MLI error in A as BASIC.SYSTEM error.
PRINTERR := $BE0C ; Print error message in A.

;;; Errors
EOK           := $00 ; Success.
ERANGE        := $02 ; Range error.
ENODEVICE     := $03 ; No device connected.
EWRITEPROT    := $04 ; Write protected.
EENDOFDATA    := $05 ; End of data (EOF).
EPATHNOTFOUND := $06 ; Path not found.
EIOERROR      := $08 ; I/O error.
EDISKFULL     := $09 ; Disk full.
EFILELOCKED   := $0A ; File locked.
EINVALIDOPT   := $0B ; Invalid option.
ENOBUFFERS    := $0C ; No file buffers available.
EFILETYPE     := $0D ; Invalid filetype.
EPROGTOOBIG   := $0E ; BASIC program too large.
ENOTDIRECT    := $0F ; Not direct command.
ESYNTAX       := $10 ; Syntax error.
EDIRFULL      := $11 ; Directory full.
ENOTOPEN      := $12 ; File not open.
EDUPFILENAME  := $13 ; Duplicate filename.
EFILEBUSY     := $14 ; File busy.
ESTILLOPEN    := $15 ; File(s) still open.

.endscope
