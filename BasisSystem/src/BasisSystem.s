



IOBUF := $1C00 ; general-purpose I/O buffer (1K)
DATABUF := $1800 ; filetypes data buffer (1K)
BUFSZ := $0400 ; size of the filetypes data buffer
ENTRYSZ := $40 ; size of an entry in the filetypes data buffer

DocumentPathBuf EQU $300 ; Path to document to be opened

Pointer    := $06 ; General purpose pointer
SavedError := $08 ; Storage for MLI error
LoaderOrg  := $1000 ; origin of (relocated) loader code
MyVersion  := $01 ; BASIS.SYSTEM version number


        .org  ProDOS::SysLoadAddress

        jmp   Continue

IDSEQ:  .byte ProDOS::InterpreterIDByte
        .byte ProDOS::InterpreterIDByte

PATHBUFLEN .byte $41
PATHBUF DS $41

;;; Set our version number and clear the memory bitmap.

Continue:
        lda   #MyVersion
        sta   ProDOS::IVERSION

;;; Only leave $0000 -$07FF (pages 0 through 7) and $BF00-$BFFF protected.

        ldx   #1
@Loop   stz   ProDOS::MEMTABL,X
        inx
        cpx   #$17
        bne   @Loop
        inx
        lda   #1
        sta   ProDOS::MEMTABL,X

;;; Check if path supplied. If not, quit.

        lda   PATHBUF
        bne   L1

        jmp   QUIT

;;; A path was supplied. Save it to buffer.

L1:     ldx   #0
@Loop   lda   PATHBUF,X
        sta   DocumentPathBuf,X
        inx
        cpx   PATHBUFLEN
        bne   @Loop

;;; Find out the filetype of the file to be opened.

        jsr   ProDOS::MLI
        .byte ProDOS::CGETFILEINFO
        .addr GetFileInfoParams
        beq   L2
        jmp   ERROR

;;; It cannot be a SYS file.

L2:     lda   FILETYPE
        cmp   #FileTypes::SYS
        bne   L3

        lda   #ProDOS::EBADFILEFMT
        jmp   ERROR

;;; Chop the filename off our path to determine directory.

L3:
        ldx   ProDOS::SysPathBuf
        dex
@Loop:  lda   ProDOS::SysPathBuf+1,X
        cmp   #"/"
        beq   L4
        dex
        bne   @Loop

;;; Append the types filename. X contains the length of the directory
;;; path.

L4:     ldy   #0
@Loop:  lda   TYPESFILE,Y
        sta   ProDOS::SysPathBuf+1,X
        beq   @Done
        inx
        iny
        bra   @Loop
@Done:  stx   ProDOS::SysPathBuf

;;; Open the launcher data file.

        jsr   ProDOS::MLI
        .byte ProDOS::COPEN
        .addr OpenParams
        beq   L5
        jmp   ERROR

;;; Read next 1K from the launcher data file.

L5:     lda   OPENREFNUM
        sta   READREFNUM
        sta   CLOSEREFNUM

READLOOP:
        jsr   ProDOS::MLI
        .byte ProDOS::CREAD
        .addr READPARM
        beq   L6
        jmp   ERROR

;;; Divide bytes read by ENTRYSZ to get count of entries.

L6:     ldx   #6   ; divide by 2^6 = 64
DIVIDE: lsr   READXFRC+1
        ror   READXFRC
        dex
        bne   DIVIDE
        lda   READXFRC
        beq   NOENT ; 0 entries means we reached EOF
        tax  ; Number of entries now in X

;;; Search for matching filetype in data buffer. Each entry is 64 bytes
;;; long (filetype + path). There are up to 16 entires per 1K buffer.

        lda   #<DATABUF
        sta   Pointer
        lda   #>DATABUF
        sta   Pointer+1

SRCHLOOP:
        lda   (Pointer)
        cmp   FILETYPE
        beq   SRCHDONE

        dex
        beq   READLOOP ; Read next buffer from data file

        lda   Pointer
        clc
        adc   #ENTRYSZ
        sta   Pointer
        bcc   L7
        inc   Pointer+1

L7:     bra   SRCHLOOP

