
;;; Zero page locations

.scope ZeroPage

GOWARM    := $00 ; (Applesoft) JMP to Applesoft warm start.
GOSTROUT  := $03 ; (Applesoft) JMP to Applesoft cold start.
USR       := $0A ; (Applesoft) JMP to USR() function.
CHARAC    := $0D ; (Applesoft) Used by STRLT2 routine.
ENDCHR    := $0E ; (Applesoft) String terminator character.
VALTYP    := $11 ; (Applesoft) Variable or value type; (DOS 3.3) scratch
DATAFLG   := $13 ; (Applesoft) Used by PARSE routine.
COMPRTYP  := $16 ; (Applesoft) Type comparison made by COMPARE routine.
SHAPE     := $1A ; (Applesoft) Pointer to current shape in shape table.
SHAPEL    := $1A ; (Applesoft) SHAPE (low byte).
SHAPEH    := $1B ; (Applesoft) SHAPE (high byte).
HCOLOR1   := $1C ; (Applesoft) Hi-res running color mask.
COUNTH    := $1D ; (Applesoft) Hi-res high-order byte of step count for line.
WNDLFT    := $20 ; (Monitor) Left column of text window (0-39/79, default 0).
WNDWDTH   := $21 ; (Monitor) Width of text window (1-40/80, default 40/80).
WNDTOP    := $22 ; (Monitor) Top of text window (0-23, default 0).
WNDBTM    := $23 ; (Monitor) Bottom of text window (1-24, default 24).
CH        := $24 ; (Monitor) Horizontal cursor position (0-39/79).
CV        := $25 ; (Monitor) Vertical cursor position (0-23).
GBAS      := $26 ; (Applesoft) Hi-res byte position; (Monitor) lo-res left endpoint, (DOS 3.3) Scratch.
GBASL     := $26 ; (Applesoft) GBAS (low byte).
GBASH     := $27 ; (Applesoft) GBAS (high byte).
BAS       := $28 ; (Monitor) Base address of text screen line that cursor is in.
BASL      := $28 ; (Monitor) GBAS (low byte).
BASH      := $29 ; (Monitor) GBAS (high byte).
BAS2      := $2A ; (Monitor) Used as scratch during text screen scrolling
BAS2L     := $2A ; (Monitor) BAS2 (low byte).
BAS2H     := $2B ; (Monitor) BAS2 (high byte).
H2        := $2C ; (Monitor) Lo-res horizontal line endpoint.
V2        := $2D ; (Monitor) Lo-res vertical line endpoint.
MASK      := $2E ; (Monitor) Lo-res color mask.
OPCODELEN := $2F ; (Monitor) Instruction length calculated by INSDS2 routine.
HMASK     := $30 ; (Applesoft) Hi-res temporary bit mask
COLOR     := $30 ; (Monitor) Lo-res color value x 17.
MONMODE   := $31 ; (Monitor) Used by command processor.
INVFLG    := $32 ; (Monitor) Text mask ($FF=normal, $7F=flash, $3F=inverse).
PROMPT    := $33 ; (Monitor, DOS 3.3) Prompt character for input line read by GETLN routine.
YSAV      := $34 ; (Monitor) Storage for Y index register.
YSAV1     := $35 ; (Monitor) Storage fror Y index register.
DRIVE     := $35 ; (DOS 3.3) Drive number if high bit; used by RWTS.
CSW       := $36 ; (Monitor, DOS 3.3, ProDOS) Pointer to character output routine.
CSWL      := $36 ; (Monitor, DOS 3.3, ProDOS) CSW (low byte).
CSWH      := $37 ; (Monitor, DOS 3.3, ProDOS) CSW (high byte).
KSW       := $38 ; (Monitor, DOS 3.3, ProDOS) Pointer to character input routine.
KSWL      := $38 ; (Monitor, DOS 3.3, ProDOS) KSW (low byte).
KSWH      := $39 ; (Monitor, DOS 3.3, ProDOS) KSW (high byte).
PC        := $3A ; (Monitor) Program Counter storage.
PCL       := $3A ; (Monitor) PCL (low byte).
PCH       := $3B ; (Monitor) PCL (high byte).
A1        := $3C ; (Monitor) General use - source starting address.
A1L       := $3C ; (Monitor) A1 (low byte).
A1H       := $3D ; (Monitor) A1 (high byte).
A2        := $3E ; (Monitor) General use - source ending address.
A2L       := $3E ; (Monitor) A2 (low byte).
A2H       := $3F ; (Monitor) A2 (high byte).
A3        := $40 ; (Monitor) General use.
A3L       := $40 ; (Monitor) A3 (low byte).
A3H       := $41 ; (Monitor) A3 (high byte).
A4        := $42 ; (Monitor) General use - destination starting address.
A4L       := $42 ; (Monitor) A4 (low byte).
A4H       := $43 ; (Monitor) A4 (high byte).
A5        := $45 ; (Monitor) General use.
A5L       := $45 ; (Monitor) A5 (low byte).
A5H       := $46 ; (Monitor) A5 (high byte).
ACC       := $45 ; (Monitor) Accumulator storage.
XREG      := $46 ; (Monitor) X Index Register storage.
YREG      := $47 ; (Monitor) Y Index Register storage.
BLOCKNUM  := $46 ; (ProDOS) Disk driver block number (word).
STATUS    := $48 ; (Monitor) Processor Status Register storage.
IOBP      := $48 ; (DOS 3.3) RWTS IOB pointer; (ProDOS) General use.
IOBPL     := $48 ; (DOS 3.3) IOBP (low byte).
IOBPH     := $49 ; (DOS 3.3) IOBP (high byte).
LOMEM     := $4A ; (Applesoft, DOS 3.3, ProDOS) LOMEM address.
LOMEML    := $4A ; (Applesoft, DOS 3.3, ProDOS) LOMEM (low byte).
LOMEMH    := $4B ; (Applesoft, DOS 3.3, ProDOS) LOMEM (high byte).
HIMEM     := $4C ; (Applesoft, DOS 3.3, ProDOS) HIMEM address.
HIMEML    := $4C ; (Applesoft, DOS 3.3, ProDOS) HIMEM (low byte).
HIMEMH    := $4D ; (Applesoft, DOS 3.3, ProDOS) HIMEM (high byte).
RND       := $4E ; (Monitor) Random number field, seeded by RDKEY.
RNDL      := $4E ; (Monitor) RND (low byte).
RNDH      := $4F ; (Monitor) RND (high byte).
LINNUM    := $50 ; (Applesoft) line number, address of current CALL instruction (2 bytes).
RESULT    := $62 ; (Applesoft) Result of last multiply or divide (5 bytes).
TXTTAB    := $67 ; (Applesoft, DOS 3.3, ProDOS) Address of start of program.
VARTAB    := $69 ; (Applesoft, DOS 3.3, ProDOS) Address of start of variable space.
ARYTAB    := $6B ; (Applesoft) Address of start of array space.
STREND    := $6D ; (Applesoft) Address of end of numeric storage.
FRETOP    := $6F ; (Applesoft, DOS 3.3, ProDOS) Address of start of string storage.
MEMSIZ    := $73 ; (Applesoft, DOS 3.3, ProDOS) Address of end of string space + 1.
CURLIN    := $75 ; (Applesoft) Line number being executed (2 bytes).
OLDLIN    := $77 ; (Applesoft) Last line number executed (2 bytes).
OLDTEXT   := $79 ; (Applesoft) Old text pointer (2 bytes).
DATLIN    := $7B ; (Applesoft) Line number where DATA is being read (2 bytes).
DATPTR    := $7D ; (Applesoft) Pointer to current DATA instruction (2 bytes).
INPTR     := $7F ; (Applesoft) Pointer to source of input ($0201 for INPUT) (2 bytes).
VARNAM    := $81 ; (Applesoft) Name of last used variable (2 bytes).
VARPNT    := $83 ; (Applesoft) Pointer to last used variable (2 bytes).
FORPNT    := $85 ; (Applesoft) General use pointer (2 bytes).
HIGHDS    := $94 ; (Applesoft) High destination pointer used by BLTU routine (2 bytes).
HIGHTR    := $96 ; (Applesoft) High end of block to be transferred by BLTU (2 bytes).
LOWTR     := $9B ; (Applesoft) General use pointer for FNDLIN, GETARYPT, BLTU, etc. (2 bytes).
FAC       := $9D ; (Applesoft) Primary floating point accumulator.
FACEXP    := $9D ; (Applesoft) Foating point exponent.
DSCTMP    := $9D ; (Applesoft) Temporary string variable descriptor.
FACMO     := $A0 ; (Applesoft) Floating point mantissa (middle byte).
FACLO     := $A1 ; (Applesoft) Floating point mantissa (low byte).
FACSIGN   := $A2 ; (Applesoft) Floating point sign.
ARG       := $A5 ; (Applesoft) Secondary floating point accumulator.
ARGEXP    := $A5 ; (Applesoft) Floating point exponent.
PRGEND    := $AF ; (Applesoft) Pointer to end of program.
CHRGET    := $B1 ; (Applesoft) Input parsing routine.
CHRGOT    := $B7 ; (Applesoft) Input parsing routine; doesn't increment TXTPTR.
TXTPTR    := $B8 ; (Applesoft) Input parsing pointer (2 bytes).
RNDSEED   := $C9 ; (Applesoft) Random number seed.
PPL       := $CA ; (Integer BASIC) Pointer to start of program (low byte).
PPH       := $CB ; (Integer BASIC) Pointer to start of program (high byte).
PVL       := $CC ; (Integer BASIC) Pointer to end of variable storage (low byte).
PVH       := $CD ; (Integer BASIC) Pointer to end of variable storage (high byte).
ACL       := $CE ; (Integer BASIC) Math accumulator (low byte).
ACH       := $CF ; (Integer BASIC) Math accumulator (high byte).
LOCK      := $D6 ; (Applesoft) RUN-lock flag.
PRINOW    := $D7 ; (Integer BASIC) Scratch flag.
ERRFLG    := $D8 ; (Applesoft) ONERR flag.
RUNMODE   := $D9 ; (Applesoft) Immediate/deferred mode flag.
ERRLIN    := $DA ; (Applesoft) Line number where ONERR error occurred.
ERRPOS    := $DC ; (Applesoft) TXTPTR save location for HNDLERR routine.
ERRNUM    := $DE ; (Applesoft) ONERR error code.
ERRSTK    := $DF ; (Applesoft) Stack pointer before error occurred.
HGRX      := $E0 ; (Applesoft) X-coordinate fo last HPLOT (2 bytes).
HGRY      := $E2 ; (Applesoft) Y-coordinate of last HPLOT.
HGRCOLOR  := $E4 ; (Applesoft) HCOLOR= value.
HGRHORIZ  := $E5 ; (Applesoft) Hi-res map byte for horizontal bit position.
HPAG      := $E6 ; (Applesoft) Hi-res plotting page.
SCALE     := $E7 ; (Applesoft) Hi-res shape SCALE= value.
HGRSHAPE  := $E8 ; (Applesoft) Pointer to start of shape table (2 bytes).
HGRCOLLIS := $EA ; (Applesoft) Hi-res collision counter for DRAW, XDRAW.
FIRST     := $F0 ; (Applesoft) Lo-res scratch pointer.
SPEEDZ    := $F1 ; (Applesoft) 256 minus SPEED= value.
TRCFLG    := $F2 ; (Applesoft) TRACE flag.
FLASHBIT  := $F3 ; (Applesoft) FLASH mask.
TXTPSV    := $F4 ; (Applesoft) ONERR handler line number (2 bytes).
ROT       := $F9 ; (Applesoft) Hi-res shape ROT= value.

.endscope
