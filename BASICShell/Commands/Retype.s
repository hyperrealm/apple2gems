
 PUT PRODOSMLI
 PUT BASICSYS

GETLN EQU $200

 ORG $300

*-------------------------------------
* Install the command
*-------------------------------------
 LDA EXTRNCMD+1
 STA NEXT_CMD+1
 LDA EXTRNCMD+2
 STA NEXT_CMD+2

 LDA #<START
 STA EXTRNCMD+1
 LDA #>START
 STA EXTRNCMD+2   
 RTS

*--------------------------------------
* Command handler entry point
* Check if command is "RETYPE"
*--------------------------------------
START EQU *
 CLD
 LDX #$00
LOOP1 LDA GETLN,X
 AND #%11011111
 CMP CMD,X
 BNE NOT_US
 INX
 CPX CMDLEN
 BNE LOOP1

 LDA #$00
 STA XCNUM
 LDA #%10000100  ; Slot & Drive, Address
 STA PBITS+1
 LDA #%00000101  ; Filename, Type 
 STA PBITS
 LDX CMDLEN
 DEX
 STX XLEN
 LDA #<MAIN
 STA XTRNADDR
 LDA #>MAIN
 STA XTRNADDR+1
 CLC
 RTS

MAIN EQU *

 ; GET_FILE_INFO

 LDA #$0A
 STA SSGINFO
 LDA #CGETFILEINFO
 JSR GOSYSTEM
 BCS DONE

 ; Check if file is of type DIR; if so, error

 LDA FIFILID
 CMP #TDIR
 BNE OK1
 LDA #EFILETYPE
 JMP DO_ERR
 
 ; Check if ,TDIR; if so, error

OK1 LDA VTYPE
 CMP #TDIR
 BNE OK2
 LDA #EINVALIDOPT
 JMP DO_ERR

 ; Set new file type

OK2 LDA #%00000100
 BIT FBITS
 BEQ SETAUXT ; no ,T param

 LDA VTYPE
 STA FIFILID

 ; Set new aux type

SETAUXT LDA #%10000000
 BIT FBITS+1
 BEQ SETINFO ; no ,A param

 LDA VADDR
 STA FIAUXID
 LDA VADDR+1
 STA FIAUXID+1

; SET_FILE_INFO

SETINFO LDA #$07
 STA SSGINFO
 LDA #CSETFILEINFO
 JSR GOSYSTEM

DONE RTS

DO_ERR JSR PRINTERR
 CLC
 RTS

NOT_US SEC
NEXT_CMD JMP $0000

CMD ASC "RETYPE"
CMDLEN DFB *-CMD

