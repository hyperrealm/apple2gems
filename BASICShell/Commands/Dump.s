
 ORG $2000
 XC

A1L EQU $3C
A1H EQU $3D
A2L EQU $3E
A2H EQU $3F
A4L EQU $42
A4H EQU $43

KBD EQU $C000
KBDSTRB EQU $C010
RD80VID EQU $C01F
PRBYTE EQU $FDDA
COUT EQU $FDED
CROUT EQU $FD8E

MASKLO EQU $FA
MASKHI EQU $FB
ROWLEN EQU $FC
MIN EQU $FD
MAX EQU $FE
LAST EQU $EB
TMP EQU $EC

 LDA $6
 STA A1L
 LDA $7
 STA A1H
 LDA $8
 STA A2L
 LDA $9
 STA A2H
 LDA $EE
 STA A4L
 LDA $EF
 STA A4H

DUMP LDA #%00000111
 STA MASKLO
 LDA #%11111000
 STA MASKHI
 LDA #8
 STA ROWLEN
 STA MAX
 STZ LAST

* Check for 80-columns

 BIT RD80VID
 BPL :SKIP80 ; not 80
 ASL ROWLEN
 ASL MAX
 ASL MASKHI
 ROL MASKLO

:SKIP80 LDA A1L
 TAX
 AND MASKLO
 STA MIN
 TXA
 AND MASKHI
 STA A1L
 
* Print address and colon

PRADDR LDA A1H
 JSR PRBYTE
 LDA A1L
 CLC
 ADC MIN
 JSR PRBYTE
 LDA #":"    
 JSR COUT

* Check if this is the last line

 LDA A2H
 CMP A1H
 BLT :DONE
 BNE :CONT2
 LDA A2L
 CMP A1L
 BGE :CONT2
:DONE RTS

* A1L <= A2L. this is the last line if
* their high-masked bits are equal

:CONT2 TAX ; Save A2L
 AND MASKHI
 STA TMP
 LDA A1L
 AND MASKHI
 CMP TMP
 BNE :NOTLAST  

 TXA
 AND MASKLO
 INC
 STA MAX
 INC LAST

:NOTLAST

 LDY #0

PRBYTES LDA #" "
 JSR COUT

 CPY MIN
 BLT :PAD
 CPY MAX
 BGE :PAD

 LDA (A1L),Y
 JSR PRBYTE
 BRA :SKIP

:PAD JSR COUT
 JSR COUT

:SKIP INY
 CPY ROWLEN
 BEQ PRSEP
 CPY #8
 BNE PRBYTES
 LDA #" "
 JSR COUT
 LDA #"-"
 JSR COUT
 BRA PRBYTES
 
PRSEP LDA #" "
 JSR COUT
 LDA #"|"
 JSR COUT
 
 LDY #0

PRCHARS CPY MIN
 BLT :PAD
 CPY MAX
 BGE :PAD

 LDA (A1L),Y
 TAX
 AND #%01100000
 BNE :NOTCTRL
 LDX #"."

:NOTCTRL TXA 
 ORA #$80
 JSR COUT
 BRA :NXTCHAR

:PAD LDA #" "
 JSR COUT

:NXTCHAR INY
 CPY ROWLEN
 BNE PRCHARS

* Check for keypress

 LDA KBD
 STA KBDSTRB
 BPL :CONT
 CMP #$83 ; ^C
 BEQ DONE
 CMP #$9B ; Esc
 BEQ DONE
 CMP #$93 ; ^S
 BNE :CONT
:WAIT BIT KBD 
 BPL :WAIT
 STA KBDSTRB

* New line; advance A1L/H by ROWLEN bytes

:CONT JSR CROUT

 CLC
 LDA A1L
 ADC ROWLEN
 STA A1L
 BCC :L1
 INC A1H
:L1

 LDA LAST
 BNE DONE

 STZ MIN
 JMP PRADDR
 
DONE RTS

