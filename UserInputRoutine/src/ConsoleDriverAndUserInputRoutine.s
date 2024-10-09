; da65 V2.18 - N/A
; Created:    2024-10-29 20:36:57
; Input file: ../obj/CONUIR.OBJ#064000
; Page:       1

;.macpack generic

        .setcpu "6502"

        .include "ControlChars.s"
        .include "Monitor.s"
        .include "MouseText.s"
        .include "OpCodes.s"
        .include "SoftSwitches.s"
        .include "ZeroPage.s"

        .org  $4000

;;; Zero page usage

        TextLineBasePtr2             := $20
        TextLineBasePtr              := $22
        OutputDataPtr                := $24 ; pointer into data being output
        DriverStatusPtr              := $26
        SourceTextLineBasePtr        := $28 ; text copy source pointer
        DestTextLineBasePtr          := $2A ; text copy dest pointer
        SaveBufferPtr                := $2E
        ViewportRightEdgeTextPage1   := $30
        ViewportRightEdgeTextPage2   := $31
        ViewportLeftEdgeTextPage1    := $32
        ViewportLeftEdgeTextPage2    := $33
        VerticalScrollDirection      := $34 ; 0 = up, 1 = down
        VerticalScrollLineCounter    := $35
        LastLine                     := $39 ; used in loop in save/restore viewport routines
        YRegStorage                  := $3A
        LineOffset                   := $3C ; byte offset from beginning of line (in memory page) for given x-pos
        TmpPointer                   := $41 ; general purpose pointer
        CallingCodePtr               := $42
        DefaultInputPtr              := $43 ; pointer to default text for input routine
        ParamTablePtr                := $44 ; pointer to call parameter table

        
        jmp     EntryPoint

;;; Text screen line base addresses
TextScreenBaseAddressTable:
        .addr   $0400
        .addr   $0480
        .addr   $0500
        .addr   $0580
        .addr   $0600
        .addr   $0680
        .addr   $0700
        .addr   $0780
        .addr   $0428
        .addr   $04A8
        .addr   $0528
        .addr   $05A8
        .addr   $0628
        .addr   $06A8
        .addr   $0728
        .addr   $07A8
        .addr   $0450
        .addr   $04D0
        .addr   $0550
        .addr   $05D0
        .addr   $0650
        .addr   $06D0
        .addr   $0750
        .addr   $07D0

;;; computes base address of line in Y and stores it at TextLineBasePtr
GetTextLineBaseAddr:
        tya
        clc
        asl     a
        tax
        lda     TextScreenBaseAddressTable,x
        sta     TextLineBasePtr
        lda     TextScreenBaseAddressTable+1,x
        sta     TextLineBasePtr+1
        rts

CalculateViewportEdgeOffsets:
        lda     DriverStatusWindowLeft
        lsr     a               ; divide by 2
        sta     ViewportLeftEdgeTextPage1
        sta     ViewportLeftEdgeTextPage2
        bcc     @Even
        inc     ViewportLeftEdgeTextPage2
@Even:  lda     DriverStatusWindowRight
        lsr     a               ; divide by 2
        sta     ViewportRightEdgeTextPage2
        sta     ViewportRightEdgeTextPage1
        bcs     @Out
        dec     ViewportRightEdgeTextPage1
@Out:   rts

ClearLineInViewport:
        lda     DriverStatusWindowWidth
        cmp     #2
        bcs     L407F           ; more than 1 char wide
        lda     DriverStatusWindowLeft
        lsr     a
        sta     LineOffset
        sta     SoftSwitch::TXTPAGE1
        bcs     L4070
        sta     SoftSwitch::TXTPAGE2
L4070:  jsr     GetTextLineBaseAddr
        lda     DriverStatusFillChar
        sty     YRegStorage
        ldy     LineOffset
        sta     (TextLineBasePtr),y
        ldy     YRegStorage
        rts
L407F:  jsr     GetTextLineBaseAddr
        jsr     CalculateViewportEdgeOffsets
ClearToEndOfLine:
        lda     DriverStatusFillChar
        sty     YRegStorage
        ldy     ViewportRightEdgeTextPage1
        sta     SoftSwitch::TXTPAGE1
L408F:  cpy     ViewportLeftEdgeTextPage1
        beq     L409A
        sta     (TextLineBasePtr),y
        dey
        cpy     ViewportLeftEdgeTextPage1
        bne     L408F
L409A:  sta     (TextLineBasePtr),y
        ldy     ViewportRightEdgeTextPage2
        sta     SoftSwitch::TXTPAGE2
L40A1:  cpy     ViewportLeftEdgeTextPage2
        beq     L40AC
        sta     (TextLineBasePtr),y
        dey
        cpy     ViewportLeftEdgeTextPage2
        bne     L40A1
L40AC:  sta     (TextLineBasePtr),y
        ldy     YRegStorage
        rts

ClearLinesToEndOfViewport:
        jsr     ClearLineInViewport
        iny
        cpy     DriverStatusWindowBottom
        bcc     ClearLinesToEndOfViewport
        beq     ClearLinesToEndOfViewport
        rts

;;; called by scroll up/down routines to calculate source line and destination
;;; line addresses for copy
CalculateLineBaseAddrsForVerticalScrollCopy:
        jsr     GetTextLineBaseAddr
        lda     TextLineBasePtr
        sta     DestTextLineBasePtr
        lda     TextLineBasePtr+1
        sta     DestTextLineBasePtr+1
        lda     VerticalScrollDirection
        bne     @Down
        iny
        jmp     @Skip
@Down:  dey
@Skip:  jsr     GetTextLineBaseAddr
        lda     TextLineBasePtr
        sta     SourceTextLineBasePtr
        lda     TextLineBasePtr+1
        sta     SourceTextLineBasePtr+1
        rts

ScrollViewportUp:
        lda     #0
        sta     VerticalScrollDirection
        lda     DriverStatusWindowHeight
        cmp     #$02
        bcs     L40EF
        ldy     DriverStatusWindowTop
        jsr     ClearLineInViewport
        rts
L40EF:  lda     DriverStatusWindowWidth
        cmp     #2
        bcs     L4127
        lda     DriverStatusWindowHeight
        sta     VerticalScrollLineCounter
        ldy     DriverStatusWindowTop
        lda     DriverStatusWindowLeft
        lsr     a
        sta     LineOffset
        sta     SoftSwitch::TXTPAGE1
        bcs     L410C
        sta     SoftSwitch::TXTPAGE2
L410C:  dec     VerticalScrollLineCounter
        bne     L4117
        ldy     DriverStatusWindowBottom
        jsr     ClearLineInViewport
        rts
L4117:  jsr     CalculateLineBaseAddrsForVerticalScrollCopy
        sty     YRegStorage
        ldy     LineOffset
        lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        ldy     YRegStorage
        jmp     L410C
L4127:  lda     DriverStatusWindowHeight
        sta     VerticalScrollLineCounter
        jsr     CalculateViewportEdgeOffsets
        ldy     DriverStatusWindowTop
L4132:  dec     VerticalScrollLineCounter
        bne     L413D
        ldy     DriverStatusWindowBottom
        jsr     ClearLineInViewport
        rts
L413D:  jsr     CalculateLineBaseAddrsForVerticalScrollCopy
        sty     YRegStorage
        ldy     ViewportRightEdgeTextPage1
        sta     SoftSwitch::TXTPAGE1
L4147:  lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        dey
        cpy     ViewportLeftEdgeTextPage1
        bne     L4147
        lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        ldy     ViewportRightEdgeTextPage2
        sta     SoftSwitch::TXTPAGE2
L4159:  lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        dey
        cpy     ViewportLeftEdgeTextPage1
        bne     L4159
        lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        ldy     YRegStorage
        jmp     L4132

ScrollViewportDown:
        lda     #1
        sta     VerticalScrollDirection
        lda     DriverStatusWindowHeight
        cmp     #2
        bcs     L417D
        ldy     DriverStatusWindowTop
        jsr     ClearLineInViewport
        rts
L417D:  lda     DriverStatusWindowWidth
        cmp     #2
        bcs     L41B5
        lda     DriverStatusWindowHeight
        sta     VerticalScrollLineCounter
        ldy     DriverStatusWindowBottom
        lda     DriverStatusWindowLeft
        lsr     a
        sta     LineOffset
        sta     SoftSwitch::TXTPAGE1
        bcs     L419A
        sta     SoftSwitch::TXTPAGE2
L419A:  dec     VerticalScrollLineCounter
        bne     L41A5
        ldy     DriverStatusWindowTop
        jsr     ClearLineInViewport
        rts
L41A5:  jsr     CalculateLineBaseAddrsForVerticalScrollCopy
        sty     YRegStorage
        ldy     LineOffset
        lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        ldy     YRegStorage
        jmp     L419A
L41B5:  lda     DriverStatusWindowHeight
        sta     VerticalScrollLineCounter
        jsr     CalculateViewportEdgeOffsets
        ldy     DriverStatusWindowBottom
L41C0:  dec     VerticalScrollLineCounter
        bne     L41CB
        ldy     DriverStatusWindowTop
        jsr     ClearLineInViewport
        rts
L41CB:  jsr     CalculateLineBaseAddrsForVerticalScrollCopy
        sty     YRegStorage
        ldy     ViewportRightEdgeTextPage1
        sta     SoftSwitch::TXTPAGE1
