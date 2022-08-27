;;; Disassembly of SU2.OBJ from the Apple IIc System Utilities Disk.
;;; This program installs a set of ampersand routines for enhanced
;;; input and output:
;;;
;;; &GET <var>   - input a single character into <var>
;;; &INPUT <var> - input a line of text into <var>
;;; &PRINT ...   - similar to PRINT, but with word-wrapping
;;; &HTAB <pos>  - similar to HTAB, but works in 80-column mode
;;; &EXIT        - uninstalls the routines

.MACPACK generic
.FEATURE string_escapes

        .include "Applesoft.s"
        .include "BASICSystem.s"
        .include "ControlChars.s"
        .include "Macros.s"
        .include "MemoryMap.s"
        .include "Monitor.s"
        .include "ProDOS.s"
        .include "SoftSwitches.s"
        .include "Vectors.s"
        .include "ZeroPage.s"

        .setcpu "65C02"

        .org    $2000

ResidentAddr := $8BD6

Loader:
        lda     #>ResidentCode
        sta     ZeroPage::A1H
        lda     #<ResidentCode
        sta     ZeroPage::A1L
        lda     #>(ResidentCode+MainCodeEnd-MainCodeStart)
        sta     ZeroPage::A2H
        lda     #<(ResidentCode+MainCodeEnd-MainCodeStart)
        sta     ZeroPage::A2L
        lda     #>ResidentAddr
        sta     ZeroPage::A4H
        lda     #<ResidentAddr
        sta     ZeroPage::A4L
        jsr     Relocate
        jmp     Install

Relocate:
        ldy     #$00
@Loop:  lda     (ZeroPage::A1),y
        sta     (ZeroPage::A4),y
        inc     ZeroPage::A4L
        bne     @Skip1
        inc     ZeroPage::A4H
@Skip1: lda     ZeroPage::A1L
        cmp     ZeroPage::A2L
        lda     ZeroPage::A1H
        sbc     ZeroPage::A2H
        inc     ZeroPage::A1L
        bne     @Skip2
        inc     ZeroPage::A1H
@Skip2: bcc     @Loop
        rts

ResidentCode := *

        .org    ResidentAddr

MainCodeStart := *

OLDCH := $047B
OURCH := $057B

ExitStatusReturnPressed     := $01
ExitStatusEscPressed        := $02
ExitStatusOpenApplePressed  := $03
ExitStatusSolidApplePressed := $04

IOBufferLength := $A0

;;;  Zero page usage:
VarPtr       := $FA
PrevAmperPtr := $FC
Pointer      := $FE

EntryPoint:
           jmp   AmperHandler

Install:
           jmp   AmperInstall

AmperAddr: .addr EntryPoint
PrevAmperAddr:
           .addr $0000

L8BE0:     .byte $00            ; never read
IIeOrNewerFlag:
           .byte $00
OriginalTXTPTR:
           .addr $0000
SavedTXTPTR:
           .addr $0000
SavedCSW:
StringLength:
           .byte $00
OASAStrVarIndex:
           .byte $00
OASAVarPtr:
           .addr $0000
PRINTOutputCharCount:
           .byte $0000

           .byte $00            ; unused

CharsLeftInOutputLine:
           .byte $00

SavedCHForPrint:
           .byte $00
CHDuringPrintOutput:
           .byte $00

L8BEF:     .byte $00            ; another storage for CH?
L8BF0:     .byte $00            ; another storage for CH? (during PRINT)
L8BF1:     .byte $00            ; ???

WordWrapSavedChar:              ; SHOULD BE +1
           .byte $00
ConvertToUpperCaseFlag:
           .byte $00            ; some kind of flag; $00 or $80
ConsumeOutputCharSavedY:
           .byte $00            ; storage for Y in ConsumeOutputChar
UnusedBytes2:
           .byte $00,$00,$00,$00,$00,$00 ; unused?
SavedCV:   .byte $00
SavedCH:   .byte $00

SavedCV2:  .byte $00            ; copy of ZeroPage::CV ; never read
ZeroPageStorage:
           .byte $00,$00,$00,$00,$00,$00,$00
BlinkCounter:
           .word $0000
CharUnderCursor:
           .byte $00
CursorIsVisible:
           .byte $00            ; $01 if visible, $00 if not
UnusedBytes3:
           .byte $00,$00        ; unused?
SavedARYTAB:
           .addr $0000          ; written, but never read
SavedBAtoBC:
           .byte $00, $00, $00  ; storage for $BA..$BC, in CHRGOT
TextWindowZPStorage2:           ; saves $20-$29
           .byte $00,$00,$00,$00,$00,$00,$00,$00
           .byte $00,$00
TextWindowZPStorage:            ; saves $20-$29
           .byte $00,$00,$00,$00,$00,$00,$00,$00
           .byte $00,$00
SkipClearingInputBufferFlag:
           .byte $00            ; $00 or $01
UnusedByte1:
           .byte $00            ; unused?
UnlimitedInputLengthFlag:
           .byte $00            ;set if  FL = 0
AlwaysZeroByte4:
           .byte $00            ; read, but never written
UnusedByte2:
           .byte $00            ; unused?
CharTyped:
           .byte $00
InputStringPtr:
           .addr $0000
SavedLOWTR:
           .addr $0000            ; LOWTR storage; never read
SavedVARPNT:
           .addr $0000          ; VARPNT storage; never read
OAVarPtr:  .addr $0000
SAVarPtr:  .addr $0000
OPStrVarPtr:
           .addr $0000
SOStrVarPtr:
           .addr $0000
ESVarPtr:
           .addr $0000
CTVarPtr:
           .addr $0000
EXVarPtr:
           .addr $0000
AlwaysZeroPtr:
           .addr $0000    ; some variable ptr that's read, but never written
IgnoreDefaultInputFlag:
           .byte $00    ; $01 = don't use default input when displaying
UsingCHRGETInterceptorFlag:
           .byte $00    ; only $00 ever gets written here
FillChar:  .byte $00
MaxInputLength:
           .byte $00
AlwaysZeroByte2:
           .byte $00    ; $00 stored here; never read
AlwaysZeroByte3:
           .byte $00    ; $00 stored here; never read
CurrentInputPos:
           .byte $00
CurrentInputLength:
           .byte $00
AppleKeyFlag:
           .byte $00    ; $01 = open apple, $00 = solid apple
UnusedBytes:
           .byte $00,$00,$00,$00 ; unused
SavedA:    .byte $00
SavedY:    .byte $00
SavedX:    .byte $00
UnusedBytes5:
           .byte $00,$00,$00    ; unused
AlwaysZeroByte5:
           .byte $00            ; $00 stored here; never read
BufferAddr:
           .addr IOBuffer
ExitValue: .byte $00            ; $01, $02, or $04 gets written here

;;;  unused garbage
           .byte $07,$5A,$8C,$49,$44,$00,$5F
           .byte $8C,$47,$49,$00,$64,$8C,$57,$49
           .byte $00

VariableTableAddr:
            .addr VariableTable
VariableTable:
           .asciiz "OP$"
           .asciiz "OA"
           .asciiz "SO$"
           .asciiz "SA"
           .asciiz "ES"
           .asciiz "CT"         ; this variable is never used
           .asciiz "FL$"
           .asciiz "FL"
           .asciiz "EX"

