
.scope SerialPort

;;; Screen holes

DELAYFLG := $0478 ; (+s)
HANDSHKE := $04F8 ; (+s)
STATEFLC := $0578 ; (+s)
CMDBYTE  := $05F8 ; (+s)
STSBYTE := $0678 ; (+s)
CHNBYTE := $06F8 ; (+s)
PWDBYTE := $06F8 ; (+s)
BUFBYTE := $0778 ; (+s)
COLBYTE := $0778 ; (+s)
MISCFLG := $07F8 ; (+s)

.endscope
