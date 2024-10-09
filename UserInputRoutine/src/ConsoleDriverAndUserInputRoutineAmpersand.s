; da65 V2.18 - N/A
; Created:    2024-11-04 21:15:27
; Input file: ../obj/CONDAMP.REL#fe2000
; Page:       1


        .setcpu "6502"

        .include "BASICSystem.s"
        .include "ZeroPage.s"
        .include "Applesoft.s"
        .include "Vectors.s"

        .include "ConsoleDriverAndUserInputRoutineDefines.s"

        .org  $1ffe
        
        .word   $0869           ; code length

CodeStart:
        lda     AmperInitializedFlag
        beq     @OK
        jmp     UndefdFunctionError
@OK:    lda     Vector::AMPERV+2
        cmp     EntryPointAddr+1
        bne     @OK2
        lda     Vector::AMPERV+1
        cmp     EntryPointAddr
        bne     @OK2
        jmp     UndefdFunctionError
@OK2:   lda     #1
        sta     AmperInitializedFlag
        lda     Vector::AMPERV+1
        sta     SavedAMPERV
        sec
        sbc     #1
        sta     SavedAMPERVMinus1
        lda     Vector::AMPERV+2
        sta     SavedAMPERV+1
        sbc     #0
        sta     SavedAMPERVMinus1+1
        lda     EntryPointAddr
        sta     Vector::AMPERV+1
        lda     EntryPointAddr+1
        sta     Vector::AMPERV+2
        rts

AmperInitializedFlag:   
        .byte   $00
SavedAMPERV:
        .addr   $0000
SavedAMPERVMinus1:
        .addr   $0000
EntryPointAddr: 
        .addr   EntryPoint

SavedTXTPTR:
        .addr   $0000
TempValue:
        .byte   $00
SavedFORPNT:
        .addr   $0000

        .addr   $0000           ; unused

ArrayStartIndex:
        .word   $A0A0
ArrayEndIndex:
        .word   $A0A0

;;; unused garbage
        .byte   $A0,$A0,$A0,$B8,$E5,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$E4
        .byte   $A0,$E1,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$EE,$E4,$A0,$EF,$E3,$A0
        .byte   $E3,$B8,$A0,$A0,$A0,$E5,$F2,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$EF,$A0
        .byte   $A0,$B7,$A0,$F2,$A0,$A0,$E8,$A0
        .byte   $BB,$F2,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$BB,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$B0,$F2,$A0,$B2,$F0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$E4,$A0
        .byte   $A0,$E4,$B4,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$E7,$EC,$A0,$A0,$A0,$A0,$EF
        .byte   $A0,$B2,$F2,$A0,$B7,$F3,$A0,$A0
        .byte   $EF,$A0,$A0,$E9,$A0,$B3,$A0,$A0
        .byte   $B0,$A0,$A0,$FF,$A0,$A0,$A0,$A0
        .byte   $A0,$B2,$F8,$A0,$A0,$E8,$A0,$A0
        .byte   $F2,$A0,$C1,$F0,$A0,$C1,$A0,$A0
        .byte   $B0,$BB,$EE,$80,$A0,$F0,$80,$A0
        .byte   $E1,$80,$A0,$A0,$FF,$A0,$A0,$81
        .byte   $A0,$F2,$FF,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$EC,$A0
        .byte   $A0,$F6,$A0,$A0,$B0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$E4,$B0,$E1,$E4,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$EE,$A0
        .byte   $A0,$EF,$A0,$A0,$E3,$A0,$A0,$F2
        .byte   $BB,$B9,$F2,$A0,$A0,$A0,$A0,$B8
        .byte   $A0,$A0,$C4,$E1,$AB,$B0,$BB,$E4
        .byte   $C3,$A0,$F0,$FF,$A0,$A0,$FF,$A0
        .byte   $A0,$FF,$A0,$F3,$FF,$A0,$F2,$FF
        .byte   $F2,$AB,$B4,$F4,$ED,$B0,$BB,$A0
        .byte   $C3,$A0,$F0,$FF,$A0,$E1,$B7,$A0
        .byte   $A0,$B0,$A0,$E4,$80,$A0,$F0,$80
        .byte   $A0,$E1,$80,$A0,$A0,$FF,$A0,$A0
        .byte   $81,$A0,$F2,$FF,$A0,$A0,$FF,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$F4,$A0
        .byte   $A0,$E1,$EC,$EE,$B3,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$E9,$A0,$E4,$A0,$A0
        .byte   $A0,$EF,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$F4,$A0,$A0,$E4,$A0,$A0
        .byte   $F5,$A0,$B7,$E5,$A0,$B0,$BB,$EE
        .byte   $FF,$A0,$F0,$FF,$A0,$E1,$80,$A0
        .byte   $A0,$80,$A0,$E1,$80,$A0,$F3,$FF
        .byte   $A0,$A0,$FF,$A0,$A0,$C3,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$EF,$80,$A0
        .byte   $A0,$80,$A0,$A0,$81,$A0,$EC,$FF
        .byte   $A0,$A0,$FF,$A0,$A0,$83,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $B8,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$EE,$A0
        .byte   $B0,$F0,$A0,$E1,$E1,$A0,$B0,$A0
        .byte   $A0,$A0,$E1,$A0,$A0,$F3,$B0,$A0
        .byte   $A0,$A0,$A0,$80,$A0,$EC,$FF,$A0
        .byte   $A0,$FF,$A0,$A0,$80,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$B9
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$E4,$A0,$E9
        .byte   $F0,$A0,$B5,$E1,$A0,$B0,$A0,$A0
        .byte   $A0,$E1,$A0,$A0,$A0,$F0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$E4,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$E6
        .byte   $F3,$E7,$E2,$E5,$A0