NOENT:  stz   Pointer ; Matching entry wasn't found.
        stz   Pointer+1

;;; Close the data file.

SRCHDONE:
        jsr   ProDOS::MLI
        .byte ProDOS::CCLOSE
        .addr CLOSEPARM

;;; Now Pointer points to the matching entry, or is $0000 if none was
;;; found.

        lda   Pointer+1
        bne   L8

        lda   #$46 ; File not found
        jmp   ERROR

;;; Copy the launcher path to SYSPATHBUF, with leading length byte.

L8:     ldy   #1
@Loop:  lda   (Pointer),Y
        beq   @Done
        sta   ProDOS::SysPathBuf,Y
        iny
        cpy   #ENTRYSZ-1
        bne   @Loop
@Done:  dey
        sty   ProDOS::SysPathBuf

;;; Relocate the launcher loader and jump to it.

;;; Start source address = RELOCSTART

        lda   #<RELOCSTART
        sta   ZeroPage::A1L
        sta   ZeroPage::A2L
        lda   #>RELOCSTART
        sta   ZeroPage::A1H
        sta   ZeroPage::A2H

;;; End source address = RELOCSTART + proglen

        clc
        lda   ZeroPage::A2L
        adc   #<(LOADEREND-LOADERSTART)
        sta   ZeroPage::A2L
        lda   ZeroPage::A2H
        adc   #>(LOADEREND-LOADERSTART)
        sta   ZeroPage::A2H

;;; Dest address = LoaderOrg

        lda   #<LoaderOrg
        sta   ZeroPage::A4L
        lda   #>LoaderOrg
        sta   ZeroPage::A4H

        ldy   #0
        jsr   Monitor::MOVE

        jmp   LOADERSTART

;;; Error handler

ERROR:  pha
        jsr   Monitor::HOME
        ldx   #0
@Loop:  lda   ERRSTR,X
        beq   @Done
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Done:  pla
        jsr   Monitor::PRBYTE
        jsr   Monitor::PRBLNK
        jsr   Monitor::RDKEY

QUIT:   jsr   ProDOS::MLI
        .byte PRoDOS::CQUIT
        .addr QUITPARM

        rts

TYPESFILE:
        .asciiz "/FILE.TYPES"
ERRSTR:
        highasciiz "ERROR READING FILE.TYPES: $"

;;; GET_FILE_INFO params

GetFileInfoParams:
        .byte $0A
        .addr DocumentPathBuf
        .byte $00 ; access
FILETYPE:
        .byte $00  ; file type
AUXTYPE:
        .word $0000 ; aux type
        .byte $00 ; storage type
        .word $0000 ; blocks used
        .word $0000 ; mod date
        .word $0000 ; mod time
        .word $0000 ; create date
        .word $0000 ; create time

;;; OPEN params

OpenParams:
        .byte $03
        .addr ProDOS::SysPathBuf
        .addr IOBUF
OPENREFNUM:
        .byte $00

;;; CLOSE params

CLOSEPARM:
        .byte $01
CLOSEREFNUM:
        .byte $00

;;; READ params

READPARM:
        .byte $04
READREFNUM:
        .byte $00
        .addr DATABUF
        .word BUFSZ  ; # of bytes requeste
READXFRC:
        .word $0000

;;; QUIT parms

QUITPARM:
        .byte $04
        .byte $00
        .word $0000
        .byte $00
        .word $0000

;;; The loader

RELOCSTART := *

        .org  LoaderOrg

LOADERSTART := *

        stz   SavedError

;;; Clear screen and print launcher path.

HEADER:
        jsr   Monitor::HOME
        lda   ProDOS::SysPathBuf
        lsr
        tax
        jsr   Monitor::PRBL2
        ldx   #0
@Loop:  lda   ProDOS::SysPathBuf+1,X
        jsr   Monitor::COUT
        inx
        cpx   ProDOS::SysPathBuf
        bne   @Loop

;;; Get the file type of the launcher program.

        jsr   ProDOS::MLI
        .byte ProDOS::CGETFILEINFO
        .addr GetFileInfoParams1
        beq   LL1
        jmp   LERROR