L41D5:  lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        dey
        cpy     ViewportLeftEdgeTextPage1
        bne     L41D5
        lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        ldy     ViewportRightEdgeTextPage2
        sta     SoftSwitch::TXTPAGE2
L41E7:  lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        dey
        cpy     ViewportLeftEdgeTextPage2
        bne     L41E7
        lda     (SourceTextLineBasePtr),y
        sta     (DestTextLineBasePtr),y
        ldy     YRegStorage
        jmp     L41C0

ViewportSavedFlag:
        .byte   $00
ViewportSaveCounter:
        .byte   $00
ViewportSaveBufferAddr:
        .addr   $0000
SaveViewportToBuffer:
        lda     #$FF
        sta     ViewportSavedFlag
        lda     ViewportSaveBufferAddr
        sta     SaveBufferPtr
        lda     ViewportSaveBufferAddr+1
        sta     SaveBufferPtr+1
        lda     DriverStatusWindowWidth
        cmp     #$02
        bcs     L4249
        lda     DriverStatusWindowLeft
        lsr     a
        sta     LineOffset
        sta     SoftSwitch::TXTPAGE1
        bcs     L4221
        sta     SoftSwitch::TXTPAGE2
L4221:  ldy     DriverStatusWindowBottom
        iny
        sty     LastLine
        ldy     DriverStatusWindowTop
        sty     ViewportSaveCounter
L422D:  jsr     GetTextLineBaseAddr
        ldy     LineOffset
        ldx     #$00
        lda     (TextLineBasePtr),y
        sta     (SaveBufferPtr,x)
        inc     SaveBufferPtr
        bne     L423E
        inc     SaveBufferPtr+1
L423E:  inc     ViewportSaveCounter
        ldy     ViewportSaveCounter
        cpy     LastLine
        bne     L422D
        rts
L4249:  lda     DriverStatusWindowTop
        sta     ViewportSaveCounter
        ldx     DriverStatusWindowBottom
        inx
        stx     LastLine
        jsr     CalculateViewportEdgeOffsets
        inc     ViewportRightEdgeTextPage1
        inc     ViewportRightEdgeTextPage2
L425C:  ldy     ViewportSaveCounter
        jsr     GetTextLineBaseAddr
        iny
        sty     ViewportSaveCounter
        ldx     #$00
        sta     SoftSwitch::TXTPAGE1
        ldy     ViewportLeftEdgeTextPage1
L426D:  lda     (TextLineBasePtr),y
        sta     (SaveBufferPtr,x)
        inc     SaveBufferPtr
        bne     L4277
        inc     SaveBufferPtr+1
L4277:  iny
        cpy     ViewportRightEdgeTextPage1
        bne     L426D
        sta     SoftSwitch::TXTPAGE2
        ldy     ViewportLeftEdgeTextPage2
L4281:  lda     (TextLineBasePtr),y
        sta     (SaveBufferPtr,x)
        inc     SaveBufferPtr
        bne     L428B
        inc     SaveBufferPtr+1
L428B:  iny
        cpy     ViewportRightEdgeTextPage2
        bne     L4281
        ldy     ViewportSaveCounter
        cpy     LastLine
        bne     L425C
        rts

RestoreViewportFromBuffer:      
        lda     ViewportSavedFlag
        beq     L42E3
        lda     ViewportSaveBufferAddr
        sta     SaveBufferPtr
        lda     ViewportSaveBufferAddr+1
        sta     SaveBufferPtr+1
        lda     DriverStatusWindowWidth
        cmp     #$02
        bcs     L42E4
        lda     DriverStatusWindowLeft
        lsr     a
        sta     LineOffset
        sta     SoftSwitch::TXTPAGE1
        bcs     L42BC
        sta     SoftSwitch::TXTPAGE2
L42BC:  ldy     DriverStatusWindowBottom
        iny
        sty     LastLine
        ldy     DriverStatusWindowTop
        sty     ViewportSaveCounter
L42C8:  jsr     GetTextLineBaseAddr
        ldy     LineOffset
        ldx     #$00
        lda     (SaveBufferPtr,x)
        sta     (TextLineBasePtr),y
        inc     SaveBufferPtr
        bne     L42D9
        inc     SaveBufferPtr+1
L42D9:  inc     ViewportSaveCounter
        ldy     ViewportSaveCounter
        cpy     LastLine
        bne     L42C8
L42E3:  rts
L42E4:  lda     DriverStatusWindowTop
        sta     ViewportSaveCounter
        ldx     DriverStatusWindowBottom
        inx
        stx     LastLine
        jsr     CalculateViewportEdgeOffsets
        inc     ViewportRightEdgeTextPage1
        inc     ViewportRightEdgeTextPage2
L42F7:  ldy     ViewportSaveCounter
        jsr     GetTextLineBaseAddr
        iny
        sty     ViewportSaveCounter
        ldx     #$00
        sta     SoftSwitch::TXTPAGE1
        ldy     ViewportLeftEdgeTextPage1
L4308:  lda     (SaveBufferPtr,x)
        sta     (TextLineBasePtr),y
        inc     SaveBufferPtr
        bne     L4312
        inc     SaveBufferPtr+1
L4312:  iny
        cpy     ViewportRightEdgeTextPage1
        bne     L4308
        sta     SoftSwitch::TXTPAGE2
        ldy     ViewportLeftEdgeTextPage2
L431C:  lda     (SaveBufferPtr,x)
        sta     (TextLineBasePtr),y
        inc     SaveBufferPtr
        bne     L4326
        inc     SaveBufferPtr+1
L4326:  iny
        cpy     ViewportRightEdgeTextPage2
        bne     L431C
        ldy     ViewportSaveCounter
        cpy     LastLine
        bne     L42F7
        rts

L4333:  .byte   $00
L4334:  .byte   $00
L4335:  .byte   $00
L4336:  .byte   $00
L4337:  .byte   $00
NumColsToScroll:
        .byte   $00

ScrollViewportSideways:
        bmi     L4353
        sta     NumColsToScroll
        lda     #$00
        sta     L4336
        lda     DriverStatusWindowRight
        sta     L4334
        sec
        sbc     NumColsToScroll
        sta     L4333
        jmp     L436D
L4353:  and     #%01111111      ; strip high bit (make unsigned)
        sta     NumColsToScroll
        lda     #$01
        sta     L4336
        lda     DriverStatusWindowLeft
        sta     L4334
        clc
        adc     NumColsToScroll
        sta     L4333
        jmp     L436D           ; useless instruction
L436D:  lda     DriverStatusWindowTop
        sta     L4337
L4373:  ldy     L4337
        jsr     GetTextLineBaseAddr
L4379:  lda     L4333
        lsr     a
        bcc     L4385
        sta     SoftSwitch::TXTPAGE1
        jmp     L4388
L4385:  sta     SoftSwitch::TXTPAGE2
L4388:  tay
        lda     (TextLineBasePtr),y
        sta     L4335
        lda     DriverStatusFillChar
        sta     (TextLineBasePtr),y
        lda     L4334
        lsr     a
        bcc     L439F
        sta     SoftSwitch::TXTPAGE1
        jmp     L43A2
L439F:  sta     SoftSwitch::TXTPAGE2
L43A2:  tay
        lda     L4335
        sta     (TextLineBasePtr),y
        lda     L4336
        beq     L43BE
        inc     L4333
        inc     L4334
        lda     DriverStatusWindowRight
        cmp     L4333
        bcs     L4379
        jmp     L43CE
L43BE:  dec     L4333
        dec     L4334
        lda     L4333
        bmi     L43CE
        cmp     DriverStatusWindowLeft
        bcs     L4379
L43CE:  inc     L4337
        lda     DriverStatusWindowBottom
        cmp     L4337
        bcc     L43FE
        lda     L4336
        bne     L43EE
        lda     DriverStatusWindowRight
        sta     L4334
        sec
        sbc     NumColsToScroll
        sta     L4333
        jmp     L4373
L43EE:  lda     DriverStatusWindowLeft
        sta     L4334
        clc
        adc     NumColsToScroll
        sta     L4333
        jmp     L4373
L43FE:  rts

L43FF:  .byte   $00
L4400:  .byte   $00
L4401:  lda     L43FF
        lsr     a
        sta     ViewportLeftEdgeTextPage1
        sta     ViewportLeftEdgeTextPage2
        bcc     @Even
        inc     ViewportLeftEdgeTextPage2
@Even:  lda     L4400
        lsr     a
        sta     ViewportRightEdgeTextPage2
        sta     ViewportRightEdgeTextPage1
        bcs     @Out
        dec     ViewportRightEdgeTextPage1
@Out:   rts

ClearToEndOfLineInViewport:
        ldy     DriverStatusCursorX
        cpy     DriverStatusWindowRight ;cursor at right edge?
        beq     @Out                    ; yes - nothing to do
        iny
        cpy     DriverStatusWindowRight ; 1- space from right edge?
        bne     @Skip                   ; no
        tya     ; divide cursor x-pos by 2
        lsr     a               
        tay
        sta     SoftSwitch::TXTPAGE1 ; flip to correct text page
        bcs     @Odd
        sta     SoftSwitch::TXTPAGE2
@Odd:   lda     DriverStatusFillChar
        sta     (TextLineBasePtr2),y ; erase single char
        jmp     @Out
@Skip:  lda     DriverStatusWindowRight
        sta     L4400
        lda     DriverStatusCursorX
        sta     L43FF
        jsr     L4401
        ldy     DriverStatusCursorY
        jsr     GetTextLineBaseAddr
        jsr     ClearToEndOfLine
