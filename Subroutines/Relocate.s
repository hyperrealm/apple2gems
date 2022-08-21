
.MACPACK generic
.FEATURE string_escapes

.include "Monitor.s"
.include "Macros.s"
.include "ZeroPage.s"

        .setcpu "65c02"

;;; Zero Page usage.


;;; Input: target page in A, length of code in X (lo), Y (hi)
;;; Source address assumed to be $2000

        .org $9600

.proc Relocate

PageDelta     := $06 ; relocation page offset
CurrentAddr   := Monitor::A1L ; Current address (for relocation loop)
EndAddr       := Monitor::A2L ; End address of block
OrigEndAddr   := Monitor::A3L ; End address of original code
OrigStartPage := $20

        stx   OrigEndAddr
        sty   OrigEndAddr+1
        stx   EndAddr
        sty   EndAddr+1
        stz   CurrentAddr
        sta   CurrentAddr+1
        pha   ; save target page

        clc
        sbc   #OrigStartPage
        sta   PageDelta
        lda   OrigEndAddr+1
        clc
        adc   #OrigStartPage
        sta   OrigEndAddr+1
        pla
        clc
        adc   EndAddr+1
        sta   EndAddr+1

;;; Read the JMP address in the first instruction, relocate it, and store
;;; it in CurrentAddr

        ldy   #1
        lda   (CurrentAddr),Y
        tax
        iny
        lda   (CurrentAddr),Y
        clc
        adc   PageDelta
        sta   CurrentAddr+1
        stx   CurrentAddr

Loop:
;;; Load opcode, check if length is 3...if not, no relocation needed.
        lda   (CurrentAddr)
        jsr   Monitor::INSDS2
        lda   ZeroPage::LENGTH
        cmp   #3
        bne   NextInstruction

        pha   ; save instruction length

        ldy   #1
        lda   (CurrentAddr),Y
        tax
        iny
        lda   (CurrentAddr),Y
        tay
        jsr   Within
        bcc   NoRelocate
        tya
        clc
        adc   PageDelta
        sta   (CurrentAddr),Y

NoRelocate:
        pla   ; restore instruction length

;;; Advance CurrentAddr by A (length of instruction)

NextInstruction:
        clc
        adc   CurrentAddr
        bcc   @Skip
        inc   CurrentAddr+1
@Skip:  lda   CurrentAddr+1
        cmp   EndAddr+1
        bne   @Done
        lda   CurrentAddr
        cmp   EndAddr
        bne   @Loop
@Done:  rts

;;; Check if address in X (lo), A (hi) is within the original block.
;;; Does not modify X or Y.
Within:
        cmp   #$20
        blt   @No
        cmp   OrigEndAddr+1
        blt   @yes
        bne   @No
        txa
        cmp   OrigEndAddr
        blt   @Yes
@No:    clc
        rts
@Yes:   sec
        rts

.endproc