IOToolkitEntryPointAddress:
        .addr   SyntaxError

CallIOToolkit:
        jmp     (IOToolkitEntryPointAddress)

L2257:  lda     L227A
        sta     GeneralParamTable+1
        lda     L227A+1
        sta     GeneralParamTable+2
MakeToolkitCall:
        jsr     CallIOToolkit
GeneralParamTable:
        .byte   $00
        .addr   $0000
        rts

L226A:  .byte   $B4
L226B:  .byte   $A0
L226C:  .byte   $A0
L226D:  .byte   $A0,$A0,$A0,$A0,$A0,$E7,$A0,$A0
        .byte   $E5,$A0,$A0,$AA,$A0
L227A:  .addr   L226A
INITCD_Entry:
        .byte   "INITCD", $00
        .addr   INITCD_Handler-1
        .byte   IOTKCall::InitConsole
WRITE_Entry:
        .byte   "WRITE", $00
        .addr   WRITE_Handler-1
        .byte   $00
WRTSTR_Entry:
        .byte   "WRTSTR", $00
        .addr   WRTSTR_Handler-1
        .byte   $00
CDINFO_Entry:
        .byte   "CDINFO", $00
        .addr   CDINFO_Handler-1
        .byte   IOTKCall::GetConsoleStatus
GTCP_Entry:
        .byte   "GTCP", $00
        .addr   GTCP_Handler-1
        .byte   IOTKCall::GetCursorPosition
GTCHR_Entry:
        .byte   "GTCHR", $00
        .addr   GTCHR_Handler-1
        .byte   IOTKCall::GetCharAtCursor
SVVP_Entry:
        .byte   "SVVP", $00
        .addr   SVVP_Handler-1
        .byte   IOTKCall::SaveViewport
RSTRVP_Entry:
        .byte   "RSTRVP", $00
        .addr   SVVP_Handler-1
        .byte   IOTKCall::RestoreViewport
GTMEM_Entry:
        .byte   "GTMEM", $00
        .addr   GTMEM_Handler-1
CDVRSN_Entry:
        .byte   "CDVRSN", $00
        .addr   CDVRSN_Handler-1
CDCPYRT_Entry:
        .byte   "CDCPYRT", $00
        .addr   CDCPYRT_Handler-1
STPCD_Entry:
        .byte   "STPCD", $00
        .addr   STPCD_Handler-1
STCDADR_Entry:
        .byte   "STCDADR", $00
        .addr   STCDADR_Handler-1
INITINPUT_Entry:
        .byte   "INIT", ApplesoftToken::INPUT, $00
        .addr   INITINPUT_Handler-1