TokenTable:
           .byte ApplesoftToken::GET, $00
           .byte ApplesoftToken::HTAB, $00
           .byte ApplesoftToken::INPUT, $00
           .byte ApplesoftToken::PRINT, $00
           .asciiz "EXIT"
           .byte $00

JumpTableAddr:
           .addr JumpTable
JumpTable:
           jmp   GETHandler
           jmp   HTABHandler
           jmp   INPUTHandler
           jmp   PRINTHandler
           jmp   EXITHandler

AmperHandler:
           lda   ZeroPage::TXTPTR
           sta   OriginalTXTPTR
           lda   ZeroPage::TXTPTR+1
           sta   OriginalTXTPTR+1
           jsr   SaveZeroPage
           lda   #$00
           sta   StringLength
           ldx   #$00
L8CBA:     lda   TokenTable,x
           bne   L8CDA
           lda   JumpTableAddr
           sta   Pointer
           lda   JumpTableAddr+1
           sta   Pointer+1
L8CC9:     dec   StringLength
           bmi   L8CD7
           inc   Pointer
           bne   L8CC9
           inc   Pointer+1
           jmp   L8CC9
L8CD7:     jmp   (Pointer)
L8CDA:     jsr   ApplesoftRoutine::CHRGOT
           cmp   TokenTable,x
           bne   L8CEC
           inx
           inc   ZeroPage::TXTPTR
           bne   L8CE9
           inc   ZeroPage::TXTPTR+1
L8CE9:     jmp   L8CBA
L8CEC:     inx
           lda   TokenTable,x
           bne   L8CEC
           inc   StringLength
           inc   StringLength
           inc   StringLength
           inx
           jsr   RestoreOriginalTXTPTR
           lda   TokenTable,x
           beq   L8D07
           jmp   L8CBA
L8D07:     jsr   RestoreOriginalTXTPTR
           lda   AlwaysZeroByte4
           cmp   #$00
           beq   L8D15
           jsr   ApplesoftRoutine::CHRGOT
           rts
L8D15:     jsr   RestoreZeroPage
           lda   PrevAmperAddr
           sta   PrevAmperPtr
           lda   PrevAmperAddr+1
           sta   PrevAmperPtr+1
           jsr   ApplesoftRoutine::CHRGOT
           jmp   (PrevAmperPtr)

CheckForEndOfStatement:
           jsr   ApplesoftRoutine::CHRGOT
           jsr   IsEndOfStatementToken
           beq   L8D3C
           cmp   #' '
           beq   CheckForEndOfStatement
           jsr   RestoreBAtoBC
           ldx   #ApplesoftError::SyntaxError
           jmp   ApplesoftRoutine::ERROR
L8D3C:     lda   UsingCHRGETInterceptorFlag
           beq   L8D4F          ; branch always taken

;;; The code immediately following the LDA TXTPTR instruction in CHRGOT is
;;; overwritten with a JMP to CHRGETInterceptor.
           lda   #$4C           ; JMP instruction
           sta   $BA
           lda   CHRGETInterceptorAddr
           sta   $BB
           lda   CHRGETInterceptorAddr+1
           sta   $BC
L8D4F:     jsr   RestoreZeroPage
           rts

HTABHandler:
           jsr   HTABHandler1
           jmp   CheckForEndOfStatement
HTABHandler1:
           jsr   ApplesoftRoutine::GETBYT
           dex
           txa
           pha
           jsr   GetWindowAndScreenWidth
           bcs   L8D76
           pla
@Modulo40:
           cmp   #40
           bcc   L8D6E
           sbc   #40
           jmp   @Modulo40
L8D6E:     sta   ZeroPage::CH
           lda   #$00
           jsr   ApplesoftRoutine::OUTDO
           rts
L8D76:     pla
SetCHModulo80:
           cmp   #80
           bcc   L8D80
           sbc   #80
           jmp   SetCHModulo80
L8D80:     sta   OURCH
           lda   #$00
           sta   ZeroPage::CH
           sta   OLDCH
           rts

INPUTHandler:
           lda   UsingCHRGETInterceptorFlag
           beq   L8D95          ; branch always taken
           ldx   #ApplesoftError::SyntaxError
           jmp   ApplesoftRoutine::ERROR
L8D95:     lda   #$00
           sta   UsingCHRGETInterceptorFlag
           jsr   ApplesoftRoutine::PTRGET
           jsr   ApplesoftRoutine::CHKSTR
           lda   ZeroPage::VARPNT
           sta   InputStringPtr
           lda   ZeroPage::VARPNT+1
           sta   InputStringPtr+1
           jsr   LookUpVariables
           jsr   CheckForEndOfStatementOrComma
           bcs   L8DBC
           beq   L8DB9
           ldx   #ApplesoftError::SyntaxError
           jmp   ApplesoftRoutine::ERROR
L8DB9:     jmp   L8E08
L8DBC:     jsr   SaveTXTPTR
           jsr   ApplesoftRoutine::GETARYPT
           sec
           lda   ZeroPage::LOWTR
           sbc   ZeroPage::ARYTAB
           sta   SavedARYTAB
           lda   ZeroPage::LOWTR+1
           sbc   ZeroPage::ARYTAB+1
           sta   SavedARYTAB+1
           jsr   ApplesoftRoutine::CHKSTR
           jsr   ApplesoftRoutine::CHKOPN
           jsr   ApplesoftRoutine::PTRGET
           jsr   ApplesoftRoutine::CHKNUM
           lda   ZeroPage::VARPNT
           sta   SavedVARPNT
           lda   ZeroPage::VARPNT+1
           sta   SavedVARPNT+1
           jsr   ApplesoftRoutine::CHKCLS
           lda   ZeroPage::TXTPTR
           pha
           lda   ZeroPage::TXTPTR+1
           pha
           jsr   RestoreTXTPTR
           jsr   ApplesoftRoutine::GETARYPT
           lda   ZeroPage::LOWTR
           sta   SavedLOWTR
           lda   ZeroPage::LOWTR+1
           sta   SavedLOWTR+1
           pla
           sta   ZeroPage::TXTPTR+1
           pla
           sta   ZeroPage::TXTPTR
           lda   #$01
L8E08:     sta   IgnoreDefaultInputFlag
           jsr   ClearInputBuffer
           lda   #$00
           cmp   IgnoreDefaultInputFlag
           beq   L8E1A
           ldy   #$00
           jmp   L8E1D
L8E1A:     jsr   LoadDefaultInputStringIntoBuffer
L8E1D:     sty   CurrentInputPos
           sty   CurrentInputLength
           jsr   SaveTextWindowZPLocations
           jsr   PrintIOBuffer
           lda   #$00
           sta   SkipClearingInputBufferFlag
           jsr   ResetCursorBlinkTimer
           lda   UsingCHRGETInterceptorFlag
           bne   L8E3C
           jsr   WaitForAndProcessKeypresses
           jsr   UpdateVariables
L8E3C:     jmp   CheckForEndOfStatement