@Out:   rts

ClearFromBeginningOfLineInViewport: 
        ldy     DriverStatusCursorX
        cpy     DriverStatusWindowLeft
        beq     L448D
        dey
        cpy     DriverStatusWindowLeft
        bne     L4475
        tya
        lsr     a
        tay
        sta     SoftSwitch::TXTPAGE1
        bcs     L446D
        sta     SoftSwitch::TXTPAGE2
L446D:  lda     DriverStatusFillChar
        sta     (TextLineBasePtr2),y
        jmp     L448D
L4475:  lda     DriverStatusCursorX
        sta     L4400
        lda     DriverStatusWindowLeft
        sta     L43FF
        jsr     L4401
        ldy     DriverStatusCursorY
        jsr     GetTextLineBaseAddr
        jsr     ClearToEndOfLine
L448D:  rts

;;;  set text line base address
SetCurrentTextLineBaseAddress:
        lda     DriverStatusCursorY
        clc
        asl     a
        tax
        lda     TextScreenBaseAddressTable,x
        sta     TextLineBasePtr2
        lda     TextScreenBaseAddressTable+1,x
        sta     TextLineBasePtr2+1
        rts

OutputCharSaveXReg:
        .byte   $00
OutputCharSaveYReg:
        .byte   $00

OutputChar:
        stx     OutputCharSaveXReg
        sty     OutputCharSaveYReg
        pha
        lda     DriverStatusCursorX
        lsr     a
        sta     SoftSwitch::TXTPAGE1
        bcs     L44B4
        sta     SoftSwitch::TXTPAGE2
L44B4:  tay
        pla
        sta     (TextLineBasePtr2),y
        lda     DirverStatusAdvanceFlag
        beq     L44DB
        inc     DriverStatusCursorX
        lda     DriverStatusWindowRight
        cmp     DriverStatusCursorX
        bcs     L44DB
        lda     DriverStatusWrapFlag
        beq     L44D8
        lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        pla
        pla
        jmp     ControlCode_MoveCursorDown
L44D8:  dec     DriverStatusCursorX
L44DB:  ldx     OutputCharSaveXReg
        ldy     OutputCharSaveYReg
        rts

CheckIf2BytesRemaining:
        sec
        lda     BytesLeftToOutput+1
        bne     @Out
        lda     BytesLeftToOutput
        cmp     #$02
        bcs     @Out            ; bge
        clc
@Out:   rts

L44F1:  .byte   $00

SavedDriverStatus:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

BytesLeftToOutput:
        .word   $0000

        .byte   $00,$00         ; unused?

OutputDataSaveXReg:
        .byte   $00
OutputDataSaveYReg:
        .byte   $00
  
ControlCodeHandlerJumpTable:
        .addr   $0000                                ; 00: no-op
        .addr   ControlCode_SaveAndResetViewport     ; 01: save & reset viewport
        .addr   ControlCode_SetViewport              ; 02: set viewport
        .addr   ControlCode_ClearFromBeginningOfLine ; 03: clear from beginning of line
        .addr   ControlCode_RestoreViewport          ; 04: restore viewport
        .addr   $0000                                ; 05: no-op
        .addr   $0000                                ; 06: no-op
        .addr   ControlCode_Bell                     ; 07: bell
        .addr   ControlCode_MoveCursorLeft           ; 08: move cursor left
        .addr   $0000                                ; 09: no-op
        .addr   ControlCode_MoveCursorDown           ; 10: move cursor down
        .addr   ControlCode_ClearToEndOfViewport     ; 11: clear to end of viewport 
        .addr   ControlCode_ClearViewport            ; 12: clear viewport
        .addr   ControlCode_CarriageReturn           ; 13: carriage return
        .addr   ControlCode_NormalText               ; 14: normal text
        .addr   ControlCode_InverseText              ; 15: inverse text
        .addr   ControlCode_SpaceExpansion           ; 16: space expansion
        .addr   ControlCode_HorizontalShift          ; 17: viewport horizontal shift
        .addr   ControlCode_VerticalPosition         ; 18: vertical position
        .addr   ControlCode_ClearFromBeginningOfViewport ; 19: clear from beginning of viewport
        .addr   ControlCode_HorizontalPosition       ; 20: horizontal position
        .addr   ControlCode_CursorMovement           ; 21: cursor movement
        .addr   ControlCode_ScrollDown               ; 22: scroll down
        .addr   ControlCode_ScrollUp                 ; 23: scroll up
        .addr   ControlCode_MouseTextOff             ; 24: mousetext off
        .addr   ControlCode_HomeCursor               ; 25: home cursor
        .addr   ControlCode_ClearLine                ; 26: clear line
        .addr   ControlCode_MouseTextOn              ; 27: mousetext on
        .addr   ControlCode_MoveCursorRight          ; 28: move cursor right
        .addr   ControlCode_ClearToEndOfLine         ; 29: clear to end of line
        .addr   ControlCode_MoveCursorToAbsolutePosition  ; 30: move cursor to absolute position
        .addr   ControlCode_MoveCursorUp             ; 31: move cursor up

OutputData:
        pha                     ; save registers
        php
        stx     OutputDataSaveXReg
        sty     OutputDataSaveYReg
        jsr     SetCurrentTextLineBaseAddress
        lda     DriverStatusCursorY
        sta     L44F1
L4559:  lda     BytesLeftToOutput
        ora     BytesLeftToOutput+1
        bne     L4564
        jmp     RestoreRegisters
L4564:  ldy     #$00
        lda     (OutputDataPtr),y
        bmi     L45A6
        cmp     #$20
        bcc     DispatchToControlCodeHandler
        ldx     MouseTextFlag
        beq     L457E
        cmp     #$40
        bcc     L457E
        cmp     #$60
        bcs     L457E
        jmp     L4598
L457E:  eor     DriverStatusInverseMask
        cmp     #$40
        bcc     L458B
        cmp     #$60
        bcs     L458B
        and     #$1F
L458B:  cmp     #$C0
        bcc     L45A0
        cmp     #$E0
        bcs     L45A0
        and     #$9F
        jmp     L45A0
L4598:  lda     (OutputDataPtr),y
        bpl     L459E
        eor     #$80
L459E:  ora     #$40
L45A0:  jsr     OutputChar
        jmp     L45AB
L45A6:  and     #$7F
        jmp     L45A0
NextOutputChar: 
L45AB:  lda     DriverStatusCursorY
        cmp     L44F1
        beq     L45B9
        sta     L44F1
        jsr     SetCurrentTextLineBaseAddress
L45B9:  inc     OutputDataPtr
        bne     L45BF
        inc     OutputDataPtr+1
L45BF:  lda     BytesLeftToOutput
        bne     L45C7
        dec     BytesLeftToOutput+1
L45C7:  dec     BytesLeftToOutput
        jmp     L4559

RestoreRegisters:
        sta     SoftSwitch::TXTPAGE1
        plp
        pla
        ldx     OutputDataSaveXReg
        ldy     OutputDataSaveYReg
        rts

ControlCodeHandlerAddress:
        .addr   $0000

DispatchToControlCodeHandler:
        asl     a
        tax
        lda     ControlCodeHandlerJumpTable+1,x
        beq     NextOutputChar
        sta     ControlCodeHandlerAddress+1
        lda     ControlCodeHandlerJumpTable,x
        sta     ControlCodeHandlerAddress
        jmp     (ControlCodeHandlerAddress)

ControlCode_SaveAndResetViewport:
        ldy     #$00
        ldx     #$10
L45F2:  lda     DriverStatusTable,y ; save driver status
        sta     SavedDriverStatus,y
        iny
        dex
        bne     L45F2
        lda     #$00
        sta     DriverStatusWindowTop
        lda     #23
        sta     DriverStatusWindowBottom
        lda     #24
        sta     DriverStatusWindowHeight
        lda     #$00
        sta     DriverStatusWindowLeft
        lda     #79
        sta     DriverStatusWindowRight
        lda     #80
        sta     DriverStatusWindowWidth
        lda     #$FF
        sta     DriverStatusWrapFlag
        sta     DriverStatusLineFeedFlag
        sta     DirverStatusAdvanceFlag
        sta     DriverStatusScrollFlag
        sta     DriverStatusSpaceExpansionFlag
        lda     #$00
        sta     MouseTextFlag
        sta     DriverStatusCursorX
        sta     DriverStatusCursorY
        lda     #$80
        sta     DriverStatusInverseMask
        lda     #$A0
        sta     DriverStatusFillChar
        jmp     NextOutputChar

L4643:  .byte   $00
L4644:  .byte   $00
L4645:  .byte   $00

ControlCode_SetViewport:
        lda     BytesLeftToOutput+1
        bne     L4655
        lda     BytesLeftToOutput
        cmp     #$04
        bcs     L4655
        jmp     NextOutputChar
L4655:  ldy     #$01            ; min X
        lda     (OutputDataPtr),y
        bmi     L46D1
        cmp     #79
        bcc     L4661
        lda     #79
L4661:  sta     L4643
        iny
        lda     (OutputDataPtr),y ; min Y
        bmi     L46D1
        cmp     #23
        beq     L4671
        bcc     L4671
        lda     #23
L4671:  sta     L4644
        iny
        lda     (OutputDataPtr),y ; max X
        bmi     L46D1
        cmp     #79
        bcc     L467F
        lda     #79
