***************************************
*             BASIC.SHELL             *
*                                     *
* A external command for BASIC.SYSTEM *
* that functions as a rudimentary     *
* shell. Loads, relocates, and        *
* dispatches to an arbitrary number   *
* of other commands, each of which is *
* stored in a separate file on disk.  *
*                                     *
* (c) 2020 Mark A. Lindner            *
***************************************

 PUT /iic/work/BASICSYS
 PUT /iic/work/PRODOSMLI
 PUT /iic/work/ZEROPAGE
 PUT /iic/work/ROMCALLS

 ORG $2000
 XC ; 65C02 program

DESTPAGE EQU $90
NUMPAGES EQU $0A ; 10 pages from $9000 - $99FF
MASK EQU $08
CMDLEN EQU $09
TMPL EQU $FA
TMPH EQU $FB

CMD_TYPE EQU $C0 ; 'CMD' filetype
TXT_TYPE EQU $04 'TXT' filetype
DIR_TYPE EQU $0D

GETLN EQU $200
 
* Allocate a buffer from BASIC.SYSTEM, and then relocate
* ourselves into that buffer. 

 LDA #NUMPAGES
 JSR GETBUFR
 BCS NOMEM
 CMP #DESTPAGE
 BNE NOMEM

* Start source address = RELOCSTART

 LDA #<RELOCSTART
 STA A1L
 STA A2L
 LDA #>RELOCSTART
 STA A1H
 STA A2H

* End source address = RELOCSTART + proglen

 CLC
 LDA A2L
 ADC #<PROGEND-PROGSTART
 STA A2L
 LDA A2H
 ADC #>PROGEND-PROGSTART
 STA A2H
 
* Dest address = $9600

 STZ A4L
 LDA #DESTPAGE
 STA A4H

 LDY #0
 JSR MOVE

 NOP
 NOP
 NOP

* Now install the command handler into BASIC.SYSTEM

 LDA EXTRNCMD+1
 STA SAVEDCMD
 LDA EXTRNCMD+2
 STA SAVEDCMD+1

 STZ EXTRNCMD+1
 LDA #DESTPAGE
 STA EXTRNCMD+2
 
 RTS

NOMEM LDA #$1E ; "PROGRAM TOO LARGE"
 JMP PRINTERR

* The command handler logic starts here.

RELOCSTART EQU *

 ORG $9000

PROGSTART CLD
 NOP
 NOP
 NOP


* Check for built-in commands
 
 LDX #<THELP
 LDA #>THELP
 JSR CMPSTR
 BCC :NEXT1
 JMP HELP_CMD

:NEXT1 LDX #<TQUIT
 LDA #>TQUIT
 JSR CMPSTR
 BCC :NEXT2
 JMP QUIT_CMD

:NEXT2 ; Handle external commands

 JMP BADCMD
 BRK
 NOP
 NOP
 CLC
 RTS

* Check if the command is in memory

 LDX #0
:L1 LDA GETLN,X
 CMP #' '
 BEQ :L1
 AND #%11011111 ; convert to lowercase
 STA GETLN,X
 INX
 BRA :L2
:L2 STX CMDLEN
 
* Find the matching cache entry in CACHETBL

 LDX #0
CACHELOOP TXA
 ASL
 ASL
 ASL
 ASL ; Step by 16 bytes
 TAY
 LDA CACHETBL,Y
 CMP CMDLEN
 BNE :NEXT ; command lengths don't match
:L1 INY
 LDA CACHETBL,Y
 CMP GETLN-1,Y
 BNE :NEXT ; commands don't match
 CPY CMDLEN
 BEQ CMDINMEM
 BRA :L1

:NEXT INX
 CPX #8
 BNE CACHELOOP
 
** NOT FOUND: need to try to load it**

* Command is not in memory.

NOTINMEM

* Construct the path to it in VPATH
 ; TODO

* Stat it

 LDA #CGETFILEINFO
 JSR GOSYSTEM
 BCS BADCMD

 LDA FIFILID
 CMP #CMD_TYPE
 BNE BADCMD

* Check that filetype is CMD and aux type is $2000

 LDA FIAUXID
 CMP #0
 BNE BADCMD
 LDA FIAUXID+1
 CMP #$20
 BNE BADCMD

* Open the file

 LDA #COPEN
 JSR GOSYSTEM
 BCS IOERROR

* Get the file size

 LDA #CGETEOF
 JSR GOSYSTEM

* Make sure it's <= 2K ($0800)

 LDA SEOF+1
 CMP #$08
 BLT :OK
 BEQ :OK
 JMP TOOBIG
 LDA SEOF
 BEQ :OK
 JMP TOOBIG
 
:OK  

* Get the file size rounded to the number of pages

 LDA SEOF+1
 LDX SEOF
 BEQ :SKIP
 INC  
:SKIP   

* Round A to the next higher power of 2.
   
 LDX #1
 STX TMPL
:L3 CMP #0
 BEQ :L4
 LSR
 ASL TMPL
 BRA :L3

* Decrement by 1 to create a mask

:L4 DEC
 STA MASK
:L5 LDA NXTBUF
 AND MASK
 BEQ SELECTED
 INC
 ORA 7
 BRA :L5

* A buffer has been selected

SELECTED LDA #CREAD
 JSR GOSYSTEM
 BCS READERR

READERR
 LDA #CCLOSE
 JSR GOSYSTEM
 BCS READERR

