
.scope ApplesoftToken

AMPERSAND   := $AF ; "&"
PLUS        := $C8 ; "+"
MINUS       := $C9 ; "-"
MULTIPLY    := $CA ; "*"
DIVIDE      := $CB ; "/"
EXPONENT    := $CC ; "^"
LESSTHAN    := $D1 ; "<"
EQUAL       := $D0 ; "="
GREATERTHAN := $CF ; ">"

ABS         := $D4 ; "ABS"
AND         := $CD ; "AND"
ASC         := $E6 ; "ASC"
AT          := $C5 ; "AT"
ATN         := $E1 ; "ATN"
CALL        := $8C ; "CALL"
CHR         := $E7 ; "CHR$"
CLEAR       := $BD ; "CLEAR"
COLOR       := $A0 ; "COLOR="
CONT        := $BB ; "CONT"
COS         := $DE ; "COS"
DATA        := $83 ; "DATA"
DEF         := $B8 ; "DEF"
DEL         := $85 ; "DEL"
DIM         := $86 ; "DIM"
DRAW        := $94 : "DRAW"
END         := $80 : "END"
EXP         := $DD ; "EXP"
FLASH       := $9F ; "FLASH"
FN          := $C2 ; "FN"
FOR         := $81 ; "FOR"
FRE         := $D6 ; "FRE"
GET         := $BE ; "GET"
GOSUB       := $B0 ; "GOSUB"
GOTO        := $AB ; "GOTO"
GR          := $88 ; "GR"
HCOLOR      := $92 ; "HCOLOR="
HGR         := $91 ; "HGR"
HGR2        := $90 ; "HGR2"
HIMEM       := $A3 ; "HIMEM:"
HLIN        := $8E ; "HLIN"
HOME        := $97 ; "HOME"
HPLOT       := $93 ; "HPLOT"
HTAB        := $96 ; "HTAB
IF          := $AD ; "IF"
INSLOT      := $8B ; "IN#"
INPUT       := $84 ; "INPUT"
INT         := $D3 ; "INT"
INVERSE     := $9E ; "INVERSE"
LEFT        := $E8 ; "LEFT$"
LEN         := $E3 ; "LEN"
LET         := $AA ; "LET"
LIST        := $BC ; "LIST"
LOAD        := $B6 ; "LOAD"
LOG         := $DC ; "LOG"
LOMEM       := $A4 ; "LOMEM:"
MID         := $EA ; "MID$"
NEW         := $BF ; "NEW"
NEXT        := $82 ; "NEXT"
NORMAL      := $9D ; "NORMAL"
NOT         := $C6 ; "NOT"
NOTRACE     := $9C ; "NOTRACE"
ON          := $B4 ; "ON"
ONERR       := $A5 ; "ONERR"
OR          := $CE ; "OR"
PDL         := $D8 ; "PDL"
PEEK        := $E2 ; "PEEK"
PLOT        := $8D ; "PLOT"
POKE        := $B9 ; "POKE"
POP         := $A1 ; "POP"
POS         := $D9 ; "POS"
PRSLOT      := $8A ; "PR#"
PRINT       := $BA ; "PRINT"
READ        := $87 ; "READ"
RECALL      := $A7 ; "RECALL"
REM         := $B2 ; "REM"
RESTORE     := $AE ; "RESTORE"
RESUME      := $A6 ; "RESUME"
RETURN      := $B1 ; "RETURN"
RIGHT       := $E9 ; "RIGHT$"
RND         := $DB ; "RND"
ROT         := $98 ; "ROT="
RUN         := $AC ; "RUN"
SAVE        := $B7 ; "SAVE"
SCALE       := $99 ; "SCALE="
SCRN        := $D7 ; "SCRN("
SGN         := $D2 ; "SGN"
SHLOAD      := $9A ; "SHLOAD"
SIN         := $DF ; "SIN"
SPC         := $C3 ; "SPC("
SPEED       := $A9 ; "SPEED="
SQR         := $DA ; "SQR"
STEP        := $C7 ; "STEP"
STOP        := $B3 ; "STOP"
STORE       := $A8 ; "STORE"
STR         := $E4 ; "STR$"
TAB         := $C0 ; "TAB("
TAN         := $E0 ; "TAN"
TEXT        := $89 ; "TEXT"
THEN        := $C4 ; "THEN"
TO          := $C1 ; "TO"
TRACE       := $9B ; "TRACE"
USR         := $D5 ; "USR"
VAL         := $E5 ; "VAL"
VLIN        := $8F ; "VLIN"
VTAB        := $A2 ; "VTAB"
WAIT        := $B5 ; "WAIT"
XDRAW       := $95 ; "XDRAW"
.endscope

