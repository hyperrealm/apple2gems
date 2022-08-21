
.MACPACK generic
.FEATURE string_escapes

.include "Monitor.s"
.include "ProDOS.s"
.include "Macros.s"

        .setcpu "65c02"
        .org  ProDOS::SysLoadAddress

Init:
        ldx   #0
@Loop:  lda   MessageText,X
        beq   @Next
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Next:  ldx   #5
@WaitLoop:
        lda   #$FF
        jsr   Monitor::WAIT
        lda   #HICHAR('.')
        jsr   Monitor::COUT
        dex
        bne   @WaitLoop
        jsr   Monitor::CROUT
        rts

MessageText:
        highasciiz "DUMMY INIT OK\r"