UpdateVariables:
           lda   #$00
           ldx   OAVarPtr+1
           ldy   OAVarPtr
           jsr   ClearVariable
           ldx   SAVarPtr+1
           ldy   SAVarPtr
           jsr   ClearVariable
           ldx   ESVarPtr+1
           ldy   ESVarPtr
           jsr   ClearVariable
           ldx   CTVarPtr+1
           ldy   CTVarPtr
           jsr   ClearVariable
           lda   ExitValue
           cmp   #ExitStatusReturnPressed
           beq   L8EAF
           cmp   #ExitStatusEscPressed
           bne   L8E7E
           lda   #$01
           ldy   ESVarPtr+1
           ldx   ESVarPtr
           jsr   StoreAInVarAtYX
           jmp   L8EAF
L8E7E:     cmp   #ExitStatusOpenApplePressed
           bne   L8E90
           lda   #$01
           ldy   OAVarPtr+1
           ldx   OAVarPtr
           jsr   StoreAInVarAtYX
           jmp   L8EAF
L8E90:     cmp   #ExitStatusSolidApplePressed
           bne   L8EA2
           lda   #$01
           ldy   SAVarPtr+1
           ldx   SAVarPtr
           jsr   StoreAInVarAtYX
           jmp   L8EAF
L8EA2:     cmp   #$05           ; useless comparison
           lda   #$01
           ldy   CTVarPtr+1
           ldx   CTVarPtr
           jsr   StoreAInVarAtYX
L8EAF:     rts

GETHandler:
           ldy   #$00
           sty   CurrentInputPos
           sty   CurrentInputLength
           lda   #HICHAR(' ')
           sta   IOBuffer,y
           lda   #$00
           jsr   ApplesoftRoutine::OUTDO
           jsr   ApplesoftRoutine::CHRGOT
           jsr   ApplesoftRoutine::PTRGET
           jsr   ApplesoftRoutine::CHKSTR
           jsr   SaveTextWindowZPLocations
           lda   #$01
           sta   MaxInputLength
           jsr   InputChar
           pha
           lda   #$01
           jsr   ReserveSpaceInString
           ldy   #$01
           lda   (ZeroPage::VARPNT),y
           sta   VarPtr
           iny
           lda   (ZeroPage::VARPNT),y
           sta   VarPtr+1
           pla
           ldy   #$00
           sta   (VarPtr),y
           jmp   CheckForEndOfStatement
InputChar:
           jsr   UpdateCursor
           jsr   CheckForKeypress
           bcc   InputChar
           jsr   HideCursor
           rts

           rts

PRINTHandler:
           jsr   ClampTextWindowWidth
           lda   #$00
           sta   PRINTOutputCharCount
           sta   PRINTOutputCharCount+1
L8F07:     sta   L8BF1
           lda   ZeroPage::CH
           sta   SavedCHForPrint
           lda   BufferAddr
           sta   Pointer
           lda   BufferAddr+1
           sta   Pointer+1
           lda   ZeroPage::CSW
           sta   SavedCSW
           lda   ZeroPage::CSW+1
           sta   SavedCSW+1
           lda   #<ConsumeOutputChar
           sta   ZeroPage::CSW
           lda   #>ConsumeOutputChar
           sta   ZeroPage::CSW+1
           jsr   ApplesoftHandler::PRINT-3
           lda   #>IOBuffer ; value may have been modified by ConsumeOutputChar
           sta   Pointer+1  ; so restore it
           lda   ZeroPage::CH
           sta   L8BEF
           lda   SavedCSW
           sta   ZeroPage::CSW
           lda   SavedCSW+1
           sta   ZeroPage::CSW+1
           bit   L8BF1
           bmi   L8F64
           sec
           ror   L8BF1
           clc
           lda   SavedCHForPrint
           ldy   CHDuringPrintOutput
           beq   L8F58
           and   #$F0
           adc   CHDuringPrintOutput
L8F58:     sta   ZeroPage::CH
           sec
           lda   L8BEF
           sbc   CHDuringPrintOutput
           sta   L8BF0
L8F64:     jsr   AdvanceOutputToCH
           ldy   #$00
           sty   OASAVarPtr
           sty   OASAVarPtr+1
           sty   L8BF1
L8F72:     lda   (Pointer),y
           cmp   #HICHAR(' ')
           bne   L8F95
           jsr   ApplesoftRoutine::OUTDO
           jsr   DecrementPRINTOutputCharCount
           bcs   L8F83
           jmp   L9053
L8F83:     dec   CharsLeftInOutputLine
           bne   L8F8B
           jsr   StartNewOutputLine
L8F8B:     iny
           bne   L8F72
           inc   OASAVarPtr+1
           inc   Pointer+1
           bcc   L8F72
L8F95:     clc
           tya
           adc   Pointer
           sta   Pointer
           bcc   L8F9F
           inc   Pointer+1
L8F9F:     ldy   #$00
L8FA1:     lda   (Pointer),y
           beq   L8FB7
           cmp   #HICHAR(' ')
           beq   L8FB7
           cmp   #HICHAR(ControlChar::Return)
           beq   L8FB7
           iny
           bne   L8FA1
           inc   OASAVarPtr+1
           inc   Pointer+1
           bcc   L8FA1
L8FB7:     sta   WordWrapSavedChar
           iny
           sty   OASAVarPtr
           dey
           cpy   CharsLeftInOutputLine
           bcc   L8FD0
           beq   L8FD0
           bne   L8FCD
           ror   L8BF1
           bne   L8FD0
L8FCD:     jsr   StartNewOutputLine
L8FD0:     ldy   #$00
L8FD2:     lda   (Pointer),y
           cmp   #$E0
           bcs   L8FE3
           bit   ConvertToUpperCaseFlag
           bmi   L8FE3
           cmp   #$C0
           bcc   L8FE3
           and   #$DF
L8FE3:     jsr   ApplesoftRoutine::OUTDO
           dec   CharsLeftInOutputLine
           bne   L8FFA
           lda   WordWrapSavedChar
           cmp   #$A0
           bne   L8FF7
           iny
           bne   L8FF7
           inc   Pointer+1
L8FF7:     jsr   StartNewOutputLineNoCR
L8FFA:     jsr   DecrementPRINTOutputCharCount
           bcc   L9043
           iny
           cpy   OASAVarPtr
           bcc   L8FD2
           lda   WordWrapSavedChar
           beq   L9053
           ldx   PRINTOutputCharCount
           bne   L9024
           ldx   PRINTOutputCharCount+1
           bne   L9024
           cmp   #HICHAR(ControlChar::Return)
           beq   L9048
           cmp   #HICHAR(' ')
           bne   L9024
           iny
           bne   L9021
           inc   Pointer+1
L9021:     jsr   StartNewOutputLineNoCR
L9024:     bit   L8BF1
           bpl   L902D
           clc
           ror   L8BF1
L902D:     clc
           lda   Pointer
           adc   OASAVarPtr
           sta   Pointer
           lda   Pointer+1
           adc   #$00
           sta   Pointer+1
           ldy   #$00
           sty   OASAVarPtr
           jmp   L8F72
L9043:     lda   WordWrapSavedChar
           beq   L9053
L9048:     lda   ZeroPage::CH
           beq   L9053
           cmp   ZeroPage::WNDLFT
           beq   L9053
           jsr   ApplesoftRoutine::CRDO
L9053:     lda   L8BF0
           beq   L9068
           clc
           jsr   GetHorizCursorPos
           and   #$F0
           adc   L8BF0
           and   #$F0
           sta   ZeroPage::CH
           jsr   AdvanceOutputToCH
L9068:     jmp   CheckForEndOfStatement


