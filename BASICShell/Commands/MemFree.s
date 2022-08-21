;;; An external command for BASIC.SHELL  that displays how much free
;;; memory there is for BASIC programs.

.MACPACK generic
.FEATURE string_escapes

.include "ZeroPage.s"
.include "BASICSystem.s"
.include "Applesoft.s"
.include "Monitor.s"
.include "Macros.s"

        .setcpu "65c02"
        .org  ProDOS::SysLoadAddress

        jmp   Start
        .byte $CC
        .byte $CC ; signature bytes

MYPBITS:
        .word $0000 ; parsing flags
MYXBITS:
        .byte $00 ; shell flags

BytesFreeText:
        highasciiz " BYTES FREE\r"
ProgramText:
        highasciiz "PROGRAM:   "
VariablesText:
        highasciiz "VARIABLES: "

Start:
;;; Free space = (FRETOP-STREND) + (VARTAB-PRGEND)

;;; Compute FRETOP - STREND and store in A1L/H
        sec
        lda   ZeroPage::FRETOP
        sbc   ZeroPage::STREND
        sta   ZeroPage::A1L
        lda   ZeroPage::FRETOP+1
        sbc   ZeroPage::STREND+1
        sta   ZeroPage::A1H

;;; Compute VARTAB - PRGEND and store in A2L/H
        sec
        lda   ZeroPage::VARTAB
        sbc   ZeroPage::PRGEND
        sta   ZeroPage::A2L
        lda   ZeroPage::VARTAB+1
        sbc   ZeroPage::PRGEND+1
        sta   ZeroPage::A2H

;;; Compute A1L/H + A2L/H and store at A3L/H
        clc
        lda   ZeroPage::A1L
        adc   ZeroPage::A2L
        sta   ZeroPage::A3L
        tax
        lda   ZeroPage::A1H
        adc   ZeroPage::A2H
        sta   ZeroPage::A3H

        jsr   Monitor::CROUT
        jsr   Applesoft::LINPRT
        lda   #<BytesFreeText
        ldy   #>BytesFreeText
        jsr   Applesoft::STROUT

        lda   ZeroPage::A2L
        ora   ZeroPage::A2H
        beq   @Done

        lda   #<ProgramText
        ldy   #>ProgramText
        jsr   Applesoft::STROUT
        ldx   ZeroPage::A2L
        lda   ZeroPage::A2H
        jsr   Applesoft::LINPRT
        jsr   Monitor::CROUT

        lda   #<VariablesText
        ldy   #>VariablesText
        jsr   Applesoft::STROUT
        ldx   ZeroPage::A1L
        lda   ZeroPage::A1H
        jsr   Applesoft::LINPRT
        jsr   Monitor::CROUT

@Done:  rts