GETINFO_Entry:
        .byte   ApplesoftToken::GET, "INFO", $00
        .addr   GETINFO_Handler-1
SETINFO_Entry:
         .byte   "SETINFO", $00
        .addr   SETINFO_Handler-1
INPUT_Entry:
        .byte   ApplesoftToken::INPUT, $00
        .addr   INPUT_Handler-1
EXITINPUT_Entry:
        .byte   "EXIT", ApplesoftToken::INPUT, $00
        .addr   EXITINPUT_Handler-1

CommandEntryTable:
        .addr   INITCD_Entry
        .addr   WRITE_Entry
        .addr   WRTSTR_Entry
        .addr   CDINFO_Entry
        .addr   GTCP_Entry
        .addr   GTCHR_Entry
        .addr   GTMEM_Entry
        .addr   SVVP_Entry
        .addr   RSTRVP_Entry
        .addr   CDVRSN_Entry
        .addr   CDCPYRT_Entry
        .addr   STPCD_Entry
        .addr   STCDADR_Entry
        .addr   INPUT_Entry
        .addr   INITINPUT_Entry
        .addr   GETINFO_Entry
        .addr   SETINFO_Entry
        .addr   EXITINPUT_Entry
        .addr   $0000

EntryPoint:
        lda     ZeroPage::TXTPTR
        sta     SavedTXTPTR
        lda     ZeroPage::TXTPTR+1
        sta     SavedTXTPTR+1
        lda     ZeroPage::FORPNT
        sta     SavedFORPNT
        lda     ZeroPage::FORPNT+1
        sta     SavedFORPNT+1
        lda     CommandEntryTable
        sta     ZeroPage::FORPNT
        lda     CommandEntryTable+1
        sta     ZeroPage::FORPNT+1
        ldy     #$00
        ldx     #$00
L2361:  jsr     ZeroPage::CHRGOT
L2364:  cmp     #$A0            ; high-ascii space
        beq     L2387
        cmp     $61 ; should be #$61 'a'
        bcc     L2375           ; to lowercase
        cmp     $7A ; should be #$7A 'z'
        beq     L2372
        bcs     L2375
L2372:  sec
        sbc     #$20
L2375:  sta     TempValue
        lda     (ZeroPage::FORPNT),y
        beq     L238D
        cmp     TempValue
        bne     L2396
        inc     ZeroPage::FORPNT
        bne     L2387
        inc     ZeroPage::FORPNT+1
L2387:  jsr     ZeroPage::CHRGET
        jmp     L2364
L238D:  jsr     ZeroPage::CHRGOT
        beq     L23BE
        cmp     #'('
        beq     L23BE
L2396:  lda     SavedTXTPTR
        sta     ZeroPage::TXTPTR
        lda     SavedTXTPTR+1
        sta     ZeroPage::TXTPTR+1
        inx
        inx
        lda     CommandEntryTable+1,x
        beq     L23B3
        sta     ZeroPage::FORPNT+1
        lda     CommandEntryTable,x
        sta     ZeroPage::FORPNT
        ldy     #$00
        jmp     L2361
L23B3:  lda     SavedAMPERVMinus1+1 ; call next amper routine
        pha
        lda     SavedAMPERVMinus1
        pha
        jmp     L23CD
L23BE:  ldy     #$03            ; command matched
        lda     (ZeroPage::FORPNT),y
        sta     GeneralParamTable
        dey
        lda     (ZeroPage::FORPNT),y
        pha
        dey
        lda     (ZeroPage::FORPNT),y
        pha
L23CD:  lda     SavedFORPNT
        sta     ZeroPage::FORPNT
        lda     SavedFORPNT+1
        sta     ZeroPage::FORPNT+1
        rts

INITCD_Handler:
        jsr     MakeToolkitCall
        jsr     ZeroPage::CHRGOT
        jmp     ReturnFromHandler

GetArrayIndexVar:
        stx     L23F8
        jsr     ApplesoftRoutine::FRMEVL
        jsr     ApplesoftRoutine::AYINT
        ldx     L23F8
        lda     ZeroPage::FACLO
        sta     ArrayStartIndex,x
        lda     ZeroPage::FACMO
        sta     ArrayStartIndex+1,x
        rts
L23F8:  .byte   $00             ; storage for X
        