;;; While CH/OURCH is > window width, output carriage return
;;; and decrement CH/OURCH by window width
AdvanceOutputToCH:
           jsr   GetWindowAndScreenWidth
           bcs   @Is80Col
           lda   ZeroPage::CH
           jmp   @Loop
@Is80Col:  lda   OURCH
@Loop:     cmp   ZeroPage::WNDWDTH
           bcc   L9086
           sbc   ZeroPage::WNDWDTH
           pha
           jsr   ApplesoftRoutine::CRDO
           pla
           jmp   @Loop
L9086:     sta   ZeroPage::CH
           sec
           lda   ZeroPage::WNDWDTH
           sbc   ZeroPage::CH
           sta   CharsLeftInOutputLine
           rts

;;; Consumes characters produced by PRINT, storing them in IOBuffer. This
;;; routine does not do bounds checking and in fact happily continues
;;; writing to subsequent memory pages beyond the end of it.
ConsumeOutputChar:
           sty   ConsumeOutputCharSavedY
           bit   L8BF1
           bmi   L90A2
           sec
           ror   L8BF1
           ldy   ZeroPage::CH
           sty   CHDuringPrintOutput
L90A2:     ldy   PRINTOutputCharCount
           sta   (Pointer),y
           iny
           sty   PRINTOutputCharCount
           bne   L90B2
           inc   PRINTOutputCharCount+1
           inc   Pointer+1 ; This is really bad...allows writing past the
L90B2:     pha             ; end of IOBuffer, into subsequent pages.
           lda   #$00
           sta   (Pointer),y
           pla
           ldy   ConsumeOutputCharSavedY
           rts

StartNewOutputLine:
           jsr   ApplesoftRoutine::CRDO
StartNewOutputLineNoCR:
           lda   ZeroPage::WNDWDTH
           sta   CharsLeftInOutputLine
           rts

DecrementPRINTOutputCharCount:
           sec
           lda   PRINTOutputCharCount
           sbc   #$01
           sta   PRINTOutputCharCount
           lda   PRINTOutputCharCount+1
           sbc   #$00
           sta   PRINTOutputCharCount+1
           rts

;;; if WNDLEFT+WNDWDTH > column_count, clamp WNDWDTH at
;;; column_count - WNDLEFT.
ClampTextWindowWidth:
           lda   #40
           bit   SoftSwitch::RD80VID
           bpl   @Is40Col
           lda   #80
@Is40Col:  pha
           lda   ZeroPage::WNDLFT
           clc
           adc   ZeroPage::WNDWDTH
           sta   StringLength
           pla
           sec
           sbc   StringLength
           bcs   @Out
           clc
           adc   ZeroPage::WNDWDTH
           sta   ZeroPage::WNDWDTH
@Out:      rts

GetHorizCursorPos:
           ldx   #$00
           lda   Monitor::MAINID
           cmp   #$06
           bne   L910B
           ldx   #$80
           bit   Monitor::SUBID1
           bpl   L910B
           lda   OURCH
           bcs   L910D
L910B:     lda   ZeroPage::CH
L910D:     stx   ConvertToUpperCaseFlag
           rts

EXITHandler:
           lda   PrevAmperAddr
           sta   Vector::AMPERV+1
           lda   PrevAmperAddr+1
           sta   Vector::AMPERV+2
           jsr   BASICSystem::FREEBUFR
           rts

GetWindowAndScreenWidth:
           lda   SoftSwitch::RD80VID
           asl   a
           lda   ZeroPage::WNDWDTH
           rts

SaveTXTPTR:
           lda   ZeroPage::TXTPTR
           sta   SavedTXTPTR
           lda   ZeroPage::TXTPTR+1
           sta   SavedTXTPTR+1
           rts

RestoreTXTPTR:
           lda   SavedTXTPTR
           sta   ZeroPage::TXTPTR
           lda   SavedTXTPTR+1
           sta   ZeroPage::TXTPTR+1
           rts

RestoreOriginalTXTPTR:
           lda   OriginalTXTPTR
           sta   ZeroPage::TXTPTR
           lda   OriginalTXTPTR+1
           sta   ZeroPage::TXTPTR+1
           rts

LoadDefaultInputStringIntoBuffer:
           lda   InputStringPtr
           sta   Pointer
           lda   InputStringPtr+1
           sta   Pointer+1
           ldy   #$00
           lda   (Pointer),y
           beq   L9183
           sec
           sbc   MaxInputLength
           bcc   L9165
           lda   MaxInputLength
           jmp   L9167
L9165:     lda   (Pointer),y
L9167:     sta   StringLength
           iny
           lda   (Pointer),y
           pha
           iny
           lda   (Pointer),y
           sta   Pointer+1
           pla
           sta   Pointer
           ldy   #$00
L9178:     lda   (Pointer),y
           sta   IOBuffer,y
           iny
           cpy   StringLength
           bne   L9178
L9183:     rts

ClearInputBuffer:
           lda   #$00
           sta   CurrentInputPos
           sta   CurrentInputLength
           tay
           jsr   ClearInputBufferFromY
           rts

ClearInputBufferFromY:
           lda   FillChar
           sta   IOBuffer,y
           cpy   #IOBufferLength-1
           beq   @Out
           iny
           jmp   ClearInputBufferFromY
@Out:      rts

IsDelete:
           cmp   #ControlChar::Delete
           beq   HandleDelete
           cmp   #ControlChar::ControlD
           beq   HandleDelete
           jmp   ControlCharNotMatched
HandleDelete:
           jsr   DeleteCharBeforeCursor
           jmp   ControlCharHandled

DeleteCharBeforeCursor:
           jsr   HideCursor
           ldy   CurrentInputPos
           beq   L91F6
           ldx   CurrentInputPos
           dex
ShiftTextLeft:
           lda   IOBuffer,y
           sta   IOBuffer,x
           iny
           tya
           sec
           sbc   MaxInputLength
           bcs   L91D1
           beq   L91D1
           inx
           jmp   ShiftTextLeft
L91D1:     lda   FillChar
           dey
           sta   IOBuffer,y
           lda   CurrentInputPos
           bne   L91E4
           lda   CurrentInputLength
           bne   L91E7
           beq   L91EA
L91E4:     dec   CurrentInputPos
L91E7:     dec   CurrentInputLength
L91EA:     lda   UnlimitedInputLengthFlag
           beq   L91F2
           dec   MaxInputLength
L91F2:     jsr   ResetCursorBlinkTimer
           rts
L91F6:     jmp   Beep

IsArrow:
           cmp   #ControlChar::LeftArrow
           beq   HandleLeftArrow
           cmp   #ControlChar::RightArrow
           beq   HandleRightArrow
           jmp   ControlCharNotMatched
HandleLeftArrow:
           jsr   MoveCursorLeft
           jmp   ControlCharHandled
HandleRightArrow:
           jsr   MoveCursorRight
           jmp   ControlCharHandled

MoveCursorLeft:
           ldy   CurrentInputPos
           bne   @OK
           jmp   Beep
@OK:       jsr   HideCursor
           dec   CurrentInputPos
           jsr   ResetCursorBlinkTimer
           rts

MoveCursorRight:
           ldy   CurrentInputPos
           iny
           cpy   MaxInputLength
           bne   MoveCursorRightNoLengthCheck
           jmp   Beep