.scope ApplesoftHandler

AMPERSAND   := $03F5
PLUS        := $E7C1
MINUS       := $E7AA
MULTIPLY    := $E982
DIVIDE      := $EA69
EXPONENT    := $EE97
LESSTHAN    := $DF6A
EQUAL       := $DF6A
GREATERTHAN := $DF6A

ABS         := $EBAF
AND         := $DF55
ASC         := $E6E5
ATN         := $F09E
CALL        := $F1D5
CHR         := $E646
CLEAR       := $D66A
COLOR       := $F24F
CONT        := $D896
COS         := $EFEA
DATA        := $D995
DEF         := $E313
DEL         := $F331
DIM         := $DFD9
DRAW        := $F769
END         := $D870
EXP         := $EF09
FLASH       := $F280
FN          := $E354
FOR         := $D766
FRE         := $E2DE
GET         := $DBA0
GOSUB       := $D921
GOTO        := $D93E
GR          := $F390
HCOLOR      := $F6E9
HGR         := $F3E2
HGR2        := $F3D8
HIMEM       := $F286
HLIN        := $F232
HOME        := $FC58
HPLOT       := $F6FE
HTAB        := $F7E7
IF          := $D9C9
INSLOT      := $F1DE
INPUT       := $DBB2
INT         := $EC23
INVERSE     := $F277
LEFT        := $E65A
LEN         := $E6D6
LET         := $DA46
LIST        := $D6A5
LOAD        := $03F5
LOG         := $E941
LOMEM       := $F2A6
MID         := $E691
NEW         := $D649
NEXT        := $DCF9
NORMAL      := $F273
NOT         := $DE90
NOTRACE     := $F26F
ON          := $D9EC
ONERR       := $F2CB
OR          := $DF4F
PDL         := $DFCD
PEEK        := $E764
PLOT        := $F225
POKE        := $E77B
POP         := $D96B
POS         := $E2FF
PRSLOT      := $F1E5
PRINT       := $DAD5
READ        := $DBE2
RECALL      := $03F5
REM         := $D9DC
RESTORE     := $D849
RESUME      := $F318
RETURN      := $D96B
RIGHT       := $E686
RND         := $EFAE
ROT         := $F721
RUN         := $D912
SAVE        := $03F5
SCALE       := $F727
SCRN        := $DEF9
SGN         := $EB90
SHLOAD      := $03F5
SIN         := $EFF1
SPC         := $DB16
SPEED       := $F262
SQR         := $EE8D
STEP        := $D7AF
STOP        := $D86E
STORE       := $03F5
STR         := $E3C5
TAB         := $DB16
TAN         := $F03A
TEXT        := $F399
TRACE       := $F26D
USR         := $000A
VAL         := $E707
VLIN        := $F241
VTAB        := $F256
WAIT        := $E784
XDRAW       := $F76F

.endscope

.scope ApplesoftError