L23F9:  sta     L240B
        jsr     ApplesoftRoutine::PTRGET
        lda     #$00
        tay
        sta     (ZeroPage::VARPNT),y
        lda     L240B
        iny
        sta     (ZeroPage::VARPNT),y
        rts

L240B:  .byte   $00
L240C:  ldy     #$00
        lda     (ZeroPage::LOWTR),y
        sta     L226C
        tya
        sta     L226D
        iny
        lda     (ZeroPage::LOWTR),y
        sta     L226A
        iny
        lda     (ZeroPage::LOWTR),y
        sta     L226B
        rts

STCDADR_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::FRMEVL
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACLO
        sta     IOToolkitEntryPointAddress
        lda     ZeroPage::FACMO
        sta     IOToolkitEntryPointAddress+1
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

GTMEM_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETBYT
        txa
        jsr     BASICSystem::GETBUFR
        bcc     L244C
        jmp     OutOfMemoryError
L244C:  sta     ArrayStartIndex
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::PTRGET
        lda     ArrayStartIndex
        ldy     #$00
        sta     (ZeroPage::VARPNT),y
        tya
        iny
        sta     (ZeroPage::VARPNT),y
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

WRTSTR_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::PTRGET
        sta     ZeroPage::LOWTR
        sty     ZeroPage::LOWTR+1
        jsr     L240C
        jsr     L2257
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

WRITE_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        ldx     #$00
        jsr     GetArrayIndexVar
        jsr     ApplesoftRoutine::CHKCOM
        ldx     #$02
        jsr     GetArrayIndexVar
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::GETARYPT
        lda     ZeroPage::LOWTR
        clc
        adc     #$07
        sta     ZeroPage::LOWTR
        bcc     L249D
        inc     ZeroPage::LOWTR+1
L249D:  ldx     #$02
L249F:  lda     ZeroPage::LOWTR
        clc
        adc     ArrayStartIndex
        sta     ZeroPage::LOWTR
        lda     ZeroPage::LOWTR+1
        adc     ArrayStartIndex+1
        sta     ZeroPage::LOWTR+1
        dex
        bpl     L249F
L24B1:  lda     ArrayEndIndex
        sec
        sbc     ArrayStartIndex
        lda     ArrayEndIndex+1
        sbc     ArrayStartIndex+1
        bmi     L24DC
        jsr     L240C
        jsr     L2257
        inc     ArrayStartIndex
        bne     L24CE
        inc     ArrayStartIndex+1
L24CE:  lda     ZeroPage::LOWTR
        clc
        adc     #$03
        sta     ZeroPage::LOWTR
        bcc     L24D9
        inc     ZeroPage::LOWTR+1
L24D9:  jmp     L24B1
L24DC:  jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

SVVP_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::FRMEVL
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACLO
        sta     GeneralParamTable+1
        lda     ZeroPage::FACMO
        sta     GeneralParamTable+2
        jsr     MakeToolkitCall
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

GTCP_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     MakeToolkitCall
        lda     L226A
        jsr     L23F9
        jsr     ApplesoftRoutine::CHKCOM
        lda     L226B
        jsr     L23F9
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

CDINFO_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     MakeToolkitCall
        jsr     ApplesoftRoutine::GETARYPT
        ldy     #$04
        lda     (ZeroPage::LOWTR),y
        cmp     #$01
        beq     L252D
        jmp     BadSubscriptError
L252D:  ldy     #$06
        lda     (ZeroPage::LOWTR),y
        cmp     #$10
        bcs     L253D
        dey
        lda     (ZeroPage::LOWTR),y
        bne     L253D
        jmp     BadSubscriptError
L253D:  ldy     #$28
        ldx     #$0F
L2541:  lda     L226A,x
        sta     (ZeroPage::LOWTR),y
        dey
        lda     #$00
        sta     (ZeroPage::LOWTR),y
        dex
        bmi     L2551
        dey
        bpl     L2541
L2551:  jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

GTCHR_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     L2257
        lda     L226A
        jsr     L23F9
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

CDVRSN_Handler: 
        jsr     ApplesoftRoutine::CHKOPN
        lda     #$01
        jsr     L23F9
        jsr     ApplesoftRoutine::CHKCOM
        lda     #$00
        jsr     L23F9
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