L467F:  cmp     L4643
        bcs     L4687
        jmp     L46D1
L4687:  sta     L4645
        iny
        lda     (OutputDataPtr),y ; max Y
        bmi     L46D1
        cmp     #23
        beq     L4697
        bcc     L4697
        lda     #23
L4697:  cmp     L4644
        bcs     L469F
        jmp     L46D1
L469F:  sta     DriverStatusWindowBottom
        lda     L4643
        sta     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        lda     L4644
        sta     DriverStatusWindowTop
        sta     DriverStatusCursorY
        lda     L4645
        sta     DriverStatusWindowRight
        sec
        sbc     DriverStatusWindowLeft
        sta     DriverStatusWindowWidth
        inc     DriverStatusWindowWidth
        lda     DriverStatusWindowBottom
        sec
        sbc     DriverStatusWindowTop
        sta     DriverStatusWindowHeight
        inc     DriverStatusWindowHeight
L46D1:  inc     OutputDataPtr   ; advance past next 4 bytes
        bne     L46D7
        inc     OutputDataPtr+1
L46D7:  inc     OutputDataPtr
        bne     L46DD
        inc     OutputDataPtr+1
L46DD:  inc     OutputDataPtr
        bne     L46E3
        inc     OutputDataPtr+1
L46E3:  inc     OutputDataPtr
        bne     L46E9
        inc     OutputDataPtr+1
L46E9:  lda     BytesLeftToOutput
        bne     L46F1
        dec     BytesLeftToOutput+1
L46F1:  dec     BytesLeftToOutput
        lda     BytesLeftToOutput
        bne     L46FC
        dec     BytesLeftToOutput+1
L46FC:  dec     BytesLeftToOutput
        lda     BytesLeftToOutput
        bne     L4707
        dec     BytesLeftToOutput+1
L4707:  dec     BytesLeftToOutput
        lda     BytesLeftToOutput
        bne     L4712
        dec     BytesLeftToOutput+1
L4712:  dec     BytesLeftToOutput
        jmp     NextOutputChar

ControlCode_RestoreViewport:
        ldy     #$00
        ldx     #$10
@Loop:  lda     SavedDriverStatus,y ; restore saved driver status
        sta     DriverStatusTable,y
        iny
        dex
        bne     @Loop
        jmp     NextOutputChar

ControlCode_MouseTextOn:
        lda     #$FF
        sta     MouseTextFlag
        jmp     NextOutputChar

ControlCode_MouseTextOff:
        lda     #$00
        sta     MouseTextFlag
        jmp     NextOutputChar

ClickDelayLoop:
        sec
@Loop1: pha
@Loop2: sbc     #$01
        bne     @Loop2
        pla
        sbc     #$01
        bne     @Loop1
        rts

ClickCounter:
       .byte   $20

ControlCode_Bell:
        lda     #$20
        sta     ClickCounter
@Loop:  lda     #$02
        jsr     ClickDelayLoop
        sta     SoftSwitch::SPKR
        lda     #$24
        jsr     ClickDelayLoop
        sta     SoftSwitch::SPKR
        dec     ClickCounter
        bne     @Loop
        jmp     NextOutputChar

ControlCode_MoveCursorLeft:
        lda     DriverStatusCursorX
        cmp     DriverStatusWindowLeft
        beq     L4771           ; at left edge
        dec     DriverStatusCursorX
        jmp     L4792
L4771:  lda     DriverStatusWrapFlag
        beq     L4792           ; no wrap
        lda     DriverStatusScrollFlag
        beq     L478C           ; no scroll
        lda     DriverStatusCursorY
        cmp     DriverStatusWindowTop
        bne     L4789           ; not at top
        jsr     ScrollViewportDown
        jmp     L478C
L4789:  dec     DriverStatusCursorY
L478C:  lda     DriverStatusWindowRight
        sta     DriverStatusCursorX
L4792:  jmp     NextOutputChar

ControlCode_MoveCursorRight:
        lda     DriverStatusCursorX
        cmp     DriverStatusWindowRight
        beq     L47A3           ; not at right edge
        inc     DriverStatusCursorX
        jmp     L47C4
L47A3:  lda     DriverStatusWrapFlag
        beq     L47C4           ; no wrap
        lda     DriverStatusScrollFlag
        beq     L47BE           ; no scroll
        lda     DriverStatusCursorY
        cmp     DriverStatusWindowBottom
        bne     L47BB           ; not at bottom
        jsr     ScrollViewportUp
        jmp     L47BE
L47BB:  inc     DriverStatusCursorY
L47BE:  lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
L47C4:  jmp     NextOutputChar

ControlCode_MoveCursorDown:
        lda     DriverStatusCursorY
        cmp     DriverStatusWindowBottom
        bne     @Skip2           ; not at bottom
        lda     DriverStatusScrollFlag
        beq     @Skip           ; no scroll
        jsr     ScrollViewportUp
@Skip:  jmp     NextOutputChar
@Skip2: inc     DriverStatusCursorY
        jsr     SetCurrentTextLineBaseAddress
        jmp     NextOutputChar

ControlCode_MoveCursorUp:
        lda     DriverStatusCursorY
        cmp     DriverStatusWindowTop
        bne     @Skip2          ; not at top
        lda     DriverStatusScrollFlag
        beq     @Skip           ; no scroll
        jsr     ScrollViewportDown
@Skip:  jmp     NextOutputChar
@Skip2: dec     DriverStatusCursorY
        jmp     NextOutputChar

ControlCode_HomeCursor:
        lda     DriverStatusWindowTop
        sta     DriverStatusCursorY
        lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        jmp     NextOutputChar

ControlCode_CarriageReturn:
        lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        lda     DriverStatusLineFeedFlag
        beq     @Out            ; no line feed
        jmp     ControlCode_MoveCursorDown
@Out:   jmp     NextOutputChar

ControlCode_SpaceExpansion:
        jsr     CheckIf2BytesRemaining
        bcc     @Out
        lda     DriverStatusSpaceExpansionFlag
        beq     @ZeroSpaces
        ldy     #$01
        lda     (OutputDataPtr),y
        sec
        sbc     #32
        beq     @ZeroSpaces
        tax
@Loop:  lda     DriverStatusFillChar
        jsr     OutputChar
        dex
        bne     @Loop
@ZeroSpaces:
        inc     OutputDataPtr
        bne     @Skip
        inc     OutputDataPtr+1
@Skip:  lda     BytesLeftToOutput
        bne     @Skip2
        dec     BytesLeftToOutput+1
@Skip2: dec     BytesLeftToOutput
@Out:   jmp     NextOutputChar

ControlCode_NormalText:
        lda     #$80
        sta     DriverStatusInverseMask
        lda     #$A0
        sta     DriverStatusFillChar
        jmp     NextOutputChar

ControlCode_InverseText:
        lda     #$00
        sta     DriverStatusInverseMask
        lda     #$20
        sta     DriverStatusFillChar
        jmp     NextOutputChar

ControlCode_CursorMovement:
        jsr     CheckIf2BytesRemaining
        bcc     L48B6
        ldy     #$01
        lda     (OutputDataPtr),y ; flags
        cmp     #$20
        bcs     L48A5           ; invalid flags
        ldy     #$00
        sty     DirverStatusAdvanceFlag
        sty     DriverStatusLineFeedFlag
        sty     DriverStatusWrapFlag
        sty     DriverStatusScrollFlag
        sty     DriverStatusSpaceExpansionFlag
        ldy     #$01
        lsr     a
        bcc     L488D
        sty     DirverStatusAdvanceFlag
L488D:  lsr     a
        bcc     L4893
        sty     DriverStatusLineFeedFlag
L4893:  lsr     a
        bcc     L4899
        sty     DriverStatusWrapFlag
L4899:  lsr     a
        bcc     L489F
        sty     DriverStatusScrollFlag
L489F:  lsr     a
        bcc     L48A5
        sty     DriverStatusSpaceExpansionFlag
L48A5:  inc     OutputDataPtr
        bne     L48AB
        inc     OutputDataPtr+1
L48AB:  lda     BytesLeftToOutput
        bne     L48B3
        dec     BytesLeftToOutput+1
L48B3:  dec     BytesLeftToOutput
L48B6:  jmp     NextOutputChar

HorizontalShiftAmount:
        .byte   $00

ControlCode_HorizontalShift:
        jsr     CheckIf2BytesRemaining
        bcc     @Out
        ldy     #$01
        lda     (OutputDataPtr),y
        beq     @Skip2
        sta     HorizontalShiftAmount
        and     #$7F
        cmp     DriverStatusWindowWidth
        bcs     @Skip
        lda     HorizontalShiftAmount
        jsr     ScrollViewportSideways
        jmp     @Skip2
@Skip:  lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        ldy     DriverStatusWindowTop
        sty     DriverStatusCursorY
        jsr     ClearLinesToEndOfViewport
        jmp     @Skip2           ; useless instruction
@Skip2: inc     OutputDataPtr
        bne     @Skip3
        inc     OutputDataPtr+1
@Skip3: lda     BytesLeftToOutput
        bne     @Skip4
        dec     BytesLeftToOutput+1
@Skip4: dec     BytesLeftToOutput
@Out:   jmp     NextOutputChar

ControlCode_ScrollDown:
        jsr     ScrollViewportDown
        jmp     NextOutputChar

ControlCode_ScrollUp:
        jsr     ScrollViewportUp
        jmp     NextOutputChar