LL1:    lda   FILETYPE1
        cmp   #FileType::SYS ; SYS file?
        beq   LL2
        lda   #ProDOS::EBADFILEFMT ; Invalid filetype
        jmp   LERROR

;;; Open the launcher program file.

LL2:    jsr   ProDOS::MLI
        .byte ProDOS::COPEN
        .addr OpenParams1
        beq   LL3
        jmp   LERROR

;;; Get the size of the launcher program file.

LL3:    lda   OPENREFNUM1
        sta   READREFNUM1
        sta   GETEOFREFNUM1
        sta   CLOSEREFNUM1

        jsr   ProDOS::MLI
        .byte ProDOS::CGETEOF
        .addr GETEOFPARM1
        sta   SavedError
        bne   DOCLOSE

;;; Read in the launcher program file.

LL4:    lda   EOF1
        sta   READREQC1
        lda   EOF1+1
        sta   READREQC1+1
        jsr   ProDOS::MLI
        .byte PrODOS::CREAD
        .addr READPARM1
        sta   SavedError

;;; Close the launcher program file.

DOCLOSE:
        jsr   ProDOS::MLI
        .byte ProDOS::CCLOSE
        .addr CLOSEPARM1

        beq   LL5
        jmp   LERROR

LL5:    lda   SavedError
        beq   LL6
        jmp   LERROR

;;; Make sure the launcher program is an interpreter and has a sufficent
;;; path buffer size.

LL6:    lda   ProDOS::SysLoadAddress
        cmp   #$4C ; JMP
        bne   @NotGood
        lda   ProDOS::SysLoadAddress+3
        cmp   #ProDOS::InterpreterID
        bne   @NotGood
        lda   ProDOS::SysLoadAddress+4
        cmp   #ProDOS::InterpreterID
        bne   @NotGood
        lda   PATHBUFLEN
        cmp   DocumentPathBuf
        bge   LL7
@NotGood:
        lda   #ProDOS::EFTYPE
        jmp   ERROR

;;; Copy the path into the launcher's buffer.

LL7:    lda   DocumentPathBuf
        sta   PATHBUF

        ldx   #0
@Loop   lda   DocumentPathBuf+1,X
        sta   PATHBUF+1,X
        inx
        cpx   DocumentPathBuf
        bne   @Loop

;;; All done! Jump to the launcher.

        jmp  ProDOS::SysLoadAddress


;;; Error handler.


LERROR:
        pha
        jsr   Monitor::HOME
        ldx   #0
@Loop:  lda   LERRORSTR,X
        beq   @Done
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Done:  pla
        jsr   Monitor::PRBYTE
        jsr   Monitor::PRBLNK
        jsr   Monitor::RDKEY

LQUIT:
        jsr   ProDOS::MLI
        .byte ProDOS::CQUIT
        .addr QUITPARM1
        rts

LERRORSTR:
        highasciiz "ERROR STARTING LAUNCHER: $"

*
* GET_FILE_INFO params
*
GetFileInfoParams1:
        .byte $0A
        .addr ProDOS::SysPathBuf
        .byte $00 ; access
FILETYPE1:
        .byte $00 ; filetype
AUXTYPE1:
        .word $0000 ; aux type
        .byte $00 ; storage type
        .word $0000 ; blocks used
        .word $0000 ; mod date
        .word $0000 ; mod time
        .word $0000 ; create date
        .word $0000 ; create time

;;; GET_EOF params

GETEOFPARM1:
        .byte $02
GETEOFREFNUM1:
        .byte $00
EOF1:   .byte $00, $00, $00

;;; OPEN parms

OpenParams1:
        .byte $03
OPENPATH1:
        .addr ProDOS::SysPathBuf
OPENIOBUF1:
        .addr IOBUF
OPENREFNUM1:
        .byte $00

;;; READ parms

READPARM1:
        .byte $04
READREFNUM1:
        .byte $00
        .addr SYSORG
READREQC1:
        .word $0000
READXFRC1:
        .word $0000

;;; CLOSE parms

CLOSEPARM1:
        .byte $01
CLOSEREFNUM1:
        byte $00

;;; QUIT parms

QUITPARM1:
        .byte $04
        .byte $00
        .word $0000
        .byte $00
        .word $0000

LOADEREND := *