CopyrightText:
        .byte   "Console Driver Ampersand Package", $0D
        .byte   "Written by Neal Johnson & Bennet Marks", $0D
        .byte   "Copyright Apple Computer, Inc. 1984"
CopyrightTextAddr:
        .addr   CopyrightText
       
CDCPYRT_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::PTRGET
        lda     #(CopyrightTextAddr-CopyrightText)
        ldy     #$00
        sta     (ZeroPage::VARPNT),y
        lda     CopyrightTextAddr
        iny
        sta     (ZeroPage::VARPNT),y
        lda     CopyrightTextAddr+1
        iny
        sta     (ZeroPage::VARPNT),y
        jsr     ApplesoftRoutine::CHKCLS
        jmp     ReturnFromHandler

STPCD_Handler:  
        lda     AmperInitializedFlag
        bne     L2612
        jmp     UndefdFunctionError
L2612:  lda     SavedAMPERV
        sta     Vector::AMPERV+1
        lda     SavedAMPERV+1
        sta     Vector::AMPERV+2
        lda     #$00
        sta     AmperInitializedFlag
        jsr     ZeroPage::CHRGOT
        jmp     ReturnFromHandler

ReturnFromHandler:
        bne     SyntaxError
        rts

SyntaxError:
        ldx     #ApplesoftError::SyntaxError
        jmp     ApplesoftRoutine::ERROR

UndefdFunctionError:
        ldx     #ApplesoftError::UndefdFunction
        jmp     ApplesoftRoutine::ERROR

BadSubscriptError:
        ldx     #ApplesoftError::BadSubscript
        jmp     ApplesoftRoutine::ERROR

OutOfMemoryError:
        ldx     #ApplesoftError::OutOfMemory
        jmp     ApplesoftRoutine::ERROR

INITINPUT_Handler:
        jsr     CallIOToolkit
        .byte   IOTKCall::InitInput
        .addr   $0000
        rts

GETINFO_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETARYPT
        jsr     CallIOToolkit
        .byte   IOTKCall::GetInputInfo
        .addr   InputInfoParamTable
        ldx     #$00
        ldy     #$09
@Loop:  lda     #$00
        sta     (ZeroPage::LOWTR),y
        lda     InputInfoParamTable,x
        iny
        sta     (ZeroPage::LOWTR),y
        iny
        inx
        cpx     #$50
        bcc     @Loop
        ldy     #$A9
        lda     L26D5
        sta     (ZeroPage::LOWTR),y
        iny
        lda     L26D4
        sta     (ZeroPage::LOWTR),y
        iny
        lda     L26D7
        sta     (ZeroPage::LOWTR),y
        iny
        lda     L26D6
        sta     (ZeroPage::LOWTR),y
        jsr     ApplesoftRoutine::CHKCLS
        rts

InputInfoParamTable:
        .byte   $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A0,$B9,$A9,$A0
        .byte   $A0,$C2,$A0,$A0,$E6,$A0,$B9,$A0
        .byte   $EF,$B6,$A0,$F4,$A0,$E1,$EF,$A0
        .byte   $E9,$A0,$A0,$E9,$A0,$A0,$A0,$E1
        .byte   $A0,$A0,$F3,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$A0,$A6,$A0,$A0,$B1
        .byte   $A0,$A0,$A0,$A0,$B2,$E9,$A0,$B7
        .byte   $E1,$A0,$A0,$BB,$A0,$A0,$A0,$A0
        .byte   $A0,$A0,$A0,$C4,$EB,$BB,$B8,$EF
L26D4:  .byte   $A0
L26D5:  .byte   $A0
L26D6:  .byte   $F4
L26D7:  .byte   $A0

SETINFO_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETARYPT
        ldx     #$00
        ldy     #$0A
@Loop:  lda     (ZeroPage::LOWTR),y
        sta     InputInfoParamTable,x
        iny
        iny
        inx
        cpx     #$50
        bcc     @Loop
        ldy     #$A9
        lda     (ZeroPage::LOWTR),y
        sta     L26D5
        iny
        lda     (ZeroPage::LOWTR),y
        sta     L26D4
        iny
        lda     (ZeroPage::LOWTR),y
        sta     L26D7
        iny
        lda     (ZeroPage::LOWTR),y
        sta     L26D6
        jsr     ApplesoftRoutine::CHKCLS
        jsr     CallIOToolkit
        .byte   IOTKCall::SetInputInfo
        .addr   InputInfoParamTable
        rts

