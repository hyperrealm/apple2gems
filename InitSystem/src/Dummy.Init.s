
.MACPACK generic

.include "Monitor.s"
.include "ProDOS.s"
.include "Macros.s"

        .setcpu "65c02"
        .org  ProDOS::SysLoadAddress

Init:
        ldx   #0
@Loop:  lda   Message,X
        beq   @Next
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Next:  ldx   #5
@WaitLoop:
        lda   #$FF
        jsr   Monitor::WAIT
        lda   #'.' | $80
        jsr   Monitor::COUT
        dex
        bne   @WaitLoop
        jsr   Monitor:: CROUT
        rts

Message:
        hiighascii "DUMMY INIT OK"
        .byte $8D
        .byte $00
