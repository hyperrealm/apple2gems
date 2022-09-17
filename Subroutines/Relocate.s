
.MACPACK generic
.FEATURE string_escapes

.include "Monitor.s"
.include "Macros.s"
.include "ZeroPage.s"

        .setcpu "65c02"

;;; Zero Page usage.

PageDelta     := $06 ; relocation page offset
CurrentAddr   := ZeroPage::A1 ; Current address (for relocation loop)
EndAddr       := ZeroPage::A2 ; End address of block
OrigEndAddr   := ZeroPage::A3 ; End address of original code

;;; Input: target page in A, length of code in X (lo), Y (hi)
;;; Source address assumed to be $2000

        .org $9600

.proc Relocate

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
        lda   ZeroPage::OPCODELEN  ; instruction length - 1
        cmp   #2                ; absolute mode?
        bne   NextInstruction

        pha   ; save instruction length - 1

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
        pla   ; restore instruction length - 1

;;; Advance CurrentAddr by A + 1 (length of instruction)

NextInstruction:
        sec
        adc   CurrentAddr
        bcc   @Skip
        inc   CurrentAddr+1
@Skip:  lda   CurrentAddr+1
        cmp   EndAddr+1
        bne   @Done
        lda   CurrentAddr
        cmp   EndAddr
        bne   Loop
@Done:  rts

;;; Check if address in X (lo), A (hi) is within the original block.
;;; Does not modify X or Y.
Within:
        cmp   #OrigStartPage
        blt   @No
        cmp   OrigEndAddr+1
        blt   @Yes
        bne   @No
        txa
        cmp   OrigEndAddr
        blt   @Yes
@No:    clc
        rts
@Yes:   sec
        rts

.endproc