INPUT_Handler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::PTRGET
        sta     InputStringVarPtr
        sty     InputStringVarPtr+1
        ldy     #$00
        lda     (ZeroPage::VARPNT),y
        sta     InputLength
        beq     L273D
        iny
        lda     (ZeroPage::VARPNT),y
        tax
        iny
        lda     (ZeroPage::VARPNT),y
        stx     ZeroPage::VARPNT
        sta     ZeroPage::VARPNT+1
        ldy     InputLength
        dey
@Loop:  lda     (ZeroPage::VARPNT),y
        sta     InputBuffer,y
        dey
        bpl     @Loop
L273D:  jsr     ApplesoftRoutine::CHKCLS
        jsr     CallIOToolkit
        .byte   IOTKCall::Input
        .addr   InputParamTable
        lda     InputStringVarPtr
        sta     ZeroPage::VARPNT
        lda     InputStringVarPtr+1
        sta     ZeroPage::VARPNT+1
        lda     InputLength
        ldy     #$00
        sta     (ZeroPage::VARPNT),y
        iny
        lda     #$66
        sta     (ZeroPage::VARPNT),y
        iny
        lda     #$27
        sta     (ZeroPage::VARPNT),y
        rts

InputParamTable:
        .addr   InputBufferBlock
        .byte   $FE
InputBufferBlock:
InputLength:
        .byte   $00
InputBuffer:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
InputStringVarPtr:
        .addr   $0000

EXITINPUT_Handler:
        jmp     STPCD_Handler