NextWithoutFor     :=   0
SyntaxError        :=  16
ReturnWithoutGosub :=  22
OutOfData          :=  42
IllegalQuantity    :=  53
Overflow           :=  69
OutOfMemory        :=  77
UndefdStatement    :=  90
BadSubscript       := 107
RedimdArray        := 120
DivisionByZero     := 133
TypeMismatch       := 163
StringTooLong      := 176
FormulaTooComplex  := 191
UndefdFunction     := 224
ReEnter            := 254
Break              := 255

.endscope

.scope ApplesoftConstant

MINUS_32768   := $E0FE ; -32768
ONE           := $E913 ; 1
SQRT_HALF     := $E92D ; sqrt(0.5)
SQRT_2        := $E932 ; sqrt(2)
MINUS_HALF    := $E937 ; -0.5
LOG_2         := $E93C ; log(2)
TEN           := $EA10 ; 10
HALF          := $EE64 ; 0.5
LN_2          := $EEDB ; ln(2)
HALF_PI       := $F063 ; pi/2
TWO_PI        := $F06B ; 2*pi
FOURTH        := $F070 ; 0.25
C_99999999_9  := $ED0D ; 99,999,999.9
C_999999999   := $ED12 ; 999,999,999
C_1E9         := $ED17 ; 10^9

.endscope

.scope ApplesoftRoutine

;;; Locating variables, data, and line numbers

PTRGET      := $DFE3 ; Locate data field for var at TXTPTR.
GETARYPT    := $F7D9 ; Locate name header for array var at TXTPTR.
FNDLIN      := $D61A ; Locate program line for line number in LINNUM.

;;; Formula evaluation

FRMNUM      := $DD67 ; Evaluate expression at TXTPTR, store result in FAC.
GETBYT      := $E6F8 ; Evaluate 8-bit math expression at TXTPTR, store in low byte of FAC.
FRMEVL      := $DD7B ; Evaluate math or string expression at TXTPTR, store result in FAC.

;;; Numeric conversions

GIVAYF      := $E2F2 ; Convert 16-bit int in Y/A to floating point value in FAC.
CONINT      := $E6FB ; Convert FAC to 8-bit uint, store result in low byte of FAC.
GETADR      := $E752 ; Convert FAC to 16-bit uint, store result in LINNUM.
QINT        := $EBF2 ; Quick greatest-integer function for FAC.
AYINT       := $E10C ; If -32768 < FAC < 32767, call QINT.
SNGFLT      := $E301 ; Convert uint in Y to floating point value in FAC.
FLOAT       := $EB93 ; Convert int in A to floating point value in FAC.
MOVFM       := $EAF9 ; Copy packed floating point value at address Y/A to FAC.
MOVMF       := $EB2B ; Copy FAC to packed floating point value at address Y/A.
CONUPK      := $E9E3 ; Copy packed floating point value at address Y/A to ARG.

;;; Floating point arithmetic

FSUB        := $E7A7 ; Call MOVFM, then FSUBT.
FSUBT       := $E7AA ; Subtract FAC from ARG, store result in FAC.
FADD        := $E7BE ; Call MOVFM, then FADDT.
FADDT       := $E7C1 ; Add FAC to ARG, store result in FAC.
FMULT       := $E97F ; Call MOVFM, then FMULTT.
FMULTT      := $E982 ; Multiply FAC by ARG, store result in FAC.
FDIV        := $EA66 ; Call MOVFM, then FDIVT.
FDIVT       := $EA69 ; Divide ARG by FAC, store result in FAC.
NEGOP       := $EED0 ; Multiply FAC by -1, store result in FAC.
MUL10       := $EA39 ; Multiply FAC by 10, store result in FAC.
DIV10       := $EA55 ; Divide FAC by 10, store result in FAC.
FADDH       := $E7A0 ; Multiply FAC by 0.5, store result in FAC.
ZEROFAC     := $E84E ; Set FAC to 0.

;;; Floating point functions