* Select first 256-byte buffer
 
* Command is now in memory; X contains the cache entry number
CMDINMEM



 CLC
 RTS

* Command is too big.
TOOBIG LDA #$1E ; "PROGRAM TOO LARGE"
 JSR PRINTERR
 CLC
 RTS


* Command not recognized

BADCMD SEC
 JMP (SAVEDCMD)

IOERROR ; TODO
 RTS

NO_PARSE STZ PBITS
 STA XLEN
 STZ PBITS+1
 STZ XCNUM
 LDA #<XRETURN
 STA XTRNADDR
 LDA #>XRETURN
 STA XTRNADDR+1
 RTS

HELP_CMD LDA #3
 JSR NO_PARSE ; Does not modify Y
 JSR CROUT
 LDX #0
:L1 LDA HLPDIR,X
 BEQ :N1
 STA VPATH1+1,X
 INX
 BRA :L1
:N1 
 JSR SKIPWS
 STZ TMPL
:L2 LDA GETLN,Y
 INY
 JSR ISALNUM
 BCC :N2
 AND #%01111111
 STA VPATH1+1,X
 INX
 INC TMPL
 BRA :L2
:N2 STX VPATH1
 LDA TMPL
 BNE :HASCMD
 DEX VPATH1
:HASCMD 

* Get help file info
 LDA #$C4 ; GET_FILE_INFO
 JSR GOSYSTEM
 BCS DOERR

 STZ TMPH
 LDA FIFILID
 CMP #TXT_TYPE
 BEQ OPENHLP
 CMP #DIR_TYPE
 BNE DOERR
 INC TMPH ; TMPH=1 if reading a dir
 
* Open the help file
OPENHLP LDA #COPEN ; $C8
 JSR GOSYSTEM
 BCS DOERR

* Read the help file
READHLP LDA OREFNUM
 STA RWREFNUM
 STZ RWDATA
 STZ RWCOUNT
 LDA #1
 STA RWCOUNT+1
 INC
 STA RWDATA+1
 LDA #CREAD ; $CA
 JSR GOSYSTEM
 BCC PRTHLP
 CMP #05 ; EOF
 BEQ DONEHLP
 JMP DOERR
PRTHLP LDX #0
:L1 LDA GETLN,X
 ORA #$80
 JSR COUT
 INX
 CPX RWTRANS
 BNE :L1
 BEQ READHLP
 
DONEHLP LDA #CCLOSE ; $CC  
 JSR GOSYSTEM

* JSR CROUT
* LDX PATHBUF1
* JSR PRNTX
* JSR PRBLNK
* LDY #1
*:Z1 LDA PATHBUF1,Y
* ORA #$80
* JSR COUT
* INY
* DEX
* BNE :Z1
* JSR CROUT

 CLC
 RTS

DOERR ; TODO
 RTS

QUIT_CMD LDA #3
 JSR NO_PARSE
 JSR CROUT
* Can't do this because we'd overwrite ourselves!
* JSR FREEBUFR
  
 LDA #"Q"
 JSR COUT
 JSR CROUT
 CLC
 RTS

* Test if accumulator contains an alphanumeric char
* (a-z, A-Z, 0-9)
ISALNUM CMP #"0"
 BLT NO1
 CMP #";"
 BLT YES1
* Test if accumulator contains an alphabetic char
* (a-z, A-Z)
ISALPHA
 AND #%11011111 ; to uppercase
 CMP #"A"
 BLT NO1
 CMP #"["
 BGE NO1 
YES1 SEC
 RTS
NO1 CLC
 RTS

SKIPWS LDA GETLN,Y
 CMP #" "
 BNE :DONE
 INY
 BRA SKIPWS
:DONE RTS  

* Compare first part of GETLN to pascal string in
* X(lo),A(hi)
* On return, Y is offset of first non-command character
* in GETLN.

CMPSTR LDY #0
 STX $06
 STA $07
:LOOP LDA GETLN,Y
 AND #%11011111 ; to uppercase
 TAX
 AND #%11100000
 CMP #%11000000
 BEQ :ISLETR
 LDX #0
:ISLETR TXA
 CMP ($06),Y
 BNE :NOMATCH
 CMP #0
 BEQ :DONE
 INY
 BRA :LOOP
:DONE
 SEC
 RTS
:NOMATCH 
 CLC
 RTS

* Data area
                               
CMDPATHLEN DFB $0 ; Length of command directory path
CMDPATH DS $40 ; Command directory path
PATHBUF1 DS $40 ; Path buffer 1 
PATHBUF2 DS $40 ; Path buffer 2                

SAVEDCMD DW $0000 ; Saved EXTRNCMD vector

THELP ASC "HELP",00
TQUIT ASC "QUIT",00
TCMDS ASC "CMDS",00
    
CMDDIR ASC '/IIC/WORK/CMDS/',00
HLPDIR ASC '/IIC/WORK/HELP/',00
               
NXTBUF DFB $00
CACHETBL DS 256

 DS \

BUFFERS EQU *
BUF1 DS 256
BUF2 DS 256
BUF3 DS 256
BUF4 DS 256
* BUF5 DS 256
* BUF6 DS 256
* BUF7 DS 256
* BUF8 DS 256

PROGEND EQU *

 TYP $06
 SAV /IIC/WORK/BASSHELL.BIN