MoveCursorRightNoLengthCheck:
           jsr   HideCursor
           dey
           tya
           sec
           sbc   CurrentInputLength
           bcc   L923C
           jmp   Beep
L923C:     inc   CurrentInputPos
           jsr   ResetCursorBlinkTimer
           rts

Beep:      jsr   Monitor::BELL1
           rts

ControlCharNotMatched:
           clc
           jmp   ReturnCharTypedInA

ControlCharHandled:
        sec
ReturnCharTypedInA:
           lda   CharTyped
           rts

IsControlRorZ:
           cmp   #ControlChar::ControlR
           beq   HandleUndo
           cmp   #ControlChar::ControlZ
           beq   HandleUndo
           jmp   ControlCharNotMatched
HandleUndo:
           jsr   HideCursor
           jsr   ClearInputBuffer
           lda   IgnoreDefaultInputFlag
           bne   L9272
           jsr   LoadDefaultInputStringIntoBuffer
           sty   CurrentInputPos
           sty   CurrentInputLength
           jsr   ResetCursorBlinkTimer
L9272:     jmp   ControlCharHandled

IsControlY:
           cmp   #ControlChar::ControlY
           beq   HandleClearToEnd
           jmp   ControlCharNotMatched
HandleClearToEnd:
           jsr   HideCursor
           ldy   CurrentInputPos
           sty   CurrentInputLength
           jsr   ClearInputBufferFromY
           jsr   ResetCursorBlinkTimer
           jmp   ControlCharHandled

IsControlX:
           cmp   #ControlChar::ControlX
           beq   HandleClear
           jmp   ControlCharNotMatched
HandleClear:
           jsr   HideCursor
           jsr   ClearInputBuffer
           jsr   ResetCursorBlinkTimer
           lda   CurrentInputPos
           sta   CurrentInputLength
           jmp   ControlCharHandled

IsControlF:
           cmp   #ControlChar::ControlF
           beq   DeleteCharUnderCursor
           jmp   ControlCharNotMatched

DeleteCharUnderCursor:
           ldy   CurrentInputPos
           cpy   MaxInputLength
           beq   L92DA
           cpy   CurrentInputLength
           bcc   L92C1
           jsr   Beep
           jmp   ControlCharHandled
L92C1:     jsr   HideCursor
           ldy   CurrentInputPos
           iny
           ldx   CurrentInputPos
           jsr   ShiftTextLeft
           ldy   CurrentInputPos
           beq   L92D7
           iny
           jsr   MoveCursorRightNoLengthCheck
L92D7:     jmp   ControlCharHandled
L92DA:     jsr   DeleteCharBeforeCursor
           jmp   ControlCharHandled

IsReturn:
           cmp   #ControlChar::Return
           beq   HandleAcceptInput
           jmp   ControlCharNotMatched
HandleAcceptInput:
           lda   #ExitStatusReturnPressed
           sta   ExitValue
HandleAcceptInputWithExitValueInA:
           jsr   StoreAInEXVar
           jsr   HideCursor
           jsr   PadOrTruncateInput
           pha
           lda   InputStringPtr
           sta   ZeroPage::VARPNT
           lda   InputStringPtr+1
           sta   ZeroPage::VARPNT+1
           pla
           jsr   ReserveSpaceInStringNoLengthCheck
           jsr   CopyIOBUfferIntoString
           jmp   ControlCharHandled

;;; This apparently clears the first two bytes of the data field of
;;; the variable pointed by VarPtr. It's always called with A=0, on both
;;; floating point and string variables.
ClearVariable:
           stx   VarPtr+1
           sty   VarPtr
           ldy   #$01
           sta   (VarPtr),y
           lda   #$00
           dey
           sta   (VarPtr),y
           rts

StoreAInVarAtYX:
           stx   VarPtr+1            ; save X and Y
           sty   VarPtr
           jsr   ApplesoftRoutine::FLOAT ; convert A to value in FAC
           ldx   VarPtr+1            ; restore X and Y
           ldy   VarPtr
           jsr   ApplesoftRoutine::MOVMF ; copy value in FAC to variable
           rts

StoreAInEXVar:
           jsr   ApplesoftRoutine::FLOAT
           ldy   EXVarPtr+1
           ldx   EXVarPtr
           jsr   ApplesoftRoutine::MOVMF
           rts

IsEsc:
           cmp   #ControlChar::Esc
           beq   HandleCancelInput
           jmp   ControlCharNotMatched
HandleCancelInput:
           lda   #ExitStatusEscPressed
           sta   ExitValue
           jmp   HandleAcceptInputWithExitValueInA

CheckForKeypress:
           lda   SoftSwitch::KBD
           rol   a
           bcc   @None
           sta   SoftSwitch::KBDSTRB
           clc
           ror   a
           sec
           rts
@None:     clc
           rts

CheckForAppleKey:
           lda   SoftSwitch::RDBTN0
           rol   a
           bcc   CheckForSolidApple
           lda   #$01
           sta   AppleKeyFlag
           lda   OPStrVarPtr
           sta   Pointer
           lda   OPStrVarPtr+1
           sta   Pointer+1
           lda   OAVarPtr
           sta   OASAVarPtr
           lda   OAVarPtr+1
           sta   OASAVarPtr+1
           jmp   L939A
CheckForSolidApple:
           lda   SoftSwitch::RDBTN1
           rol   a
           bcs   L937F
           jmp   ControlCharNotMatched
L937F:     lda   #$00
           sta   AppleKeyFlag
           lda   SOStrVarPtr
           sta   Pointer
           lda   SOStrVarPtr+1
           sta   Pointer+1
           lda   SAVarPtr
           sta   OASAVarPtr
           lda   SAVarPtr
           sta   OASAVarPtr+1
L939A:     ldy   #$00
           lda   (Pointer),y
           bne   L93A3
           jmp   L9427
L93A3:     sta   StringLength
           sty   OASAStrVarIndex
           iny
           lda   (Pointer),y
           sta   VarPtr
           iny
           lda   (Pointer),y
           sta   VarPtr+1
           ldy   #$00
L93B5:     lda   (VarPtr),y
           cmp   #'-'
           bne   L93FC
           ldx   #$00
           cpx   OASAStrVarIndex
           beq   L93E9
           cmp   CharTyped
           bne   L93F7
L93C7:     ldy   #$00
           lda   CharTyped
           sta   (VarPtr),y
           lda   #$01
           sta   (Pointer),y
           lda   AppleKeyFlag
           beq   L93DC
           lda   #ExitStatusOpenApplePressed
           jmp   L93DE
L93DC:     lda   #ExitStatusSolidApplePressed
L93DE:     sta   ExitValue
           ldx   #$00
           stx   UsingCHRGETInterceptorFlag
           jmp   HandleAcceptInputWithExitValueInA
L93E9:     lda   #$01
L93EB:     sta   OASAStrVarIndex
           iny
           cpy   StringLength
           bne   L93B5
           jmp   L9427
L93F7:     lda   #$00
           jmp   L93EB
L93FC:     ldx   #$01
           cpx   OASAStrVarIndex
           beq   L940B
           cmp   CharTyped
           beq   L93C7
           jmp   L93F7
L940B:     cmp   CharTyped
           beq   L9415
           bpl   L9415
           jmp   L93F7