LOG         := $E941 ; Calculate natural logarithm of FAC, store result in FAC.
SIGN        := $EB82 ; Calculate sign of FAC (-1, 0, 1), store result in FAC.
ABS         := $EBAF ; Calculate absolute value of FAC, store result in FAC.
FCOMP       := $EBB2 ; Compare FAC to value at address Y/A, return 0, 1, or -1.
INT         := $EC23 ; Convert FAC to integer, store result in FAC.
SQR         := $EE8D ; Calcualte square root of FAC, store result in FAC.
FPWRT       := $EE97 ; Calculate ARG raised to FAC base e.
EXP         := $EF09 ; Calculate natural exponent of FAC, store result in FAC.
RND         := $EFAE ; Generate low-quality random number in FAC.
COS         := $EFEA ; Calculate cosine of FAC, store result in FAC.
SIN         := $EFF1 ; Calculate sine of FAC, store result in FAC.
TAN         := $F03A ; Calculate tangent of FAC, store result in FAC.
ATN         := $F09E ; Calculate arctangent of FAC, store result in FAC.
MOVAF       := $EB63 ; Copy FAC to ARG.
MOVFA       := $EB53 ; Copy ARG to FAC.

;;; String processing and memory management

GETSPACE    := $E452 ; Allocate space for new string variable.
REASON      := $D3E3 ; Check if address Y/A is below FRETOP.
STRINI      := $E3D5 ; Allocate space for new string variable.
MAKSTR      := $E3E9 ; Create descriptor for string at address Y/A.
SAVD        := $DA9A ; Update string descriptor at FORPNT.
GARBAG      := $E484 ; Perform garbage collection on string table.
MOVSTR      := $E5E2 ; Copy string to FRESPC.
FOUT        := $ED34 ; Convert FAC to a string, store its address in Y/A.
COPY        := $DAB7 ; Move string in memory.
BLTU        := $D393 ; Move block of memory.

;;; Logical and comparsion operators

AND         := $DF55 ; Calculate logical AND of FAC and ARG, store result in FAC.
OR          := $DF4F ; Calculate logical OR of FAC and ARG, store result in FAC.
NOT         := $DE98 ; Calculate logical NOT of FAC, store result in FAC.
COMPARE     := $DF6A ; Compare ARG to FAC, using comparison COMPRTYP.

;;; Hi-res graphics

HGR         := $F3E2 ; Turn on and clear hi-res page 1.
HGR2        := $F3D8 ; Turn on and clear hi-res page 2.
HGRO        := $F3E4 ; Turn on and clear hi-res page HPAG.
HCLR        := $F3F2 ; Clear hi-res page HPAG to color 0 (black).
BKGND       := $F3F6 ; Fill hi-res page HPAG to color HCOLOR.
BKGNDO      := $F3F4 ; Fill hi-res page HPAG to color in A.
HCOLOR      := $F6F0 ; Convert hi-res color in X to a color mask and store in HCOLOR.
HPOSN       := $F411 ; Set hi-res plotting position to column X/Y, row A.
HPLOT       := $F457 ; Plot a hi-res point at current plotting position in current color.
HFIND       := $F5CB ; Store current hi-res plotting position in HGRX and HGRY.
HLIN        := $F53A ; Draw hi-res line from current plotting position to column A/X, row Y.
SHNUM       := $F730 ; Store address of shape number in X at SHAPE.
DRAW        := $F601 ; Draw shape at address X/Y.
XDRAW       := $F65D ; Erase (XOR) shape at address X/Y.

;;; Program parsing