ControlCode_HorizontalPosition:
        jsr     CheckIf2BytesRemaining
        bcc     @Out
        ldy     #$01
        lda     (OutputDataPtr),y
        clc
        adc     DriverStatusWindowLeft
        cmp     DriverStatusWindowRight
        bcc     @Skip
        lda     DriverStatusWindowRight
@Skip:  sta     DriverStatusCursorX
        inc     OutputDataPtr
        bne     @Skip2
        inc     OutputDataPtr+1
@Skip2: lda     BytesLeftToOutput
        bne     @Skip3
        dec     BytesLeftToOutput+1
@Skip3: dec     BytesLeftToOutput
@Out:   jmp     NextOutputChar

ControlCode_VerticalPosition:
        jsr     CheckIf2BytesRemaining
        bcc     @Out
        ldy     #$01
        lda     (OutputDataPtr),y
        clc
        adc     DriverStatusWindowTop
        cmp     DriverStatusWindowBottom
        bcc     @Skip
        lda     DriverStatusWindowBottom
@Skip:  sta     DriverStatusCursorY
        inc     OutputDataPtr
        bne     @Skip2
        inc     OutputDataPtr+1
@Skip2: lda     BytesLeftToOutput
        bne     @Skip3
        dec     BytesLeftToOutput+1
@Skip3: dec     BytesLeftToOutput
@Out:   jmp     NextOutputChar

ControlCode_MoveCursorToAbsolutePosition:
        lda     BytesLeftToOutput+1
        bne     L4971
        lda     BytesLeftToOutput
        cmp     #$03
        bcs     L4971
        jmp     NextOutputChar
L4971:  ldy     #$01
        lda     (OutputDataPtr),y
        clc
        adc     DriverStatusWindowLeft
        cmp     DriverStatusWindowRight
        bcc     L4981
        lda     DriverStatusWindowRight
L4981:  sta     DriverStatusCursorX
        iny
        lda     (OutputDataPtr),y
        clc
        adc     DriverStatusWindowTop
        cmp     DriverStatusWindowBottom
        bcc     L4993
        lda     DriverStatusWindowBottom
L4993:  sta     DriverStatusCursorY
        inc     OutputDataPtr
        bne     L499C
        inc     OutputDataPtr+1
L499C:  lda     BytesLeftToOutput
        bne     L49A4
        dec     BytesLeftToOutput+1
L49A4:  dec     BytesLeftToOutput
        inc     OutputDataPtr
        bne     L49AD
        inc     OutputDataPtr+1
L49AD:  lda     BytesLeftToOutput
        bne     L49B5
        dec     BytesLeftToOutput+1
L49B5:  dec     BytesLeftToOutput
        jmp     NextOutputChar

ControlCode_ClearViewport:
        lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        ldy     DriverStatusWindowTop
        sty     DriverStatusCursorY
        jsr     ClearLinesToEndOfViewport
        jmp     NextOutputChar

ControlCode_ClearToEndOfViewport:
        jsr     ClearToEndOfLineInViewport
        ldy     DriverStatusCursorY
        cpy     DriverStatusWindowBottom
        beq     @Out
        iny
        jsr     ClearLinesToEndOfViewport
@Out:   jmp     NextOutputChar

ControlCode_ClearLine:
        ldy     DriverStatusCursorY
        jsr     ClearLineInViewport
        lda     DriverStatusWindowLeft
        sta     DriverStatusCursorX
        jmp     NextOutputChar

ControlCode_ClearToEndOfLine:
        jsr     ClearToEndOfLineInViewport
        jmp     NextOutputChar

ControlCode_ClearFromBeginningOfLine:
        jsr     ClearFromBeginningOfLineInViewport
        jmp     NextOutputChar

ControlCode_ClearFromBeginningOfViewport:
        jsr     ClearFromBeginningOfLineInViewport
        ldy     DriverStatusWindowTop
        cpy     DriverStatusCursorY
        beq     @Out
@Loop:  jsr     ClearLineInViewport
        iny
        cpy     DriverStatusCursorY
        bne     @Loop
@Out:   jmp     NextOutputChar

L4A11:  jmp     InputRoutineMain

InputInfoBlock:
InputFieldWidth:
        .byte   254
InputFillChar:
        .byte   ' '
InputMouseTextFillCharFlag:
        .byte   $00
InputCursorType:
        .byte   $00
InputControlCharsAllowedFlag:
        .byte   $00
InputBeepOnErrorFlag:
        .byte   $01
InputImmediateModeFlag:
        .byte   $00
InputEntryType:
        .byte   $00
InputBorderChar:
         .byte   ' '
InputExitType:
        .byte   $00
InputLastEvent:                 ;unused
        .byte   $00
InputLastChar:
        .byte   $00
InputLastKeypressModifier:
        .byte   $00
InputNumTerminatorChars:
        .byte   $02
InputTerminatorChars:
        .byte   ControlChar::Return
        .byte   ControlChar::Esc
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
InputTerminatorCharModifiers:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
InputTerminatorTypes:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
InputOriginX:
        .byte   $00
InputOriginY:
        .byte   $00
InputCursorX: 
        .byte   $00
InputCursorY:
        .byte   $00
InputCursorPos:
        .byte   $00
InputCurrentLength:
        .byte   $00
InputSlowBlink:
        .byte   $00
InputFastBlink:
        .byte   $00
L4A66:  .byte   $00
L4A67:  .byte   $00
L4A68:  .byte   $A0
L4A69:  .byte   $A0
L4A6A:  .byte   $A0
L4A6B:  .byte   $A0
L4A6C:  .byte   $C3,$A0

L4A6E:  .byte   $00
MaxInputLength:
        .byte   $00

InputBuffer:     ; 255 bytes
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
        .byte   $00,$00,$00,$00,$00,$00,$00
L4B6F:  .byte   $00
L4B70:  .byte   $00
L4B71:  .byte   $00
L4B72:  .byte   $00
L4B73:  .byte   $00
L4B74:  .byte   $00
L4B75:  .byte   $00
L4B76:  .byte   $00

InputRoutineMain:
        sta     DefaultInputPtr
        sty     DefaultInputPtr+1
        stx     MaxInputLength
        ldx     InputEntryType
        beq     L4B9E
        ldx     InputCursorX
        ldy     InputCursorY
        jsr     SetInputCursorPosToXY
        ldx     InputEntryType
        cpx     #$02
        bne     L4B9E
        lda     InputLastChar
        ora     InputLastKeypressModifier
        bne     L4BCF
        jmp     L4BBC
L4B9E:  jsr     L4BEB
        ldx     InputEntryType
        bne     L4BB9
        jsr     L4CA7
        lda     InputImmediateModeFlag
        beq     L4BBC
        ldx     #$00
        stx     InputLastChar
        stx     InputLastKeypressModifier
        jmp     L4BC6
L4BB9:  jsr     L4CD0
L4BBC:  jsr     InputChar
        lda     InputImmediateModeFlag
        beq     L4BCF
        ldx     #$00
L4BC6:  stx     InputExitType
        ldx     #$02
        stx     InputEntryType
        rts
L4BCF:  jsr     L4DC2
        bmi     L4BBC
        beq     L4BE2
        dex
        lda     InputTerminatorTypes,x
        beq     L4BDF
        jmp     L50CC
L4BDF:  jmp     L50BE
L4BE2:  jsr     L4F72
        jsr     L4D65
        jmp     L4BBC
L4BEB:  ldx     InputFieldWidth
        inx
        bne     L4BF4
        dec     InputFieldWidth
L4BF4:  jsr     GetCursorPosInViewportCoordinates
        stx     L4A68
        sty     L4A69
        ldx     #79
        ldy     #23
        jsr     SetCursorAbsolutePosition
        jsr     GetCursorPosInViewportCoordinates
        stx     L4B73
        sty     L4B74
        ldx     L4A68
        ldy     L4A69
        jsr     SetCursorAbsolutePosition
        lda     InputEntryType
        beq     L4C27
        ldx     InputOriginX
        ldy     InputOriginY
        stx     L4A68
        sty     L4A69
L4C27:  clc
        lda     #$01
        adc     L4B74
        sec
        sbc     L4A69
        sta     L4A6A
        sta     L4A6B
        lda     #$00
        sta     L4A6C
        ldx     L4B73
        dex
L4C40:  clc
        lda     L4A6B
        adc     L4A6A
        sta     L4A6B
        lda     L4A6C
        adc     #$00
        sta     L4A6C
        dex
        bpl     L4C40
        sec
        lda     L4A6B
        sbc     L4A68
        sta     L4A6B
        lda     L4A6C
        sbc     #$00
        sta     L4A6C
        bne     L4C76
        ldx     L4A6B
        dex
        dex
        cpx     InputFieldWidth
        bcs     L4C76
        stx     InputFieldWidth
L4C76:  ldx     MaxInputLength
        cpx     InputFieldWidth
        beq     L4C83
        bcs     L4C83
        stx     InputFieldWidth
L4C83:  ldy     #$00
        lda     (DefaultInputPtr),y
        sta     L4A6E
        cmp     InputFieldWidth
        beq     L4C97
        bcc     L4C97
        lda     InputFieldWidth
        sta     L4A6E
L4C97:  cmp     InputCursorPos
        bcs     L4CA1
        tax
        inx
        stx     InputCursorPos
L4CA1:  lda     #$FF
        sta     L4B70
        rts