;;; relocation table:
        .byte   $81,$01,$00,$00
        .byte   $81,$06,$00,$00,$81,$0C,$00,$00
        .byte   $81,$14,$00,$00,$81,$19,$00,$00
        .byte   $81,$1E,$00,$00,$81,$24,$00,$00
        .byte   $81,$2A,$00,$00,$81,$30,$00,$00
        .byte   $81,$35,$00,$00,$81,$38,$00,$00
        .byte   $81,$3E,$00,$00,$81,$49,$00,$00
        .byte   $81,$52,$02,$00,$81,$55,$02,$00
        .byte   $81,$58,$02,$00,$81,$5B,$02,$00
        .byte   $81,$5E,$02,$00,$81,$61,$02,$00
        .byte   $81,$64,$02,$00,$81,$7A,$02,$00
        .byte   $81,$83,$02,$00,$81,$8C,$02,$00
        .byte   $81,$96,$02,$00,$81,$A0,$02,$00
        .byte   $81,$A8,$02,$00,$81,$B1,$02,$00
        .byte   $81,$B9,$02,$00,$81,$C3,$02,$00
        .byte   $81,$CC,$02,$00,$81,$D5,$02,$00
        .byte   $81,$DF,$02,$00,$81,$E7,$02,$00
        .byte   $81,$F1,$02,$00,$81,$F9,$02,$00
        .byte   $81,$01,$03,$00,$81,$0B,$03,$00
        .byte   $81,$0F,$03,$00,$81,$17,$03,$00
        .byte   $81,$19,$03,$00,$81,$1B,$03,$00
        .byte   $81,$1D,$03,$00,$81,$1F,$03,$00
        .byte   $81,$21,$03,$00,$81,$23,$03,$00
        .byte   $81,$25,$03,$00,$81,$27,$03,$00
        .byte   $81,$29,$03,$00,$81,$2B,$03,$00
        .byte   $81,$2D,$03,$00,$81,$2F,$03,$00
        .byte   $81,$31,$03,$00,$81,$33,$03,$00
        .byte   $81,$35,$03,$00,$81,$37,$03,$00
        .byte   $81,$39,$03,$00,$81,$3B,$03,$00
        .byte   $81,$42,$03,$00,$81,$47,$03,$00
        .byte   $81,$4C,$03,$00,$81,$51,$03,$00
        .byte   $81,$54,$03,$00,$81,$59,$03,$00
        .byte   $81,$76,$03,$00,$81,$7D,$03,$00
        .byte   $81,$8B,$03,$00,$81,$97,$03,$00
        .byte   $81,$9C,$03,$00,$81,$A3,$03,$00
        .byte   $81,$AA,$03,$00,$81,$B1,$03,$00
        .byte   $81,$B4,$03,$00,$81,$B8,$03,$00
        .byte   $81,$BC,$03,$00,$81,$C3,$03,$00
        .byte   $81,$CE,$03,$00,$81,$D3,$03,$00
        .byte   $81,$D9,$03,$00,$81,$DF,$03,$00
        .byte   $81,$E2,$03,$00,$81,$EB,$03,$00
        .byte   $81,$F0,$03,$00,$81,$F5,$03,$00
        .byte   $81,$FA,$03,$00,$81,$05,$04,$00
        .byte   $81,$11,$04,$00,$81,$15,$04,$00
        .byte   $81,$1B,$04,$00,$81,$21,$04,$00
        .byte   $81,$30,$04,$00,$81,$35,$04,$00
        .byte   $81,$3B,$04,$00,$81,$4A,$04,$00
        .byte   $81,$4D,$04,$00,$81,$56,$04,$00
        .byte   $81,$64,$04,$00,$81,$71,$04,$00
        .byte   $81,$74,$04,$00,$81,$7A,$04,$00
        .byte   $81,$82,$04,$00,$81,$8A,$04,$00
        .byte   $81,$A3,$04,$00,$81,$AA,$04,$00
        .byte   $81,$B2,$04,$00,$81,$B6,$04,$00
        .byte   $81,$B9,$04,$00,$81,$BC,$04,$00
        .byte   $81,$C1,$04,$00,$81,$C4,$04,$00
        .byte   $81,$C7,$04,$00,$81,$CC,$04,$00
        .byte   $81,$DA,$04,$00,$81,$E0,$04,$00
        .byte   $81,$EE,$04,$00,$81,$F3,$04,$00
        .byte   $81,$F6,$04,$00,$81,$FC,$04,$00
        .byte   $81,$02,$05,$00,$81,$05,$05,$00
        .byte   $81,$08,$05,$00,$81,$0E,$05,$00
        .byte   $81,$11,$05,$00,$81,$17,$05,$00
        .byte   $81,$1D,$05,$00,$81,$2B,$05,$00
        .byte   $81,$3B,$05,$00,$81,$42,$05,$00
        .byte   $81,$55,$05,$00,$81,$5B,$05,$00
        .byte   $81,$5E,$05,$00,$81,$61,$05,$00
        .byte   $81,$67,$05,$00,$81,$6F,$05,$00
        .byte   $81,$77,$05,$00,$81,$7D,$05,$00
        .byte   $81,$EA,$05,$00,$81,$F9,$05,$00
        .byte   $81,$FF,$05,$00,$81,$08,$06,$00
        .byte   $81,$0B,$06,$00,$81,$10,$06,$00
        .byte   $81,$13,$06,$00,$81,$19,$06,$00
        .byte   $81,$21,$06,$00,$81,$27,$06,$00
        .byte   $81,$41,$06,$00,$81,$4E,$06,$00
        .byte   $81,$51,$06,$00,$81,$5C,$06,$00
        .byte   $81,$6A,$06,$00,$81,$70,$06,$00
        .byte   $81,$76,$06,$00,$81,$7C,$06,$00
        .byte   $81,$E5,$06,$00,$81,$F3,$06,$00
        .byte   $81,$F9,$06,$00,$81,$FF,$06,$00
        .byte   $81,$05,$07,$00,$81,$0B,$07,$00
        .byte   $81,$0E,$07,$00,$81,$18,$07,$00
        .byte   $81,$1B,$07,$00,$81,$22,$07,$00
        .byte   $81,$32,$07,$00,$81,$38,$07,$00
        .byte   $81,$41,$07,$00,$81,$44,$07,$00
        .byte   $81,$47,$07,$00,$81,$4C,$07,$00
        .byte   $81,$51,$07,$00,$01,$59,$07,$00
        .byte   $41,$5E,$07,$66,$81,$62,$07,$00
        .byte   $81,$67,$08,$00,$00,$00