CHRGET      := $00B1 ; Advance TXTPTR and return next token.
CHRGOT      := $00B7 ; Return next token.
CHKCOM      := $DEBE ; Check if TXTPTR is pointing to a comma.
CHKCLS      := $DEB8 ; Check if TXTPTR is pointing to a close parenthesis.
CHKOPN      := $DEBB ; Check if TXTPTR is pointing to an open parenthesis.
SYNCHR      := $DEC0 ; Check if TXTPTR is pointing to a char that is same as the one in A.
CHKNUM      := $DD6A ; Check if FAC contains a pointer to a numeric variable descriptor.
CHKSTR      := $DD6C ; Check if FAC contains a pointer to a string variable descriptor.
CHKVAL      := $DD6D ; If Carry is set, calls CHKSTR; otherwise calls CHKNUM.
ISLETC      := $E07D ; Check if A contains uppercase letter; set Carry if so.
LINGET      := $DA0C ; Load the line number at TXTPTR into LINNUM.
HFNS        := $F6B9 ; Parse a hi-res plotting coordinate at TXTPTR.
ADDON       := $D998 ; Advance TXTPTR by the number of bytes given by Y.
DATA        := $D995 ; Advance TXTPTR to the end of the current statement.
STXTPT      := $D697 ; Set TXTPTR to the beginning of the program.
DATAN       := $D9A3 ; Store the offset of the next colon, or end of the current line, in Y.
REMN        := $D9A6 ; Sture the offset to the end of the current line in Y.
PARSE       := $D56C ; Parse a program line.
TOKTBL      := $D0D0 ; Applesoft token table.

;;; Text input

INCHR       := $D553 ; Read a character from the current input device into A.
INLIN       := $D52C ; Read a line of input from the current input device into the input buffer.
ISCNTC      := $D858 ; Check if Control-C was pressed; execute break routine if so.

;;; Text output
STROUT      := $DB3A ; Print the null- or double-quote-terminated string pointed to by A/Y.
STRPRT      := $DB3D ; Print the string whose descriptor is in FAC.
OUTDO       := $DB50 ; Print the character in A.
OUTSPC      := $DB57 ; Print a space.
OUTQST      := $DB5A ; Print a question mark.
CRDO        := $DAFB ; Print a carriage return.
PRNTFAC     := $ED2E ; Prin tthe value in FAC.
LINPRT      := $ED24 ; Print the 16-bit integer in X/A.
INPRT       := $ED19 ; Print "IN" followed by the line number in CURLIN.

;;; Error handling

STKINI      := $D683 ; Initialize the Applesoft stack.
ERROR       := $D412 ; Perform error handling.
HANDLERR    := $F2E9 ; Handle the error code in X.
RESUME      := $F317 ; Restores the current line number and TXTPTR after an error.
NXTERR      := $DD0B ; Prints "NEXT WITHOUT FOR" and stops the program.
SYNERR      := $DEC9 ; Prints "SYNTAX ERROR" and stops the program.
RETERR      := $D979 ; Prints "RETURN WITHOUT GOSUB" and stops the program.
DATAERR     := $E1BC ; Prints "OUT OF DATA" and stops the program.
IQERR       := $E199 ; Prints "ILLEGAL QUANTITY" and stops the program.
OVERFLOW    := $E8D5 ; Prints "OVERFLOW" and stops the program.
MEMERR      := $D410 ; Prints "OUT OF MEMORY" and stops the program.
UNDSTM      := $D97C ; Prints "UNDEF'D STATEMENT" and stops the program.
SUBERR      := $E196 ; Prints "BAD SUBSCRIPT" and stops the program.
DIVZERO     := $EAE1 ; Prints "DIVISION BY ZERO" and stops the program.
TYPERR      := $DD76 ; Prints "TYPE MISMATCH" and stops the program.
FMLERR      := $E430 ; Prints "FORMULA TOO COMPLEX" and stops the program.
UNDFNC      := $E30E ; Prints "UNDEF'D FUNCTION" and stops the program.
DRCTERR     := $E30B ; Prints "ILLEGAL DIRECT" and stops the program.
ERRDIR      := $E306 ; Raises an "ILLEGAL DIRECT" error if a program is not running.

;;; Miscellaneous

COLD        := $E000 ; Interpreter cold-start.
WARM        := $E003 ; Interpreter warm-start.
RUN         := $D566 ; Execute current program.

.endscope