L4CA7:  jsr     UpdateInputCursor
        stx     InputOriginX
        sty     InputOriginY
        lda     L4A6E
        sta     InputCurrentLength
        sta     L4B6F
        beq     L4CC4
        tay
L4CBC:  lda     (DefaultInputPtr),y
        sta     InputBuffer,y
        dey
        bpl     L4CBC
L4CC4:  jsr     L505D
        ldx     #$01
        stx     InputCursorPos
        jsr     L4FDB
        rts

L4CD0:  jsr     L505D
        ldx     #$00
        jsr     L4FDB
        rts

;;;  blink cursor routine
BlinkCursor:
L4CD9:  lda     L4B70
        bmi     L4D11
        beq     L4D0C
        jsr     L4D53
        bne     L4D52
        jsr     L4D78
        lda     #ControlChar::Backspace
        jsr     OutputCharAndUpdateInputCursor
        lda     InputCursorType
        bne     L4CFB
        ldx     InputSlowBlink
        ldy     InputFastBlink
        jmp     L4D01
L4CFB:  ldx     L4A66
        ldy     L4A67
L4D01:  stx     L4B71
        sty     L4B72
        lda     #$00
        jmp     L4D4F
L4D0C:  jsr     L4D53
        bne     L4D52
L4D11:  jsr     L4D65
        lda     InputCursorType
        beq     L4D34
        lda     L4B75
        ldx     InputCursorPos
        cpx     L4A6E
        beq     L4D28
        bcc     L4D28
        lda     #' '
L4D28:  jsr     L516B
        ldx     InputSlowBlink
        ldy     InputFastBlink
        jmp     L4D42
L4D34:  lda     #'_'
        sta     L4B76
        jsr     OutputCharAndUpdateInputCursor
        ldx     L4A66
        ldy     L4A67
L4D42:  stx     L4B71
        sty     L4B72
        lda     #ControlChar::Backspace
        jsr     OutputCharAndUpdateInputCursor
        lda     #$0F
L4D4F:  sta     L4B70
L4D52:  rts

L4D53:  lda     L4B71
        bne     L4D5B
        dec     L4B72
L4D5B:  dec     L4B71
        lda     L4B71
        ora     L4B72
        rts

L4D65:  ldy     InputCursorPos
        lda     (DefaultInputPtr),y
        cpy     InputFieldWidth
        beq     L4D74
        bcc     L4D74
        lda     InputBorderChar
L4D74:  sta     L4B75
        rts

L4D78:  ldx     InputMouseTextFillCharFlag
        beq     L4D94
        ldx     L4A6E
        cpx     InputCursorPos
        bcs     L4D92
        cpx     InputFieldWidth
        beq     L4D92
        jsr     TurnMouseTextOn
        ldx     #$01
        jmp     L4D94
L4D92:  ldx     #$00
L4D94:  stx     L4DA6
        jsr     L4D65
        jsr     OutputCharAndUpdateInputCursor
        ldx     L4DA6
        beq     L4DA5
        jsr     TurnMouseTextOff
L4DA5:  rts

L4DA6:  .byte   $00             ; storage for X register

;;;  Jump table for input control
InputControlJumpTable:
        .byte   ControlChar::LeftArrow
        .addr   LeftArrowInputHandler
        .byte   ControlChar::RightArrow
        .addr   RightArrowInputHandler
        .byte   ControlChar::Delete
        .addr   DeleteKeyInputHandler
        .byte   ControlChar::ControlD
        .addr   DeleteKeyInputHandler
        .byte   ControlChar::ControlE
        .addr   ControlEInputHandler
        .byte   ControlChar::ControlX
        .addr   ControlXInputHandler
        .byte   ControlChar::ControlY
        .addr   ControlYInputHandler
        .byte   ControlChar::ControlZ
        .addr   ControlZInputHandler
        .byte   ControlChar::ControlF
        .addr   ControlFInputHandler

L4DC2:  jsr     L4D78
        lda     #ControlChar::Backspace
        jsr     OutputCharAndUpdateInputCursor
        jsr     L4D65
        lda     InputLastChar
        ldx     InputLastKeypressModifier
        cmp     #$61
        bcc     L4DDD
        cmp     #$7B
        bcs     L4DDD
        and     #$DF
L4DDD:  ldy     #$FF
L4DDF:  iny
        cpy     InputNumTerminatorChars
        bcs     L4E0B
        cmp     InputTerminatorChars,y
        bne     L4DDF
        sta     L4A68
        txa
        cmp     InputTerminatorCharModifiers,y
        beq     L4DFE
        and     InputTerminatorCharModifiers,y
        bne     L4DFE
        lda     L4A68
        jmp     L4DDF
L4DFE:  tya
        tax
        lda     L4A68
        inx
        stx     InputExitType
        lda     InputLastChar
        rts
L4E0B:  lda     InputLastChar
        cpx     #$00
        bne     L4E2D
        ldx     #$00
L4E14:  cmp     InputControlJumpTable,x
        bne     L4E26
        lda     InputControlJumpTable+1,x
        sta     TmpPointer
        lda     InputControlJumpTable+2,x
        sta     TmpPointer+1
        jmp     (TmpPointer)
L4E26:  inx
        inx
        inx
        cpx     #$1B
        bcc     L4E14
L4E2D:  cmp     #$20
        bcs     L4E42
        ldx     InputControlCharsAllowedFlag
        beq     L4E57
        ldx     InputLastKeypressModifier
        cpx     #$01
        bne     L4E57
        ora     #$80
        jmp     L4E47
L4E42:  ldx     InputLastKeypressModifier
        bne     L4E57
L4E47:  ldy     InputCursorPos
        cpy     InputFieldWidth
        beq     L4E54
        bcc     L4E54
        jmp     L4E57
L4E54:  ldx     #$00
        rts
L4E57:  jsr     InputError
L4E5A:  jsr     L4D65
        ldx     #$FF
        stx     L4B70
        rts

LeftArrowInputHandler:
        ldx     #$01
        cpx     InputCursorPos
        bne     @Skip
        jsr     InputError
        jmp     L4E5A
@Skip:  jsr     L4D78
        dec     InputCursorPos
        lda     #ControlChar::Backspace
        jsr     OutputCharAndUpdateInputCursor
        jsr     OutputCharAndUpdateInputCursor
        jmp     L4E5A

RightArrowInputHandler:
        jsr     L4F5F
        jsr     L4D78
        inc     InputCursorPos
        jmp     L4E5A

DeleteKeyInputHandler:
        ldx     #$01
        cpx     InputCursorPos
        bne     L4E9A
        jsr     InputError
        jmp     L4E5A
L4E9A:  jsr     L4D78
        lda     #ControlChar::Backspace
        jsr     OutputCharAndUpdateInputCursor
        jsr     OutputCharAndUpdateInputCursor
        dec     InputCursorPos
L4EA8:  ldy     InputCursorPos
        iny
L4EAC:  beq     L4EC2
        cpy     MaxInputLength
        beq     L4EB8
        bcc     L4EB8
        jmp     L4EC2
L4EB8:  lda     (DefaultInputPtr),y
        dey
        sta     (DefaultInputPtr),y
        iny
        iny
        jmp     L4EAC
L4EC2:  dec     InputCurrentLength
        ldx     L4A6E
        cpx     InputCurrentLength
        bcc     L4EE2
        beq     L4ED2
        dec     L4A6E
L4ED2:  lda     InputFillChar
        ldy     InputMouseTextFillCharFlag
        beq     L4EDD
        lda     MouseTextFillChar
L4EDD:  ldy     MaxInputLength
        sta     (DefaultInputPtr),y
L4EE2:  ldx     #$00
        jsr     L4FDB
        jmp     L4E5A

ControlFInputHandler:
        jsr     L4F5F
        jmp     L4EA8

ControlEInputHandler:   
        lda     #$00
        ldx     InputCursorType
        bne     @Skip
        lda     #$01
@Skip:  sta     InputCursorType
        jmp     L4E5A

ControlXInputHandler:
        ldx     #$00
        stx     L4A6E
        stx     InputCurrentLength
        inx
        stx     InputCursorPos
        ldx     InputOriginX
        ldy     InputOriginY
        jsr     SetInputCursorPosToXY
        jsr     L505D
        ldx     #$00
        jsr     L4FDB
        jmp     L4E5A

ControlYInputHandler:
        ldy     InputCursorPos
        dey
        sty     L4A6E
        sty     InputCurrentLength
        jsr     L505D
        ldx     #$00
        jsr     L4FDB
        jmp     L4E5A

ControlZInputHandler:
        lda     L4B6F
        sta     L4A6E
        sta     InputCurrentLength
        beq     @Skip
        tay
@Loop:  lda     InputBuffer,y
        sta     (DefaultInputPtr),y
        dey
        bpl     @Loop
        ldx     InputOriginX
        ldy     InputOriginY
        jsr     SetInputCursorPosToXY
@Skip:  jsr     L505D
        ldx     #$01
        stx     InputCursorPos
        jsr     L4FDB
        jmp     L4E5A

L4F5F:  ldy     InputCursorPos
        cpy     L4A6E
        bcc     @Out
        beq     @Out
        jsr     InputError
        pla
        pla
        jmp     L4E5A
@Out:   rts

L4F72:  sta     L4A6A
        ldy     InputCurrentLength
        lda     InputCursorType
        beq     L4F8A
        cpy     InputCursorPos
        bcc     L4F99
        jmp     L4FAF
        lda     InputCursorType
        bne     L4FAF