L9415:     dey
           dey
           bmi   L9422
           lda   (VarPtr),y
           cmp   CharTyped
           beq   L93C7
           bmi   L93C7
L9422:     iny
           iny
           jmp   L93F7
L9427:     lda   #$00
           sec
           rts

CheckForEndOfStatementOrComma:
           jsr   ApplesoftRoutine::CHRGOT
           cmp   #','
           beq   L9442
           cmp   #' '
           beq   CheckForEndOfStatementOrComma
           cmp   #':'
           beq   L9447
           cmp   #$00
           beq   L9447
           lda   #$01
           clc
           rts
L9442:     jsr   ApplesoftRoutine::CHRGET
           sec
           rts
L9447:     lda   #$00
           clc
           rts

;;; Called prior to starting input in &GET and &INPUT.
SaveTextWindowZPLocations:
           ldy   #$00
           ldx   #$0A
L944F:     lda   ZeroPage::WNDLFT,y
           sta   TextWindowZPStorage,y
           iny
           dex
           bne   L944F
           jsr   GetWindowAndScreenWidth
           bcc   L9466
           lda   OURCH
           ldy   #$04
           sta   TextWindowZPStorage,y ; update CH
L9466:     rts

ProcessKeypress:
           sta   CharTyped
           jsr   IsReturn
           bcc   @NotReturn
           jmp   FinishInput
@NotReturn:
           jsr   CheckForAppleKey
           bcc   CheckForControlChars
           beq   @NotAppleKey
           jmp   CancelInput
@NotAppleKey:
           jmp   L94CE
CheckForControlChars:
           jsr   IsEsc
           bcc   @NotEsc
           jmp   CancelInput
@NotEsc:   jsr   IsControlX
           bcs   L94CE
           jsr   IsControlY
           bcs   L94CE
           jsr   IsControlRorZ
           bcs   L94CE
           jsr   IsControlF
           bcs   L94CE
           jsr   IsArrow
           bcs   L94CE
           jsr   IsDelete
           bcs   L94CE
           lda   CharTyped
           beq   L94CE
           jsr   HideCursor
           lda   SkipClearingInputBufferFlag
           cmp   #$01
           beq   @SkipClear
           jsr   ClearInputBuffer
@SkipClear:
           lda   CharTyped
           and   #$7F
           sec
           sbc   #$20
           bcs   @NotControlChar
           jsr   Beep
           clc
           rts
@NotControlChar:
           lda   CharTyped
           jsr   InsertTypedCharIntoBuffer
           jsr   ResetCursorBlinkTimer
L94CE:     lda   #$01
           sta   SkipClearingInputBufferFlag
           jsr   PrintIOBuffer
           clc
           rts

FinishInput:
           jsr   PrintIOBuffer
           jmp   ReturnWithCarrySet

CancelInput:
           jsr   PrintIOBuffer
           jsr   GetWindowAndScreenWidth
           bcs   L94FA
           lda   CurrentInputLength
           clc
           adc   ZeroPage::CH
L94ED:     sta   ZeroPage::CH
           sec
           sbc   ZeroPage::WNDWDTH
           beq   ReturnWithCarrySet
           bcs   L94ED
           jmp   ReturnWithCarrySet
L94FA:     lda   CurrentInputLength
           clc
           adc   OURCH
L9500:     sta   OURCH
           sec
           sbc   ZeroPage::WNDWDTH
           beq   ReturnWithCarrySet
           bcs   L9500
ReturnWithCarrySet:
           sec
           rts

LookUpVariables:
           jsr   SaveTXTPTR
           lda   VariableTableAddr
           sta   ZeroPage::TXTPTR
           lda   VariableTableAddr+1
           sta   ZeroPage::TXTPTR+1
           jsr   ApplesoftRoutine::PTRGET
           sty   OPStrVarPtr+1
           sta   OPStrVarPtr
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           sty   OAVarPtr+1
           sta   OAVarPtr
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           sty   SOStrVarPtr+1
           sta   SOStrVarPtr
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           sty   SAVarPtr+1
           sta   SAVarPtr
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           sty   ESVarPtr+1
           sta   ESVarPtr
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           sty   CTVarPtr+1
           sta   CTVarPtr
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           ldy   #$00
           lda   (ZeroPage::VARPNT),y
           bne   L956F
           lda   #' '           ; default fill character
           jmp   L957D
L956F:     iny
           lda   (ZeroPage::VARPNT),y
           sta   Pointer
           iny
           lda   (ZeroPage::VARPNT),y
           sta   Pointer+1
           ldy   #$00
           lda   (Pointer),y
L957D:     sta   FillChar
           jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           jsr   ApplesoftRoutine::MOVFM
           jsr   ApplesoftRoutine::CONINT
           lda   #$00
           sta   UnlimitedInputLengthFlag
           cpx   #$00
           bne   L959A
           ldx   #$01
           stx   UnlimitedInputLengthFlag
L959A:     stx   MaxInputLength
           sec
           lda   #IOBufferLength
           sbc   MaxInputLength
           bcs   L95AA
           ldx   #ApplesoftError::IllegalQuantity
           jmp   ApplesoftRoutine::ERROR
L95AA:     jsr   ApplesoftRoutine::CHRGET
           jsr   ApplesoftRoutine::PTRGET
           sty   EXVarPtr+1
           sta   EXVarPtr
           jsr   RestoreTXTPTR
           rts

PadOrTruncateInput:
           ldy   CurrentInputLength
           cpy   MaxInputLength
           bcs   @Truncate
           lda   #' '
@Loop:     sta   IOBuffer,y
           iny
           cpy   MaxInputLength
           bcc   @Loop
           lda   CurrentInputLength
           rts
@Truncate: lda   MaxInputLength
           rts

PrintIOBuffer:
           jsr   SwapTextWindowZPLocations
           lda   ZeroPage::WNDWDTH
           sec
           sbc   #$01
           sta   OASAStrVarIndex
           cld
           sec
           sbc   ZeroPage::CH
           sta   StringLength
           lda   MaxInputLength
           sta   OASAVarPtr
           ldy   #$00
L95EF:     lda   #$00
           cmp   IgnoreDefaultInputFlag
           beq   L960B
           lda   IOBuffer,y
           jsr   IsLowercaseLetter
           bcs   L960E
           lda   IIeOrNewerFlag
           bne   L960B
           lda   IOBuffer,y
L9606:     and   #$7F
           jmp   L960E
L960B:     lda   IOBuffer,y
L960E:     iny
           tax
           jsr   IsInBottomRightCornerOfTextWindow
           txa
           bcc   L963A
           inc   ZeroPage::WNDWDTH
           inc   ZeroPage::WNDBTM
           jsr   ApplesoftRoutine::OUTDO
           dec   ZeroPage::WNDWDTH
           dec   ZeroPage::WNDBTM
           lda   #$00
           sta   UnlimitedInputLengthFlag
           sty   MaxInputLength
           dey
           sec
           tya
           sbc   CurrentInputPos
           bcs   L9637
           adc   CurrentInputPos
           sta   CurrentInputPos
L9637:     jmp   L9653
L963A:     jsr   ApplesoftRoutine::OUTDO
           dec   OASAVarPtr
           beq   L9653
           dec   StringLength
           beq   L964A
           jmp   L95EF
L964A:     lda   OASAStrVarIndex
           sta   StringLength
           jmp   L95EF
