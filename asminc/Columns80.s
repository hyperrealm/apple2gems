;;; 80-column firwmare

.scope Columns80

;;; Screen holes

OLDCH   := $047B ; Old CH value from Zero Page.
MODE    := $04FB ; Operating mode (bitmask)
OURCH   := $057B ; Horizontal cursor position
OURCV   := $05FB ; Vertical cursor position
CHAR    := $067B ; Character to be output or input
XCOORD  := $06FB ; Pascal GOTOXY X-coordinate
OLDBASL := $077B ; Pascal scratch space
OLDBASH := $07FB ; Pascal scratch space
CURSOR  := $07FB ; Cursor character; IIc/IIc+ only

;;; Entry points

AUXMOVE := $C311
XFER    := $C314

.endscope