L4F8A:  cpy     InputCursorPos
        bcc     L4F99
        lda     (DefaultInputPtr),y
        iny
        sta     (DefaultInputPtr),y
        dey
        dey
        jmp     L4F8A
L4F99:  ldy     InputCurrentLength
        cpy     MaxInputLength
        bcs     L4FA4
        inc     InputCurrentLength
L4FA4:  ldy     InputFieldWidth
        cpy     L4A6E
        beq     L4FAF
        inc     L4A6E
L4FAF:  ldy     InputCursorPos
        lda     L4A6A
        sta     (DefaultInputPtr),y
        cpy     L4A6E
        bcc     L4FC1
        beq     L4FC1
        sty     L4A6E
L4FC1:  lda     InputCursorType
        bne     L4FCB
        ldx     #$00
        jsr     L4FDB
L4FCB:  lda     L4A6A
        jsr     OutputCharAndUpdateInputCursor
        inc     InputCursorPos
        lda     L4A6A
        jsr     UpdateInputCursor
        rts

L4FDB:  stx     L4A68
        ldx     InputCursorX
        ldy     InputCursorY
        stx     L4A6B
        sty     L4A6C
        clc
        lda     DefaultInputPtr
        adc     InputCursorPos
        tax
        lda     #$00
        adc     DefaultInputPtr+1
        tay
        sec
        lda     L4A6E
        sbc     InputCursorPos
        clc
        adc     #$01
        sta     L4A69
        txa
        ldx     L4A69
        jsr     OutputDataAtAY
        ldx     L4A68
        beq     L5018
        jsr     UpdateInputCursor
        stx     L4A6B
        sty     L4A6C
L5018:  lda     InputMouseTextFillCharFlag
        beq     L5020
        jsr     TurnMouseTextOn
L5020:  clc
        lda     #$01
        adc     DefaultInputPtr
        adc     L4A6E
        tax
        lda     #$00
        adc     DefaultInputPtr+1
        tay
        sec
        lda     InputFieldWidth
        sbc     L4A6E
        sta     L4A69
        txa
        ldx     L4A69
        jsr     OutputDataAtAY
        lda     InputMouseTextFillCharFlag
        beq     L5047
        jsr     TurnMouseTextOff
L5047:  ldx     L4A68
        beq     L5053
        ldy     L4A6E
        iny
        sty     InputCursorPos
L5053:  ldx     L4A6B
        ldy     L4A6C
        jsr     SetInputCursorPosToXY
        rts

L505D:  ldy     InputCurrentLength
        iny
        beq     @Out
        lda     InputFillChar
        ldx     InputMouseTextFillCharFlag
        beq     @Loop
        lda     MouseTextFillChar
@Loop:  sta     (DefaultInputPtr),y
        iny
        beq     @Out
        cpy     MaxInputLength
        beq     @Loop
        bcc     @Loop
@Out:   rts

OutputCharAndUpdateInputCursor:
        jsr     OutputCharInA
        jsr     UpdateInputCursor
        rts

UpdateInputCursor:
        jsr     GetCursorPosInViewportCoordinates
        stx     InputCursorX
        sty     InputCursorY
        rts

SetInputCursorPosToXY:
        stx     InputCursorX
        sty     InputCursorY
        jsr     SetCursorAbsolutePosition
        rts

InputChar:
        jsr     ReadKeyboard
        bmi     L50AA           ; high bit set?
        jsr     BlinkCursor
        lda     InputImmediateModeFlag
        beq     InputChar
        lda     #$00
        ldx     #$00
        jmp     L50AC
L50AA:  and     #%01111111      ; strip high bit
L50AC:  sta     InputLastChar
        stx     InputLastKeypressModifier
        rts

InputError:
        lda     InputBeepOnErrorFlag
        beq     @Out
        lda     #ControlChar::Bell
        jsr     OutputCharAndUpdateInputCursor
@Out:   rts

L50BE:  jsr     L4D78
        lda     #$00
        sta     InputCursorPos
        sta     InputEntryType
        jmp     L50D4

L50CC:  jsr     L4D78
        lda     #$01
        sta     InputEntryType
L50D4:  lda     #ControlChar::Backspace
        jsr     OutputCharAndUpdateInputCursor
        ldy     #$00
        lda     L4A6E
        sta     (DefaultInputPtr),y
        rts

AccumulatorTmpStorage:
        .byte   $00             ; tmp storage for A
L50E2:  .byte   $00             ; tmp storage for Y

;;; stores cursor position relative to viewport top-left corner in X, Y.
GetCursorPosInViewportCoordinates:
        sta     AccumulatorTmpStorage
        sec
        lda     DriverStatusCursorX
        sbc     DriverStatusWindowLeft
        tax
        sec
        lda     DriverStatusCursorY
        sbc     DriverStatusWindowTop
        tay
        lda     AccumulatorTmpStorage
        rts

;;; sets cursor position to X,Y
SetCursorAbsolutePosition:
        sta     AccumulatorTmpStorage
        stx     SetCursorControlSeqX
        sty     SetCursorControlSeqY
        lda     SetCursorPosControlSeqAddr
        sta     OutputDataPtr
        lda     SetCursorPosControlSeqAddr+1
        sta     OutputDataPtr+1
        lda     #3
        sta     BytesLeftToOutput
        jsr     OutputData
        lda     AccumulatorTmpStorage
        ldx     SetCursorControlSeqX
        ldy     SetCursorControlSeqY
        rts

SetCursorPosControlSeq:
        .byte   ControlChar::SetCursorXY ; 'absolute position' control code
SetCursorControlSeqX:
        .byte   $00
SetCursorControlSeqY:        
        .byte   $00
SetCursorPosControlSeqAddr:
        .addr   SetCursorPosControlSeq
        
ReadKeyboard:
        lda     SoftSwitch::KBD
        bpl     @Out
        sta     AccumulatorTmpStorage
        sta     SoftSwitch::KBDSTRB
        lda     #$00
        ldx     SoftSwitch::RDBTN0
        bpl     @Skip
        ora     #%00000001
@Skip:  ldx     SoftSwitch::RDBTN1
        bpl     @Skip2
        ora     #%00000010
@Skip2: tax
        lda     AccumulatorTmpStorage
@Out:   rts

OutputCharInA:
        sta     SingleChar
        lda     SingleCharAddr
        sta     OutputDataPtr
        lda     SingleCharAddr+1
        sta     OutputDataPtr+1
        lda     #$01
        sta     BytesLeftToOutput
        jsr     OutputData
        lda     SingleChar
        rts

SingleChar:
        .byte   $00 
SingleCharAddr:
        .addr   SingleChar

;;; outputs data at A,Y of length X.
OutputDataAtAY: 
        sta     OutputDataPtr
        sty     OutputDataPtr+1
        stx     BytesLeftToOutput
        jsr     OutputData
        rts

;;; Outputs overwrite cursor, in either inverse or normal
L516B:  sta     ByteSequenceToOutput+1
        stx     AccumulatorTmpStorage
        sty     L50E2
        ldx     #ControlChar::InverseVideo
        ldy     #ControlChar::NormalVideo
        lda     DriverStatusInverseMask
        bne     @Skip
        ldx     #ControlChar::NormalVideo
        ldy     #ControlChar::InverseVideo
@Skip:  stx     ByteSequenceToOutput
        sty     ByteSequenceToOutput+2
        lda     ByteSequenceToOutputAddr
        sta     OutputDataPtr
        lda     ByteSequenceToOutputAddr+1
        sta     OutputDataPtr+1
        lda     #3
        sta     BytesLeftToOutput
        jsr     OutputData
        lda     ByteSequenceToOutput+1
        ldx     AccumulatorTmpStorage
        ldy     L50E2
        rts

ByteSequenceToOutput:
        .byte   $00             ; first control char
        .byte   $00             ; char to output
        .byte   $00             ; second control char
ByteSequenceToOutputAddr:
        .addr   ByteSequenceToOutput

MouseTextFillChar:
        .byte   MouseText::Ellipsis

TurnMouseTextOn:
        sta     AccumulatorTmpStorage
        lda     #ControlChar::MouseTextOn
        jsr     OutputCharInA
        lda     #ControlChar::InverseVideo
        jsr     OutputCharInA
        lda     AccumulatorTmpStorage
        rts

TurnMouseTextOff:
        sta     AccumulatorTmpStorage
        lda     #ControlChar::NormalVideo
        jsr     OutputCharInA
        lda     #ControlChar::MouseTextOff
        jsr     OutputCharInA
        lda     AccumulatorTmpStorage
        rts

L51CB:  .byte   $00

Handler_Input:
        lda     ParamTablePtr
        sta     TmpPointer
        lda     ParamTablePtr+1
        sta     TmpPointer+1
        ldy     #$02
        lda     (TmpPointer),y
        tax
        ldy     #$00
        lda     (TmpPointer),y
        sta     L51CB
        iny
        lda     (TmpPointer),y
        tay
        lda     L51CB
        jsr     L4A11
        txa
        clc
        jmp     ReturnWithErrorCode

L51EF:  .byte   $00             ; slow blink default value
L51F0:  .byte   $19             ; fast blink default value
L51F1:  .byte   $80             ; blink counter?
L51F2:  .byte   $0C             ; blink counter?

Handler_InitializeInputInfo:
        ldy     #$53