L9653:     lda   ZeroPage::CV
           sta   SavedCV2 ; never read
           pha
           jsr   RestoreSwappedTextWindowZPLocations
           pla
           sta   ZeroPage::CV
           rts

WaitForAndProcessKeypresses:
           jsr   UpdateCursor
           jsr   CheckForKeypress
           bcc   WaitForAndProcessKeypresses
           jsr   ProcessKeypress
           bcc   WaitForAndProcessKeypresses
           rts

CHRGETInterceptorAddr:
           .addr CHRGETInterceptor

;;; Dead code that is never called. (It's installed into CHRGET/CHRGOT
;;; only if UsingCHRGETInterceptorFlag is nonzero.) It appears to
;;; intercept the CHRGET/CHRGOT routines so that a single keypress can be
;;; processed while Applesoft is executing BASIC program code (basically
;;; an asynchronous read-key routine).
CHRGETInterceptor:
           jsr   SaveRegisters
           jsr   SaveZeroPage
           jsr   SaveCursorPos
           jsr   IsDeferredMode
           bcc   @Immed          ; branch if immediate mode
           jsr   UpdateCursor
           jsr   CheckForKeypress
           bcc   @Done
           jsr   ProcessKeypress
           bcc   @Done
           ldy   #$00
           jsr   ApplesoftRoutine::SNGFLT ; Y -> FAC
           ldy   AlwaysZeroPtr+1
           ldx   AlwaysZeroPtr
           jsr   ApplesoftRoutine::MOVMF ; FAC -> var
@Immed:    lda   #$00
           sta   UsingCHRGETInterceptorFlag
           jsr   RestoreBAtoBC
@Done:     jsr   RestoreCursorPos
           jsr   RestoreZeroPage
           jsr   RestoreRegisters
           cmp   #':'  ; Executes the remaining code in CHRGOT.
           bcs   L96B1
           jmp   $00BE ; CMP #' ' instruction in CHRGOT
L96B1:     jmp   $00C8 ; RTS instruction at end of CHRGOT

InsertTypedCharIntoBuffer:
           ldx   IgnoreDefaultInputFlag
           beq   L96BC
           jsr   CharToUppercase
L96BC:     sta   L8BF1
           lda   CurrentInputPos
           cmp   MaxInputLength
           bne   L96CA
           jmp   Beep
L96CA:     lda   UnlimitedInputLengthFlag
           beq   L96E1
           lda   MaxInputLength
           cmp   #IOBufferLength-1
           beq   L96DC
           inc   MaxInputLength
           jmp   L96E1
L96DC:     lda   #$00
           sta   UnlimitedInputLengthFlag
L96E1:     lda   MaxInputLength
           cld
           sec
           sbc   CurrentInputPos
           sta   WordWrapSavedChar
           ldx   MaxInputLength
           ldy   MaxInputLength
           dex
           dey
           dey
L96F5:     lda   IOBuffer,y
           sta   IOBuffer,x
           dex
           dey
           dec   WordWrapSavedChar
           bne   L96F5
           lda   L8BF1
           ldy   CurrentInputPos
           sta   IOBuffer,y
           cpy   MaxInputLength
           beq   @Out
           inc   CurrentInputPos
           ldy   CurrentInputLength
           cpy   MaxInputLength
           beq   @Out
           inc   CurrentInputLength
@Out:      rts

IsEndOfStatementToken:
           cmp   #':'
           beq   @Out
           cmp   #$00
@Out:      rts

ReserveSpaceInString:
           pha
           ldy   #$00
           cmp   (ZeroPage::VARPNT),y
           bcs   ReserveSpaceInStringAfterLengthCheck
           pla
           sta   (ZeroPage::VARPNT),y
           rts
ReserveSpaceInStringAfterLengthCheck:
           pla
           sta   BytesToReserve
           jsr   ReserveStringSpace
           ldy   #$00
           lda   BytesToReserve
           sta   (ZeroPage::VARPNT),y
           iny
           lda   ZeroPage::FRETOP
           sta   (ZeroPage::VARPNT),y
           iny
           lda   ZeroPage::FRETOP+1
           sta   (ZeroPage::VARPNT),y
           rts

ReserveSpaceInStringNoLengthCheck:
           pha
           jmp   ReserveSpaceInStringAfterLengthCheck

CopyIOBUfferIntoString:
           ldy   #$00
           lda   (ZeroPage::VARPNT),y
           sta   StringLength
           inc   StringLength
           iny
           lda   (ZeroPage::VARPNT),y
           sta   Pointer
           iny
           lda   (ZeroPage::VARPNT),y
           sta   Pointer+1
           ldy   #$00
@Loop:     cpy   StringLength
           beq   @Out
           lda   IOBuffer,y
           sta   (Pointer),y
           iny
           jmp   @Loop
@Out:      rts

IsLowercaseLetter:
           pha
           cmp   #'a'
           bmi   @No
           cmp   #'{'
           bpl   @No
           pla
           clc
           rts
@No:       pla
           sec
           rts

SaveRegisters:
           sta   SavedA
           sty   SavedY
           stx   SavedX
           rts

RestoreRegisters:
           lda   SavedA
           ldy   SavedY
           ldx   SavedX
           rts

;;; Also performs garbage collection if memory is low.
ReserveStringSpace:
           clc
           lda   ZeroPage::STREND
           adc   #$00
           tax
           lda   ZeroPage::STREND+1
           adc   #$02
           cpx   ZeroPage::FRETOP
           sbc   ZeroPage::FRETOP+1
           bcc   @Skip
           ldx   #$04
@Loop:     lda   FRECommand-1,x
           sta   MemoryMap::INBUF-1,x
           dex
           bne   @Loop
           jsr   BASICSystem::DOSCMD
@Skip:     sec
           lda   ZeroPage::FRETOP
           sbc   BytesToReserve
           sta   ZeroPage::FRETOP
           lda   ZeroPage::FRETOP+1
           sbc   #$00
           sta   ZeroPage::FRETOP+1
           lda   ZeroPage::STREND
           cmp   ZeroPage::FRETOP
           lda   ZeroPage::STREND+1
           sbc   ZeroPage::FRETOP+1
           bcs   Crash
           rts
Crash:     brk   ; unexpected out of memory condition

FRECommand:
           highascii "FRE\r"
BytesToReserve:
          .byte $00

CharToUppercase:
           jsr   IsLowercaseLetter
           bcs   @Out
           and   #%11011111
@Out:      rts

;;; Restore text window zero page locations from TextWindowZPStorage2.
RestoreSwappedTextWindowZPLocations:
           ldy   #$00
           ldx   #$0A
@Loop:     lda   TextWindowZPStorage2,y
           sta   ZeroPage::WNDLFT,y
           iny
           dex
           bne   @Loop
           jsr   GetWindowAndScreenWidth
           bcc   @Out
           ldy   #$04
           lda   TextWindowZPStorage2,y ; CH value
           sta   OURCH
           lda   #$00
           sta   OLDCH
           sta   ZeroPage::CH
@Out:      rts

;;; Copy text window zero page locations to TextWindowZPStorage2,
;;; then restore them from TextWindowZPStorage.
SwapTextWindowZPLocations:
           ldy   #$00
           ldx   #$0A
@Loop:     lda   ZeroPage::WNDLFT,y
           sta   TextWindowZPStorage2,y
           lda   TextWindowZPStorage,y
           sta   ZeroPage::WNDLFT,y
           iny
           dex
           bne   @Loop
           jsr   GetWindowAndScreenWidth
           bcc   @Out
           ldy   #$04
           lda   OURCH
           sta   TextWindowZPStorage2,y
           lda   TextWindowZPStorage,y
           sta   OURCH
@Out:      rts

IOBufferToUppercase:            ; never called
           ldy   #$00
@Loop:     cpy   MaxInputLength
           beq   @Out
           lda   IOBuffer,y
           jsr   CharToUppercase
           sta   IOBuffer,y
           iny
           jmp   @Loop
@Out:      rts

           ldy   OASAVarPtr+1          ; unreachable instruction?

RestoreBAtoBC:
           lda   SavedBAtoBC
           sta   $BA
           lda   SavedBAtoBC+1
           sta   $BB
           lda   SavedBAtoBC+2
           sta   $BC
           rts

SaveZeroPage:
           ldx   #$06
           ldy   #$00
@Loop:     lda   VarPtr,y
           sta   ZeroPageStorage,y
           iny
           dex
           bne   @Loop
           rts

RestoreZeroPage:
           ldx   #$06
           ldy   #$00
@Loop:     lda   ZeroPageStorage,y
           sta   VarPtr,y
           iny
           dex
           bne   @Loop
           rts

;;; Returns with Carry set if Applesoft is in deferred mode.
IsDeferredMode:
           lda   ZeroPage::CURLIN+1
           cmp   #$FF
           bne   @Deferred
           clc
           rts
@Deferred: sec
           rts

ResetCursorBlinkTimer:
           pha
           tya
           pha
           lda   #$00
           sta   BlinkCounter
           lda   #$01
           sta   BlinkCounter+1
           lda   #$00
           sta   CursorIsVisible
           pla
           tay
           pla
           rts

HideCursor:
           pha
           tya
           pha
           lda   CursorIsVisible
           beq   @NotVisible
           ldy   CurrentInputPos
           cpy   MaxInputLength
           bne   @Skip
           dey
@Skip:     lda   CharUnderCursor
           sta   IOBuffer,y
@NotVisible:
           lda   #$00
           sta   CursorIsVisible
           jsr   PrintIOBuffer
           pla
           tay
           pla
           rts

UpdateCursor:
           dec   BlinkCounter+1
           bne   L98FF
           lda   #$00
           cmp   BlinkCounter
           beq   L98C1
           dec   BlinkCounter
           jmp   L98FF
L98C1:     lda   CursorIsVisible
           bne   L9900
           lda   UsingCHRGETInterceptorFlag
           beq   L98D0          ; branch always taken
           lda   #$02
           jmp   L98D2
L98D0:     lda   #$08
L98D2:     sta   BlinkCounter
           lda   #$00
           sta   BlinkCounter+1
           ldy   CurrentInputPos
           cpy   MaxInputLength
           bne   L98E3
           dey
L98E3:     lda   IOBuffer,y
           sta   CharUnderCursor
           ldy   #$01
           lda   #HICHAR('_')
L98ED:     sty   CursorIsVisible
           ldy   CurrentInputPos
           cpy   MaxInputLength
           bne   L98F9
           dey
L98F9:     sta   IOBuffer,y
           jsr   PrintIOBuffer
L98FF:     rts
L9900:     lda   UsingCHRGETInterceptorFlag
           beq   L990A          ; branch always taken
           lda   #$01
           jmp   L990C
L990A:     lda   #$36
L990C:     sta   BlinkCounter
           lda   #$00
           sta   BlinkCounter+1
           ldy   #$00
           lda   CharUnderCursor
           jmp   L98ED

IsInBottomRightCornerOfTextWindow:
           lda   ZeroPage::CV
           clc
           adc   #$01
           cmp   ZeroPage::WNDBTM
           bne   L993E
           jsr   GetWindowAndScreenWidth
           bcc   @Is40Col
           cld
           sbc   #$01
           cmp   OURCH
           bne   L993E
           sec
           rts
@Is40Col:  cld
           sec
           sbc   #$01
           cmp   ZeroPage::CH
           bne   L993E
           sec
           rts
L993E:     clc
           rts

SaveCursorPos:
           lda   ZeroPage::CV
           sta   SavedCV
           lda   ZeroPage::CH
           sta   SavedCH
           rts

RestoreCursorPos:
           ldx   SavedCV
           jsr   ApplesoftHandler::VTAB+3
           ldx   SavedCH
           jsr   GetWindowAndScreenWidth
           bcs   @Is80Col
           jsr   ApplesoftHandler::HTAB+3
           rts
@Is80Col:  jmp   SetCHModulo80

;;; Code area starting here gets repurposed as the I/O buffer after
;;; installation.
IOBuffer:

SystemChecks:
           lda   ProDOS::MACHID
           ldx   #$00
           ror   a
           ror   a              ; 80 col card present into C
           bcc   L996B          ; branch if not present
           ldx   #$64           ; 100
L996B:     stx   L8BE0
           lda   ProDOS::MACHID
           ror   a
           ror   a
           ror   a
           ror   a
           and   #$03           ; memory size (1 = 48K, 2 = 64K, 3 = 128K)
           tax
           dex
           lda   L99BC,x        ; 48K -> 0, 64K -> 10, 128K -> 20
           clc
           adc   L8BE0
           sta   L8BE0
           lda   #$08
           bit   ProDOS::MACHID ; bit 7 is 1 if IIe or newer
           bne   L999C          ; branch if not II
           lda   ProDOS::MACHID
           rol   a
           rol   a
           rol   a
           and   #$03           ; get bits 4 and 3; 3 will be 0
           clc
           adc   L8BE0
           sta   L8BE0
           jmp   L99AB
L999C:     bpl   L99A3          ; not II
           lda   #$04
           jmp   L99A5
L99A3:     lda   #$05
L99A5:     adc   L8BE0
           sta   L8BE0
L99AB:     ldy   #$01
           lda   ProDOS::MACHID
           and   #$C0           ; get bits 7 and 6
           cmp   #$80           ; not Apple III?
           beq   L99B8
           ldy   #$00           ; Apple III
L99B8:     sty   IIeOrNewerFlag
           rts

L99BC:     .byte $00,$0A,$14,$08 ; 0, 10, 20, 8 ???

AmperInstall:
           lda   Vector::AMPERV+1
           sta   PrevAmperAddr
           lda   Vector::AMPERV+2
           sta   PrevAmperAddr+1
           lda   AmperAddr
           sta   Vector::AMPERV+1
           lda   AmperAddr+1
           sta   Vector::AMPERV+2
           cld
           sec
           jsr   SystemChecks
           lda   #$00
           sta   AlwaysZeroByte2
           sta   AlwaysZeroByte3
           sta   AlwaysZeroByte5
           sta   UnlimitedInputLengthFlag
           lda   $BA
           sta   SavedBAtoBC
           lda   $BB
           sta   SavedBAtoBC+1
           lda   $BC
           sta   SavedBAtoBC+2
           rts

           .byte $00, $00, $00, $00 ; unused

MainCodeEnd := *

;;; Garbage bytes
           .byte $00, $60, $4C, $E3, $65, $20, $07, $8F
           .byte $90, $03, $4C, $CE