@Loop:  lda     #$00
        sta     InputInfoBlock,y
        dey
        bpl     @Loop
        lda     #254
        sta     InputFieldWidth
        lda     #' '
        sta     InputFillChar
        lda     #$01
        sta     InputBeepOnErrorFlag
        lda     #' '
        sta     InputBorderChar
        lda     #$02
        sta     InputNumTerminatorChars
        lda     #ControlChar::Return
        sta     InputTerminatorChars
        lda     #ControlChar::Esc
        sta     InputTerminatorChars+1
        lda     L51EF
        sta     InputSlowBlink
        lda     L51F0
        sta     InputFastBlink
        lda     L51F1
        sta     L4A66
        lda     L51F2
        sta     L4A67
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_RetrieveInputInfo:
        lda     ParamTablePtr
        sta     TmpPointer
        lda     ParamTablePtr+1
        sta     TmpPointer+1
        ldy     #$53            ; length of info block - 1
@Loop:  lda     InputInfoBlock,y
        sta     (TmpPointer),y
        dey
        bpl     @Loop
        lda     #0
        clc
        jmp     ReturnWithErrorCode

Handler_SetInputInfo:
        lda     ParamTablePtr
        sta     TmpPointer
        lda     ParamTablePtr+1
        sta     TmpPointer+1
        ldy     #$53            ; length of info block - 1
@Loop:  lda     (TmpPointer),y
        sta     InputInfoBlock,y
        dey
        bpl     @Loop
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

;;; storage for 32 zero page locations
ZeroPageStorage:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

SaveZeroPage:
        ldy     #$00
        ldx     #$20
@Loop:  lda     TextLineBasePtr2,y
        sta     ZeroPageStorage,y
        iny
        dex
        bne     @Loop
        rts

RestoreZeroPage:
        ldy     #$00
        ldx     #$20
@Loop:  lda     ZeroPageStorage,y
        sta     TextLineBasePtr2,y
        iny
        dex
        bne     @Loop
        rts

CopyCursorPositionToParamTable:
        ldy     #$00
        lda     DriverStatusCursorX
        sta     (ParamTablePtr),y
        iny
        lda     DriverStatusCursorY
        sta     (ParamTablePtr),y
        rts

CopyCharAtCursorToParamTable:
        lda     DriverStatusCursorX
        lsr     a
        sta     SoftSwitch::TXTPAGE1
        bcs     @Odd
        sta     SoftSwitch::TXTPAGE2
@Odd:   ldy     DriverStatusCursorY
        jsr     GetTextLineBaseAddr
        lda     DriverStatusCursorX
        lsr     a
        tay
        lda     (TextLineBasePtr),y
        ldy     #$00
        sta     (ParamTablePtr),y
        rts

CopyDriverStatusToParamTable:
        lda     DriverStatusTableAddress
        sta     DriverStatusPtr
        lda     DriverStatusTableAddress+1
        sta     DriverStatusPtr+1
        ldx     DriverStatusTableLength
        ldy     #$00
@Loop:  lda     (DriverStatusPtr),y
        sta     (ParamTablePtr),y
        iny
        dex
        bne     @Loop
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

CallCommandCode:
        .byte   $00
CallReturnAddress:
        .addr   $0000

        .byte   $FF,$FF         ; unused?

DriverStatusTable:
DriverStatusCursorY:
        .byte   $00
DriverStatusCursorX:
        .byte   $00
DriverStatusWindowTop:
        .byte   $00
DriverStatusWindowBottom:
        .byte   $17
DriverStatusWindowLeft:
        .byte   $00
DriverStatusWindowRight:
        .byte   $4F
DriverStatusWindowWidth:
        .byte   $50
DriverStatusWindowHeight:
        .byte   $18
DriverStatusWrapFlag:
        .byte   $FF
DirverStatusAdvanceFlag:
        .byte   $FF
DriverStatusLineFeedFlag:
        .byte   $FF
DriverStatusScrollFlag:
        .byte   $FF
DriverStatusInverseMask:
        .byte   $80
DriverStatusSpaceExpansionFlag:
        .byte   $FF
DriverStatusFillChar:
        .byte   $A0             ; high ascii space
MouseTextFlag:
        .byte   $00
DriverStatusTableLength:
        .byte   $10
DriverStatusTableAddress:
        .addr   DriverStatusTable

EntryPoint:
        jsr     SaveZeroPage
        pla
        sta     CallReturnAddress
        sta     CallingCodePtr
        pla
        sta     CallReturnAddress+1
        sta     CallingCodePtr+1
        inc     CallingCodePtr
        bne     L5322
        inc     CallingCodePtr+1
L5322:  nop
        inc     CallReturnAddress
        bne     L532B
        inc     CallReturnAddress+1
L532B:  inc     CallReturnAddress
        bne     L5333
        inc     CallReturnAddress+1
L5333:  inc     CallReturnAddress
        bne     L533B
        inc     CallReturnAddress+1
L533B:  ldy     #$00
        lda     (CallingCodePtr),y
        sta     CallCommandCode
        iny
        lda     (CallingCodePtr),y
        sta     ParamTablePtr
        iny
        lda     (CallingCodePtr),y
        sta     ParamTablePtr+1
        lda     CallCommandCode
        bne     @Not00
        jmp     Handler_OutputData       ; output data
@Not00: cmp     #$01            ; save viewport
        bne     @Not01
        jmp     Handler_SaveViewport
@Not01: cmp     #$02            ; restore viewport
        bne     @Not02
        jmp     Handler_RestoreViewport
@Not02: cmp     #$03            ; get driver status
        bne     @Not03
        jmp     Handler_GetDriverStatus
@Not03: cmp     #$04            ; get cursor position
        bne     @Not04
        jmp     Handler_GetCursorPosition
@Not04: cmp     #$05            ; get character at cursor
        bne     @Not05
        jmp     Handler_GetCharacterAtCursor
@Not05: cmp     #$06            ; initialize driver
        bne     @Not06
        jmp     Handler_InitializeDriver
@Not06: cmp     #$0A
        bne     @Not0A
        jmp     Handler_InitializeInputInfo
@Not0A: cmp     #$0B
        bne     @Not0B
        jmp     Handler_RetrieveInputInfo
@Not0B: cmp     #$0C
        bne     @Not0C
        jmp     Handler_SetInputInfo
@Not0C: cmp     #$0D
        bne     @Not0D
        jmp     Handler_Input
@Not0D: lda     #$02            ; error: unknown command code
        sec
        jmp     ReturnWithErrorCode

Handler_GetCursorPosition:
        jsr     CopyCursorPositionToParamTable
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_GetCharacterAtCursor:
        jsr     CopyCharAtCursorToParamTable
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_SaveViewport:
        ldy     #$00
        lda     (ParamTablePtr),y
        sta     ViewportSaveBufferAddr
        iny
        lda     (ParamTablePtr),y
        sta     ViewportSaveBufferAddr+1
        lda     #$FF
        sta     SoftSwitch::SETALTCHAR
        sta     SoftSwitch::STORE80ON
        jsr     SaveViewportToBuffer
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_RestoreViewport:
        lda     ViewportSavedFlag
        bne     @OK
        lda     #$01            ; error: no viewport saved
        sec
        jmp     ReturnWithErrorCode
@OK:    ldy     #$00
        lda     (ParamTablePtr),y
        sta     ViewportSaveBufferAddr
        iny
        lda     (ParamTablePtr),y
        sta     ViewportSaveBufferAddr+1
        lda     #$FF
        sta     SoftSwitch::SETALTCHAR
        sta     SoftSwitch::STORE80ON
        jsr     RestoreViewportFromBuffer
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_OutputData:     
        lda     #$FF
        sta     SoftSwitch::SET80VID
        sta     SoftSwitch::SETALTCHAR
        sta     SoftSwitch::STORE80ON
        ldy     #$00
        lda     (ParamTablePtr),y
        sta     OutputDataPtr
        iny
        lda     (ParamTablePtr),y
        sta     OutputDataPtr+1
        iny
        lda     (ParamTablePtr),y
        sta     BytesLeftToOutput
        iny
        lda     (ParamTablePtr),y
        sta     BytesLeftToOutput+1
        jsr     OutputData
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_InitializeDriver:
        lda     #$00
        sta     DriverStatusCursorY
        sta     DriverStatusCursorX
        sta     DriverStatusWindowLeft
        sta     MouseTextFlag
        sta     DriverStatusWindowTop
        lda     #$FF
        sta     DriverStatusWrapFlag
        sta     DirverStatusAdvanceFlag
        sta     DriverStatusLineFeedFlag
        sta     DriverStatusScrollFlag
        sta     DriverStatusSpaceExpansionFlag
        lda     #23
        sta     DriverStatusWindowBottom
        lda     #24
        sta     DriverStatusWindowHeight
        lda     #$80
        sta     DriverStatusInverseMask
        lda     #$A0
        sta     DriverStatusFillChar
        lda     #79
        sta     DriverStatusWindowRight
        lda     #80
        sta     DriverStatusWindowWidth
        lda     #$00
        clc
        jmp     ReturnWithErrorCode

Handler_GetDriverStatus:
        jsr     CopyDriverStatusToParamTable
        lda     #$00
        clc
        jmp     ReturnWithErrorCode ; useless instruction

ReturnWithErrorCode:
        sta     SavedErrorCode
        jsr     RestoreZeroPage
        lda     CallReturnAddress+1
        pha
        lda     CallReturnAddress
        pha
        lda     SavedErrorCode
        rts

SavedErrorCode:
        .byte   $00
