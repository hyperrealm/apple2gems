;;; MouseText ToolKit

      .include "MouseTextToolKitDefines.s"
      .include "/pkg/cc65-2.19/share/cc65/asminc/apple2.inc"
      .setcpu "6502"

KBD               := $C000   ; Read keyboard
TXTPAGE1          := $C054
TXTPAGE2          := $C055
RDPAGE2           := $C01C
VBLINT            := $C019
SET80VID          := $C00D
CLR80VID          := $C00C
SPKR              := $C030
ProDOSMLI         := $BF00

TextRowBasePtr    := $0000
EventPtr          := $0002
EventPtr2         := $0004
GeneralStorageByte:= $0006
ReturnAddressPtr  := $0007
ParamTablePtr     := $0009
SaveAreaPtr       := $000B
MenuBarOrWindowPtr:= $000D
MenuBlockOrDocInfoPtr:= $000F
MenuStructPtr    := $0011
MenuItemStructPtr:= $0013
TextStringPtr    := $0015

      .org   $6100

;;; -------------------
;;; ToolKit entry point
;;; -------------------
MTTK:
      cld
      txa
      pha
      lda   ZeroPageSavedFlag ; zero page saved?
      bne   L6117             ; yes-skip saving it
      ldx   #$00
      jsr   SaveSoftSwitchStates ; to buffer #0
L610D:lda   $0000,x ; save zero page
      sta   ZeroPageStorage,x
      inx
      cpx   #$17
      bcc   L610D
L6117:inc   ZeroPageSavedFlag
      pla
      sta   GeneralStorageByte ; pull & save the call number
      pla
      sta   ReturnAddressPtr ; pull & save the return address + 3
      clc
      adc   #$03
      tax
      pla
      sta   ReturnAddressPtr+1
      adc   #$00
      pha
      txa
      pha
      lda   GeneralStorageByte ; call number
      pha
      tya
      pha
      ldy   #$03
      lda   (ReturnAddressPtr),y ; pull the param table address
      sta   ParamTablePtr+1      ; and load it into ParamTablePtr
      dey
      lda   (ReturnAddressPtr),y
      sta   ParamTablePtr
      dey
      lda   (ReturnAddressPtr),y
      tax
      dey
      sty   LastError      ; set LastError to 0
      cpx   #$31           ; is call number >= 49?
      bcs   L616C          ; yes - invalid call
      lda   ParamSpecsTable,x ; load param specification for this call
      bmi   L6152             ;DeskTop doesn't need to have been started
      bit   DeskTopStartedFlag ; DeskTop started?
      bpl   L6174              ; no - error
L6152:and   #%01111111         ; strip off MSB to get param count
      cmp   (ParamTablePtr),y  ; param count matches?
      bne   L6170              ; no - error
      txa
      asl   a ; multiply call number by 2 to get jump table offset
      tay
      lda   CleanupRoutineAddr+1 ; push cleanup routine address for RTS
      pha
      lda   CleanupRoutineAddr
      pha
      lda   DispatchTable+1,y
      pha
      lda   DispatchTable,y
      pha
      rts   ; RTS to jump to routine
L616C:lda   #ErrInvalidCall
      bne   L6176 ; branch always taken
L6170:lda   #ErrWrongParamCount
      bne   L6176 ; branch always taken
L6174:lda   #ErrDesktopNotStarted
L6176:sta   LastError
      jmp   L617E

;;; Cleanup routine

CleanupRoutineAddr:
      .addr * + 1
L617E:dec   ZeroPageSavedFlag ; clear flag
      bne   L6192
      ldx   #$00
      jsr   RestoreSoftSwitchStates ; from buffer #0
L6188:lda   ZeroPageStorage,x ; restore zero page
      sta   $0000,x
      inx
      cpx   #$17
      bcc   L6188
L6192:pla   ; restore X & Y registers
      tay
      pla
      tax
      lda   LastError ; load error code into A
      cmp   #$01
      lda   LastError
      rts   ; all done

CurrentYCoord:
      .byte $00 ; y-coord for reading/writing text char on screen
CurrentXCoord:
      .byte $00 ; x-coord for reading/writing text char on screen
CharRegister:
      .byte $00 ; char to be written to or that was read from screen
LastError:
      .byte $00
MouseTrackingMode:
      .byte $00 ; current mouse tracking mode

;;; Zero Page storage
ZeroPageStorage:
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00

ZeroPageSavedFlag:
      .byte $00 ; $80 = zero page currently saved
DeskTopStartedFlag:
      .byte $00 ; $80 = DeskTop has been started

;;; Dispatch Table
DispatchTable:
      .word StartDeskTop-1               ; 00
      .word StopDeskTop-1                ; 01
      .word SetCursor-1                  ; 02
      .word ShowCursor-1                 ; 03
      .word HideCursor-1                 ; 04
      .word CheckEvents-1                ; 05
      .word GetEvent-1                   ; 06
      .word FlushEvents-1                ; 07
      .word SetKeyEvent-1                ; 08
      .word InitMenu-1                   ; 09
      .word SetMenu-1                    ; 0A
      .word MenuSelect-1                 ; 0B
      .word MenuKey-1                    ; 0C
      .word HiliteMenu-1                 ; 0D
      .word DisableMenu-1                ; 0E
      .word DisableMenuItem-1            ; 0F
      .word CheckMenuItem-1              ; 10
      .word PascIntAdr-1                 ; 11
      .word SetGlobalTextPointerOffset-1 ; 12
      .word Version-1                    ; 13
      .word SetMark-1                    ; 14
      .word PeekEvent-1                  ; 15
      .word InitWindowMgr-1              ; 16
      .word OpenWindow-1                 ; 17
      .word CloseWindow-1                ; 18
      .word CloseAllWindows-1            ; 19
      .word FindWindow-1                 ; 1A
      .word FrontWindow-1                ; 1B
      .word SelectWindow-1               ; 1C
      .word TrackGoAway-1                ; 1D
      .word DragWindow-1                 ; 1E
      .word GrowWindow-1                 ; 1F
      .word WindowToScreen-1             ; 20
      .word ScreenToWindow-1             ; 21
      .word WinChar-1                    ; 22
      .word WinString-1                  ; 23
      .word WinBlock-1                   ; 24
      .word WinOp-1                      ; 25
      .word WinText-1                    ; 26
      .word FindControl-1                ; 27
      .word SetCtlMax-1                  ; 28
      .word TrackThumb-1                 ; 29
      .word UpdateThumb-1                ; 2A
      .word ActivateCtl-1                ; 2B
      .word ObscureCursor-1              ; 2C
      .word GetWinPtr-1                  ; 2D
      .word PostEvent-1                  ; 2E
      .word SetUserHook-1                ; 2F
      .word KeyboardMouse-1              ; 30

;;; Param Table Specs Flags
ParamSpecsTable:
      .byte $86,$00,$01,$00,$00,$00,$03,$00
      .byte $01,$02,$01,$02,$04,$01,$02,$03
      .byte $03,$81,$01,$82,$04,$03,$02,$01
      .byte $01,$00,$04,$01,$01,$01,$03,$01
      .byte $05,$05,$04,$05,$06,$04,$05,$04
      .byte $02,$03,$02,$02,$00,$02,$03,$02
      .byte $00

MouseNotFoundFlag:
      .byte $00
MouseUpperClampBoundX:
      .word $027F
MouseUpperClampBoundY:
      .word $017F
MouseXScaleFactor:
      .byte $03 ; 2^3 (for 80-col screen)
MouseYScaleFactor:
      .byte $04 ; 2^4
MouseXCoord:
      .word $0000 ; in screen coordinates
MouseYCoord:
      .word $0000 ; in screen coordinates
MouseButtonState:
      .byte $00 ; bit 7: button down, bit 6: button still down

.proc CallMouseFirmware
      php
      sei
      bit   MouseNotFoundFlag
      bmi   L6277          ; return if mouse not present
      pha
      lda   TXTPAGE1
MouseFirmwareBaseAddress:= * + 2
      lda   $C000,y        ; operand gets overwritten
      sta   MouseFirmwareEntryPoint
MouseSlot_Cs     := * + 1
      ldx   #$00           ; operand gets overwritten
MouseSlot_s0     := * + 1
      ldy   #$00           ; operand gets overwritten
      pla
MouseFirmwareEntryPoint:= * + 1
      jsr   $0000          ; operand gets overwritten
      bcs   L627A
L6277:plp                  ; return with success status
      clc
      rts
L627A:plp                  ; return with error status
      sec
      rts
.endproc

;;; Checks for presence of mouse firmware by comparing
;;; signature bytes. Returns with Zero flag set if found,
;;; cleared otherwise.

.proc CheckMouseFirmwareSignatureBytes
      ldy   #$05
      lda   (ReturnAddressPtr),y
      cmp   #$38
      bne   OUT
      ldy   #$07
      lda   (ReturnAddressPtr),y
      cmp   #$18
      bne   OUT
      ldy   #$0B
      lda   (ReturnAddressPtr),y
      cmp   #$01
      bne   OUT
      ldy   #$0C
      lda   (ReturnAddressPtr),y
      cmp   #$20
OUT:  rts
.endproc

;;; Searches the slot ROM space for the mouse firmware.
;;; On input, A contains the expected slot (if that slot is
;;; required to be the mouse slot), or 0 to find the slot.
;;; If found, updates the operands in the CallMouseFirmware
;;; routine above. Returns the slot number in A.
.proc FindMouseSlot
      pha
      and   #%01111111
      beq   L62B0
      cmp   #$08 ; slot >= 8 is invalid
      bcc   L62AA
      pla
      lda   #ErrInvalidSlotNum
      bne   ReturnWithError
L62AA:ldx   #$01
      ora   #%11000000
      bne   L62B4
L62B0:ldx   #$07 ; start with slot 7
      lda   #$C7
L62B4:sta   ReturnAddressPtr+1
      lda   #$00
      sta   ReturnAddressPtr
L62BA:jsr   CheckMouseFirmwareSignatureBytes
      beq   FOUND ; mouse firmware found
      dec   ReturnAddressPtr+1
      dex
      bne   L62BA ; try next lower slot
      pla
      bpl   L62CB
      lda   #ErrMouseNotFound
      bne   ReturnWithError
L62CB:tay
      lda   #$80
      bne   L62E8
FOUND:pla
      lda   ReturnAddressPtr+1
      sta   CallMouseFirmware::MouseSlot_Cs
      sta   CallMouseFirmware::MouseFirmwareBaseAddress
      sta   CallMouseFirmware::MouseFirmwareEntryPoint+1
      and   #%00001111
      tay
      asl   a
      asl   a
      asl   a
      asl   a
      sta   CallMouseFirmware::MouseSlot_s0
      lda   #$00
L62E8:sta   MouseNotFoundFlag
      tya
      clc
      rts
.endproc

.proc ReturnWithError
      sta   LastError
      sec
      rts
.endproc

;;; Configures the mouse. The upper clamping bounds are set to (80, 24) or
;;; (40, 24) multiplied by powers of 2.

.proc ConfigureMouse
      lda   #$03 ; 2^3 = 8
      sta   MouseXScaleFactor
      lda   #$04 ; 2^4 = 16
      sta   MouseYScaleFactor
      bit   Columns80Flag
      bmi   L6305
      inc   MouseXScaleFactor ; if 40 columns, use 2^4 = 16
L6305:lda   #$7F
      sta   MouseUpperClampBoundX
      lda   #$02
      sta   MouseUpperClampBoundX+1 ; $27F = 639 = 80 x 2^3 (or 40 x 2^4) - 1
      lda   #$7F
      sta   MouseUpperClampBoundY
      lda   #$01
      sta   MouseUpperClampBoundY+1 ; $17F = 383 = 24 x 2^4 - 1
      lda   MachineSubID
      cmp   #$40
      bcs   L6332
      dec   MouseXScaleFactor
      dec   MouseYScaleFactor
      lsr   MouseUpperClampBoundX+1
      ror   MouseUpperClampBoundX
      lsr   MouseUpperClampBoundY+1
      ror   MouseUpperClampBoundY
L6332:lda   #$00
      sta   MouseXCoord
      sta   MouseYCoord
      sta   MouseButtonState ; reset mouse location and button state
      lda   $FBB3
      pha
      lda   #$06
      sta   $FBB3 ; temporarily set the machine ID byte if LCRAM is on
      ldy   #InitMouseEP
      jsr   CallMouseFirmware
      pla
      sta   $FBB3 ; restore the machine ID byte
      lda   #$00
      sta   $0478
      sta   $0578
      lda   MouseUpperClampBoundX
      sta   $04F8
      lda   MouseUpperClampBoundX+1
      sta   $05F8
      lda   #$00
      ldy   #ClampMouseEP ; clamp X axis
      jsr   CallMouseFirmware
      lda   #$00
      sta   $0478
      sta   $0578
      lda   MouseUpperClampBoundY
      sta   $04F8
      lda   MouseUpperClampBoundY+1
      sta   $05F8
      lda   #$01
      ldy   #ClampMouseEP ; clamp Y axis
      jsr   CallMouseFirmware
      ldy   #HomeMouseEP
      jsr   CallMouseFirmware
      bit   InterruptAllocatedFlag
      bmi   L6393
      lda   #$01 ; mouse on, interrupts off
      bne   L6395
L6393:lda   #$09 ; mouse on, VBL interrupt on
L6395:ldy   #SetMouseEP ; set mouse mode
      jsr   CallMouseFirmware
      rts
.endproc

;;; Reads mouse position and button state from the
;;; mouse firmeware screen holes, and scales the mouse
;;; position down to screen coordinates.
.proc ReadMouseState
      php
      sei
      bit   MouseNotFoundFlag
      bmi   L63E0 ; branch if flag set
      ldy   #ReadMouseEP
      jsr   CallMouseFirmware
      ldx   CallMouseFirmware::MouseSlot_Cs
      lda   $03B8,x
      sta   MouseXCoord
      lda   $04B8,x
      sta   MouseXCoord+1
      lda   $0438,x
      sta   MouseYCoord
      lda   $0538,x
      sta   MouseYCoord+1
      lda   $06B8,x
      sta   MouseButtonState
      ldx   MouseXScaleFactor ; scale mouse coordinates
L63CB:lsr   MouseXCoord+1 ; to screen coordinates
      ror   MouseXCoord
      dex
      bne   L63CB
      ldx   MouseYScaleFactor
L63D7:lsr   MouseYCoord+1
      ror   MouseYCoord
      dex
      bne   L63D7
L63E0:plp
      rts
.endproc

MousePosXScaledUp:
      .word $0000
MousePosYScaledUp:
      .word $0000

.proc SetMousePosition
      php
      sei
      bit   MouseNotFoundFlag
      bmi   L6444
      lda   #$00
      sta   MousePosXScaledUp+1
      sta   MousePosYScaledUp+1
      lda   MouseXCoord
      cmp   MaxColumnNumber
      beq   L63FF
      bcs   L6444  ; branch if > max col
L63FF:sta   MousePosXScaledUp
      lda   MouseYCoord
      cmp   #$18 ; 24 (last row)
      bcs   L6444 ; branch if >= max row
      sta   MousePosYScaledUp
      ldx   MouseXScaleFactor ; scale from screen coordinates
L640F:asl   MousePosXScaledUp ; to mouse coordinates
      rol   MousePosXScaledUp+1
      dex
      bne   L640F
      ldx   MouseYScaleFactor
L641B:asl   MousePosYScaledUp
      rol   MousePosYScaledUp+1
      dex
      bne   L641B
      ldx   CallMouseFirmware::MouseSlot_Cs
      lda   MousePosXScaledUp
      sta   $03B8,x
      lda   MousePosXScaledUp+1
      sta   $04B8,x
      lda   MousePosYScaledUp
      sta   $0438,x
      lda   MousePosYScaledUp+1
      sta   $0538,x
      ldy   #PosMouseEP
      jsr   CallMouseFirmware
L6444:plp
      rts
.endproc

.proc TurnOffMouse
      lda   #$00
      ldy   #SetMouseEP
      jsr   CallMouseFirmware
      jsr   ServeMouse
      rts
.endproc

.proc ServeMouse
      bit   MouseNotFoundFlag
      bmi   ERR
      ldy   #ServeMouseEP
      jsr   CallMouseFirmware
      rts
ERR:  sec
      rts
.endproc

Columns80Flag:
      .byte $00
MaxColumnNumber:
      .word $0000
MaxRowNumber:
      .word $0017
InterruptAllocatedFlag:
      .byte $00
OperatingSystemType:
      .byte $00
MachineID:
      .byte $00
MachineSubID:
      .byte $00
ProcStatusRegStorage:
      .byte $00

.proc ExitWithError

ExitWithOSUnsupported:
      lda   #ErrOSNotSupported
ExitWithErrorInA:
      sta   LastError
OUT:  rts

.endproc

;;; ----------------------------------------
;;; ToolKit call $00 (0)
;;; ----------------------------------------
.proc StartDeskTop
      php
      pla
      sta   ProcStatusRegStorage
      ldy   #$01
      lda   (ParamTablePtr),y
      cmp   #$06
      bne   ExitWithError::ExitWithOSUnsupported
      sta   MachineID
      iny
      lda   (ParamTablePtr),y
      sta   MachineSubID
      iny
      lda   (ParamTablePtr),y
      cmp   #$02
      bcs   ExitWithError::ExitWithOSUnsupported
      sta   OperatingSystemType
      iny
      lda   (ParamTablePtr),y ; requested mouse slot
      jsr   FindMouseSlot
      bcs   ExitWithError::OUT ; mouse not found
      ldy   #$04
      sta   (ParamTablePtr),y ; set mouse slot in params
      iny
      lda   (ParamTablePtr),y ; interrupt mode
      beq   L64AA ; branch if passive mode
      lda   #$80
      bit   MouseNotFoundFlag
      bpl   L64AA ; branch if clear
      lda   #$00
      sta   (ParamTablePtr),y ; force passive mode
L64AA:sta   InterruptAllocatedFlag
      iny
      lda   (ParamTablePtr),y
      bne   L64BC ; 80 columns mode
      sta   Columns80Flag
      sta   CLR80VID
      lda   #$27 ; 39
      bne   L64C6 ; branch always taken
L64BC:lda   #$80
      sta   Columns80Flag
      sta   SET80VID
      lda   #$4F ; 79
L64C6:sta   MaxColumnNumber
      lda   #$01
      sta   TemporaryParamTable ; reset user hooks to NULL
      lda   TemporaryParamTableAddress
      sta   ParamTablePtr
      lda   TemporaryParamTableAddress+1
      sta   ParamTablePtr+1
L64D8:jsr   SetUserHook
      dec   TemporaryParamTable
      bpl   L64D8
      jsr   InitCursorState
      jsr   EnableKeyEvents
      jsr   CalcDesktopClipRect
      bit   InterruptAllocatedFlag
      bpl   L64F8
      jsr   AllocInterrupt
      bcc   L64F8
      lda   #ErrInstallIntFailed
      jmp   ExitWithError::ExitWithErrorInA
L64F8:lda   MachineSubID
      cmp   #$40
      bcs   L6502 ; branch if IIe
      cli
      bcc   L650C ; branch if IIc
L6502:bit   InterruptAllocatedFlag
      bpl   L650C
      sei
      jsr   SetVBLInterruptRate
      cli
L650C:jsr   ConfigureMouse
      lda   #$80
      sta   DeskTopStartedFlag
      sta   SETALTCHAR
      rts
.endproc

.proc SetVBLInterruptRate
      lda   #$F4
      sta   VBLCounter
      lda   #$00
      sta   VBLCounter+1
      ldx   VBLINT
L6525:txa
      eor   VBLINT
      bpl   L6525 ; loop until VBLINT flag toggles
L652B:ldy   VBLINT
L652E:inc   VBLCounter ; increment counter
      bne   L6536
      inc   VBLCounter+1
L6536:tya
      eor   VBLINT ; loop until VBLINT flag toggles
      bpl   L652E
      txa
      eor   VBLINT
      bpl   L652B
      ldx   #$00 ; 0 = 60Hz
      lda   VBLCounter+1
      cmp   #$05 ; if VBLCounter >= $500 then 50Hz
      bcc   L654C
      inx   ; 1 = 50Hz (not supported on IIc)
L654C:txa
      ldy   #MouseTimeDataEP
      jsr   CallMouseFirmware
      rts
VBLCounter:
      .word $0000
.endproc

TemporaryParamTableAddress:
      .addr TemporaryParamTable
TemporaryParamTable:
      .byte $02,$00,$00,$00

;;; ----------------------------------------
;;; ToolKit call $01 (1)
;;; ----------------------------------------
.proc StopDeskTop
      jsr   TurnOffMouse
      lda   #$00
      sta   DeskTopStartedFlag
      jsr   HideCursor
      bit   InterruptAllocatedFlag
      bpl   SKIP ; branch if no
      jsr   DeallocInterrupt
SKIP: lda   ProcStatusRegStorage
      pha
      plp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $2F (47)
;;; ----------------------------------------
.proc SetUserHook
      php
      sei
      ldy   #$01
      lda   (ParamTablePtr),y ; hook ID (0 or 1)
      cmp   #$02
      bcs   L65A8 ; >= 2 is invalid hook ID
      asl   a
      tax   ; (x is now 0 or 2)
      lda   CheckEventsHookCallSites,x ; copies either the address CheckEventsPreHook or
      sta   EventPtr2 ; the address CheckEventsPostHook into EventPtr2.
      lda   CheckEventsHookCallSites+1,x
      sta   EventPtr2+1
      ldy   #$03
L658C:lda   (ParamTablePtr),y ; copies the hook address from the param table
      dey                     ; to (EventPtr2).
      sta   (EventPtr2),y
      cpy   #$01
      bne   L658C
      iny                  ; Y is now 2
      ora   (EventPtr2),y
      bne   L659F          ; Branch if the address is null
      dey                  ; Y is now 1
      lda   #$90           ; Copies BCC instruction
      sta   (EventPtr2),y  ; to (EventPtr2)+1
L659F:lda   L65AE,y        ; Copies SEC or JSR instruction
      ldy   #$00
      sta   (EventPtr2),y  ; to (EventPtr2)
      plp
      rts
L65A8:lda   #ErrInvalidUserHookID
      sta   LastError
      plp
L65AE:rts
      .byte $38 ; SEC instruction
      .byte $20 ; JSR instruction
.endproc

CheckEventsHookCallSites:
      .addr CheckEventsPreHook
      .addr CheckEventsPostHook

;;; ----------------------------------------
;;; ToolKit call $12 (18) - undocumented
;;; ----------------------------------------
.proc SetGlobalTextPointerOffset
      ldy   #$01
      lda   (ParamTablePtr),y
      sta   GlobalTextPointerOffset
      iny
      lda   (ParamTablePtr),y
      sta   GlobalTextPointerOffset+1
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $13 (19)
;;; ----------------------------------------
.proc Version
      ldy   #$01
      lda   #$02 ; This is version 2.1
      sta   (ParamTablePtr),y
      iny
      lda   #$01
      sta   (ParamTablePtr),y
      rts
.endproc

;;; Param table for ALLOC_INTERRUPT
AllocInterruptParams:
      .byte $02 ; param count
AllocInterruptNum:
      .byte $00
AllocInterruptAddr:
      .addr InterruptHandler1

.proc AllocInterrupt
      lda   OperatingSystemType
      cmp   #$00 ; ProDOS
      beq   OK
      clc
      rts
OK:   jsr   ProDOSMLI
      .byte $40 ; ALLOC_INTERRUPT
      .addr AllocInterruptParams
      rts
.endproc

;;; Param table for DEALLOC_INTERRUPT
DeallocInterruptParams:
      .byte $01 ; param count
DeallocInterruptNum:
      .byte $00

.proc DeallocInterrupt
      lda   OperatingSystemType
      cmp   #$00
      bne   OUT ; skip if not ProDOS
      lda   AllocInterruptNum
      sta   DeallocInterruptNum
      jsr   ProDOSMLI
      .byte $41 ; DEALLOC_INTERRUPT
      .addr DeallocInterruptParams
OUT:  rts
.endproc

;;; There are two buffers here; buffer #0 (first and third byte)
;;; for saving state during a toolkit call, and buffer #1 (second
;;; and fourth byte) for saving state during interrupt handling.
StorageForRD80COL:
      .byte $00,$00
StorageForRDPAGE2:
      .byte $00,$00

;;; Save soft switch states to buffer #X (0 or 1)
.proc SaveSoftSwitchStates
      lda   RD80COL
      sta   StorageForRD80COL,x
      lda   RDPAGE2
      sta   StorageForRDPAGE2,x
      sta   SET80COL
      lda   TXTPAGE1
      rts
.endproc

;;; Restore soft switch states from buffer #X (0 or 1)
.proc RestoreSoftSwitchStates
      lda   StorageForRDPAGE2,x
      bmi   L661B
      lda   TXTPAGE1
      jmp   L661E
L661B:lda   TXTPAGE2
L661E:lda   StorageForRD80COL,x
      bmi   L6627
      sta   CLR80COL
      rts
L6627:sta   SET80COL
      rts
.endproc

.proc PrintCharAtCurrentCoord
      tya   ; save X, Y
      pha
      txa
      pha
      jsr   CalcTextRowBaseAddr
      lda   CharRegister
      jsr   PrintCharInA
      pla   ; restore X, Y
      tax
      pla
      tay
      rts
.endproc

.proc PrintCharInA
      tax
      php
      sei
      lda   TXTPAGE1
      lda   CurrentXCoord
      bit   Columns80Flag
      bmi   L664F ; branch if on
      tay
      jmp   L6656
L664F:lsr   a ; shift odd/even bit into Carry
      tay
      bcs   L6656 ; branch if odd column
      lda   TXTPAGE2
L6656:txa
      sta   (TextRowBasePtr),y
      lda   TXTPAGE1
      plp
      rts
.endproc

.proc CacheCharAtCurrentCoord
      tya   ; save X, Y
      pha
      txa
      pha
      jsr   CalcTextRowBaseAddr
      jsr   ReadCharAtCurrentCoord
      sta   CharRegister
      pla   ; restore X, Y
      tax
      pla
      tay
      rts
.endproc

;;; Returns character in A.
.proc ReadCharAtCurrentCoord
      php
      sei
      lda   TXTPAGE1
      lda   CurrentXCoord
      bit   Columns80Flag
      bmi   L6681 ; branch if off
      tay
      jmp   L6688
L6681:lsr   a
      tay
      bcs   L6688 ; branch if odd column
      lda   TXTPAGE2
L6688:lda   (TextRowBasePtr),y
      tay
      lda   TXTPAGE1
      tya
      plp
      rts
.endproc

.proc CalcTextRowBaseAddr
      lda   CurrentYCoord
      pha
      lsr   a
      and   #%00000011
      ora   #%00000100
      sta   TextRowBasePtr+1
      pla
      and   #$18
      bcc   L66A3
      adc   #$7F
L66A3:sta   TextRowBasePtr
      asl   a
      asl   a
      ora   TextRowBasePtr
      sta   TextRowBasePtr
      rts
.endproc

TextRectangleXCoord:
      .byte $00
TextRectangleYCoord:
      .byte $00
TextRectangleEndXCoordPlus1:
      .byte $00
TextRectangleEndYCoordPlus1:
      .byte $00
SaveOrRestoreTextMode:
      .byte $00 ; $00 for save, $80 for restore

.proc SaveAndRestoreTextRectangle
SaveTextRectangle:
      lda   #$00
      beq   L66B7
RestoreTextRectangle:
      lda   #$80
L66B7:sta   SaveOrRestoreTextMode
      lda   TextRectangleXCoord
      sta   CurrentXCoord
      lda   TextRectangleYCoord
      sta   CurrentYCoord
      ldy   #$00
L66C8:bit   SaveOrRestoreTextMode
      bmi   L66D8 ; branch if restore
      jsr   CacheCharAtCurrentCoord
      lda   CharRegister
      sta   (SaveAreaPtr),y
      jmp   L66E0
L66D8:lda   (SaveAreaPtr),y
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
L66E0:iny
      bne   L66E5
      inc   SaveAreaPtr+1
L66E5:inc   CurrentXCoord
      lda   TextRectangleEndXCoordPlus1
      cmp   CurrentXCoord
      bcs   L66C8
      lda   TextRectangleXCoord
      sta   CurrentXCoord
      inc   CurrentYCoord
      lda   TextRectangleEndYCoordPlus1
      cmp   CurrentYCoord
      bcs   L66C8
      rts
.endproc

Bit5Mask:
      .byte $20 ; %00100000
Bit6Mask:
      .byte $40 ; %01000000

;;; Maps values $00-$1F to MouseText ($40-$5F)
;;; Maps values < $80 to normal
;;; Maps values >= $80 to inverse
.proc RemapChar
      eor   #%10000000 ; Toggle bit 7 (maps $00-$7F (inverse) to $80-$FF (normal), or vv.)
      bit   Bit5Mask
      bne   OUT ; if bit 5 is set ($20-$3F, $60-$7F), eg., not MouseText, return
      eor   #%01000000  ; toggle bit 6 (maps $00-$1F to $40-$5F) or vv.
      bit   Bit6Mask
      beq   OUT ; if bit 6 is clear ($00-$3F), return
      and   #%01111111 ; Clear bit 7
OUT:  rts
.endproc

LengthOfTextToOutput:
      .byte $00
TextOutputCounter:
      .byte $00
MenuOrWindowOptionByte:
      .byte $00
InverseTextFlag:
      .byte $00

.proc OutputText
OutputTextNormal:
      lda   #$00
      beq   L671F ; branch always taken
OutputTextInverse:
      lda   #$80
L671F:sta   InverseTextFlag
      jsr   MaybeOffsetTextStringPtr
      tya   ; save X and Y on stack
      pha
      txa
      pha
      ldy   #$00
      lda   (TextStringPtr),y
      sta   LengthOfTextToOutput
      iny
      sty   TextOutputCounter
      jsr   MaybeDerefTextStringPtr
      jsr   CalcTextRowBaseAddr
L673A:ldy   TextOutputCounter
      cpy   LengthOfTextToOutput
      beq   L6744
      bcs   L675D
L6744:lda   (TextStringPtr),y
      bit   InverseTextFlag
      bpl   L674D
      eor   #%10000000 ; toggle MSB for inverse
L674D:jsr   RemapChar
      iny
      sty   TextOutputCounter
      jsr   PrintCharInA
      inc   CurrentXCoord
      jmp   L673A
L675D:pla   ; restore X and Y from stack
      tax
      pla
      tay
      rts
.endproc

GlobalTextPointerOffset:
      .word $0000

;;; If undocumented bit 4 of the window option byte is set,
;;; then add global text pointer offset to the text pointer
;;; offset. (This may be some form of rudimentary
;;; localization.)
.proc MaybeOffsetTextStringPtr
      lda   MenuOrWindowOptionByte
      and   #%00010000 ; reserved bit 4
      beq   L6794 ; return if clear
      lda   GlobalTextPointerOffset
      sta   L6789
      sta   L6790
      lda   GlobalTextPointerOffset+1
      sta   L678A
      sta   L6791
      inc   L6790
      bne   L6785
      inc   L6791
L6785:clc
      lda   TextStringPtr
L6789 := * + 1
L678A := * + 2
      adc   GlobalTextPointerOffset
      sta   TextStringPtr
      lda   TextStringPtr+1
L6790 := * + 1
L6791 := * + 2
      adc   GlobalTextPointerOffset+1
      sta   TextStringPtr+1
L6794:rts
.endproc

;;; if (undocumented) bit 3 of window option byte is set,
;;; then the data pointed to by TextStringPtr is interpreted
;;; as a length byte followed by a pointer to the actual text,
;;; which is immediately preceded in memory by a length byte.
;;; TextStringPtr is overwritten with that pointer, and
;;; decremented by 1 in order to point to the length byte.
.proc MaybeDerefTextStringPtr
      lda   MenuOrWindowOptionByte
      and   #%00001000 ; reserved bit 3
      beq   OUT ; return if clear
      ldy   #$01
      lda   (TextStringPtr),y
      pha
      iny
      lda   (TextStringPtr),y
      sta   TextStringPtr+1
      pla
      sta   TextStringPtr
      lda   TextStringPtr
      bne   L67AF
      dec   TextStringPtr+1
L67AF:dec   TextStringPtr
OUT:  rts
.endproc

MultiplyArg1:
      .word $0000
MultiplyArg2:
      .byte $00
MultiplyResult:
      .word $0000

.proc Multiply
MultiplyBytes:
      ldx   #$08  ; 8 bits
      bne   L67BD ; branch always taken
MultiplyWordAndByte:
      ldx   #$10  ; 16 bits
L67BD:lda   #$00
      sta   MultiplyResult+1
L67C2:asl   a
      rol   MultiplyResult+1
      asl   MultiplyArg1+1
      rol   MultiplyArg2
      bcc   L67D7
      clc
      adc   MultiplyArg1
      bcc   L67D7
      inc   MultiplyResult+1
L67D7:dex
      bne   L67C2
      sta   MultiplyResult
        rts
.endproc

DivideArg1:
      .word $0000
DivideArg2:
      .byte $00
DivideResult:
      .word $0000

.proc DivideWordByByte
      bit   DivideArg1+1
      bmi   L67ED
      bit   DivideArg2
      bpl   L67F6
L67ED:lsr   DivideArg1+1
      ror   DivideArg1
      lsr   DivideArg2
L67F6:lda   DivideArg2
      ldx   #$08
      lda   DivideArg1
      sta   DivideResult
      lda   DivideArg1+1
L6804:asl   DivideResult
      rol   a
      cmp   DivideArg2
      bcc   L6813
      sbc   DivideArg2
      inc   DivideResult
L6813:dex
      bne   L6804
      sta   DivideResult+1
      rts
.endproc

CursorVisibleFlag:
      .byte $00
CursorXCoord:
      .byte $00
CursorYCoord:
      .byte $00
CharUnderCursor:
      .byte $00
CursorChar:
      .byte $00

.proc InitCursorState
      lda   #$00
      sta   CursorVisibleFlag
      sta   CursorXCoord
      sta   CursorYCoord
      lda   #MTCharArrowCursor
      sta   CursorChar
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $02 (2)
;;; ----------------------------------------
.proc SetCursor
      php
      sei
      bit   CursorVisibleFlag
      php
      bpl   SKIP1 ; branch if not visible
      jsr   HideCursor
SKIP1:ldy   #$01
      lda   (ParamTablePtr),y ; new cursor char
      jsr   RemapChar
      sta   CursorChar
      plp
      bpl   SKIP2 ; branch if wasn't visible
      jsr   ShowCursor
SKIP2:plp
      rts
.endproc

;;; Changes the cursor char to the one in A.
.proc ChangeCursorChar
      php
      sei
      pha
      jsr   HideCursor
      pla
      sta   CursorChar
      jsr   ShowCursor
      plp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $03 (3)
;;; ----------------------------------------
.proc ShowCursor
      php
      sei
      bit   CursorVisibleFlag
      bmi   OUT
      lda   #$80
      sta   CursorVisibleFlag
      jsr   CopyCursorCoordToCurrentCoord ; save char under cursor
      jsr   CacheCharAtCurrentCoord
      lda   CharRegister
      sta   CharUnderCursor
      lda   CursorChar
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord ; display cursor
OUT:  plp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $04 (4)
;;; ----------------------------------------
.proc HideCursor
      php
      sei
      bit   CursorVisibleFlag
      bpl   OUT
      bit   CursorObscuredFlag
      bmi   OUT
      lda   #$00
      sta   CursorVisibleFlag
      jsr   CopyCursorCoordToCurrentCoord
      jsr   CacheCharAtCurrentCoord
      lda   CharRegister
      cmp   CursorChar
      bne   OUT
      lda   CharUnderCursor
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord ; restore char under cursor
OUT:  plp
      rts
.endproc

CursorObscuredFlag:
      .byte $00

;;; Also unobscures the cursor.
.proc MoveCursorToLatestMousePos
      php
      sei
      ldx   MouseXCoord
      ldy   MouseYCoord
      bit   CursorVisibleFlag
      bpl   L68FF ; branch if no
      jsr   CopyCursorCoordToCurrentCoord
      jsr   CacheCharAtCurrentCoord
      bit   CursorObscuredFlag
      bmi   L68CA ; branch if yes
      lda   CharRegister
      cmp   CursorChar
      bne   L68E2
L68CA:cpx   CursorXCoord
      bne   L68D4
      cpy   CursorYCoord
      beq   OUT
L68D4:bit   CursorObscuredFlag
      bmi   L68E2 ; branch if yes
      lda   CharUnderCursor
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
L68E2:stx   CurrentXCoord
      sty   CurrentYCoord
      jsr   CacheCharAtCurrentCoord
      lda   CharRegister
      sta   CharUnderCursor
      lda   CursorChar
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      lda   #$00
      sta   CursorObscuredFlag
L68FF:stx   CursorXCoord
      sty   CursorYCoord
OUT:  plp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $2C (44)
;;; ----------------------------------------
.proc ObscureCursor
      php
      sei
      bit   CursorVisibleFlag
      bpl   L1 ; branch if no
      jsr   CopyCursorCoordToCurrentCoord
      jsr   CacheCharAtCurrentCoord
      lda   CharRegister
      cmp   CursorChar
      bne   L1
      lda   CharUnderCursor
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
L1:   lda   #$80
      sta   CursorObscuredFlag
      sta   CursorVisibleFlag
      lda   MouseXCoord
      sta   CursorXCoord
      lda   MouseYCoord
      sta   CursorYCoord
      plp
      rts
.endproc

.proc CopyCursorCoordToCurrentCoord
      lda   CursorXCoord
      sta   CurrentXCoord
      lda   CursorYCoord
      sta   CurrentYCoord
      rts
.endproc

SetKeyEventFlag:
      .byte $00

;;; Set during CheckForUpdateEvent, checked by CreateDragOrUpdateEvent.
CheckForUpdateEventsFlag:
      .byte $00

.proc EnableKeyEvents
      jsr   FlushEvents
      lda   #$80
      sta   SetKeyEventFlag
      lda   #$00
      sta   MouseEmulationFlags
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $06 (6)
;;; ----------------------------------------
.proc GetEvent
      jsr   LoadEventOutputPtrWithParam
DequeueEvent:
      bit   InterruptAllocatedFlag
      bmi   L6963
      jsr   InterruptHandler
L6963:php
      sei
      bit   MouseEmulationFlags
      bpl   L696D ; branch if Safety-Net mode is off
      jsr   ProcessKeyboardMouseModeEvent
L696D:jsr   GetHeadEvent
      bcs   L697F ; branch if queue empty
      lda   EventPtr ; move head ptr forward
      sta   EventQueueHeadPtr
      lda   EventPtr+1
      sta   EventQueueHeadPtr+1
      jmp   L6982
L697F:jsr   CreateDragOrUpdateEvent
L6982:plp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $2E (46)
;;; ----------------------------------------
.proc PostEvent
      php
      sei
      ldy   #$01
      lda   (ParamTablePtr),y ; event type
      bmi   L69B2
      cmp   #EventTypeUpdate
      bcs   L69C9          ; invalid event type
      cmp   #EventTypeKeyPress
      beq   L69B2          ; if keypress, skip mouse pos update
      pha                  ; save event type on stack
      iny
      lda   (ParamTablePtr),y ; event x-coord
      tax
      iny
      lda   (ParamTablePtr),y ; event y-coord
      cpx   MouseXCoord
      bne   L69A6
      cmp   MouseYCoord
      beq   L69AF          ; branch if same as current mouse pos
L69A6:stx   MouseXCoord
      sta   MouseYCoord
      jsr   SetMousePosition ; move mouse to this event's coordinates
L69AF:pla                    ; restore event type from stack
      beq   OUT
L69B2:clc
      lda   ParamTablePtr
      adc   #$01
      sta   EventPtr
      lda   ParamTablePtr+1
      adc   #$00
      sta   EventPtr+1
      jsr   EnqueueEvent
      bcc   OUT
      lda   #ErrEventQueueFull
      jmp   L69CB
L69C9:lda   #ErrInvalidEvent
L69CB:sta   LastError
OUT:  plp
      rts
.endproc

.proc LoadEventOutputPtrWithParam
      clc
      lda   ParamTablePtr
      adc   #$01
      sta   EventOutputPtr
      lda   ParamTablePtr+1
      adc   #$00
      sta   EventOutputPtr+1
      rts
.endproc

.proc CreateDragOrUpdateEvent
      lda   CheckForUpdateEventsFlag
      bpl   L69EF ; branch if no
      lda   MouseTrackingMode
      bne   L69EF ; branch if none
      jsr   CheckForUpdateEvent
      bne   OUT
L69EF:bit   MouseEmulationFlags ; A = 0 at this point
      bpl   L69FB ; branch if Safety-Net mode is off
      bit   SimulatedMouseButtonDownFlag
      bpl   L6A02 ; branch if no
      bmi   L6A00 ; branch if yes
L69FB:bit   MouseButtonState
      bpl   L6A02
L6A00:lda   #EventTypeDrag
L6A02:ldy   #$00
      sta   (EventPtr2),y ; set event type
      iny
      lda   MouseXCoord
      sta   (EventPtr2),y ; set event x-coord
      iny
      lda   MouseYCoord
      sta   (EventPtr2),y ; set event y-coord
OUT:  rts
.endproc

.proc CheckForUpdateEvent
      jsr   GetFrontWindow
      jmp   L6A1C
L6A19:jsr   NextWindow
L6A1C:bcs   DONE
      ldy   #$0F
      lda   (MenuBarOrWindowPtr),y ; get window's document info struct ptr
      bne   L6A19                  ; if it isn't NULL, iterate on next window
      dey
      lda   (MenuBarOrWindowPtr),y
      bpl   L6A19
      lda   #$00
      sta   (MenuBarOrWindowPtr),y
      lda   #EventTypeUpdate
      ldy   #$00
      sta   (EventPtr2),y ; set event type
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; get window ID
      ldy   #$01
      sta   (EventPtr2),y ; set window ID in event
      iny
      sta   (EventPtr2),y ; set window ID in event
      rts
DONE: lda   #$00
      sta   CheckForUpdateEventsFlag
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $15 (21)
;;; ----------------------------------------
.proc PeekEvent
      jsr   LoadEventOutputPtrWithParam
      php
      sei
      bit   InterruptAllocatedFlag
      bmi   SKIP
      jsr   InterruptHandler
SKIP: jsr   GetHeadEvent
      bcc   OUT
      jsr   CreateDragOrUpdateEvent ; if queue empty, create mouse event
OUT:  plp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $08 (8)
;;; ----------------------------------------
.proc SetKeyEvent
      ldy   #$01
      lda   (ParamTablePtr),y ; get new flag value
      beq   OFF
      lda   #$80
OFF:  sta   SetKeyEventFlag
      rts
.endproc

.proc CopyDataIntoEvent
      ldy   #$00
LOOP: lda   (EventPtr),y
      sta   (EventPtr2),y
      iny
      cpy   GeneralStorageByte
      bcc   LOOP
      rts
.endproc

EventBufferEventType:
      .byte $00
EventBufferXCoord:
      .byte $00
EventBufferYCoord:
      .byte $00
EventBufferAddress:
      .addr EventBufferEventType
AppleKeyModifierMask:
      .byte $00

;;; If bit 7 is set, mouse movement is simulated by using arrow keys.
;;; If bit 6 is set, then a Keyboard Mouse Mode operation is in
;;; progress.
;;;
;;; If both bits 6 & 7 are set, then Keyboard Mouse Mode is on. The
;;; SimulatedMouseButtonDownFlag is set to $80 because all operations
;;; supported in Keyboard Mouse mode (resize window, move window,
;;; and interact with menu bar) are effectively mouse drags. Holding
;;; down the Open-Apple key acts as an accelerator for movement when
;;; pressing the arrow keys to move the mouse cursor.
;;;
;;; If only bit 7 is set, then Saftey Net Mode is on. This mode remains
;;; active as long as the Open-Apple key is held down continuously.
;;; In this mode, the Solid-Apple key functions as the mouse button,
;;; and SimulatedMouseButtonDownFlag tracks whether it is currently
;;; down or not.
;;;
;;; It is not valid to have only bit 6 set.
MouseEmulationFlags:
      .byte $00

;;; All KeyboardMouseMode operations are effectively mouse drags;
;;; this flag is set when the toolkit is simulating the mouse button
;;; being down during a Keyboard Mouse Mode operation. It is also set
;;; when the Solid-Apple key is being held down in Safety-Net mode to
;;; simulate a mouse button press.
SimulatedMouseButtonDownFlag:
      .byte $00
PreviousAppleKeyModifierMask:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $05 (5)
;;; ----------------------------------------
CheckEvents:
      bit   InterruptAllocatedFlag
      bpl   CheckEventsPreHook   ; branch if no
      lda   #ErrInterruptModeInUse
      sta   LastError
      rts
CheckEventsPreHook:
      sec                  ; these 3 bytes of code get overwritten
      bcc   L6A8B
L6A8B:bcc   CheckEventsPostHook
      jsr   ProcessKeyboardEvents
CheckEventsPostHook:
      sec                  ; these 3 bytes of code get overwritten
      bcc   L6A93
L6A93:rts

.proc ProcessKeyboardEvents
      lda   BUTN1 ; Solid-Apple
      asl   a
      lda   BUTN0 ; Open-Apple
      and   #%10000000
      rol   a
      rol   a
      sta   AppleKeyModifierMask
      bit   MouseEmulationFlags
      bmi   L6AD2 ; branch if Safety-Net mode is on
      ldx   SimulatedMouseButtonDownFlag
      beq   L6ACB ; branch if Solid-Apple key was not down
      lsr   a
      bcc   L6AC5 ; branch if Open-Apple not down
      lsr   a
      bcs   L6AD2 ; branch if Solid-Apple down
      lda   #$80 ; starting Safety Net Mode...
      sta   MouseEmulationFlags ; turn on Safety-Net mode
      lda   #$00
      sta   PreviousAppleKeyModifierMask
      jsr   FlushEventsAndSaveCursorVisibilityState
      jsr   PlayTone
      jsr   ShowCursor
L6AC5:lda   #$00
      sta   SimulatedMouseButtonDownFlag
      rts
L6ACB:cmp   #$03 ; both Apple keys down?
      bne   L6AD2
      sta   SimulatedMouseButtonDownFlag ; sets it to $03 ???
L6AD2:jsr   ReadMouseState
      jsr   MoveCursorToLatestMousePos
      lda   MouseButtonState
      asl   a ; shift button state into Carry flag; 'still down' state into MSB
      eor   MouseButtonState ; check if button state changed
      bmi   L6B05 ; branch if yes
      bit   SetKeyEventFlag
      bmi   L6AEB
      bit   MouseEmulationFlags
      bpl   OUT ; branch if Safety-Net mode is off
L6AEB:lda   KBD ; read keyboard soft switch
      bpl   OUT ; branch if no key down
      and   #%01111111 ; strip MSB
      sta   EventBufferXCoord
      bit   KBDSTRB ; clear keyboard strobe
      lda   AppleKeyModifierMask
      sta   EventBufferYCoord
      lda   #EventTypeKeyPress
      sta   EventBufferEventType
      bne   EnqueueEventFromEventBuffer ; branch always taken
L6B05:bit   MouseEmulationFlags
      bcs   L6B1A ; branch if (real, not simulated) mouse button is down
      bpl   L6B37 ; branch if Safety-Net mode is off
      bvs   L6B10 ; branch if Keyboard Mouse Mode is on
      bvc   StopTrackingKeyboardMouseModeButton ; branch if Keyboard Mouse mode off
L6B10:lda   #$00
      sta   MouseEmulationFlags ; turn off all modes
      sta   MouseAndCursorStateSavedFlag ; clear flag
      beq   StopTrackingKeyboardMouseModeButton ; branch always taken
L6B1A:bmi   StartTrackingKeyboardMouseModeButton
      lda   AppleKeyModifierMask
      beq   L6B2E ; branch if neither Apple key is down
      lda   #EventTypeAppleKeyDown
      bne   L6B43 ; branch always taken
PostNoneEvent:
      lda   #EventTypeNone
      beq   L6B43 ; branch always taken
StartTrackingKeyboardMouseModeButton:
      lda   #$80
      sta   SimulatedMouseButtonDownFlag
L6B2E:lda   #EventTypeButtonDown
      bne   L6B43 ; branch always taken
StopTrackingKeyboardMouseModeButton:
      lda   #$00
      sta   SimulatedMouseButtonDownFlag
L6B37:lda   MouseTrackingMode
      cmp   #TrackingModeMenuInteraction
      bne   L6B41
      jsr   UpdateCoordOfMenuItemTitle
L6B41:lda   #EventTypeButtonUp ; create button-up event in buffer
L6B43:sta   EventBufferEventType
      lda   MouseXCoord
      sta   EventBufferXCoord
      lda   MouseYCoord
      sta   EventBufferYCoord
EnqueueEventFromEventBuffer:
      php
      sei
      lda   EventBufferAddress
      sta   EventPtr
      lda   EventBufferAddress+1
      sta   EventPtr+1
      jsr   EnqueueEvent
      plp
OUT:  rts
.endproc

InterruptHandlerZeroPageStorage:
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00
InterruptHandlerZeroPageStorageLength = *-InterruptHandlerZeroPageStorage

.proc InterruptHandler
      ldx   #$00 ; save zero page
LOOP1:lda   $00,x
      sta   InterruptHandlerZeroPageStorage,x
      inx
      cpx   #$0B
      bcc   LOOP1
      ldy   #$04 ; save CurrentYCoord, CurrentXCoord, CharRegister, and LastError
LOOP2:lda   CurrentYCoord-1,y
      sta   InterruptHandlerZeroPageStorage,x
      inx
      dey
      bne   LOOP2
      ldx   #$01
      jsr   SaveSoftSwitchStates ; to buffer #1
      jsr   CheckEventsPreHook
      ldx   #$01
      jsr   RestoreSoftSwitchStates ; from buffer #1
      dex
LOOP3:lda   InterruptHandlerZeroPageStorage,x ; restore zero page
      sta   $00,x
      inx
      cpx   #$0B
      bcc   LOOP3
      ldy   #$04 ; and other variables
LOOP4:lda   InterruptHandlerZeroPageStorage,x
      sta   CurrentYCoord-1,y
      inx
      dey
      bne   LOOP4
      rts
.endproc

InterruptHandler1:
      cld
      jsr   ServeMouse
      bcs   L6BB9
InterruptHandlerAddr:= * + 1
      jsr   InterruptHandler
      clc
L6BB9:rts

;;; ----------------------------------------
;;; ToolKit call $11 (17)
;;; ----------------------------------------
.proc PascIntAdr
      ldy   #$01
      lda   InterruptHandlerAddr
      sta   (ParamTablePtr),y
      iny
      lda   InterruptHandlerAddr+1
      sta   (ParamTablePtr),y
      rts
.endproc

;;; This event buffer is used by the mouse tracking modes.
EventBuffer2EventType:
      .byte $00
EventBuffer2XCoord:
      .byte $00
EventBuffer2YCoord:
      .byte $00
EventBuffer2Address:
      .addr EventBuffer2EventType
MouseDragTrackingLastXCoord:
      .byte $00
MouseDragTrackingLastYCoord:
      .byte $00

;;; Returns with Carry set if button was released.
.proc MouseDragTrackingRoutine
      lda   EventBuffer2Address
      sta   EventOutputPtr
      lda   EventBuffer2Address+1
      sta   EventOutputPtr+1
      jsr   GetEvent::DequeueEvent
      lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      beq   L6C0A
      cmp   #EventTypeNone
      beq   L6C0A
      cmp   #EventTypeDrag
      bne   MouseDragTrackingRoutine
      lda   EventBuffer2XCoord
      cmp   MouseDragTrackingLastXCoord
      php
      sta   MouseDragTrackingLastXCoord
      lda   EventBuffer2YCoord
      cmp   MouseDragTrackingLastYCoord
      sta   MouseDragTrackingLastYCoord
      bne   L6C07 ; coordinates changed since last event
      plp
      bne   L6C08
      beq   MouseDragTrackingRoutine ; loop if coordinates unchanged
L6C07:plp
L6C08:clc
      rts
L6C0A:sec
      rts
.endproc

EventQueueHeadPtr:
      .addr EventQueue
EventQueueTailPtr:
      .addr EventQueue
EventOutputPtr:
      .addr $0000
;;; Event Queue 32 entries of 3 bytes each
EventQueue:
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
;;; What are these last 3 bytes for?
EventQueueLast:
      .byte $00,$00,$00
EventQueueStartPtr:
      .addr EventQueue
EventQueueEndPtr:
      .addr EventQueue + (32*3)

;;; ----------------------------------------
;;; ToolKit call $07 (7)
;;; ----------------------------------------
.proc FlushEvents
      php
      sei
      ldx   #$01 ; head = tail = start
LOOP: lda   EventQueueStartPtr,x
      sta   EventQueueHeadPtr,x
      sta   EventQueueTailPtr,x
      dex
      bpl   LOOP
      plp
      rts
.endproc

.proc EnqueueEvent
      lda   EventQueueTailPtr ; tail == end? branch to LCA8
      cmp   EventQueueEndPtr
      bne   L6CA8
      lda   EventQueueTailPtr+1
      cmp   EventQueueEndPtr+1
      bne   L6CA8
      lda   EventQueueStartPtr ; EventPtr2 = start
      sta   EventPtr2
      lda   EventQueueStartPtr+1
      sta   EventPtr2+1
      jmp   L6CB7
L6CA8:clc
      lda   EventQueueTailPtr ; EventPtr2 = tail + 3
      adc   #$03
      sta   EventPtr2
      lda   EventQueueTailPtr+1
      adc   #$00
      sta   EventPtr2+1
L6CB7:lda   EventQueueHeadPtr ; head == EventPtr2? queue full
      cmp   EventPtr2
      bne   L6CC5
      lda   EventQueueHeadPtr+1
      cmp   EventPtr2+1
      beq   ERR
L6CC5:lda   EventPtr2 ; tail = EventPtr2
      sta   EventQueueTailPtr
      lda   EventPtr2+1
      sta   EventQueueTailPtr+1
      lda   #$03 ; number of bytes to copy
      sta   GeneralStorageByte
      jsr   CopyDataIntoEvent
      clc
      rts
ERR:  sec
      rts
.endproc

.proc GetHeadEvent
      lda   EventOutputPtr
      sta   EventPtr2
      lda   EventOutputPtr+1
      sta   EventPtr2+1
      lda   EventQueueTailPtr ; if head == tail, queue is empty
      cmp   EventQueueHeadPtr
      bne   L6CF4
      lda   EventQueueTailPtr+1
      cmp   EventQueueHeadPtr+1
      beq   ERR             ; queue empty
L6CF4:lda   EventQueueHeadPtr ; if head == end, set head = start
      cmp   EventQueueEndPtr
      bne   L6D11
      lda   EventQueueHeadPtr+1
      cmp   EventQueueEndPtr+1
      bne   L6D11
      lda   EventQueueStartPtr ; EventPtr = start
      sta   EventPtr
      lda   EventQueueStartPtr+1
      sta   EventPtr+1
      jmp   L6D20
L6D11:clc   ; otherwise, advance head by 3 bytes
      lda   EventQueueHeadPtr
      adc   #$03
      sta   EventPtr
      lda   EventQueueHeadPtr+1
      adc   #$00
      sta   EventPtr+1
L6D20:lda   #$03 ; number of bytes to copy
      sta   GeneralStorageByte
      jsr   CopyDataIntoEvent
      clc
      rts
ERR:  sec
      rts
.endproc

.proc ProcessKeyboardMouseModeEvent
      bit   MouseEmulationFlags
      bvs   L6D35 ; branch if Keyboard Mouse Mode on
      lda   BUTN0 ; Open-Apple
      bpl   FinishKeyboardMouseMode1 ; if Open-Apple not down
L6D35:jsr   GetHeadEvent
      bcs   L6D54 ; branch if queue empty
      ldy   #$00
      lda   (EventPtr2),y ; event type
      cmp   #EventTypeKeyPress
      bne   L6D75
      jsr   FlushEvents
      ldy   #$01
      lda   (EventPtr2),y ; key char
      jsr   ProcessKeyboardMouseModeArrowKeypress
      bcc   L6D54
      bit   MouseEmulationFlags
      bvs   EndKeyboardMouseModeOperation ; branch if Keyboard Mouse Mode on
      rts
L6D54:jsr   MoveCursorToLatestMousePos
      bit   MouseEmulationFlags
      bvs   L6D75 ; branch if Keyboard Mouse Mode is on
      lda   BUTN1 ; Solid-Apple
      eor   PreviousAppleKeyModifierMask ; Solid Apple key state changed?
      bpl   L6D75 ; branch if no
      eor   PreviousAppleKeyModifierMask ; A = $00 or $80 here
      sta   PreviousAppleKeyModifierMask
      lda   SimulatedMouseButtonDownFlag
      bmi   L6D72 ; branch if on
      jmp   ProcessKeyboardEvents::StartTrackingKeyboardMouseModeButton
L6D72:jmp   ProcessKeyboardEvents::StopTrackingKeyboardMouseModeButton
L6D75:rts
FinishKeyboardMouseMode1:
      lda   SimulatedMouseButtonDownFlag
      bpl   FinishKeyboardMouseMode ; branch if SA key was not down
      jsr   ProcessKeyboardEvents::StopTrackingKeyboardMouseModeButton
FinishKeyboardMouseMode:
      lda   #$00
      sta   MouseEmulationFlags ; turn off all modes
      sta   SimulatedMouseButtonDownFlag
      ldx   MouseTrackingMode
      bne   L6D8E
      sta   MouseAndCursorStateSavedFlag ; clear flag
L6D8E:jsr   RestoreMouseAndCursorState
      lda   MouseAndCursorStateSavedCursorObscuredFlag
      bpl   L6D99 ; branch if no
      jsr   ObscureCursor
L6D99:lda   MouseAndCursorStateSavedCursorVisibleFlag
      bmi   L6DA1 ; branch if yes
      jsr   HideCursor
L6DA1:rts
.endproc

.proc EndKeyboardMouseModeOperation
      cmp   #CharEsc
      beq   CancelOperationAndExitKeyboardMouseMode
      cmp   #CharReturn
      beq   FinishOperationAndExitKeyboardMouseMode
      sta   KeyboardMouseModeSavedKeypress
      ldx   #$07
L6DAF:lda   MenuBarOrWindowPtr,x ; save 8 bytes of struct on stack
      pha
      dex
      bpl   L6DAF
      ldy   #$02
      lda   (EventPtr2),y  ; get modifier mask from event
      sta   KeyboardMouseModeSavedModifierMask
      tax
      lda   KeyboardMouseModeSavedKeypress
      jsr   FindMenuItemForKey
      tay
      ldx   #$00 ; restore 8 bytes of struct from stack
L6DC6:pla
      sta   MenuBarOrWindowPtr,x
      inx
      cpx   #$08
      bne   L6DC6
      tya
      beq   OUT
      lda   MouseTrackingMode
      beq   L6DE9 ; branch if no mouse tracking mode is active
      cmp   #TrackingModeMenuInteraction
      beq   L6DE0
      jsr   ProcessKeyboardMouseModeEvent::FinishKeyboardMouseMode1
      jmp   L6DE9
L6DE0:jsr   UpdateCoordOfMenuItemTitle
      jsr   ProcessKeyboardEvents::PostNoneEvent
      jsr   ProcessKeyboardMouseModeEvent::FinishKeyboardMouseMode
L6DE9:lda   #EventTypeKeyPress
      sta   EventBufferEventType
      lda   KeyboardMouseModeSavedKeypress
      sta   EventBufferXCoord
      lda   KeyboardMouseModeSavedModifierMask
      sta   EventBufferYCoord
      jsr   ProcessKeyboardEvents::EnqueueEventFromEventBuffer
OUT:  rts
.endproc

KeyboardMouseModeSavedKeypress:
      .byte $00
KeyboardMouseModeSavedModifierMask:
      .byte $00

.proc CancelOperationAndExitKeyboardMouseMode
      jsr   UpdateCoordOfMenuItemTitle
      jsr   ProcessKeyboardMouseModeEvent::FinishKeyboardMouseMode
      rts
.endproc

.proc FinishOperationAndExitKeyboardMouseMode
      jsr   ProcessKeyboardMouseModeEvent::FinishKeyboardMouseMode1
      rts
.endproc

.proc UpdateCoordOfMenuItemTitle
           ldx   MouseTrackingMode
           cpx   #TrackingModeMenuInteraction
           bne   OUT ; if not tracking menu interaction, return
           lda   SelectedMenuNumberOrID
           beq   OUT
           ldy   #$07
           lda   (MenuBlockOrDocInfoPtr),y ; left coord for hilite/select
           sta   SelectedMenuTitleXCoord
           lda   SelectedMenuItemNumber
           sta   SelectedMenuTitleYCoord
OUT:       rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $30 (48)
;;; ----------------------------------------
.proc KeyboardMouse
      lda   #%11000000
      sta   MouseEmulationFlags ; turn on all modes
      sta   SimulatedMouseButtonDownFlag
      jsr   FlushEventsAndSaveCursorVisibilityState
      jsr   SaveMouseAndCursorState
      jsr   ShowCursor
      rts
.endproc

;;; This is a table of deltas for adjusting x- and y-
;;; coordinates when tracking the mouse in keyboard mouse mode.

;;; The arrow keys (left, down, up, right) have the ASCII values
;;; $08, $0A, $0B, $15, respectively. This routine remaps the right
;;; arrow to ASCII code $09, thereby giving a contiguous range:
;;; $08, $09, $0A, $0B for left, right, down, up, respectively.
;;; 8 is then subtracted from the value to get an index (0-3) into
;;; one of the 4-byte tables below.
;;; There are four 4-byte tables.
;;; 1) The first table contains the coordinate pointer offsets
;;;    within the event structure (+0 for the x-coordinate,
;;;    +2 for the y-coordinate) for the corresponding arrow key
;;;    direction.
;;; 2) The second table is identical to the first table, but applies
;;;    to fast-tracking mode.
;;; 3) The third table contains the deltas by which the corresponding
;;;    coordinate (x for horizontal arrow keypress, y for vertical
;;;    arrow keypress) is adjusted when that key is pressed. For
;;;    example, up-arrow is represented by the third byte in the table,
;;;    $FF, or -1.
;;; 4) The fourth table contains the deltas by which the corresponding
;;;    coordinate is adjusted when that key is pressed in fast tracking
;;;    mode. For example, up-arrow is $FB, or -5.

ArrowKeyCoordinateTable:
      .byte $00,$00,$02,$02,$00,$00,$02,$02
      .byte $FF,$01,$01,$FF,$F6,$0A,$05,$FB

;;; Returns with Carry set if the keypress wasn't recognized.
.proc ProcessKeyboardMouseModeArrowKeypress
      cmp   #CharTab ; tab key?
      beq   L6E59 ; yes - invalid
      cmp   #CharRightArrow ; right arrow key?
      bne   L6E51 ; no - branch
      lda   #CharTab ; yes - remap it to Tab
L6E51:cmp   #CharLeftArrow
      bcc   L6E59 ; less than $08 - invalid
      cmp   #CharUpArrow+1 ; up or down arrow key?
      bcc   L6E5B ; yes
L6E59:sec  ; no - invalid
      rts
L6E5B:ldx   MouseTrackingMode
      cpx   #TrackingModeMenuInteraction
      beq   L6EC9
      tax
      bit   MouseEmulationFlags
      bvc   L6E74          ; branch if Keyboard Mouse Mode off
      ldy   #$02
      lda   (EventPtr2),y  ; accelerator mask
      cmp   #$01           ; Open-Apple key down?
      bne   L6E74          ; no - normal mode
      inx                  ; yes - accelerated mode;
      inx                  ; advance to the next 4-byte table
      inx
      inx
L6E74:ldy   ArrowKeyCoordinateTable-8,x
      bne   L6E9E          ; branch if vertical axis
      lda   MouseTrackingMode
      cmp   #TrackingModeDragWindow
      bne   L6E9E          ; branch if not dragging window
      clc
      lda   MouseXCoord    ; adjust x-coordinate by appropriate delta
      adc   ArrowKeyCoordinateTable,x
      bpl   L6E8D          ; positive value?
      ldy   #$00           ; if not, clamp to 0
      beq   L6E98          ; branch always taken
L6E8D:sec
      sbc   MaxColumnNumber ; if > max col, clamp to max col
      beq   L6E9E
      bcc   L6E9E
      ldy   MaxColumnNumber
L6E98:sty   MouseXCoord
      jmp   L6EE1
L6E9E:clc                  ; Y = 2 here
      lda   MouseXCoord,y  ; adjust y-coordinate by appropriate delta
      adc   ArrowKeyCoordinateTable,x
      beq   L6EA9          ;
      bpl   L6EB7          ; if > 0, OK
L6EA9:tya
      beq   L6EC1          ; if < 0, clamp to 0 below
      lda   MouseTrackingMode
      cmp   #TrackingModeDragWindow
      bne   L6EC1          ; branch if not dragging window
      lda   #$01
      bne   L6EC3          ; branch always taken
L6EB7:cmp   MaxColumnNumber,y ; if > max row, clamp to max row
      bcc   L6EC3
      lda   MaxColumnNumber,y
      bne   L6EC3          ; branch always taken
L6EC1:lda   #$00
L6EC3:sta   MouseXCoord,y
      jmp   L6EDC
L6EC9:and   #$0B
      cmp   #$0A           ; up or down arrow?
      bcs   L6ED9          ; branch if yes
      jsr   HandleHorizArrowKey
      lda   #$00
      sta   MouseYCoord
      beq   L6EDC          ; branch always taken
L6ED9:jsr   HandleVertArrowKey
L6EDC:jsr   SetMousePosition ; update mouse position to new coordinates
      clc
      rts
L6EE1:ldx   #$00
      tay
      bpl   L6EE7
      dex
L6EE7:clc
      adc   WindowDragWindowXCoord1
      sta   WindowDragWindowXCoord1
      txa
      adc   WindowDragWindowXCoord1+1
      sta   WindowDragWindowXCoord1+1
      lda   #$FF           ; -1
      sta   MouseDragTrackingLastXCoord
      jmp   L6EDC
.endproc

.proc HandleHorizArrowKey
      pha   ; push char typed on stack
      jsr   LoadMenuBarStructPtr
      lda   MouseXCoord
      sta   EventBuffer2XCoord
      jsr   FindMenuAtXCoord
      pla   ; restore char typed
      cmp   #CharTab ; right arrow (remapped as tab)?
      beq   L6F1C ; branch if yes
      ldx   SelectedMenuNumberOrID
      dex   ; select previous menu
      beq   L6F17 ; if 0, wrap around to last menu
      bpl   SetMouseXCoordAtMenuLeftSelect
L6F17:ldx   FindMenuAtXCoordMenuCount
      bne   SetMouseXCoordAtMenuLeftSelect ; branch always taken
L6F1C:ldx   SelectedMenuNumberOrID
      cpx   FindMenuAtXCoordMenuCount ; on last menu?
      bcc   L6F26
      ldx   #$00 ; yes, wrap around to first menu
L6F26:inx
SetMouseXCoordAtMenuLeftSelect:
      jsr   LoadMenuBlockPtrForMenuNumberX
      ldy   #$07
      lda   (MenuBlockOrDocInfoPtr),y ; left for hilite/select
      sta   MouseXCoord
      rts
.endproc

.proc HandleVertArrowKey
      pha   ; push char typed on stack
      jsr   LoadMenuBarStructPtr
      ldx   SelectedMenuNumberOrID
      beq   L6F8A ; no menu selected?
      jsr   HandleHorizArrowKey::SetMouseXCoordAtMenuLeftSelect
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; read menu option byte
      bmi   L6F83 ; branch if menu is disabled
L6F44:jsr   LoadMenuStructPtr
      ldy   #$00
      lda   MouseYCoord
      cmp   (MenuStructPtr),y ; number of items
      beq   L6F52
      bcs   L6F83 ; branch if y coordinate is past bottom of menu
L6F52:pla
      pha
      cmp   #CharDownArrow ; down arrow?
      beq   L6F65 ; branch if yes
      ldx   MouseYCoord
      beq   L6F60 ; if in row 0 (menu bar), wrap around to bottom item
      dex
      bpl   L6F70
L6F60:lda   (MenuStructPtr),y ; number of items
      tax
      bne   L6F70
L6F65:lda   MouseYCoord ; if at bottom of menu, wrap around to top item
      ldx   #$00
      cmp   (MenuStructPtr),y ; number of items
      bcs   L6F70
      tax
      inx
L6F70:stx   MouseYCoord
      beq   L6F81
      jsr   LoadMenuItemPtrForItemX
      ldy   #$00
      lda   (MenuItemStructPtr),y ; item option byte
      bmi   L6F44                 ; loop to next item if item is disabled
      asl   a                     ; shift filler flag into MSB
      bmi   L6F44                 ; loop to next item if item is filler
L6F81:pla
      rts
L6F83:pla
      lda   #$00 ; set y coord to 0 (menu bar row)
      sta   MouseYCoord
      rts
L6F8A:pla
      ; There is an 'rts' missing here; this would crash.
.endproc

MouseAndCursorStateSavedFlag:
      .byte $00
MouseAndCursorStateSavedXCoord:
      .byte $00
MouseAndCursorStateSavedYCoord:
      .byte $00
MouseAndCursorStateSavedCursorVisibleFlag:
      .byte $00
MouseAndCursorStateSavedCursorObscuredFlag:
      .byte $00

.proc SaveMouseAndCursorState
      lda   MouseXCoord
      sta   MouseAndCursorStateSavedXCoord
      lda   MouseYCoord
      sta   MouseAndCursorStateSavedYCoord
      lda   #$80
      sta   MouseAndCursorStateSavedFlag
      rts
.endproc

.proc RestoreMouseAndCursorState
      bit   MouseAndCursorStateSavedFlag
      bpl   L6FBB
      lda   MouseAndCursorStateSavedXCoord
      sta   MouseXCoord
      lda   MouseAndCursorStateSavedYCoord
      sta   MouseYCoord
      jsr   SetMousePosition
      lda   #$00
      sta   MouseAndCursorStateSavedFlag
L6FBB:jsr   MoveCursorToLatestMousePos
      rts
.endproc

;;; Also unobscures the cursor.
.proc FlushEventsAndSaveCursorVisibilityState
      jsr   FlushEvents
      lda   CursorVisibleFlag
      sta   MouseAndCursorStateSavedCursorVisibleFlag
      lda   CursorObscuredFlag
      sta   MouseAndCursorStateSavedCursorObscuredFlag
      lda   #$00
      sta   CursorObscuredFlag
      rts
.endproc

.proc PlayTone
      lda   #$24
      sta   L6FE5
      ldy   #$20
      bne   L6FE4 ; branch always taken
PlayTone1:
      lda   #$0C
      sta   L6FE5
      ldy   #$C0
L6FE4:
L6FE5 := * + 1
      lda   #$24 ; operand is overwritten
      sec
L6FE7:pha
L6FE8:sbc   #$01
      bne   L6FE8
      pla
      sbc   #$01
      bne   L6FE7
      lda   SPKR
      dey
      bne   L6FE4
      rts
.endproc

MenuSaveAreaPtr:
      .word $0000
MenuSaveAreaSize:
      .word $0000
MenuBarStructPtr:
      .word $0000

;;; ----------------------------------------
;;; ToolKit call $09 (9)
;;; ----------------------------------------
.proc InitMenu
      ldy   #$01
      lda   (ParamTablePtr),y
      sta   MenuSaveAreaPtr
      iny
      lda   (ParamTablePtr),y
      sta   MenuSaveAreaPtr+1
      iny
      lda   (ParamTablePtr),y
      sta   MenuSaveAreaSize
      iny
      lda   (ParamTablePtr),y
      sta   MenuSaveAreaSize+1
      rts
.endproc

.proc LoadMenuBarStructPtr
      lda   MenuBarStructPtr
      sta   MenuBarOrWindowPtr
      lda   MenuBarStructPtr+1
      sta   MenuBarOrWindowPtr+1
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $0A (10)
;;; ----------------------------------------
.proc SetMenu
      ldy   #$01
      lda   (ParamTablePtr),y
      sta   MenuBarStructPtr
      iny
      lda   (ParamTablePtr),y
      sta   MenuBarStructPtr+1
      jsr   LoadMenuBarStructPtr
      jsr   CalculateMenuBounds
      jsr   DrawMenuBar
      ldx   #$01 ; select first menu title
      stx   SelectedMenuTitleXCoord
      dex
      stx   SelectedMenuTitleYCoord
      rts
.endproc

CalculateMenuBoundsMenuCount:
      .byte $00
CalculateMenuBoundsCurrentMenuXPos:
      .byte $00

;;; Calculates bounds of each menu.
.proc CalculateMenuBounds
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; number of menus
      sta   CalculateMenuBoundsMenuCount
      ldx   #$01
      stx   CalculateMenuBoundsCurrentMenuXPos
      jsr   LoadMenuBlockPtrForMenuNumberX
L7054:lda   CalculateMenuBoundsCurrentMenuXPos
      ldy   #$07
      sta   (MenuBlockOrDocInfoPtr),y ; left for hilite/select
      inc   CalculateMenuBoundsCurrentMenuXPos ; add 1 for space before title
      lda   CalculateMenuBoundsCurrentMenuXPos
      ldy   #$06
      sta   (MenuBlockOrDocInfoPtr),y ; x position for title display
      ldy   #$02
      lda   (MenuBlockOrDocInfoPtr),y ; pointer to title string
      sta   TextStringPtr
      iny
      lda   (MenuBlockOrDocInfoPtr),y
      sta   TextStringPtr+1
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; menu option byte
      sta   MenuOrWindowOptionByte
      jsr   MaybeOffsetTextStringPtr
      ldy   #$00
      lda   (TextStringPtr),y ; length of title string
      sec                     ; add 1 for space after title
      adc   CalculateMenuBoundsCurrentMenuXPos
      sta   CalculateMenuBoundsCurrentMenuXPos
      ldy   #$08
      sta   (MenuBlockOrDocInfoPtr),y ; right for hilite/select
      inc   CalculateMenuBoundsCurrentMenuXPos
      jsr   CalculateMenuSaveAreaAndEdges
      jsr   NextMenuBlock
      inx
      cpx   CalculateMenuBoundsMenuCount
      bcc   L7054
      rts
.endproc

MaxMenuItemWidth:
      .byte $00
CalculateMenuSaveAreaAndEdgesMenuXCoord:
      .byte $00
CalculateMenuSaveAreaAndEdgesItemCount:
      .byte $00
CalculateMenuSaveAreaAndEdgesMenuWidth:
      .byte $00

.proc CalculateMenuSaveAreaAndEdges
      txa
      pha   ; save X
      ldy   #$07
      lda   (MenuBlockOrDocInfoPtr),y ; left for hilite/select
      sta   CalculateMenuSaveAreaAndEdgesMenuXCoord
      dec   CalculateMenuSaveAreaAndEdgesMenuXCoord
      jsr   LoadMenuStructPtr
      lda   #$00
      sta   MaxMenuItemWidth
      ldy   #$00
      lda   (MenuStructPtr),y ; menu item count
      sta   CalculateMenuSaveAreaAndEdgesItemCount
      ldx   #$01
      jsr   LoadMenuItemPtrForItemX ; start with first menu item
L70BD:ldy   #$00
      lda   (MenuItemStructPtr),y ; menu item option byte
      and   #%01000000 ; is filler?
      bne   L70FB                 ; branch if yes
      lda   (MenuItemStructPtr),y ; menu item option byte
      sta   MenuOrWindowOptionByte
      ldy   #$04
      lda   (MenuItemStructPtr),y ; pointer to menu item title
      sta   TextStringPtr
      iny
      lda   (MenuItemStructPtr),y
      sta   TextStringPtr+1
      jsr   MaybeOffsetTextStringPtr
      ldy   #$00
      lda   (MenuItemStructPtr),y ; menu item option byte
      and   #%00000011            ; shortcut has Apple modifier?
      bne   L70EC                 ; branch if yes
      ldy   #$02
      lda   (MenuItemStructPtr),y ; keyboard shortcut char #1
      beq   L70EE                 ; branch if none
      cmp   #$20                  ; space char
      lda   #$00
      bcs   L70EE                 ; branch if not a control character
L70EC:lda   #$03
L70EE:ldy   #$00
      clc
      adc   (TextStringPtr),y     ; add 3 for width of keyboard shortcut
      cmp   MaxMenuItemWidth      ; update max item width if needed
      bcc   L70FB
      sta   MaxMenuItemWidth
L70FB:jsr   NextMenuItem          ; get next menu item
      inx
      cpx   CalculateMenuSaveAreaAndEdgesItemCount
      bcc   L70BD          ; loop if more menu items
      clc
      lda   #$04           ; add 4 to width
      adc   MaxMenuItemWidth
      sta   CalculateMenuSaveAreaAndEdgesMenuWidth ; update menu width
      adc   CalculateMenuSaveAreaAndEdgesMenuXCoord
      cmp   MaxColumnNumber ; does menu extend past right edge of screen?
      beq   L7117
      bcs   L7125
L7117:ldy   #$02 ; menu fits on screen
      sta   (MenuStructPtr),y ; right column of save box
      lda   CalculateMenuSaveAreaAndEdgesMenuXCoord
      ldy   #$01
      sta   (MenuStructPtr),y ; left column of save box
      jmp   L7134
L7125:lda   MaxColumnNumber ; menu doesn't fit on screen; truncate width
      ldy   #$02
      sta   (MenuStructPtr),y ; right column of save box
      sec
      sbc   CalculateMenuSaveAreaAndEdgesMenuWidth
      ldy   #$01
      sta   (MenuStructPtr),y ; left column of save box
L7134:lda   CalculateMenuSaveAreaAndEdgesMenuWidth
      sta   MultiplyArg1
      ldx   CalculateMenuSaveAreaAndEdgesItemCount
      inx
      stx   MultiplyArg2
      jsr   Multiply::MultiplyBytes ; width * height
      lda   MultiplyResult+1
      cmp   MenuSaveAreaSize+1 ; update save area size
      bcc   L715B
      bne   L7156
      lda   MenuSaveAreaSize
      cmp   MultiplyResult
      bcs   L715B
L7156:lda   #ErrSaveAreaTooSmall ; fail if provided save area is too small
      sta   LastError
L715B:pla   ; restore X
      tax
      rts
.endproc

.proc LoadMenuStructPtr
      ldy   #$04
      lda   (MenuBlockOrDocInfoPtr),y ; menu data structure ptr (lo)
      sta   MenuStructPtr
      iny
      lda   (MenuBlockOrDocInfoPtr),y ; menu data structure ptr (hi)
      sta   MenuStructPtr+1
      rts
.endproc

DrawMenuBarMenuCount:
      .byte $00

.proc DrawMenuBar
      jsr   LoadMenuBarStructPtr
      lda   #CharInvSpace
      sta   CharRegister
      lda   #$00
      sta   CurrentYCoord
      sta   CurrentXCoord
      ldx   MaxColumnNumber
      inx
LOOP1:jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      dex
      bne   LOOP1
      stx   CurrentYCoord
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; number of menus
      sta   DrawMenuBarMenuCount
      inx
      jsr   LoadMenuBlockPtrForMenuNumberX
LOOP2:jsr   OutputMenuTitleInverse
      jsr   NextMenuBlock
      dec   DrawMenuBarMenuCount
      bne   LOOP2
      rts
.endproc

.proc MaybeRestoreTextUnderMenu
      lda   PreviousSelectedMenuNumber
      beq   OUT ; no previous menu was selected
      lda   MenuSaveAreaPtr
      sta   SaveAreaPtr
      lda   MenuSaveAreaPtr+1
      sta   SaveAreaPtr+1
      jsr   SaveAndRestoreTextRectangle::RestoreTextRectangle
      jsr   MoveCursorToLatestMousePos
OUT:  rts
.endproc

.proc SaveTextUnderMenu
      jsr   HideCursor
      ldy   #$01
      lda   (MenuStructPtr),y ; left column of save box
      sta   TextRectangleXCoord
      ldy   #$02
      lda   (MenuStructPtr),y ; right column of save box
      sta   TextRectangleEndXCoordPlus1
      ldy   #$00
      lda   (MenuStructPtr),y ; number of items
      sta   TextRectangleEndYCoordPlus1
      inc   TextRectangleEndYCoordPlus1 ; +1 for bottom edge of menu
      lda   #$01
      sta   TextRectangleYCoord
      lda   MenuSaveAreaPtr
      sta   SaveAreaPtr
      lda   MenuSaveAreaPtr+1
      sta   SaveAreaPtr+1
      jsr   SaveAndRestoreTextRectangle::SaveTextRectangle
      jsr   ShowCursor
      rts
.endproc

NumberOfMenuItemsInMenu:
      .byte $00
MenuDisabledFlag:
      .byte $00

;;; Draws the currently selected menu
.proc DrawMenu
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; menu option byte
      and   #%10000000                ; menu disabled?
      beq   L71F5                     ; branch if no
      lda   #$80
L71F5:sta   MenuDisabledFlag
      ldx   SelectedMenuNumberOrID
      stx   PreviousSelectedMenuNumber
      beq   OUT ; branch if no previous selection
      jsr   LoadMenuBlockPtrForMenuNumberX
      jsr   LoadMenuStructPtr
      ldy   #$00
      lda   (MenuStructPtr),y ; menu item count
      sta   NumberOfMenuItemsInMenu
      jsr   SaveTextUnderMenu
      ldx   #$01
      jsr   LoadMenuItemPtrForItemX
      ldx   #$01
L7217:jsr   DrawMenuItem
      jsr   NextMenuItem
      inx
      dec   NumberOfMenuItemsInMenu
      bne   L7217 ; loop if there are more menu items to draw
      lda   TextRectangleEndYCoordPlus1 ; draw bottom edge of menu
      sta   CurrentYCoord
      lda   TextRectangleXCoord
      sta   CurrentXCoord
      lda   #CharSpace
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   #MTCharOverscore
      sta   CharRegister
L723F:jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   CurrentXCoord
      cmp   TextRectangleEndXCoordPlus1
      bcc   L723F
      lda   #CharSpace
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      jsr   MoveCursorToLatestMousePos
OUT:  rts
.endproc

;;; Draws the menu item whose number is in X
.proc DrawMenuItem
      stx   CurrentYCoord
      lda   TextRectangleEndXCoordPlus1
      sta   CurrentXCoord
      lda   #MTCharLeftVerticalBar ; left edge
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      lda   TextRectangleXCoord
      sta   CurrentXCoord
      lda   #MTCharRightVerticalBar ; right edge
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      ldy   #$00
      lda   (MenuItemStructPtr),y ; menu item option byte
      and   #%01000000 ; filler item?
      bne   DrawMenuFillerItem
      txa
      jsr   DrawMenuItemTitleAndMarkNormal
      jsr   DrawMenuItemShortcut
      bit   MenuDisabledFlag
      bmi   L7294 ; branch if menu disabled
      ldy   #$00
      lda   (MenuItemStructPtr),y ; menu item option byte
      and   #%10000000
      beq   L72AD ; branch if not disabled
L7294:lda   #CharCheckerboard ; draw disabled checkerboards
      sta   CharRegister
      ldx   TextRectangleEndXCoordPlus1
      dex
      stx   CurrentXCoord
      jsr   PrintCharAtCurrentCoord
      ldx   TextRectangleXCoord
      inx
      stx   CurrentXCoord
      jsr   PrintCharAtCurrentCoord
L72AD:ldx   CurrentYCoord
      rts
.endproc

.proc DrawMenuFillerItem
      ldy   #$02
      lda   (MenuItemStructPtr),y ; get filler character
      bmi   SKIP ; branch if >= $80
      jsr   RemapChar
SKIP: sta   CharRegister
      inc   CurrentXCoord
LOOP: jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   CurrentXCoord
      cmp   TextRectangleEndXCoordPlus1
      bcc   LOOP
      rts
.endproc

MenuItemShortcutChar:
      .byte $00

.proc DrawMenuItemShortcut
      ldy   #$02
      lda   (MenuItemStructPtr),y ; shortcut char #1
      beq   OUT ; branch if none
      cmp   #$20
      bcs   L72E3 ; branch if not a control character
      ora   #%01000000 ; convert to uppercase
      sta   MenuItemShortcutChar
      ldy   #MTCharDiamond
      bne   L72F4 ; branch always taken
L72E3:sta   MenuItemShortcutChar
      ldy   #$00
      lda   (MenuItemStructPtr),y ; item option byte
      and   #%00000011 ; has Apple key modifier?
      beq   OUT ; branch if no
      ldy   #MTCharOpenApple
      lsr   a
      bcs   L72F4
      dey   ; Y = MTCharSolidApple
L72F4:sty   CharRegister
      ldx   TextRectangleEndXCoordPlus1
      dex
      dex
      dex
      stx   CurrentXCoord
      jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   MenuItemShortcutChar
      jsr   RemapChar
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   #CharSpace
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
OUT:  rts
.endproc

SelectedMenuNumberOrID:
      .byte $00
SelectedMenuItemNumber:
      .byte $00
PreviousSelectedMenuNumber:
      .byte $00
PreviousSelectedMenuItemNumber:
      .byte $00
SelectedMenuTitleXCoord:
      .byte $01
SelectedMenuTitleYCoord:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $0B (11)
;;; ----------------------------------------
.proc MenuSelect
      jsr   HandleMenuInteraction
      ldy   #$01
      lda   SelectedMenuNumberOrID
      sta   (ParamTablePtr),y
      iny
      lda   SelectedMenuItemNumber
      sta   (ParamTablePtr),y
      rts
.endproc

.proc HandleMenuInteraction
      lda   #TrackingModeMenuInteraction
      sta   MouseTrackingMode
      jsr   LoadMenuBarStructPtr
      lda   #$00
      ldx   #$04
L7341:sta   SelectedMenuNumberOrID-1,x ; clear current/previous selected variables
      dex
      bne   L7341
      lda   #$FF ; -1
      sta   MouseDragTrackingLastXCoord
      bit   MouseEmulationFlags
      bvc   L737B ; branch if Keyboard Mouse Mode off
      jsr   SaveMouseAndCursorState
      lda   #%11000000
      sta   SimulatedMouseButtonDownFlag
      php
      sei
      lda   SelectedMenuTitleXCoord
      sta   MouseXCoord
      sta   EventBuffer2XCoord
      lda   SelectedMenuTitleYCoord
      sta   MouseYCoord
      sta   EventBuffer2YCoord
      jsr   SetMousePosition
      plp
      jsr   MoveCursorToLatestMousePos
      lda   #EventTypeDrag
      sta   EventBuffer2EventType
      bne   L7383 ; branch always taken
L737B:jsr   MouseDragTrackingRoutine
      lda   EventBuffer2YCoord
      bne   L739F
L7383:jsr   FindMenuAtXCoord
      lda   SelectedMenuNumberOrID
      cmp   PreviousSelectedMenuNumber
      beq   L739F ; branch if selected menu didn't change
      jsr   MaybeRestoreTextUnderMenu
      jsr   MoveMenuHighlight
      jsr   DrawMenu
      lda   #$00
      sta   SelectedMenuItemNumber
      sta   PreviousSelectedMenuItemNumber
L739F:lda   SelectedMenuNumberOrID
      beq   L73BA ; branch if no menu selected
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; menu option byte
      and   #%10000000
      bne   L73BA ; branch if menu disabled
      jsr   IsMenuItemSelected
      lda   SelectedMenuItemNumber
      cmp   PreviousSelectedMenuItemNumber
      beq   L73BA ; branch if selected menu item didn't change
      jsr   MoveMenuItemHighlight
L73BA:lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      beq   L73CA
      cmp   #EventTypeNone
      bne   L737B
      lda   #$00
      sta   SelectedMenuItemNumber
L73CA:jsr   MaybeRestoreTextUnderMenu
      lda   SelectedMenuNumberOrID
      beq   L73E7
      ldx   SelectedMenuItemNumber
      beq   L73E7
      jsr   LoadMenuItemPtrForItemX
      ldy   #$00
      lda   (MenuItemStructPtr),y
      and   #%11000000
      beq   L73E7 ; branch if not disabled or filler
      lda   #$00
      sta   SelectedMenuItemNumber
L73E7:lda   SelectedMenuItemNumber
      beq   L73F0 ; branch always taken
      ldy   #$00
      lda   (MenuBlockOrDocInfoPtr),y ; menu ID
L73F0:sta   SelectedMenuNumberOrID
      bne   L73FD
      lda   PreviousSelectedMenuNumber
      beq   L73FD
      jsr   OutputMenuTitleInverse
L73FD:lda   #TrackingModeNone
      sta   MouseTrackingMode
      rts
.endproc

FindMenuAtXCoordMenuCount:
           .byte $00

.proc FindMenuAtXCoord
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; number of menus
      sta   FindMenuAtXCoordMenuCount
      ldx   #$01
      jsr   LoadMenuBlockPtrForMenuNumberX
L7410:lda   EventBuffer2XCoord
      ldy   #$07
      cmp   (MenuBlockOrDocInfoPtr),y ; left for hilite/select
      bcc   L7421                     ; x coord is to left of left edge?
      ldy   #$08
      cmp   (MenuBlockOrDocInfoPtr),y ; right for hilite/select
      bcc   L7430                     ; x is to left of right edge?
      beq   L7430
L7421:jsr   NextMenuBlock ; try next menu
      inx
      cpx   FindMenuAtXCoordMenuCount
      bcc   L7410
      lda   #$00
      sta   SelectedMenuNumberOrID
      rts
L7430:inx
      stx   SelectedMenuNumberOrID
      rts
.endproc

.proc MoveMenuHighlight
      ldx   PreviousSelectedMenuNumber
      beq   L7440 ; nothing previously selected
      jsr   LoadMenuBlockPtrForMenuNumberX
      jsr   OutputMenuTitleInverse ; deselect previous menu
L7440:ldx   SelectedMenuNumberOrID
      stx   PreviousSelectedMenuNumber
      beq   L7456 ; nothing newly selected
      jsr   LoadMenuBlockPtrForMenuNumberX
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; menu option byte
      and   #%10000000
      bne   L7457 ; branch if disabled
      jsr   OutputMenuTitleNormal ; select new menu item
L7456:rts
L7457:jsr   OutputMenuTitleDisabled
      rts
.endproc

OutputMenuTitleSpaceChar:
      .byte $00 ; space or inverse space
OutputMenuTitleRightXCoord:
      .byte $00

.proc OutputMenuTitleInverse
      lda   #CharInvSpace
      sta   OutputMenuTitleSpaceChar
      jsr   GetMenuTitle
      jsr   OutputText::OutputTextInverse
      rts
.endproc

.proc OutputMenuTitleNormal
      lda   #CharSpace
      sta   OutputMenuTitleSpaceChar
      jsr   GetMenuTitle
      jsr   OutputText::OutputTextNormal
      rts
.endproc

.proc OutputMenuTitleDisabled
      jsr   OutputMenuTitleNormal
      lda   #CharCheckerboard
      sta   CharRegister
      ldy   #$07
      lda   (MenuBlockOrDocInfoPtr),y ; left for hilite/select
      sta   CurrentXCoord
      jsr   PrintCharAtCurrentCoord
      ldy   #$08
      lda   (MenuBlockOrDocInfoPtr),y ; right for hilite/select
      sta   CurrentXCoord
      jsr   PrintCharAtCurrentCoord
      rts
.endproc

;;; Prints blanks under the menu title, and loads the menu title
;;; into TextStringPtr.
.proc GetMenuTitle
      lda   #$00
      sta   CurrentYCoord
      ldy   #$07
      lda   (MenuBlockOrDocInfoPtr),y ; left for hilite/select
      sta   CurrentXCoord
      ldy   #$08
      lda   (MenuBlockOrDocInfoPtr),y ; right for hilite/select
      sta   OutputMenuTitleRightXCoord
      lda   OutputMenuTitleSpaceChar
      sta   CharRegister
LOOP: jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   OutputMenuTitleRightXCoord
      cmp   CurrentXCoord
      bcs   LOOP
      ldy   #$06
      lda   (MenuBlockOrDocInfoPtr),y
      sta   CurrentXCoord
      ldy   #$02
      lda   (MenuBlockOrDocInfoPtr),y
      sta   TextStringPtr
      iny
      lda   (MenuBlockOrDocInfoPtr),y
      sta   TextStringPtr+1
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y
      sta   MenuOrWindowOptionByte
      rts
.endproc

.proc LoadMenuBlockPtrForMenuNumberX
      clc
      lda   MenuBarOrWindowPtr
      adc   #$02
      sta   MenuBlockOrDocInfoPtr
      lda   MenuBarOrWindowPtr+1
      adc   #$00
      sta   MenuBlockOrDocInfoPtr+1
LOOP: dex
      beq   OUT
      jsr   NextMenuBlock
      jmp   LOOP
OUT:  rts
.endproc

.proc NextMenuBlock
      clc
      lda   MenuBlockOrDocInfoPtr
      adc   #$0A
      sta   MenuBlockOrDocInfoPtr
      bcc   OUT
      inc   MenuBlockOrDocInfoPtr+1
OUT:  rts
.endproc

.proc IsMenuItemSelected
      jsr   LoadMenuStructPtr
      lda   EventBuffer2YCoord
      beq   NONE ; on menu bar
      ldy   #$00
      cmp   (MenuStructPtr),y ; number of menu items
      bcc   L7509 ; <= -> OK
      beq   L7509
      jmp   NONE ; beyond last item
L7509:ldy   #$01
      lda   (MenuStructPtr),y ; left hilite/select
      cmp   EventBuffer2XCoord
      bcs   NONE               ; >= left edge
      lda   EventBuffer2XCoord
      ldy   #$02
      cmp   (MenuStructPtr),y ; right hilite/select
      bcs   NONE             ; >= right edge
      lda   EventBuffer2YCoord
      sta   SelectedMenuItemNumber
      rts
NONE: lda   #$00
      sta   SelectedMenuItemNumber
      rts
.endproc

.proc MoveMenuItemHighlight
      ldx   PreviousSelectedMenuItemNumber
      beq   L753E
      jsr   LoadMenuItemPtrForItemX
      ldy   #$00
      lda   (MenuItemStructPtr),y ; option byte
      and   #%11000000 ; disabled or filler?
      bne   L753E ; branch if yes
      lda   PreviousSelectedMenuItemNumber
      jsr   DrawMenuItemTitleAndMarkNormal
L753E:ldx   SelectedMenuItemNumber
      stx   PreviousSelectedMenuItemNumber
      beq   OUT
      jsr   LoadMenuItemPtrForItemX
      ldy   #$00
      lda   (MenuItemStructPtr),y ; option byte
      and   #%11000000
      bne   OUT
      lda   SelectedMenuItemNumber
      jsr   DrawMenuItemTitleAndMarkInverse
OUT:  rts
.endproc

DrawMenuItemXCoord:
      .byte $00 ; x-coord of menu item title
DrawMenuItemMarkChar:
      .byte $00 ; mark character

.proc DrawMenuItemTitleAndMarkNormal
      ldx   #CharSpace
      stx   OutputMenuTitleSpaceChar
      ldx   #MTCharCheckmark
      stx   DrawMenuItemMarkChar
      ldx   #$00
      stx   MenuItemTitleInverseFlag
      jsr   DrawMenuItemHighlightAndMark
      jsr   OutputText::OutputTextNormal
      rts
.endproc

.proc DrawMenuItemTitleAndMarkInverse
      ldx   #CharInvSpace
      stx   OutputMenuTitleSpaceChar
      ldx   #MTCharInvCheckmark
      stx   DrawMenuItemMarkChar
      ldx   #$80
      stx   MenuItemTitleInverseFlag
      jsr   DrawMenuItemHighlightAndMark
      jsr   OutputText::OutputTextInverse
      rts
.endproc

MenuItemTitleInverseFlag:
      .byte $00

;;; Draws the highlight bar and the mark character for a menu item.
;;; Also loads the menu item title into TextStringPtr.
.proc DrawMenuItemHighlightAndMark
      sta   CurrentYCoord
      ldy   #$01
      lda   (MenuStructPtr),y ; left col of save box
      tax
      inx
      stx   CurrentXCoord
      ldy   #$02
      lda   (MenuStructPtr),y ; right col of save box
      tax
      dex
      ldy   #$00
      lda   (MenuItemStructPtr),y ; item option byte
      and   #%00000011
      bne   L75AB ; branch if has Apple key modifier(s)
      ldy   #$02
      lda   (MenuItemStructPtr),y ; keyboard shortcut char #1
      beq   L75AE ; branch if none
      cmp   #$20
      bcs   L75AE ; branch if not a control character
L75AB:dex
      dex
      dex   ; decrement final x coord by 3 if no shortcut
L75AE:stx   DrawMenuItemXCoord
L75B1:lda   OutputMenuTitleSpaceChar ; draw highlight bar
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      lda   DrawMenuItemXCoord
      cmp   CurrentXCoord
      bcs   L75B1
      ldy   TextRectangleXCoord
      iny
      iny
      sty   CurrentXCoord
      ldy   #$00
      lda   (MenuItemStructPtr),y ; menu item option byte
      sta   MenuOrWindowOptionByte
      and   #%00100000
      beq   L75E3 ; branch if item is not checked
      lda   (MenuItemStructPtr),y ; menu item option byte
      and   #%00000100
      bne   L75E8 ; branch if has mark character
      lda   DrawMenuItemMarkChar ; use default mark character
      bne   L75F2 ; branch always taken
L75E3:lda   OutputMenuTitleSpaceChar
      bne   L75F2 ; branch always taken
L75E8:ldy   #$01
      lda   (MenuItemStructPtr),y ; mark character
      eor   MenuItemTitleInverseFlag
      jsr   RemapChar
L75F2:sta   CharRegister
      jsr   PrintCharAtCurrentCoord
      inc   CurrentXCoord
      ldy   #$04
      lda   (MenuItemStructPtr),y ; title text ptr (lo)
      sta   TextStringPtr
      iny
      lda   (MenuItemStructPtr),y ; title text ptr (hi)
      sta   TextStringPtr+1
      rts
.endproc

.proc LoadMenuItemPtrForItemX
      clc
      lda   MenuStructPtr
      adc   #$04
      sta   MenuItemStructPtr
      lda   MenuStructPtr+1
      adc   #$00
      sta   MenuItemStructPtr+1
LOOP: dex
      beq   OUT
      jsr   NextMenuItem
      jmp   LOOP
OUT:  rts
.endproc

.proc NextMenuItem
      clc
      lda   MenuItemStructPtr
      adc   #$06
      sta   MenuItemStructPtr
      bcc   OUT
      inc   MenuItemStructPtr+1
OUT:  rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $0D (13)
;;; ----------------------------------------
.proc HiliteMenu
      jsr   LoadMenuBarStructPtr
      ldy   #$01
      lda   (ParamTablePtr),y ; menu ID
      beq   L7638
      jsr   FindMenuByID
      bcc   L763F
L7638:lda   #$00
      sta   SelectedMenuNumberOrID
      beq   L7642 ; branch always taken
L763F:stx   SelectedMenuNumberOrID
L7642:jsr   MoveMenuHighlight
      jsr   MoveCursorToLatestMousePos
      rts
.endproc

FindMenuItemForKeyAppleKeyModifierMask:
      .byte $00
FindMenuItemForKeyCharacter:
      .byte $00
FindMenuItemForKeyMenuCount:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $0C (12)
;;; ----------------------------------------
.proc MenuKey
      ldy   #$04
      lda   (ParamTablePtr),y ; modifier mask
      and   #%00000011 ; Apple key down bits
      tax
      dey
      lda   (ParamTablePtr),y ; character typed
      and   #%01111111 ; clear MSB
      cmp   #CharEsc
      bne   L766B
      jsr   KeyboardMouse ; turn on keyboard mouse mode
      jsr   HandleMenuInteraction
      lda   SelectedMenuNumberOrID
      ldx   SelectedMenuItemNumber
      jmp   L7673
L766B:jsr   FindMenuItemForKey
      stx   PreviousSelectedMenuNumber
      tax
      tya
L7673:ldy   #$01
      sta   (ParamTablePtr),y ; menu ID
      iny
      txa
      sta   (ParamTablePtr),y ; menu item number
      beq   OUT
      jsr   OutputMenuTitleNormal
      jsr   MoveCursorToLatestMousePos
OUT:  rts
.endproc

;;; Returns the menu item number in X ($00 if not found)
;;; and menu ID in Y ($00 if not found)
.proc FindMenuItemForKey
      tay
      beq   L76B8
      sta   FindMenuItemForKeyCharacter
      stx   FindMenuItemForKeyAppleKeyModifierMask
      jsr   LoadMenuBarStructPtr
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; number of menus
      sta   FindMenuItemForKeyMenuCount
      ldx   #$01
      jsr   LoadMenuBlockPtrForMenuNumberX ; get first menu
LOOP: ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; menu option byte
      and   #%10000000
      bne   NEXT ; branch if disabled
      jsr   LoadMenuStructPtr
      jsr   FindMenuItemForKeyInCurrentMenu ; search for item in this menu
      bcc   LoadMenuIDIntoY ; found it!
NEXT: jsr   NextMenuBlock ; try next menu
      inx
      cpx   FindMenuItemForKeyMenuCount
      bcc   LOOP
      jsr   PlayTone::PlayTone1 ; didn't find it
L76B8:lda   #$00
      tax
      rts
.endproc

.proc LoadMenuIDIntoY
      inx
      pha
      ldy   #$00
      lda   (MenuBlockOrDocInfoPtr),y ; menu ID
      tay
      pla
      rts
.endproc

FindMenuItemForKeyMenuItemCount:
      .byte $00

.proc FindMenuItemForKeyInCurrentMenu
      txa
      pha ; save x on stack
      ldy   #$00
      lda   (MenuStructPtr),y ; number of menu items
      sta   FindMenuItemForKeyMenuItemCount
      ldx   #$01
      jsr   LoadMenuItemPtrForItemX
LOOP: ldy   #$00
      lda   (MenuItemStructPtr),y ; menu item option byte
      and   #%11000000 ; disabled or filler?
      bne   L76F7 ; branch if yes
      lda   (MenuItemStructPtr),y ; menu item option byte
      ldy   FindMenuItemForKeyCharacter
      cpy   #$20
      bcc   L76EA ; branch if control character
      and   FindMenuItemForKeyAppleKeyModifierMask
      beq   L76F7 ; branch if no Apple key modifiers
L76EA:tya
      ldy   #$02
      cmp   (MenuItemStructPtr),y ; shortcut character #1
      beq   FOUND ; branch if matches
      ldy   #$03
      cmp   (MenuItemStructPtr),y ; shortuct character #2
      beq   FOUND ; branch if matches
L76F7:jsr   NextMenuItem ; try next item
      inx
      cpx   FindMenuItemForKeyMenuItemCount
      bcc   LOOP ; loop if more items
      pla
      tax
      sec ; didn't find it
      rts
FOUND:inx ; found it
      txa
      tay ; a = x + 1 (menu item number)
      pla ; restore x from stack
      tax
      tya
      clc
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $0E (14)
;;; ----------------------------------------
.proc DisableMenu
      jsr   LoadMenuBarStructPtr
      ldy   #$01
      lda   (ParamTablePtr),y ; menu ID
      jsr   FindMenuByID
      bcs   ERR ; branch if menu not found
      ldy   #$02
      lda   (ParamTablePtr),y ; disabled status
      beq   L1
      ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; set disabled flag
      ora   #%10000000
      sta   (MenuBlockOrDocInfoPtr),y
      rts
L1:   ldy   #$01
      lda   (MenuBlockOrDocInfoPtr),y ; clear disabled flag
      and   #%01111111
      sta   (MenuBlockOrDocInfoPtr),y
      rts
ERR:  lda   #ErrInvalidMenuID
      sta   LastError
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $0F (15)
;;; ----------------------------------------
.proc DisableMenuItem
      lda   #%10000000
      jsr   SetMenuItemState
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $10 (16)
;;; ----------------------------------------
.proc CheckMenuItem
      lda   #%00100000
      jsr   SetMenuItemState
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $14 (20)
;;; ----------------------------------------
.proc SetMark
      lda   #%00000100
      jsr   SetMenuItemState
      bcs   OUT ; branch if not found
      ldy   #$04
      lda   (ParamTablePtr),y ; mark character
      ldy   #$01
      sta   (MenuItemStructPtr),y ; mark character
OUT:  rts
.endproc

SetMenuItemStateBitToSet:
      .byte $00

.proc SetMenuItemState
      sta   SetMenuItemStateBitToSet
      jsr   LoadMenuBarStructPtr
      jsr   FindMenuAndMenuItem
      bcs   ERR ; branch if not found
      ldy   #$03
      lda   (ParamTablePtr),y ; input flag
      beq   OFF
      ldy   #$00 ; turn bit on
      lda   SetMenuItemStateBitToSet
      ora   (MenuItemStructPtr),y
      sta   (MenuItemStructPtr),y
      clc
      rts
OFF:  ldy   #$00 ; turn bit off
      lda   #%11111111
      eor   SetMenuItemStateBitToSet
      and   (MenuItemStructPtr),y
      sta   (MenuItemStructPtr),y
ERR:  sec
      rts
.endproc

FindMenuByIDMenuCount:
      .byte $00
FindMenuByIDMenuID:
      .byte $00

.proc FindMenuByID
      sta   FindMenuByIDMenuID
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; number of menus
      sta   FindMenuByIDMenuCount
      ldx   #$01
      jsr   LoadMenuBlockPtrForMenuNumberX
      ldy   #$00
L778F:lda   (MenuBlockOrDocInfoPtr),y ; menu ID
      cmp   FindMenuByIDMenuID
      beq   L77A6
      cpx   FindMenuByIDMenuCount
      bcs   L77A2
      inx
      jsr   NextMenuBlock
      jmp   L778F
L77A2:ldx   #$00 ; not found
      sec
      rts
L77A6:inx ; found
      clc
      rts
.endproc

.proc FindMenuAndMenuItem
      ldy   #$01
      lda   (ParamTablePtr),y ; menu ID
      jsr   FindMenuByID
      bcs   L77C9
      jsr   LoadMenuStructPtr
      ldy   #$02
      lda   (ParamTablePtr),y ; menu number
      beq   L77CD             ; branch if 0
      ldy   #$00
      cmp   (MenuStructPtr),y
      beq   L77C3
      bcs   L77CD ; branch if > item count
L77C3:tax
      jsr   LoadMenuItemPtrForItemX
      clc
      rts
L77C9:lda   #ErrInvalidMenuID
      bne   L77CF
L77CD:lda   #ErrInvalidMenuItemNum
L77CF:sta   LastError
      sec
      rts
.endproc

FrontWindowPtr:
      .word $0000
LastWindowPtr:
      .word $0000
ReservedMemAreaPtr:
      .word $0000
ReservedMemAreaSize:
      .word $0000
WindowCoordinatesX:
      .word $0000
WindowCoordinatesY:
      .word $0000
ScreenCoordinatesX:
      .word $0000
ScreenCoordinatesY:
      .word $0000
WindowPtrIsAtFrontWindowFlag:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $16 (22)
;;; ----------------------------------------
.proc InitWindowMgr
      lda   #$00
      ldy   #$04
LOOP1:sta   FrontWindowPtr-1,y  ; clear pointers
      dey
      bne   LOOP1
      ldy   #$04
LOOP2:lda   (ParamTablePtr),y ; save reserved mem ptr, size
      sta   LastWindowPtr+1,y
      dey
      bne   LOOP2
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $17 (23)
;;; ----------------------------------------
.proc OpenWindow
      jsr   LoadWindowPtrFromParamTable
      beq   L7828
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; window ID
      beq   L7828                  ; 0 is invalid
      jsr   FindWindowByIDInA
      bcc   L782E                  ; window already open
      jsr   LoadWindowPtrFromParamTable
      lda   #ErrNone
      sta   LastError
      lda   #%10000000
      ldy   #$16
      sta   (MenuBarOrWindowPtr),y ; window status byte
      jsr   UpdateCachedWindowState
      jsr   ValidateWinfoStructure
      bcc   L7821          ; branch if valid
      rts
L7821:jsr   ClampWindowPosition
      jsr   DrawNewWindow
      rts
L7828:lda   #ErrBadWindowInfo
      sta   LastError
      rts
L782E:lda   #ErrWindowAlreadyOpen
      sta   LastError
      jsr   SelectCurrentWindow
      rts
.endproc

.proc LoadWindowPtrFromParamTable
      ldy   #$01
      lda   (ParamTablePtr),y
      sta   MenuBarOrWindowPtr
      iny
      lda   (ParamTablePtr),y
      sta   MenuBarOrWindowPtr+1
      rts
.endproc

;;; Size of save area needed to save window outline to backing store
;;; during drag or resize. This is checked by ValidateWinfoStructure
;;; to ensure that it is >= 2*content_width + 2*content_height, which
;;; is the product of the maximum window width and height.
ValidateWinfoStructureSaveBytesNeeded:
      .byte $00
WindowOptionBitHasVertScrollBarFlag:
      .byte $00
WindowOptionBitHasHorizScrollBarFlag:
      .byte $00
ValidateWinfoStructureMasks:
      .byte $02,$01        ; masks for testing the scrollbar bits
ValidateWinfoStructureMaxY:
      .byte $00

.proc ValidateWinfoStructure
      ldy   #$16
      ldx   #$01
L784D:lda   (MenuBarOrWindowPtr),y ; window status byte
      and   ValidateWinfoStructureMasks,x ; extract scrollbar presence bit
      beq   L7856 ; branch if scrollbar not present
      lda   #%10000000
L7856:sta   WindowOptionBitHasVertScrollBarFlag,x ; set scrollbar flag
      dex
      bpl   L784D
      lda   #$17           ; 23
      sta   ValidateWinfoStructureMaxY
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000001             ; is alert/dialog?
      beq   L786C                  ; branch if no
      inc   ValidateWinfoStructureMaxY ; add 1 since no title bar
L786C:ldy   #$0B
      lda   (MenuBarOrWindowPtr),y ; max content width
      cmp   #$51
      bcs   L78B7 ; branch if >= 81 (it's invalid)
      asl   a
      sta   ValidateWinfoStructureSaveBytesNeeded ; 2 * max content width
      ldy   #$0D
      lda   (MenuBarOrWindowPtr),y ; max content height
      cmp   ValidateWinfoStructureMaxY
      bcs   L78B7; branch if > max y (it's invalid)
      asl   a ; multiply by 2
      clc
      adc   ValidateWinfoStructureSaveBytesNeeded ; add to BytesNeeded
      sta   ValidateWinfoStructureSaveBytesNeeded
      lda   ReservedMemAreaSize+1 ; see if BytesNeeded is enough
      bne   L7896
      lda   ReservedMemAreaSize
      cmp   ValidateWinfoStructureSaveBytesNeeded
      bcc   L78BB ; no - it's too small
L7896:ldy   #$0A
      lda   (MenuBarOrWindowPtr),y ; min content width
      tax
      bit   WindowOptionBitHasVertScrollBarFlag
      bmi   L78A2 ; branch if yes
      inx   ; add 2 to width if no v. scroll bar
      inx
L78A2:cpx   #$03
      bcc   L78B7 ; branch if < 3 (it's invalid)
      ldy   #$0C
      lda   (MenuBarOrWindowPtr),y ; min content length
      tax
      bit   WindowOptionBitHasHorizScrollBarFlag
      bmi   L78B1 ; branch if yes
      inx                  ; add 1 to length if no h. scroll bar
L78B1:cpx   #$02
      bcc   L78B7 ; branch if < 2 (it's invalid)
      clc   ; validated successfully
      rts
L78B7:lda   #ErrBadWindowInfo
      bne   L78BD ; branch always taken
L78BB:lda   #ErrWindowBufferTooSmall
L78BD:sta   LastError
      sec
      rts
.endproc

;;; Draws a window and links it at the head of the list of windows.
.proc DrawNewWindow
      jsr   RedrawCurrentWindowAsInactive
      jsr   LinkWindowAtHead
      jsr   SetWindowScreenAreaCovered
      jsr   DrawWindow
      rts
.endproc

.proc RedrawCurrentWindowAsInactive
      lda   MenuBarOrWindowPtr ; save window ptr on stack
      pha
      lda   MenuBarOrWindowPtr+1
      pha
      jsr   GetFrontWindow
      bcs   L78E8 ; no windows open?
      lda   #$00
      sta   WindowPtrIsAtFrontWindowFlag
      jsr   CacheWindowAndScrollBarGeometry
      jsr   DrawWindowFrame
      jsr   DrawRightAndBottomEdgesOfInactiveWindow
L78E8:pla   ; restore window ptr from stack
      sta   MenuBarOrWindowPtr+1
      pla
      sta   MenuBarOrWindowPtr
      jsr   CacheWindowContentSizeAdjustedForScrollBars
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $18 (24)
;;; ----------------------------------------
.proc CloseWindow
      jsr   FindWindowByIDInParamTable
      bcc   FOUND
      rts
FOUND:jsr   CloseCurrentWindow
      jsr   DrawWindowsBackToFront
      rts
.endproc

CloseAllWindows1:
      jsr   CloseCurrentWindow
      ; falls through...

;;; ----------------------------------------
;;; ToolKit call $10 (16)
;;; ----------------------------------------
CloseAllWindows:
      jsr   GetFrontWindow
      bcc   CloseAllWindows1
      rts

.proc CloseCurrentWindow
      jsr   UnlinkWindow
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%01111111 ; clear window-is-open flag
      sta   (MenuBarOrWindowPtr),y
      jsr   EraseWindow
      rts
.endproc

WindowID:
      .byte $00

FindWindowByIDInParamTable:
      ldy   #$01
      lda   (ParamTablePtr),y ; window ID
FindWindowByIDInA:
      sta   WindowID
      jsr   GetFrontWindow
      bcs   L7937 ; no more windows
      lda   WindowID
      beq   L7940 ; if param was 0, returning front window's ID
L7929:ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; window ID
      cmp   WindowID
      beq   L793D ; if they match, window found
      jsr   NextWindow ; otherwise continue with next window
      bcc   L7929
L7937:lda   #ErrInvalidWindowID
      sta   LastError
      rts
L793D:jsr   CacheWindowContentSizeAdjustedForScrollBars
L7940:clc
      rts

.proc GetFrontWindowOrFail
      jsr   GetFrontWindow
      bcc   OUT
      lda   #ErrNoWindows
      sta   LastError
OUT:  rts
.endproc

.proc GetFrontWindow
      lda   FrontWindowPtr
      sta   MenuBarOrWindowPtr
      lda   FrontWindowPtr+1
      sta   MenuBarOrWindowPtr+1
      jmp   FinishNextOrPrevWindow
.endproc

.proc GetLastWindow
      lda   LastWindowPtr
      sta   MenuBarOrWindowPtr
      lda   LastWindowPtr+1
      sta   MenuBarOrWindowPtr+1
      jmp   FinishNextOrPrevWindow
.endproc

NextWindow:
      ldy   #$18
      jmp   FollowWindowLink
PrevWindow:
      ldy   #$1A
FollowWindowLink:
      lda   (MenuBarOrWindowPtr),y
      tax
      iny
      lda   (MenuBarOrWindowPtr),y
      stx   MenuBarOrWindowPtr
      sta   MenuBarOrWindowPtr+1
      jmp   FinishNextOrPrevWindow

.proc FinishNextOrPrevWindow
      lda   MenuBarOrWindowPtr
      bne   L7985
      lda   MenuBarOrWindowPtr+1
      bne   L7985
      sec
      rts
L7985:jsr   CacheWindowContentSizeAdjustedForScrollBars
      clc
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $1B (27)
;;; ----------------------------------------
.proc FrontWindow
      jsr   GetFrontWindow
      bcc   L7993
      lda   #$00
      beq   L7997 ; branch always taken
L7993:ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; Window ID
L7997:ldy   #$01
      sta   (ParamTablePtr),y
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $1C (28)
;;; ----------------------------------------
.proc SelectWindow
      jsr   FindWindowByIDInParamTable
      bcc   SelectCurrentWindow
      rts
.endproc

.proc SelectCurrentWindow
      jsr   IsWindowPtrAtFrontWindow
      bit   WindowPtrIsAtFrontWindowFlag
      bmi   OUT  ; branch if yes
      jsr   UnlinkWindow
      jsr   DrawNewWindow
OUT:  rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $20 (32)
;;; ----------------------------------------
.proc WindowToScreen
      jsr   FindWindowByIDInParamTable
      bcc   L79B7          ; branch if found
      rts
L79B7:ldy   #$02
L79B9:lda   (ParamTablePtr),y ; window coordinates
      sta   WindowCoordinatesX-2,y
      iny
      cpy   #$06
      bcc   L79B9
      jsr   ConvertWindowCoordToScreenCoord
      ldy   #$06
L79C8:lda   WindowCoordinatesX-2,y
      sta   (ParamTablePtr),y
      iny
      cpy   #$0A
      bcc   L79C8
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $21 (33)
;;; ----------------------------------------
.proc ScreenToWindow
      jsr   FindWindowByIDInParamTable
      bcc   L79D9 ; branch if found
      rts
L79D9:ldy   #$02
L79DB:lda   (ParamTablePtr),y
      sta   WindowCoordinatesY,y
      iny
      cpy   #$06
      bcc   L79DB
      jsr   ConvertScreenCoordToWindowCoord
      ldy   #$06
L79EA:lda   LastWindowPtr,y
      sta   (ParamTablePtr),y
      iny
      cpy   #$0A
      bcc   L79EA
      rts
.endproc

;;; Converts the window coordinates to screen
;;; coordinates by adding the window's origin
;;; (top-left corner) from them.
.proc ConvertWindowCoordToScreenCoord
      ldx   #$00
      ldy   #$04
      jsr   L79FE
      inx
      iny
L79FE:clc
      lda   WindowCoordinatesX,x
      adc   (MenuBarOrWindowPtr),y
      sta   ScreenCoordinatesX,x
      inx
      iny
      lda   WindowCoordinatesX,x
      adc   (MenuBarOrWindowPtr),y
      sta   ScreenCoordinatesX,x
      rts
.endproc

;;; Converts the screen coordinates to window
;;; coordinates by subtracting the window's origin
;;; (top-left corner) from them.
.proc ConvertScreenCoordToWindowCoord
      ldx   #$00
      ldy   #$04
      jsr   L7A1B
      inx
      iny
L7A1B:sec
      lda   ScreenCoordinatesX,x
      sbc   (MenuBarOrWindowPtr),y
      sta   WindowCoordinatesX,x
      iny
      inx
      lda   ScreenCoordinatesX,x
      sbc   (MenuBarOrWindowPtr),y
      sta   WindowCoordinatesX,x
      rts
.endproc

.proc IsWindowPtrAtFrontWindow
      lda   MenuBarOrWindowPtr
      cmp   FrontWindowPtr
      bne   L7A41
      lda   MenuBarOrWindowPtr+1
      cmp   FrontWindowPtr+1
      bne   L7A41
      lda   #$80
      bne   L7A43 ; branch always taken
L7A41:lda   #$00
L7A43:sta   WindowPtrIsAtFrontWindowFlag
      rts
.endproc

.proc LinkWindowAtHead
      lda   FrontWindowPtr
      bne   L7A6B
      lda   FrontWindowPtr+1
      bne   L7A6B ; branch if current front window ptr is not null
      ldy   #$18
L7A53:sta   (MenuBarOrWindowPtr),y ; set next and prev pointers to null
      iny
      cpy   #$1C
      bcc   L7A53
      lda   MenuBarOrWindowPtr ; set front and last window ptrs to this window ptr
      sta   FrontWindowPtr
      sta   LastWindowPtr
      lda   MenuBarOrWindowPtr+1
      sta   FrontWindowPtr+1
      sta   LastWindowPtr+1
      rts
L7A6B:ldy   #$18 ; set window's next ptr to front window ptr
      lda   FrontWindowPtr
      sta   MenuBlockOrDocInfoPtr
      sta   (MenuBarOrWindowPtr),y
      iny
      lda   FrontWindowPtr+1 ; set temp ptr = front window ptr
      sta   MenuBlockOrDocInfoPtr+1
      sta   (MenuBarOrWindowPtr),y
      ldy   #$1A
      lda   MenuBarOrWindowPtr ; set old front window's prev ptr to this window
      sta   (MenuBlockOrDocInfoPtr),y
      sta   FrontWindowPtr
      lda   #$00
      sta   (MenuBarOrWindowPtr),y ; and this window's prev ptr to null
      iny
      sta   (MenuBarOrWindowPtr),y
      lda   MenuBarOrWindowPtr+1
      sta   (MenuBlockOrDocInfoPtr),y ; set front window ptr to this window
      sta   FrontWindowPtr+1
      rts
.endproc

UnlinkWindowNextWindowPtr:
      .word $0000
UnlinkWindowPrevWindowPtr:
      .word $0000

.proc UnlinkWindow
      ldy   #$18
      lda   (MenuBarOrWindowPtr),y ; pointer to next window
      sta   UnlinkWindowNextWindowPtr
      iny
      lda   (MenuBarOrWindowPtr),y
      sta   UnlinkWindowNextWindowPtr+1
      ldy   #$1A ; pointer to prev window
      lda   (MenuBarOrWindowPtr),y
      sta   UnlinkWindowPrevWindowPtr
      iny
      lda   (MenuBarOrWindowPtr),y
      sta   UnlinkWindowPrevWindowPtr+1
      lda   UnlinkWindowPrevWindowPtr
      sta   MenuBlockOrDocInfoPtr
      tax
      lda   UnlinkWindowPrevWindowPtr+1
      sta   MenuBlockOrDocInfoPtr+1 ; tmp ptr = prev window ptr
      bne   L7AD1
      txa
      bne   L7AD1
      lda   UnlinkWindowNextWindowPtr
      sta   FrontWindowPtr ; front window ptr = next window ptr
      lda   UnlinkWindowNextWindowPtr+1
      sta   FrontWindowPtr+1
      jmp   L7ADE
L7AD1:ldy   #$18 ; pointer to next window
      lda   UnlinkWindowNextWindowPtr
      sta   (MenuBlockOrDocInfoPtr),y ; tmp ptr = next window ptr
      iny
      lda   UnlinkWindowNextWindowPtr+1
      sta   (MenuBlockOrDocInfoPtr),y
L7ADE:lda   UnlinkWindowNextWindowPtr
      sta   MenuBlockOrDocInfoPtr
      tax
      lda   UnlinkWindowNextWindowPtr+1
      sta   MenuBlockOrDocInfoPtr+1
      bne   L7AFD
      txa
      bne   L7AFD
      lda   UnlinkWindowPrevWindowPtr
      sta   LastWindowPtr  ; last window ptr = prev window ptr
      lda   UnlinkWindowPrevWindowPtr+1
      sta   LastWindowPtr+1
      jmp   OUT
L7AFD:ldy   #$1A ; pointer to prev window
      lda   UnlinkWindowPrevWindowPtr
      sta   (MenuBlockOrDocInfoPtr),y ; tmp ptr = prev window ptr
      iny
      lda   UnlinkWindowPrevWindowPtr+1
      sta   (MenuBlockOrDocInfoPtr),y
OUT:   rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $2D (45)
;;; ----------------------------------------
.proc GetWinPtr
      jsr   FindWindowByIDInParamTable
      bcc   OK ; branch if found
      rts
OK:   ldy   #$02 ; copy window ptr to param table
      lda   MenuBarOrWindowPtr
      sta   (ParamTablePtr),y
      iny
      lda   MenuBarOrWindowPtr+1
      sta   (ParamTablePtr),y
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $1A (26)
;;; ----------------------------------------
.proc FindWindow
      ldy   #$00
      sty   ScreenCoordinatesX+1
      sty   ScreenCoordinatesY+1
      iny
      lda   (ParamTablePtr),y
      sta   ScreenCoordinatesX
      iny
      lda   (ParamTablePtr),y
      sta   ScreenCoordinatesY
      bne   L7B39
      ldx   #ControlAreaMenuBar ; y coord is 0
      lda   #$00
      beq   L7BA1 ; branch always taken
L7B39:jsr   GetFrontWindow
      bcc   L7B44
L7B3E:ldx   #ControlAreaDesktop ; no windows are open
      lda   #$00
      beq   L7BA1 ; branch always taken
L7B44:jsr   IsPointInWindow
      bcc   L7B85 ; no - skip rest to try next window
      lda   WindowCoordinatesY
      cmp   #$FF ; y-coord negative?
      bne   L7B62 ; branch if not
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000010 ; has close box?
      beq   L7B9B ; branch if not
      lda   WindowCoordinatesX
      bne   L7B9B ; if x != 0, it's not the close box
      ldx   #ControlAreaCloseBox
      jmp   L7B9D
L7B62:ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000100 ; has resize box?
      beq   L7B96 ; branch if not
      ldx   WindowCoordinatesX
      inx
      txa
      ldy   #$08
      cmp   (MenuBarOrWindowPtr),y ; current content width
      bne   L7B96
      ldx   WindowCoordinatesY ; x != content width, then it's not the resize box
      inx
      txa
      ldy   #$09
      cmp   (MenuBarOrWindowPtr),y ; current content length
      bne   L7B96 ; y != content length, then it's not the resize box
      ldx   #ControlAreaResizeBox
      jmp   L7B9D
L7B85:jsr   NextWindow ; try next window
      bcs   L7B3E ; branch if no more windows
      jsr   IsPointInWindow
      bcc   L7B85
      lda   WindowCoordinatesY
      cmp   #$FF  ; y == -1 ?
      beq   L7B9B ; branch if yes
L7B96:ldx   #ControlAreaContentRegion
      jmp   L7B9D
L7B9B:ldx   #ControlAreaDragRegion ; in window title bar
L7B9D:ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; set window ID in params
L7BA1:ldy   #$04
      sta   (ParamTablePtr),y
      txa
      dey
      sta   (ParamTablePtr),y ; set control area in params
      rts
.endproc

IsPointInWindowMinYCoord:
      .byte $00 ; 0 for dialog/alert, -1 for window

;;; Returns with Carry set if point is within window.
.proc IsPointInWindow
      jsr   ConvertScreenCoordToWindowCoord
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000001 ; is dialog/alert box?
      beq   L7BBA ; branch if no
      lda   #$00
      beq   L7BBC ; branch always taken
L7BBA:lda   #$FF ; -1
L7BBC:sta   IsPointInWindowMinYCoord
      lda   WindowCoordinatesX+1
      bne   OUTS ; branch if x-coord is negative
      lda   WindowCoordinatesX
      ldy   #$08
      cmp   (MenuBarOrWindowPtr),y ; window content width
      bcs   OUTS ; branch if x-coord >= content width
      lda   WindowCoordinatesY
      cmp   IsPointInWindowMinYCoord
      beq   INS ; branch if y-coord == minimum y coord
      ldy   #$09 ; window content height
      cmp   (MenuBarOrWindowPtr),y
      bcs   OUTS  ; branch if content height >= y-coord
INS:  sec ; point is within window
      rts
OUTS: clc ; point is outside window
      rts
.endproc

TrackGoAwaySavedCursorChar:
           .byte $00

;;; ----------------------------------------
;;; ToolKit call $1D (29)
;;; ----------------------------------------
.proc TrackGoAway
      jsr   GetFrontWindowOrFail
      bcc   L7BE6
      rts
L7BE6:lda   #TrackingModeCloseBox
      sta   MouseTrackingMode
      lda   CursorChar
      sta   TrackGoAwaySavedCursorChar
      lda   #$00
      sta   WindowCoordinatesX ; x-coord = 0
      sta   WindowCoordinatesX+1
      lda   #$FF
      sta   WindowCoordinatesY ; y-coord = -1
      sta   WindowCoordinatesY+1
      sta   MouseDragTrackingLastXCoord
      jsr   ConvertWindowCoordToScreenCoord
L7C07:jsr   MouseDragTrackingRoutine
      bcs   L7C29 ; drag ended
      lda   EventBuffer2XCoord
      cmp   ScreenCoordinatesX
      bne   L7C20 ; branch if x-coord changed
      lda   EventBuffer2YCoord
      cmp   ScreenCoordinatesY
      bne   L7C20 ; branch if y-coord changed
      lda   #CharInvAsterisk
      bne   L7C23 ; branch always taken
L7C20:lda   TrackGoAwaySavedCursorChar
L7C23:jsr   ChangeCursorChar
      jmp   L7C07
L7C29:lda   TrackGoAwaySavedCursorChar
      jsr   ChangeCursorChar
      lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      bne   L7C4A
      lda   EventBuffer2XCoord ; did coordinates change?
      cmp   ScreenCoordinatesX
      bne   L7C4A
      lda   EventBuffer2YCoord
      cmp   ScreenCoordinatesY
      bne   L7C4A
      lda   #$01 ; window size did change
      bne   L7C4C ; branch always taken
L7C4A:lda   #$00 ; window size didn't change
L7C4C:ldy   #$01
      sta   (ParamTablePtr),y ; set result value
      lda   #TrackingModeNone
      sta   MouseTrackingMode
      rts
.endproc

.proc RecordDragStartPosition
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000001 ; is dialog/alert?
      bne   ERR ; return with failure if yes
      php
      sei
      ldy   #$06
      lda   (MenuBarOrWindowPtr),y ; window y-coord
      sec
      sbc   #$01 ; decrement y-coord
      sta   MouseYCoord
      ldy   #$03
      sta   (ParamTablePtr),y ; save in param table
      ldy   #$04
      lda   (MenuBarOrWindowPtr),y ; window x-coord
      bpl   L7C78 ; branch if positive
      lda   #$00 ; otherwise set x-coord to 0
      beq   L7C7D ; branch always taken
L7C78:lda   #$01
      clc
      adc   (MenuBarOrWindowPtr),y ; increment x-coord
L7C7D:sta   MouseXCoord
      ldy   #$02
      sta   (ParamTablePtr),y ; save in param table
      jsr   SetMousePosition
      plp
      clc
      rts
ERR:  sec
      rts
.endproc

WindowDragStartXCoord:
      .byte $00
WindowDragStartYCoord:
      .byte $00
WindowDragWindowXCoord1:
      .word $0000
WindowDragWindowYCoord1:
      .word $0000
WindowDragWindowXCoord2:
      .word $0000
WindowDragWindowYCoord2:
      .word $0000

;;; ----------------------------------------
;;; ToolKit call $1E (30)
;;; ----------------------------------------
.proc DragWindow
      jsr   FindWindowByIDInParamTable
      bcs   L7CA5 ; window not found
      bit   MouseEmulationFlags
      bvc   L7CB6 ; branch if Keyboard Mouse Mode off
      jsr   RecordDragStartPosition
      bcc   L7CB6
L7CA5:jsr   PlayTone::PlayTone1 ; fail if trying to drag alert/dialog
      lda   #ErrCallFailed
      sta   LastError
      bit   MouseEmulationFlags
      bvc   L7CB5 ; branch if Keyboard Mouse Mode off
      jmp   ProcessKeyboardMouseModeEvent::FinishKeyboardMouseMode
L7CB5:rts
L7CB6:ldy   #$02
      lda   (ParamTablePtr),y ; save x-coord of drag start
      sta   WindowDragStartXCoord
      sta   MouseDragTrackingLastXCoord
      iny
      lda   (ParamTablePtr),y ; save y-coord of drag start
      sta   WindowDragStartYCoord
      sta   MouseDragTrackingLastYCoord
      lda   #TrackingModeDragWindow
      sta   MouseTrackingMode
      ldy   #$04 ; save window's original coords in two buffers
L7CD0:lda   (MenuBarOrWindowPtr),y
      sta   WindowDragWindowXCoord1-4,y
      sta   WindowDragWindowXCoord2-4,y
      iny
      cpy   #$08
      bcc   L7CD0
      jsr   IsWindowPtrAtFrontWindow
      jsr   HideCursor
      jsr   DrawWindowOutline
      jsr   ShowCursor
L7CE9:jsr   MouseDragTrackingRoutine
      bcs   L7D00 ; branch if drag done
      jsr   UndrawWindowOutline
      jsr   UpdateWindowPosForDrag
      jsr   HideCursor
      jsr   DrawWindowOutline
      jsr   ShowCursor
      jmp   L7CE9
L7D00:jsr   UndrawWindowOutline
      lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      bne   L7D2B ; branch if drag was canceled
      ldy   #$04
      lda   WindowDragWindowXCoord2
      cmp   (MenuBarOrWindowPtr),y ; x-coord changed?
      bne   L7D1C
      ldy   #$06
      lda   WindowDragWindowYCoord2
      cmp   (MenuBarOrWindowPtr),y ; y-coord changed?
      beq   L7D3A
L7D1C:jsr   UpdateWindowPosForDrag ; window position did change
      jsr   LoadWindowClipRect
      jsr   EraseWindowRegionNoClip
      jsr   DrawWindowsBackToFront
      jmp   L7D3A
L7D2B:ldx   #$00
      ldy   #$04
L7D2F:lda   WindowDragWindowXCoord2,x ; update window with final position
      sta   (MenuBarOrWindowPtr),y
      iny
      inx
      cpx   #$04
      bcc   L7D2F
L7D3A:lda   #TrackingModeNone
      sta   MouseTrackingMode
      rts
.endproc

WindowDragXCoordDelta:
      .word $0000

;;; Calculates the delta between the window start position (in screen
;;; coordinates) and the final event coordinates, and adds that delta
;;; to the window's position. Only one byte is needed for the y-delta
;;; since a window's y coordinate absolutely must be between 0 and 23
;;; inclusive.
.proc UpdateWindowPosForDrag
      ldx   #$00
      sec
      lda   EventBuffer2XCoord
      sbc   WindowDragStartXCoord
      sta   WindowDragXCoordDelta
      bcs   L1
      dex
L1:   stx   WindowDragXCoordDelta+1
      clc
      adc   WindowDragWindowXCoord1
      ldy   #$04
      sta   (MenuBarOrWindowPtr),y ; window x-coord (lo)
      iny
      txa
      adc   WindowDragWindowXCoord1+1
      sta   (MenuBarOrWindowPtr),y ; window x-coord (hi)
      ldy   #$06
      sec
      lda   EventBuffer2YCoord
      sbc   WindowDragStartYCoord
      clc
      adc   WindowDragWindowYCoord1
      sta   (MenuBarOrWindowPtr),y ; window y-coord (lo)
      jsr   ClampWindowPosition
      ldy   #$04
      sec
      lda   (MenuBarOrWindowPtr),y ; window x-coord (lo)
      sbc   WindowDragXCoordDelta
      sta   WindowDragWindowXCoord1
      iny
      lda   (MenuBarOrWindowPtr),y ; window x-coord (hi)
      sbc   WindowDragXCoordDelta+1
      sta   WindowDragWindowXCoord1+1
      rts
.endproc

MinWindowYCoord:
      .byte $00 ; $01 if dialog, $02 if window

;;; Adjusts the window position if necessary, so that at least
;;;  one character of the title bar is on screen.
.proc ClampWindowPosition
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000001 ; is dialog/alert?
      beq   L7D97 ; branch if no
      lda   #$01
      bne   L7D99 ; branch always taken
L7D97:lda   #$02
L7D99:sta   MinWindowYCoord
      ldy   #$07
      lda   (MenuBarOrWindowPtr),y ; window y-coord (hi)
      bmi   L7DB4
      bne   L7DB0
      dey
      lda   (MenuBarOrWindowPtr),y ; window y-coord (lo)
      cmp   MinWindowYCoord
      bmi   L7DB4 ; branch if it's < min y-coord
      cmp   #$19 ; 25
      bmi   L7DC0 ; branch if it's <= max row
L7DB0:lda   #$18 ; set y-coord to max row
      bne   L7DB7 ; branch always taken
L7DB4:lda   MinWindowYCoord
L7DB7:ldy   #$06
      sta   (MenuBarOrWindowPtr),y ; window y-coord (lo)
      lda   #$00
      iny
      sta   (MenuBarOrWindowPtr),y ; set window y-coord (hi) to 0
L7DC0:ldy   #$05
      lda   (MenuBarOrWindowPtr),y ; window x-coord (hi)
      dey
      tax
      bmi   L7DDF ; branch if negative
      bne   L7DD1
      lda   (MenuBarOrWindowPtr),y ; window x-coord (lo)
      cmp   MaxColumnNumber
      bcc   OUT ; return if x-coord < max column
L7DD1:ldx   MaxColumnNumber
      dex
      txa
      sta   (MenuBarOrWindowPtr),y ; set x-coord (lo) to max column -1
      iny
      lda   #$00
      sta   (MenuBarOrWindowPtr),y ; set x-coord (hi) to 0
      beq   OUT ; branch always taken
L7DDF:cmp   #$FF ; -1
      bne   L7DF0
      lda   (MenuBarOrWindowPtr),y ; y=4; window x-coord (lo)
      bpl   L7DF0
      clc
      ldy   #$08
      adc   (MenuBarOrWindowPtr),y ; content width
      cmp   #$01 ; x-coord + content width >= 1?
      bpl   OUT ; branch if yes
L7DF0:ldy   #$08
      lda   #$01
      sec
      sbc   (MenuBarOrWindowPtr),y ; 1 - content width
      ldy   #$04
      sta   (MenuBarOrWindowPtr),y ; window x-coord (lo)
      iny
      lda   #$FF  ; -1
      sta   (MenuBarOrWindowPtr),y ; window x-coord (hi)
OUT:  rts
.endproc

GrowWindowInitialWidth:
      .byte $00
GrowWindowInitialHeight:
      .byte $00
GrowWindowRightXCoord:
      .byte $00
GrowWindowBottomYCoord:
      .byte $00
GrowWindowXDelta:
      .byte $00
GrowWindowYDelta:
      .byte $00
GrowWindowSizeChangedFlag:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $1F (31)
;;; ----------------------------------------
.proc GrowWindow
      jsr   GetFrontWindowOrFail
      bcs   L7E34 ; no windows open
      ldy   #$01
      lda   #$00
      sta   (ParamTablePtr),y
      sta   WindowCoordinatesX+1 ; set high byte of coordinates
      sta   WindowCoordinatesY+1 ; to 0
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000100 ; has resize box?
      beq   L7E34 ; branch to failure handler if no
      ldy   #$08
      lda   (MenuBarOrWindowPtr),y ; current content width
      sta   GrowWindowInitialWidth
      ldy   #$09
      lda   (MenuBarOrWindowPtr),y ; current content length
      sta   GrowWindowInitialHeight
      jsr   SetMousePositionForWindowResize
      bcc   L7E45
L7E34:jsr   PlayTone::PlayTone1
      lda   #ErrCallFailed
      sta   LastError
      bit   MouseEmulationFlags ; turn off keyboard mouse mode if on
      bvc   L7E44 ; branch if Keyboard Mouse Mode off
      jmp   ProcessKeyboardMouseModeEvent::FinishKeyboardMouseMode
L7E44:rts
L7E45:lda   ScreenCoordinatesX ; save resize start pos (coord of resize box)
      sta   GrowWindowRightXCoord
      sta   MouseDragTrackingLastXCoord
      lda   ScreenCoordinatesY
      sta   GrowWindowBottomYCoord
      sta   MouseDragTrackingLastYCoord
      jsr   IsWindowPtrAtFrontWindow
      jsr   HideCursor
      jsr   DrawWindowOutline
      jsr   ShowCursor
      lda   #TrackingModeResizeWindow
      sta   MouseTrackingMode
L7E68:jsr   MouseDragTrackingRoutine
      bcs   L7E82 ; branch if drag finished
      jsr   UndrawWindowOutline
      jsr   UpdateWindowSizeAfterResize
      jsr   SetMousePositionForWindowResize
      jsr   HideCursor
      jsr   DrawWindowOutline
      jsr   ShowCursor
      jmp   L7E68
L7E82:jsr   UndrawWindowOutline
      lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      bne   L7EBC ; cancel operation
      lda   GrowWindowRightXCoord
      cmp   MouseDragTrackingLastXCoord
      bne   L7E9C
      lda   GrowWindowBottomYCoord
      cmp   MouseDragTrackingLastYCoord
      beq   L7ECD ; branch if size didn't change
L7E9C:jsr   UpdateWindowSizeAfterResize
      jsr   LoadWindowClipRect
      jsr   EraseWindowRegionNoClip
      jsr   CacheWindowAndScrollBarGeometry
      ldy   #$01
      tya
      sta   (ParamTablePtr),y ; set size changed param value
      lda   #$80
      sta   GrowWindowSizeChangedFlag ; window size did change
      jsr   DrawWindowsBackToFront
      lda   #$00
      sta   GrowWindowSizeChangedFlag ; window size did not change
      beq   L7ECD ; branch always taken
L7EBC:ldy   #$08
      lda   GrowWindowInitialWidth
      sta   (MenuBarOrWindowPtr),y ; restore initial width
      ldy   #$09
      lda   GrowWindowInitialHeight
      sta   (MenuBarOrWindowPtr),y ; restore initial height
      jsr   CacheWindowContentSizeAdjustedForScrollBars
L7ECD:lda   #TrackingModeNone
      sta   MouseTrackingMode
      rts
.endproc

.proc UpdateWindowSizeAfterResize
      sec
      lda   EventBuffer2XCoord
      sbc   GrowWindowRightXCoord
      sta   GrowWindowXDelta
      clc
      adc   GrowWindowInitialWidth
      ldy   #$08
      sta   (MenuBarOrWindowPtr),y ; window content width
      sec
      lda   EventBuffer2YCoord
      sbc   GrowWindowBottomYCoord
      sta   GrowWindowYDelta
      clc
      adc   GrowWindowInitialHeight
      ldy   #$09
      sta   (MenuBarOrWindowPtr),y ; window content height
      jsr   ClampWindowSize
      rts
.endproc

;;; Returns with Carry set on failure. Sets the screen coordinates,
;;; (and, if keyboard mouse mode is on, the mouse position) to the
;;; coordinates of the window's resize box.
.proc SetMousePositionForWindowResize
      ldy   #$08
      lda   (MenuBarOrWindowPtr),y ; window content width
      sta   WindowCoordinatesX
      dec   WindowCoordinatesX
      ldy   #$09
      lda   (MenuBarOrWindowPtr),y ; window content height
      sta   WindowCoordinatesY
      dec   WindowCoordinatesY
      jsr   ConvertWindowCoordToScreenCoord
      ldx   ScreenCoordinatesX
      ldy   ScreenCoordinatesY
      cpx   MaxColumnNumber
      beq   L7F1F
      bcs   OUT ; x > max col? return with failure
L7F1F:cpy   #$18
      bcs   OUT ; y >= max row? return with failure
      cpx   MouseXCoord
      bne   L7F2D
      cpy   EventBuffer2YCoord
      beq   L7F3E
L7F2D:bit   MouseEmulationFlags
      bpl   L7F3E ; don't update mouse coord if not in Safety-Net mode
      php
      sei
      stx   MouseXCoord
      sty   MouseYCoord
      jsr   SetMousePosition
      plp
L7F3E:clc
OUT:  rts
.endproc

.proc ClampWindowSize
      ldy   #$08
      lda   (MenuBarOrWindowPtr),y ; window content width
      ldy   #$0A
      cmp   (MenuBarOrWindowPtr),y ; window min content width
      bcc   L7F52 ; branch if current < min
      ldy   #$0B
      cmp   (MenuBarOrWindowPtr),y ; window max content width
      bcc   L7F64 ; branch if current < max
      beq   L7F64 ; or current == max
L7F52:bit   GrowWindowXDelta
      bmi   L7F5C ; branch if window shrank horizontally
      ldy   #$0B
      jmp   L7F5E ; max content width
L7F5C:ldy   #$0A
L7F5E:lda   (MenuBarOrWindowPtr),y ; min content width
      ldy   #$08
      sta   (MenuBarOrWindowPtr),y ; current content width
L7F64:ldy   #$09
      lda   (MenuBarOrWindowPtr),y ; current content length
      ldy   #$0C
      cmp   (MenuBarOrWindowPtr),y ; min content length
      bcc   L7F76 ; branch if current < min
      ldy   #$0D
      cmp   (MenuBarOrWindowPtr),y ; max content length
      bcc   L7F88 ; branch if current < max
      beq   L7F88 ; or current == max
L7F76:bit   GrowWindowYDelta
      bmi   L7F80 ; branch if window shrank vertically
      ldy   #$0D ; max content length
      jmp   L7F82
L7F80:ldy   #$0C
L7F82:lda   (MenuBarOrWindowPtr),y ; min content length
      ldy   #$09
      sta   (MenuBarOrWindowPtr),y ; content length
L7F88:jsr   CacheWindowContentSizeAdjustedForScrollBars
      rts
.endproc

;;; Set during DrawWindowsBackToFront and tested by
;;; CalcColumnsObscuredInWindowRow.
RedrawingAllWindowsFlag:
      .byte $00
RedrawingAllWindowsSavedWindowPtr:
      .word $0000

.proc DrawWindowsBackToFront
      lda   #$80
      sta   RedrawingAllWindowsFlag
      lda   MenuBarOrWindowPtr ; save current window ptr
      sta   RedrawingAllWindowsSavedWindowPtr
      lda   MenuBarOrWindowPtr+1
      sta   RedrawingAllWindowsSavedWindowPtr+1
      jsr   SetDesktopClipRectToWindowScreenAreaCovered
      jsr   GetLastWindow
      bcs   L7FC7 ; no other windows; done
L7FA6:lda   MenuBarOrWindowPtr
      cmp   RedrawingAllWindowsSavedWindowPtr
      bne   L7FB4
      lda   MenuBarOrWindowPtr+1
      cmp   RedrawingAllWindowsSavedWindowPtr+1
      beq   L7FBC ; branch if reached current window
L7FB4:jsr   IsWindowPtrAtFrontWindow
      bit   WindowPtrIsAtFrontWindowFlag
      bpl   L7FBF ; branch if current window isn't front window
L7FBC:jsr   CalcDesktopClipRect
L7FBF:jsr   DrawWindow
      jsr   PrevWindow ; continue with previous (next higher) window
      bcc   L7FA6
L7FC7:jsr   CalcDesktopClipRect
      lda   RedrawingAllWindowsSavedWindowPtr ; restore current window ptr
      sta   MenuBarOrWindowPtr
      lda   RedrawingAllWindowsSavedWindowPtr+1
      sta   MenuBarOrWindowPtr+1
      jsr   SetWindowScreenAreaCovered
      lda   #$00
      sta   RedrawingAllWindowsFlag
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $24 (36)
;;; ----------------------------------------
.proc WinBlock
      jsr   FindWindowByIDInParamTable
      bcc   OK
      rts
OK:   ldy   #$02 ; copy doc pointer from param table
      lda   (ParamTablePtr),y
      sta   MenuBlockOrDocInfoPtr
      iny
      lda   (ParamTablePtr),y
      sta   MenuBlockOrDocInfoPtr+1
      iny
      ldx   #$00 ; copy start & stop coordinates for window text rect
L7FF1:lda   (ParamTablePtr),y
      sta   WindowTextBlockStartX,x
      iny
      inx
      cpx   #$08
      bcc   L7FF1
      ldx   #$02
L7FFE:inc   WindowTextBlockEndX,x ; increment ex,ey to ex+1,ey+1
      bne   L8006
      inc   WindowTextBlockEndX+1,x
L8006:dex
      dex
      beq   L7FFE
      jsr   ClampWindowTextBlock
      jsr   CalculateWindowTextBoxClipRect
      lda   MenuBlockOrDocInfoPtr+1
      beq   L8018 ; branch if doc pointer is null
      jsr   OutputCurrentDocumentInWindow
      rts
L8018:jmp   DrawWindowContents1
.endproc

.proc LoadTextBlockCoordsFromParamTable
      jsr   LoadTextBlockStartXFromParamTable
      jsr   LoadTextBlockStartYFromParamTable
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $22 (34)
;;; ----------------------------------------
.proc WinChar
      jsr   FindWindowByIDInParamTable
      bcc   OK
      rts
OK:   jsr   ResetWindowTextBlock
      jsr   LoadTextBlockCoordsFromParamTable
      ldy   #$06
      lda   (ParamTablePtr),y ; char to write
      jsr   RemapChar
      sta   CharRegister
      jsr   ClampWindowTextBlock
      jsr   CalculateWindowTextBoxClipRect
      lda   WindowClipRectWidth ; if char position is outside window
      beq   OUT ; clip rect, then return
      lda   WindowClipRectHeight
      beq   OUT
      lda   WindowTextBoxClipRectVisibleOffsetX
      ora   WindowClipRectVisibleOffsetX
      ora   WindowTextBoxClipRectVisibleOffsetY
      ora   WindowClipRectVisibleOffsetY
      bne   OUT
      lda   WindowClipRectStartY
      sta   CurrentYCoord
      jsr   CalcColumnsObscuredInWindowRow
      ldx   WindowClipRectStartX
      stx   CurrentXCoord
      lda   ColumnFlags,x
      bpl   OUT ; branch if cell obscured by other windows
      jsr   PrintCharAtCurrentCoord
OUT:  rts
.endproc

.proc ClearWindowContentArea
      jsr   ResetWindowTextBlock
      jsr   EraseWindowRegionNoClamp
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $25 (37)
;;; ----------------------------------------
.proc WinOp
      jsr   FindWindowByIDInParamTable
      bcc   OK
      rts
OK:   ldy   #$06
      lda   (ParamTablePtr),y ; window operation type
      cmp   #WinOpClearToStartOfWindow
      beq   ClearToStartOfWindow
      cmp   #WinOpClearToStartOfLine
      beq   ClearToStartOfLine
      cmp   #WinOpClearWindow
      beq   ClearWindowContentArea
      cmp   #WinOpClearToEndOfWindow
      beq   ClearToEndOfWindow
      cmp   #WinOpClearLine
      beq   ClearLine
      cmp   #WinOpClearToEndOfLine
      beq   ClearToEndOfLine
      rts
.endproc

.proc ClearToEndOfWindow
      jsr   ClearToEndOfLine
      jsr   ResetWindowTextBlock
      jsr   LoadTextBlockStartYFromParamTable
      inc   WindowTextBlockStartY
      bne   L1
      inc   WindowTextBlockStartY+1
L1:   jsr   EraseWindowRegion
      rts
.endproc

.proc ClearToStartOfWindow
      jsr   ResetWindowTextBlock
      jsr   LoadTextBlockEndYFromParamTable
      jsr   EraseWindowRegion
      jsr   ClearToStartOfLine
      rts
.endproc

.proc ClearLine
      jsr   SetWindowTextBlockEndYToNextLine
      jsr   EraseWindowRegion
      rts
.endproc

.proc ClearToEndOfLine
      jsr   SetWindowTextBlockEndYToNextLine
      jsr   LoadTextBlockStartXFromParamTable
      jsr   EraseWindowRegion
      rts
.endproc

.proc ClearToStartOfLine
      jsr   SetWindowTextBlockEndYToNextLine
      jsr   LoadTextBlockEndXFromParamTable
      jsr   EraseWindowRegion
      rts
.endproc

.proc SetWindowTextBlockEndYToNextLine
      jsr   ResetWindowTextBlock
      jsr   LoadTextBlockStartYFromParamTable
      clc
      lda   WindowTextBlockStartY
      adc   #$01
      sta   WindowTextBlockEndY
      lda   WindowTextBlockStartY+1
      adc   #$00
      sta   WindowTextBlockEndY+1
      rts
.endproc

.proc LoadTextBlockStartXFromParamTable
      ldy   #$02
      lda   (ParamTablePtr),y
      sta   WindowTextBlockStartX
      iny
      lda   (ParamTablePtr),y
      sta   WindowTextBlockStartX+1
      rts
.endproc

.proc LoadTextBlockStartYFromParamTable
      ldy   #$04
      lda   (ParamTablePtr),y
      sta   WindowTextBlockStartY
      iny
      lda   (ParamTablePtr),y
      sta   WindowTextBlockStartY+1
      rts
.endproc

.proc LoadTextBlockEndXFromParamTable
      ldy   #$02
      lda   (ParamTablePtr),y
      sta   WindowTextBlockEndX
      iny
      lda   (ParamTablePtr),y
      sta   WindowTextBlockEndX+1
      rts
.endproc

.proc LoadTextBlockEndYFromParamTable
      ldy   #$04
      lda   (ParamTablePtr),y
      sta   WindowTextBlockEndY
      iny
      lda   (ParamTablePtr),y
      sta   WindowTextBlockEndY+1
      rts
.endproc

LengthOfStringToOutput:
      .byte $00
StartIndexOfStringToOutput:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $23 (35)
;;; ----------------------------------------
.proc WinString
      jsr   ProcessWinTextParams
      bcs   OUT
      lda   (ParamTablePtr),y ; number of chars to display (must be 0)
      sta   MenuOrWindowOptionByte
      jsr   MaybeOffsetTextStringPtr
      ldy   #$00
      lda   (TextStringPtr),y ; get string length
      sta   LengthOfStringToOutput
      jsr   MaybeDerefTextStringPtr
      inc   TextStringPtr
      bne   L1
      inc   TextStringPtr+1 ; increment ptr past length
L1:   jsr   OutputClippedTextStringInWindow
OUT:  rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $26 (38)
;;; ----------------------------------------
.proc WinText
      jsr   ProcessWinTextParams
      bcs   OUT
      lda   (ParamTablePtr),y ; get string length
      sta   LengthOfStringToOutput
      jsr   OutputClippedTextStringInWindow
OUT:  rts
.endproc

.proc ProcessWinTextParams
      jsr   FindWindowByIDInParamTable
      bcs   ERR
      jsr   ResetWindowTextBlock
      jsr   LoadTextBlockCoordsFromParamTable
      jsr   ClampWindowTextBlock
      jsr   CalculateWindowTextBoxClipRect
      lda   WindowClipRectWidth
      beq   ERR
      lda   WindowClipRectHeight
      beq   ERR
      ldy   #$06
      lda   (ParamTablePtr),y ; ptr to text (lo)
      sta   TextStringPtr
      iny
      lda   (ParamTablePtr),y ; ptr to text (hi)
      sta   TextStringPtr+1
      iny
      clc
      rts
ERR:  sec
      rts
.endproc

.proc OutputClippedTextStringInWindow
      lda   WindowClipRectVisibleOffsetY
      ora   WindowTextBoxClipRectVisibleOffsetY
      bne   OUT
      clc
      lda   WindowClipRectVisibleOffsetX
      adc   WindowTextBoxClipRectVisibleOffsetX
      sta   StartIndexOfStringToOutput
      clc
      lda   TextStringPtr
      adc   StartIndexOfStringToOutput
      sta   TextStringPtr
      bcc   L819F
      inc   TextStringPtr+1
L819F:lda   LengthOfStringToOutput
      cmp   StartIndexOfStringToOutput
      bcc   OUT
      beq   OUT
      sec
      sbc   StartIndexOfStringToOutput
      sta   LengthOfTextToOutput
      lda   WindowClipRectStartY
      sta   CurrentYCoord
      clc
      lda   WindowClipRectStartX
      sta   CurrentXCoord
      adc   LengthOfTextToOutput
      cmp   WindowClipRectEndXPlus1
      bcc   L81CB
      lda   WindowClipRectWidth
      sta   LengthOfTextToOutput
L81CB:jsr   OutputTextStringInWindow
OUT:  rts
.endproc

.proc OutputRepeatedChar
      tya ; save x and y on stack
      pha
      txa
      pha
      jsr   CalcColumnsObscuredInWindowRow
      lda   #$00
      sta   TextOutputCounter
      jsr   CalcTextRowBaseAddr
LOOP: ldy   TextOutputCounter
      cpy   LengthOfTextToOutput
      bcs   DONE
      inc   TextOutputCounter
      ldx   CurrentXCoord
      lda   ColumnFlags,x
      bpl   SKIP ; skip if column obscured
      lda   CharRegister
      jsr   PrintCharInA
SKIP: inc   CurrentXCoord
      jmp   LOOP
DONE: pla   ; restore x and y
      tax
      pla
      tay
      rts
.endproc

OutputTextStringInWindow:
      lda   #$00
      beq   L8208 ; branch always taken

OutputInverseTextStringInWindow: ; never called
      lda   #$80
L8208:sta   InverseTextFlag
      tya ; save x and y on stack
      pha
      txa
      pha
      jsr   CalcColumnsObscuredInWindowRow
      lda   #$00
      sta   TextOutputCounter
      jsr   CalcTextRowBaseAddr
L821A:ldy   TextOutputCounter
      cpy   LengthOfTextToOutput
      bcs   L823E
      ldx   CurrentXCoord
      lda   ColumnFlags,x
      bpl   L8235 ; skip if column obscured
      lda   (TextStringPtr),y
      eor   InverseTextFlag
      jsr   RemapChar
      jsr   PrintCharInA
L8235:inc   TextOutputCounter
      inc   CurrentXCoord
      jmp   L821A
L823E:pla  ; restore x and y
      tax
      pla
      tay
      rts

;;; Erases the portion of the screen that was occupied by
;;; the current window (including its frame).
.proc EraseWindow
      jsr   SetWindowTextBlockToWindowBounds
      jsr   EraseWindowRegionNoClamp
      rts
.endproc

.proc DrawWindow
      jsr   IsWindowPtrAtFrontWindow
      jsr   DrawWindowFrame
      bit   WindowPtrIsAtFrontWindowFlag
      bpl   L8260 ; branch if no
      bit   GrowWindowSizeChangedFlag
      bpl   L8260 ; branch if no
      jsr   ClearWindowContentArea
      jmp   L8263
L8260:jsr   DrawWindowContents
L8263:jsr   CacheWindowAndScrollBarGeometry
      bit   WindowPtrIsAtFrontWindowFlag
      bpl   L826F ; branch if no
      jsr   DrawScrollBarsAndResizeBox
      rts
L826F:jsr   DrawRightAndBottomEdgesOfInactiveWindow
      rts
.endproc

DrawWindowContents:
      jsr   ResetWindowTextBlock
      jsr   CalculateWindowTextBoxClipRect
DrawWindowContents1:
      lda   WindowClipRectWidth
      beq   L82B3
      lda   WindowClipRectHeight
      beq   L82B3
      ldy   #$0F
      lda   (MenuBarOrWindowPtr),y ; doc pointer (hi)
      beq   L82B4 ; branch if null
      sta   L82A7
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      bpl   L82BE ; branch if no user window function
      ldy   #$0E
      lda   (MenuBarOrWindowPtr),y ; doc pointer (lo)
      sta   L82A6
      lda   LastError ; save last error on stack
      pha
      ldy   #$00
      lda   (MenuBarOrWindowPtr),y ; load A with window ID
      ldx   MenuBarOrWindowPtr ; x and y with pointer to window struct
      ldy   MenuBarOrWindowPtr+1
L82A6 := * + 1
L82A7 := * + 2
      jsr   $0000 ; operand is overwritten with address of user window function
      tax   ; save error from routine in X
      beq   L82AF ; branch if no error
      pla
      lda   #ErrUserHookRoutineError ; replace error saved on stack
      pha
L82AF:pla ; restore last error from stack
      sta   LastError
L82B3:rts
L82B4:ldy   #$0E
      lda   #$80
      sta   (MenuBarOrWindowPtr),y ; overwrites low byte of doc info ptr with $80. why???
      sta   CheckForUpdateEventsFlag
      rts
L82BE:jsr   OutputDocumentInWindow
      rts

WindowCharToOutput:
      .byte $00
WindowContentWidth:
      .byte $00
WindowContentLength:
      .byte $00
WindowDrawingXCounter:
      .byte $00
WindowDrawingYCounter:
      .byte $00
WindowIsDialogOrAlertFlag:
      .byte $00
WindowHasCloseBoxFlag:
      .byte $00

DrawWindowOutline:
      lda   #$00
      sta   DrawWindowRestoreOverrittenCharsFlag
      lda   #$80
      sta   DrawWindowSaveOverwittenCharsFlag
      bne   DrawWindowFrameWithCurrentDrawingFlags ; branch always taken

UndrawWindowOutline:
      lda   #$00
      sta   DrawWindowSaveOverwittenCharsFlag
      lda   #$80
      sta   DrawWindowRestoreOverrittenCharsFlag
      bne   DrawWindowFrameWithCurrentDrawingFlags ; branch always taken

DrawWindowFrame:
      lda   #$00
      sta   DrawWindowRestoreOverrittenCharsFlag ; not restoring overwitten chars
      sta   DrawWindowSaveOverwittenCharsFlag    ; or saving overwritten chars
      beq   L82F5                                ; branch always taken

DrawWindowFrameWithCurrentDrawingFlags:
           lda   ReservedMemAreaPtr ; use MenuItemStructPtr as pointer into reserved mem area
           sta   MenuItemStructPtr
           lda   ReservedMemAreaPtr+1
           sta   MenuItemStructPtr+1
L82F5:     ldy   #$08
           lda   (MenuBarOrWindowPtr),y ; window content width
           sta   WindowContentWidth
           ldy   #$09
           lda   (MenuBarOrWindowPtr),y ; windot content length
           sta   WindowContentLength
           jsr   SetWindowDrawingCoordToWindowTopLeftCorner
           ldy   #$01
           lda   (MenuBarOrWindowPtr),y ; window option byte
           and   #%00000001 ; is dialog/alert?
           beq   L8310 ; branch if no
           lda   #$80
L8310:     sta   WindowIsDialogOrAlertFlag
           lda   (MenuBarOrWindowPtr),y ; window option byte
           and   #%00000010 ; has close box?
           bne   L831B ; branch if yes
           lda   #$80
L831B:     sta   WindowHasCloseBoxFlag
           ldy   #$00
           lda   #MTCharOverUnderScore
           bit   WindowIsDialogOrAlertFlag
           bpl   L8329 ; branch if not dialog/alert
           lda   #CharUnderscore
L8329:     jsr   DrawRowOfCharAcrossWindow ; draw top edge of window
           lda   #MTCharLeftVerticalBar
           jsr   DrawColumnOfCharAcrossWindow ; draw right edge of window
           jsr   ResetWindowDrawingCoordToWindowTopLeftCorner
           lda   #MTCharRightVerticalBar
           jsr   DrawColumnOfCharAcrossWindow ; draw left edge of window
           lda   #MTCharOverscore
           jsr   DrawRowOfCharAcrossWindow ; draw bottom edge of window
           lda   DrawWindowSaveOverwittenCharsFlag
           ora   DrawWindowRestoreOverrittenCharsFlag
           ora   WindowIsDialogOrAlertFlag
           bmi   L8361 ; branch if any of the above flags is set
           bit   WindowPtrIsAtFrontWindowFlag
           bpl   L835E ; branch if no
           bit   WindowHasCloseBoxFlag
           bmi   L835E ; branch if yes
           jsr   ResetWindowDrawingCoordToWindowTopLeftCorner
           jsr   IncrementWindowDrawingXCoord ; x coord ++
           lda   #MTCharDottedBox ; draw window close box
           jsr   OutputWindowCharWithBackingStore
L835E:     jsr   DrawWindowTitle ; draw window title bar
L8361:     rts

.proc DrawRowOfCharAcrossWindow
      sta   WindowCharToOutput
      jsr   IncrementWindowDrawingXCoord
      ldx   WindowContentWidth
      stx   WindowDrawingXCounter
LOOP: lda   WindowCharToOutput
      jsr   OutputWindowCharWithBackingStore
      jsr   IncrementWindowDrawingXCoord ; x coord ++
      dec   WindowDrawingXCounter
      bne   LOOP
      rts
.endproc

.proc DrawColumnOfCharAcrossWindow
      sta   WindowCharToOutput
      bit   WindowIsDialogOrAlertFlag
      bpl   SKIP
      lda   #CharSpace
SKIP: jsr   OutputWindowCharWithBackingStore
      jsr   IncrementWindowDrawingYCoord
      lda   WindowContentLength
      sta   WindowDrawingYCounter
LOOP: lda   WindowCharToOutput
      jsr   OutputWindowCharWithBackingStore
      jsr   IncrementWindowDrawingYCoord
      dec   WindowDrawingYCounter ; y coord ++
      bne   LOOP
      lda   #CharSpace
      jsr   OutputWindowCharWithBackingStore
      rts
.endproc

WindowDrawingXCoord:
      .word $0000
WindowDrawingYCoord:
      .word $0000
WindowDrawingCoordWindowTopLeftCorner:
      .word $0000, $0000
DrawWindowSaveOverwittenCharsFlag:
      .byte $00
DrawWindowRestoreOverrittenCharsFlag:
      .byte $00

;;; Depending on the two flags above, this routine either
;;; outputs the character in A at the current window drawing
;;; coordinates and saves it to the backing store, OR
;;; reads a character from the backing store and outputs it
;;; at the current window drawing coordinates.
.proc OutputWindowCharWithBackingStore
      tax   ; save char to X
      lda   WindowDrawingXCoord+1
      bne   OUT ; x coord is negative, return
      lda   WindowDrawingXCoord
      cmp   DesktopMinXCoord
      bcc   OUT ; if x coord < desktop min x coord, return
      cmp   DesktopMaxXCoordPlus1
      bcs   OUT ; if x coord > desktop max x coord, return
      sta   CurrentXCoord
      lda   WindowDrawingYCoord
      cmp   DesktopMinYCoord
      bcc   OUT ; if y coord < desktop min y coord, return
      cmp   DesktopMaxYCoordPlus1
      bcs   OUT ; if y coord > desktop max y coord, return
      sta   CurrentYCoord
      jsr   MaybeSaveCharToSaveArea
      txa   ; restore char from X
      jsr   MaybeReadCharFromSaveArea
      sta   CharRegister
      jsr   PrintCharAtCurrentCoord
OUT:  rts
.endproc

;;; Initializes window coordinates to -1, -1; converts to screen coordinates,
;;; and sets both the window drawing coordinates and saved coordinates to
;;; those.
.proc SetWindowDrawingCoordToWindowTopLeftCorner
      lda   #$FF
      ldx   #$00
LOOP1:sta   WindowCoordinatesX,x
      inx
      cpx   #$04
      bcc   LOOP1
      jsr   ConvertWindowCoordToScreenCoord
      ldx   #$00
LOOP2:lda   ScreenCoordinatesX,x
      sta   WindowDrawingCoordWindowTopLeftCorner,x
      sta   WindowDrawingXCoord,x
      inx
      cpx   #$04
      bcc   LOOP2
      rts
.endproc

.proc ResetWindowDrawingCoordToWindowTopLeftCorner
      ldx   #$00
LOOP: lda   WindowDrawingCoordWindowTopLeftCorner,x
      sta   WindowDrawingXCoord,x
      inx
      cpx   #$04
      bcc   LOOP
      rts
.endproc

.proc MaybeSaveCharToSaveArea
      bit   DrawWindowSaveOverwittenCharsFlag
      bpl   OUT
      jsr   CacheCharAtCurrentCoord
      lda   CharRegister
      sta   (MenuItemStructPtr),y
      iny
      bne   OUT
      inc   MenuItemStructPtr+1
OUT:  rts
.endproc

.proc MaybeReadCharFromSaveArea
      bit   DrawWindowRestoreOverrittenCharsFlag
      bpl   OUT
      lda   (MenuItemStructPtr),y
      iny
      bne   OUT
      inc   MenuItemStructPtr+1
OUT:  rts
.endproc

.proc IncrementWindowDrawingXCoord
      inc   WindowDrawingXCoord
      bne   OUT
      inc   WindowDrawingXCoord+1
OUT:  rts
.endproc

.proc IncrementWindowDrawingYCoord
      inc   WindowDrawingYCoord
      bne   OUT
      inc   WindowDrawingYCoord+1
OUT:  rts
.endproc

DrawWindowTitleLength:
      .byte $00 ; title string length

.proc DrawWindowTitle
      sec
      lda   WindowContentWidth
      sbc   #$02
      sta   WindowContentWidth
      ldy   #$02
      lda   (MenuBarOrWindowPtr),y ; title string ptr (lo)
      sta   TextStringPtr
      iny
      lda   (MenuBarOrWindowPtr),y ; title string ptr (hi)
      sta   TextStringPtr+1
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      sta   MenuOrWindowOptionByte
      jsr   MaybeOffsetTextStringPtr
      ldy   #$00
      lda   (TextStringPtr),y ; get string length
      iny
      sta   DrawWindowTitleLength
      clc
      lda   WindowContentWidth
      sbc   DrawWindowTitleLength
      bcs   L847F ; branch if title is narrower than window content width
      lda   WindowContentWidth
      sta   DrawWindowTitleLength ; truncate title to window content width
      ldy   #$02
      bne   L8483 ; branch always taken
L847F:lsr   a ; center the title
      tay
      iny
      iny
L8483:sty   WindowCoordinatesX
      lda   #$00
      sta   WindowCoordinatesX+1
      lda   #$FF ; -1
      sta   WindowCoordinatesY
      sta   WindowCoordinatesY+1
      jsr   ConvertWindowCoordToScreenCoord ; calc. screen coord of title
      lda   ScreenCoordinatesX
      sta   WindowDrawingXCoord
      lda   ScreenCoordinatesX+1
      sta   WindowDrawingXCoord+1
      lda   ScreenCoordinatesY
      sta   WindowDrawingYCoord
      jsr   MaybeDerefTextStringPtr
      ldy   #$01
L84AD:dec   DrawWindowTitleLength
      bmi   OUT
      lda   (TextStringPtr),y
      iny
      bit   WindowPtrIsAtFrontWindowFlag
      bpl   L84BC
      eor   #%10000000           ; Make inverse if active window
L84BC:jsr   RemapChar
      jsr   OutputWindowCharWithBackingStore
      jsr   IncrementWindowDrawingXCoord
      jmp   L84AD
OUT:  rts
.endproc

;;; Clipping rectangle defining the portion of a window's content
;;; area, in screen coordinates, that is within the bounds of the screen.

WindowClipRectStartX:
      .byte $00
WindowClipRectStartY:
      .byte $00
WindowClipRectEndXPlus1:
      .byte $00
WindowClipRectEndYPlus1:
      .byte $00
WindowClipRectVisibleOffsetX:
      .byte $00
WindowClipRectVisibleOffsetY:
      .byte $00
WindowClipRectWidth:
      .byte $00
WindowClipRectHeight:
      .byte $00
WindowTextBlockStartX:
      .word $00000
WindowTextBlockStartY:
      .word $0000
;;; The end coordinates are x+1,y+1 of the ex,ey parameters passed to
;;; WinBlock. This is to make comparisons easier (<, >= rather than
;;;  <=, =)
WindowTextBlockEndX:
      .word $0000
WindowTextBlockEndY:
      .word $0000

;;; If the window text box start x/y coordinates are left-of/above the
;;; window content area clip rect top left corner, then these are the
;;; x/y offsets from the window text box start x/y coordinates to the
;;; top-left corner of the window content area clip rect.
WindowTextBoxClipRectVisibleOffsetX:
      .byte $00
WindowTextBoxClipRectVisibleOffsetY:
      .byte $00

DesktopMinXCoord:
      .byte $00
DesktopMinYCoord:
      .byte $00
DesktopMaxXCoordPlus1:
      .byte $00
DesktopMaxYCoordPlus1:
      .byte $00

.proc ZeroWindowTextBlockVars
      lda   #$00
      tax
LOOP: sta   WindowTextBlockStartX,x
      inx
      cpx   #$0A
      bcc   LOOP
      rts
.endproc

;;; This effectively sets the clipping rectangle for the entire
;;; desktop; it encompasses the entire screen except for the
;;; first row, which is occupied by the menu bar.
.proc CalcDesktopClipRect
      ldx   #$00
      stx   DesktopMinXCoord
      inx   ; plus 1 to exclude the menu bar
      stx   DesktopMinYCoord
      ldx   #$18 ; 24
      stx   DesktopMaxYCoordPlus1
      ldx   MaxColumnNumber
      inx
      stx   DesktopMaxXCoordPlus1
      rts
.endproc

;;; Resets the window text block to encompass the window's
;;; entire content area.
.proc ResetWindowTextBlock
      jsr   ZeroWindowTextBlockVars
      lda   WindowContentWidthAdjustedForScrollBars
      sta   WindowTextBlockEndX
      lda   WindowContentHeightAdjustedForScrollBars
      sta   WindowTextBlockEndY
      rts
.endproc

.proc SetWindowTextBlockToWindowBounds
      lda   #$FF                  ; -1
      sta   WindowTextBlockStartX ; init to (-1,-1)
      sta   WindowTextBlockStartX+1
      sta   WindowTextBlockStartY
      sta   WindowTextBlockStartY+1
      lda   #$00
      sta   WindowTextBlockEndX+1
      sta   WindowTextBlockEndY+1
      ldy   #$08
      lda   (MenuBarOrWindowPtr),y ; content width
      sta   WindowTextBlockEndX
      inc   WindowTextBlockEndX
      ldy   #$09
      lda   (MenuBarOrWindowPtr),y ; content length
      sta   WindowTextBlockEndY
      inc   WindowTextBlockEndY
      rts
.endproc

EraseWindowRegion:
      jsr   ClampWindowTextBlock
EraseWindowRegionNoClamp:
      jsr   CalculateWindowTextBoxClipRect
EraseWindowRegionNoClip:
      lda   #CharSpace
      sta   CharRegister
      lda   WindowClipRectStartY
      sta   CurrentYCoord
L854D:lda   CurrentYCoord
      cmp   WindowClipRectEndYPlus1
      bcs   L856A
      lda   WindowClipRectStartX
      sta   CurrentXCoord
      lda   WindowClipRectWidth
      sta   LengthOfTextToOutput
      jsr   OutputRepeatedChar
      inc   CurrentYCoord
      jmp   L854D
L856A:rts

DocumentPtr:
      .word $0000
DocumentWidth:
      .byte $00
DocumentXCoord:
      .word $0000
DocumentYCoord:
      .word $0000

OutputDocumentInWindow:
      ldy   #$0F
      lda   (MenuBarOrWindowPtr),y ; doc ptr (hi)
      sta   MenuBlockOrDocInfoPtr+1
      dey
      lda   (MenuBarOrWindowPtr),y ; doc ptr (lo)
      sta   MenuBlockOrDocInfoPtr
OutputCurrentDocumentInWindow:
      ldy   #$00
      lda   (MenuBlockOrDocInfoPtr),y ; doc text ptr
      sta   DocumentPtr
      iny
      lda   (MenuBlockOrDocInfoPtr),y
      sta   DocumentPtr+1
      ldy   #$04
      lda   (MenuBlockOrDocInfoPtr),y ; doc x-coord (lo)
      sta   DocumentXCoord
      iny
      lda   (MenuBlockOrDocInfoPtr),y ; doc x-coord (hi)
      sta   DocumentXCoord+1
      ldy   #$06
      lda   (MenuBlockOrDocInfoPtr),y ; doc y-coord (lo)
      sta   DocumentYCoord
      iny
      lda   (MenuBlockOrDocInfoPtr),y ; doc y-coord (hi)
      sta   DocumentYCoord+1
      ldy   #$03
      lda   (MenuBlockOrDocInfoPtr),y ; doc width
      sta   DocumentWidth
      ldx   #$02
L85AD:clc
      lda   DocumentXCoord,x ; adjust doc. x-coord by text block start x
      adc   WindowTextBlockStartX,x
      sta   DocumentXCoord,x
      lda   DocumentXCoord+1,x
      adc   WindowTextBlockStartX+1,x
      sta   DocumentXCoord+1,x
      dex
      dex
      beq   L85AD
      clc
      lda   WindowClipRectVisibleOffsetY
      adc   DocumentYCoord
      sta   DocumentYCoord
      bcc   L85D3
      inc   DocumentYCoord+1
L85D3:lda   DocumentWidth  ; multiply doc width * doc y-coord
      sta   MultiplyArg1
      lda   DocumentYCoord
      sta   MultiplyArg1+1
      lda   DocumentYCoord+1
      sta   MultiplyArg2
      jsr   Multiply::MultiplyWordAndByte
      clc
      lda   DocumentPtr ; use that to offset the document ptr
      adc   MultiplyResult
      sta   MenuStructPtr ; MenuStructPtr is used as a pointer into
      lda   DocumentPtr+1 ; the document by this routine.
      adc   MultiplyResult+1
      sta   MenuStructPtr+1
      clc
      lda   MenuStructPtr ; then offset by the doc x-coord
      adc   DocumentXCoord
      sta   MenuStructPtr
      lda   MenuStructPtr+1
      adc   DocumentXCoord+1
      sta   MenuStructPtr+1
      clc
      lda   MenuStructPtr
      adc   WindowClipRectVisibleOffsetX ; now offset again to take into
      sta   MenuStructPtr ; account the clipping rectangle
      bcc   L8614
      inc   MenuStructPtr+1
L8614:lda   WindowClipRectStartY
      sta   CurrentYCoord
L861A:lda   CurrentYCoord
      cmp   WindowClipRectEndYPlus1 ; if Y coord reaches right edge of clip rect
      bcs   L864B ; then stop and return
      lda   WindowClipRectStartX
      sta   CurrentXCoord
      lda   MenuStructPtr  ; set pointer to text to output
      sta   TextStringPtr
      lda   MenuStructPtr+1
      sta   TextStringPtr+1
      lda   WindowClipRectWidth
      sta   LengthOfTextToOutput ; and length of text to output
      jsr   OutputTextStringInWindow ;output row of (clipped) text
      inc   CurrentYCoord ; advance y-coord
      clc
      lda   MenuStructPtr
      adc   DocumentWidth ; advance to next line of text
      sta   MenuStructPtr
      bcc   L8648
      inc   MenuStructPtr+1
L8648:jmp   L861A ; loop
L864B:rts

CalculateWindowTextBoxClipRect:
      ldx   #$00 ; convert the text block start x&y coordinates
L864E:lda   WindowTextBlockStartX,x ; to screen coordinates
      sta   WindowCoordinatesX,x
      inx
      cpx   #$04
      bcc   L864E
      jsr   ConvertWindowCoordToScreenCoord
      ldx   #$01
      ldy   #$02
L8660:lda   #$00
      sta   WindowClipRectVisibleOffsetX,x
      lda   ScreenCoordinatesX+1,y ; x/y-coord (hi)
      bmi   L8674 ; branch if < 0
      bne   L8684 ; branch if != 0 (x/y coord is > 255)
      lda   ScreenCoordinatesX,y ; x/y coord (lo)
      cmp   DesktopMinXCoord,x ; compare x/y-coord to desktop clip rect start x/y
      bcs   L8687 ; branch if >=
L8674:sec   ; otherwise it's <
      lda   DesktopMinXCoord,x ; so compute the x/y offset into the visible area
      sbc   ScreenCoordinatesX,y
      sta   WindowClipRectVisibleOffsetX,x ; and save it
      lda   DesktopMinXCoord,x ; use desktop clip rect start x/y
      jmp   L8687 ; as the text block clip rect start x/y
L8684:lda   DesktopMaxXCoordPlus1,x ; in this case; clip rect is 0-wide
L8687:sta   WindowClipRectStartX,x ; set window clip rect start x/y
      dey
      dey
      dex
      beq   L8660 ; iterate on other x/y coordinate
      ldx   #$00 ; convert the text block end x&y coordinates
L8691:lda   WindowTextBlockEndX,x ; to screen coordinates
      sta   WindowCoordinatesX,x
      inx
      cpx   #$04
      bcc   L8691
      jsr   ConvertWindowCoordToScreenCoord
      ldy   #$02
      ldx   #$01
L86A3:lda   ScreenCoordinatesX+1,y ; x/y coord (hi)
      bmi   L86B8 ; branch if < 0
      bne   L86B2 ; branch if != 0 (xy/y coord is > 255)
      lda   ScreenCoordinatesX,y ; x/y coord (lo)
      cmp   DesktopMaxXCoordPlus1,x ; compare x/y-coord to desktop clip rect end x/y
      bcc   L86BB ; branch if <
L86B2:lda   DesktopMaxXCoordPlus1,x ; otherwise it's >=
      jmp   L86BB ; so use it...
L86B8:lda   DesktopMinXCoord,x ; otherwise use the desktiop min x/y coord
L86BB:sta   WindowClipRectEndXPlus1,x ; as the window clip rect end x/y
      dey
      dey
      dex
      beq   L86A3 ; iterate on coordinate value for other axis

CalculateWindowClipRectWidthAndHeight:
      ldx   #$01
L86C5:sec
      lda   WindowClipRectEndXPlus1,x
      sbc   WindowClipRectStartX,x
      bcs   L86D0
      lda   #$00
L86D0:sta   WindowClipRectWidth,x
      dex
      beq   L86C5
      rts

ClampWindowTextBlockSavedContentWidth:
      .byte $00
ClampWindowTextBlockSavedContentHeight:
      .byte $00

;;; Clamps the window text block start and end coordinates so they
;;; don't extend outside the window's content area.
.proc ClampWindowTextBlock
      lda   WindowContentWidthAdjustedForScrollBars
      sta   ClampWindowTextBlockSavedContentWidth
      lda   WindowContentHeightAdjustedForScrollBars
      sta   ClampWindowTextBlockSavedContentHeight
      ldx   #$01
      ldy   #$02
L86E9:lda   #$00
      sta   WindowTextBoxClipRectVisibleOffsetX,x
      lda   WindowTextBlockStartX+1,y ; start x/y coord (hi)
      bmi   L8702 ; branch if < 0 (it's invalid)
      beq   L8713 ; branch if == 0 (it's valid)
      lda   ClampWindowTextBlockSavedContentWidth,x ; otherwise it's > 255
      sta   WindowTextBlockStartX,y ; clamp it to the content width/height
      lda   #$00
      sta   WindowTextBlockStartX+1,y
      beq   L8713
L8702:sec
      lda   #$00
      sbc   WindowTextBlockStartX,y ; negate the coordinate
      sta   WindowTextBoxClipRectVisibleOffsetX,x ; and save the (positive) value
      lda   #$00
      sta   WindowTextBlockStartX,y ; clamp the coordinate to 0
      sta   WindowTextBlockStartX+1,y
L8713:dey
      dey
      dex
      beq   L86E9 ; iterate on other x/y coordinate
      ldy   #$02
      ldx   #$01
L871C:lda   WindowTextBlockEndX+1,y ; end x/y coord (hi)
      bmi   L8739 ; branch if < 0 (it's invalid)
      bne   L872B ; branch if == 0 (it's valid)
      lda   WindowTextBlockEndX,y ; end x/y coord (lo)
      cmp   ClampWindowTextBlockSavedContentWidth,x
      bcc   L8741 ; branch if < content width/height (it's valid)
L872B:lda   #$00
      sta   WindowTextBlockEndX+1,y ; otherwise clamp it to the
      lda   ClampWindowTextBlockSavedContentWidth,x ; content width/height
      sta   WindowTextBlockEndX,y
      jmp   L8741
L8739:lda   #$00
      sta   WindowTextBlockEndX+1,y ; clamp it to 0
      sta   WindowTextBlockEndX,y
L8741:dey
      dey
      dex
      beq L871C ; iterate on coordinate value for other axis
      rts
.endproc

.proc SetWindowScreenAreaCovered
      jsr   SetWindowTextBlockToWindowBounds
      jsr   CalculateWindowTextBoxClipRect
      ldx   #$00
      ldy   #$1C
LOOP: lda   WindowClipRectStartX,x
      sta   (MenuBarOrWindowPtr),y ; screen area covered
      iny
      inx
      cpx   #$04
      bcc   LOOP
      rts
.endproc

.proc SetDesktopClipRectToWindowScreenAreaCovered
      ldx   #$00
      ldy   #$1C
LOOP: lda   (MenuBarOrWindowPtr),y ; screen area covered
      sta   DesktopMinXCoord,x
      iny
      inx
      cpx   #$04
      bcc   LOOP
      rts
.endproc

.proc LoadWindowClipRect
      ldx   #$00
      ldy   #$1C
LOOP: lda   (MenuBarOrWindowPtr),y ; screen area covered
      sta   WindowClipRectStartX,x
      iny
      inx
      cpx   #$04
      bcc   LOOP
      jsr   CalculateWindowClipRectWidthAndHeight
      rts
.endproc

ColumnFlagsCurrentIndex:
      .byte $00

;;; 80 flags
ColumnFlags:
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00
      .byte $00,$00,$00,$00,$00,$00,$00,$00

;;; Starting with the current window, iterates backward through all the
;;; windows in front of that window to determine which of this window's
;;; columns (for a given row, given by CurrentYCoord) are obscured by
;;; those other windows. The ColumnFlags are set accordingly: $00 if
;;; obscured, $80 if not.
.proc CalcColumnsObscuredInWindowRow
      lda   #$80
      ldx   #$00
LOOP1:sta   ColumnFlags,x ; set all flags initially
      inx
      cpx   #$50
      bcc   LOOP1
      bit   RedrawingAllWindowsFlag
      bmi   OUT ; return if yes
      jsr   IsWindowPtrAtFrontWindow
      bit   WindowPtrIsAtFrontWindowFlag
      bmi   OUT ; return if yes
      lda   MenuBarOrWindowPtr ; save window ptr on stack
      pha
      lda   MenuBarOrWindowPtr+1
      pha
LOOP2:jsr   PrevWindow
      bcs   DONE ; finished all windows
      ldy   #$1D
      lda   CurrentYCoord
      cmp   (MenuBarOrWindowPtr),y ; screen area covered Y coord
      bcc   LOOP2 ; current Y < ? skip this window
      ldy   #$1F
      cmp   (MenuBarOrWindowPtr),y ; screen area covered Y max + 1 coord
      bcs   LOOP2 ; current Y >= ? skip this window
      ldy   #$1C
      lda   (MenuBarOrWindowPtr),y ; screen area covered X coord
      tax
      ldy   #$1E ; screen area covered X max + 1 coord
      lda   (MenuBarOrWindowPtr),y
      sta   ColumnFlagsCurrentIndex
      lda   #$00
LOOP3:cpx   ColumnFlagsCurrentIndex ; clear flags for columns that lie within window
      bcs   LOOP2
      sta   ColumnFlags,x
      inx
      jmp   LOOP3
DONE: pla
      sta   MenuBarOrWindowPtr+1 ; restore window ptr from stack
      pla
      sta   MenuBarOrWindowPtr
      jsr   IsWindowPtrAtFrontWindow
      jsr   CacheWindowContentSizeAdjustedForScrollBars
OUT:  rts
.endproc

CurrentContentWidth:
      .byte $00
CurrentContentLength:
      .byte $00
HorizScrollBoxPosition:
      .byte $00
VertScrollBoxPosition:
      .byte $00
CurrentContentWidthMinus2:
      .byte $00
HBarScrollBoxPresentFlag:
      .byte $00
VBarScrollBoxPresentFlag:
      .byte $00
HScrollBarPresentFlag:
      .byte $00
VScrollBarPresentFlag:
      .byte $00
HScrollBarMaxPos:
      .byte $00
HScrollBoxMaxXPos:
      .byte $00
VScrollBarMaxPos:
      .byte $00
VScrollBoxMaxYPos:
      .word $0000
RightScrollArrowXPos:
      .byte $00 ; also current content width - 1
CurrentContentWidthMinus1:
      .byte $00
L883B:.byte $00 ; copy of CurrentContentWidthMinus1 (never read)
CurrentContentLengthMinus1:
      .byte $00
L883D:.byte $00 ; copy of CurrentContentLengthMinus1 (never read)

DownScrollArrowYPos:
      .byte $00            ; also current content length - 1
      .byte $00            ; unused byte
UpdateCachedWindowStateWindowStatusByte:
      .byte $00            ; window status byte bits 3-7

;;; Caches some flags from the two scroll bar option bytes into the
;;; undocumented bits of the window option byte. Also, if the resize
;;; box is enabled but both scroll bars aren't enabled, forces the
;;; vertical scroll bar to be enabled.
.proc UpdateCachedWindowState
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%11111000; clear bits 0-2
      sta   UpdateCachedWindowStateWindowStatusByte
      ldy   #$10
      lda   (MenuBarOrWindowPtr),y ; horiz. control option byte
      and   #%10000000             ; scroll bar present?
      beq   L885A                  ; branch if no
      lda   UpdateCachedWindowStateWindowStatusByte
      ora   #%00000001             ; set bit 0 (horiz scroll bar present)
      sta   UpdateCachedWindowStateWindowStatusByte ; and update
L885A:ldy   #$11                   ; vert. control option byte
      lda   (MenuBarOrWindowPtr),y
      and   #%10000000             ; scroll bar present?
      beq   L886A                  ; branch if no
      lda   UpdateCachedWindowStateWindowStatusByte
      ora   #%00000010             ; set bit 1 (vert scroll bar present)
      sta   UpdateCachedWindowStateWindowStatusByte ; and update
L886A:ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000100             ; has resize box?
      bne   L887B                  ; branch if yes
      lda   UpdateCachedWindowStateWindowStatusByte
      and   #%00000011             ; has both scroll bars?
      cmp   #%00000011
      bne   L888F                  ; branch if no
L887B:lda   UpdateCachedWindowStateWindowStatusByte
      ora   #%00000100             ; set bit 2 (resize box enabled)
      sta   UpdateCachedWindowStateWindowStatusByte ; and update
      and   #%00000011             ; has both scroll bars?
      bne   L888F                  ; branch if yes
      lda   UpdateCachedWindowStateWindowStatusByte
      ora   #%00000010             ; set bit 2 (vert scroll bar present)
      sta   UpdateCachedWindowStateWindowStatusByte ; and update
L888F:lda   UpdateCachedWindowStateWindowStatusByte
      ldy   #$16
      sta   (MenuBarOrWindowPtr),y ; store in window status byte
      jsr   ClampHorizScrollPos    ; clamp scroll bar positions
      jsr   ClampVertScrollPos
      rts
.endproc

.proc ClampHorizScrollPos
      ldy   #$12
      lda   (MenuBarOrWindowPtr),y ; horiz scroll maximum
      ldy   #$13
      cmp   (MenuBarOrWindowPtr),y ; horiz scroll pos
      bcs   OUT ; if max >= pos, ok
      sta   (MenuBarOrWindowPtr),y ; pos = max
OUT:  rts
.endproc

.proc ClampVertScrollPos
      ldy   #$14
      lda   (MenuBarOrWindowPtr),y ; vert scroll maximum
      ldy   #$15
      cmp   (MenuBarOrWindowPtr),y ; vert scroll pos
      bcs   OUT                  ; if max >= pos, ok
      sta   (MenuBarOrWindowPtr),y ; pos = max
OUT:  rts
.endproc

WindowContentWidthAdjustedForScrollBars:
      .byte $00
WindowContentHeightAdjustedForScrollBars:
      .byte $00

.proc CacheWindowContentSizeAdjustedForScrollBars
      ldy   #$09
      lda   (MenuBarOrWindowPtr),y ; current content length
      tax
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000001 ; horiz scroll bar present?
      beq   L88C7 ; branch if no
      dex
L88C7:stx   WindowContentHeightAdjustedForScrollBars ; save content_length - 1
      ldy   #$08 ; current content width
      lda   (MenuBarOrWindowPtr),y
      tax
      ldy   #$16 ; window status byte
      lda   (MenuBarOrWindowPtr),y
      and   #%00000010 ; vert scroll bar present?
      beq   L88D9 ; branch if no
      dex
      dex
L88D9:stx   WindowContentWidthAdjustedForScrollBars ; save content_width - 2
      rts
.endproc

.proc CacheWindowAndScrollBarGeometry
      ldy   #$08
      lda   (MenuBarOrWindowPtr),y ; current content width
      sta   CurrentContentWidth
      tay
      dey
      sty   CurrentContentWidthMinus1
      sty   L883B
      dey
      sty   CurrentContentWidthMinus2
      ldy   #$09
      lda   (MenuBarOrWindowPtr),y ; current content length
      sta   CurrentContentLength
      tay
      dey
      sty   CurrentContentLengthMinus1
      sty   L883D
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000100             ; resize box enabled?
      beq   L8910                  ; branch if no
      dec   CurrentContentWidth
      dec   CurrentContentWidth
      dec   CurrentContentLength
L8910:lda   #$00
      sta   HBarScrollBoxPresentFlag
      sta   VBarScrollBoxPresentFlag
      sta   HScrollBarPresentFlag
      sta   VScrollBarPresentFlag
      ldx   #$80
      ldy   #$10
      lda   CurrentContentWidth
      cmp   #$05
      bcs   L8938 ; branch if current content width >= 5
      cmp   #$03
      bcc   L894A ; branch if current content width < 3
      lda   (MenuBarOrWindowPtr),y ; horiz control option byte
      and   #%10000000             ; scrollbar present?
      beq   L894A                  ; branch if no
      stx   HScrollBarPresentFlag  ; set scrollbar present
      bne   L894A                  ; branch always taken
L8938:lda   (MenuBarOrWindowPtr),y ; horiz control option byte
      and   #%10000000             ; scrollbar present?
      beq   L894A                  ; branch if no
      stx   HScrollBarPresentFlag  ; set scrollbar present
      lda   (MenuBarOrWindowPtr),y ; horiz control option byte
      and   #%01000000             ; scroll box present?
      beq   L894A                  ; branch if no
      stx   HBarScrollBoxPresentFlag ; set scrollbar present
L894A:ldy   #$11                     ; vert control option byte
      lda   CurrentContentLength
      cmp   #$05
      bcs   L8962 ; branch if current content length >= 5
      cmp   #$03
      bcc   L8974 ; branch if current content length < 3
      lda   (MenuBarOrWindowPtr),y ; vert control option byte
      and   #%10000000             ; scrollbar present?
      beq   L8974                  ; branch if no
      stx   VScrollBarPresentFlag  ; set scrollbar present
      bne   L8974                  ; branch always taken
L8962:lda   (MenuBarOrWindowPtr),y ; vert control option byte
      and   #%10000000             ; scrollbar present?
      beq   L8974                  ; branch if no
      stx   VScrollBarPresentFlag  ; set scrollbar present
      lda   (MenuBarOrWindowPtr),y ; vert control option byte
      and   #%01000000             ; scroll box present?
      beq   L8974                  ; branch if no
      stx   VBarScrollBoxPresentFlag ; set scrollbar present
L8974:ldy   #$12
      lda   (MenuBarOrWindowPtr),y ; horiz scroll max
      sta   HScrollBarMaxPos
      ldy   #$14
      lda   (MenuBarOrWindowPtr),y ; vert scroll max
      sta   VScrollBarMaxPos
      ldx   CurrentContentWidth
      dex
      stx   RightScrollArrowXPos
      dex
      dex
      stx   HScrollBoxMaxXPos ; h. scroll box max pos (content width - 3)
      ldx   CurrentContentLength
      dex
      stx   DownScrollArrowYPos
      dex
      dex
      stx   VScrollBoxMaxYPos ; v. scroll box max pos (content length - 3)
      rts
.endproc

ControlRegion:
      .byte $00
ControlPart:
      .byte $00
PointXInWindowCoord:
      .byte $00
PointYInWindowCoord:
      .byte $00

;;; ----------------------------------------
;;; ToolKit call $27 (39)
;;; ----------------------------------------
.proc FindControl
      jsr   GetFrontWindowOrFail
      bcc   L89A5
      rts
L89A5:lda   #ControlRegionContent
      sta   ControlRegion
      ldy   #$01
      lda   (ParamTablePtr),y ; point x-coord
      sta   PointXInWindowCoord
      iny
      lda   (ParamTablePtr),y ; point x-coord (hi) must be 0
      bne   L89FD
      iny
      lda   (ParamTablePtr),y ; point y-coord
      sta   PointYInWindowCoord
      iny
      lda   (ParamTablePtr),y ; point y-coord (hi) must be 0
      bne   L89FD
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000001             ; horiz scroll bar present?
      beq   L8A26                  ; branch if no
      lda   CurrentContentLengthMinus1
      cmp   PointYInWindowCoord
      beq   L89D3
      bcs   L8A26 ; branch if >
L89D3:lda   #ControlRegionDeadZone
      sta   ControlRegion
      ldy   #$10
      lda   (MenuBarOrWindowPtr),y ; horiz control option byte
      and   #%10000001             ; active & present?
      cmp   #%10000001
      bne   L89FD ; branch if no
      bit   HScrollBarPresentFlag
      bpl   L89FD ; branch if no
      lda   PointXInWindowCoord
      bne   L89F1 ; branch if non-zero
      lda   #ControlPartUpOrLeftArrow
      jmp   L8A1B
L89F1:cmp   RightScrollArrowXPos
      bne   L89FB
      lda   #ControlPartDownOrRightArrow
      jmp   L8A1B
L89FB:bcc   L8A00
L89FD:jmp   L8A90
L8A00:bit   HBarScrollBoxPresentFlag
      bpl   L89FD ; branch if no
      lda   PointXInWindowCoord
      cmp   HorizScrollBoxPosition
      bne   L8A12
      lda   #ControlPartScrollBox
      jmp   L8A1B
L8A12:bcc   L8A19
      lda   #ControlPartPageDownOrRightRegion
      jmp   L8A1B
L8A19:lda   #ControlPartPageUpOrLeftRegion
L8A1B:sta   ControlPart
      lda   #ControlRegionHorizScrollBar
      sta   ControlRegion
      jmp   L89FD
L8A26:ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000010             ; vscroll bar present?
      beq   L89FD                  ; branch if no
      lda   CurrentContentWidthMinus2
      cmp   PointXInWindowCoord
      beq   L8A38
      bcs   L8A90 ; branch if >
L8A38:lda   #ControlRegionDeadZone
      sta   ControlRegion
      lda   CurrentContentWidthMinus2
      cmp   PointXInWindowCoord
      beq   L8A90
      ldy   #$11
      lda   (MenuBarOrWindowPtr),y ; vert control option byte
      and   #%10000001
      cmp   #%10000001     ; active & present?
      bne   L8A90          ; branch if no
      bit   VScrollBarPresentFlag
      bpl   L8A90          ; branch if no
      lda   PointYInWindowCoord
      bne   L8A5E          ; branch if non-zero
      lda   #$01
      jmp   L8A85
L8A5E:cmp   DownScrollArrowYPos
      bne   L8A68
      lda   #ControlPartDownOrRightArrow
      jmp   L8A85
L8A68:bcs   L8A90
      bit   VBarScrollBoxPresentFlag
      bpl   L8A90          ; branch if no
      lda   PointYInWindowCoord
      cmp   VertScrollBoxPosition
      bne   L8A7C
      lda   #ControlPartScrollBox
      jmp   L8A85
L8A7C:bcc   L8A83
      lda   #ControlPartPageDownOrRightRegion
      jmp   L8A85
L8A83:lda   #ControlPartPageUpOrLeftRegion
L8A85:sta   ControlPart
      lda   #ControlRegionVertScrollBar
      sta   ControlRegion
      jmp   L8A90
L8A90:lda   ControlRegion ; set results in param table
      ldy   #$05
      sta   (ParamTablePtr),y
      lda   ControlPart
      iny
      sta   (ParamTablePtr),y
      rts
.endproc

ScaleScrollBoxCoordToPosTemp1:
      .byte $00; storage for X
ScaleScrollBoxCoordToPosTemp2:
      .byte $00 ; storage for A / 2

;;; Calculates the scroll box coordinate for the given
;;; scroll position, basically by dividing the scroll
;;; position by the scroll bar maximum value to get a
;;; percentage (of the entire width/height of the document)
;;; and then multiplying that by the scroll box max
;;; coordinate to get the scroll box coordinate for that
;;; scroll position.
;;;
;;; Input:
;;; X: Scroll box max position
;;; Y: Scroll box max coordinate
;;; A: Scroll pox position
;;; Output:
;;; A: Scroll box coordinate
;;;
;;; If A == 0, return 0
;;; If A >= X, return Y
;;; Otherwise, return (((A * Y-1) - (Y/2)) / (X-1)) + 1
.proc ScaleScrollBoxCoordToPos
      sta   MultiplyArg1
      stx   ScaleScrollBoxCoordToPosTemp1
      cmp   #$00
      beq   OUT ; return if A == 0
      cmp   ScaleScrollBoxCoordToPosTemp1
      tya   ; Y -> A
      bcs   OUT ; return if A >= X
      dey   ; Y--
      sty   MultiplyArg2
      lsr   a
      sta   ScaleScrollBoxCoordToPosTemp2 ; Y/2
      jsr   Multiply::MultiplyBytes ; multiply A * Y - 1
      sec
      lda   MultiplyResult
      sbc   ScaleScrollBoxCoordToPosTemp2
      sta   DivideArg1
      lda   MultiplyResult+1
      sbc   #$00
      sta   DivideArg1+1
      ldy   ScaleScrollBoxCoordToPosTemp1
      dey
      sty   DivideArg2  ; divide result by X - 1
      jsr   DivideWordByByte
      lda   DivideResult
      clc
      adc   #$01 ; add 1
OUT:  rts
.endproc

.proc CalcHorizScrollBoxPosition
      ldx   HScrollBarMaxPos
      ldy   HScrollBoxMaxXPos
      jsr   ScaleScrollBoxCoordToPos
      clc
      adc   #$01
      rts
.endproc

.proc ScaleHScrollBoxXCoordToPos
      ldx   HScrollBoxMaxXPos
      ldy   HScrollBarMaxPos
      sec
      sbc   #$01
      jsr   ScaleScrollBoxCoordToPos
      rts
.endproc

.proc CalcVertScrollBoxPosition
      ldx   VScrollBarMaxPos
      ldy   VScrollBoxMaxYPos
      jsr   ScaleScrollBoxCoordToPos
      clc
      adc   #$01
      rts
.endproc

.proc ScaleVScrollBoxXCoordToPos
      ldx   VScrollBoxMaxYPos
      ldy   VScrollBarMaxPos
      sec
      sbc   #$01
      jsr   ScaleScrollBoxCoordToPos
      rts
.endproc

.proc OutputCharInWindowAtXY
      sta   CharRegister
      jsr   IsXYWithinWindowAndOnScreen
      bcs   SKIP
      jsr   PrintCharAtCurrentCoord
SKIP: ldx   WindowCoordinatesX
      ldy   WindowCoordinatesY
      rts
.endproc

.proc GetCharAtXYWithinWindow
      jsr   IsXYWithinWindowAndOnScreen
      bcs   SKIP
      jsr   CacheCharAtCurrentCoord
SKIP: lda   CharRegister
      ldx   WindowCoordinatesX
      ldy   WindowCoordinatesY
      rts
.endproc

;;; determines if the window coordinates in X, Y are on the screen
;;; (Carry clear) or outside it (Carry set)
.proc IsXYWithinWindowAndOnScreen
      stx   WindowCoordinatesX
      sty   WindowCoordinatesY
      lda   #$00
      sta   WindowCoordinatesX+1
      sta   WindowCoordinatesY+1
      jsr   ConvertWindowCoordToScreenCoord
      lda   ScreenCoordinatesX+1
      and   ScreenCoordinatesY+1
      bne   NO ; if both coords negative, return "no"
      lda   ScreenCoordinatesX
      cmp   DesktopMinXCoord
      bcc   NO ; branch if outside screen
      cmp   DesktopMaxXCoordPlus1
      bcs   NO
      sta   CurrentXCoord
      lda   ScreenCoordinatesY
      cmp   DesktopMinYCoord
      bcc   NO
      cmp   DesktopMaxYCoordPlus1
      bcs   NO
      sta   CurrentYCoord
      clc
      rts
NO:   sec
      rts
.endproc

.proc DrawHorizScrollBarArrows
      bit   HScrollBarPresentFlag
      bpl   OUT ; branch if no
      ldy   CurrentContentLengthMinus1
      ldx   #$00
      lda   #MTCharLeftScrollArrow
      jsr   OutputCharInWindowAtXY
      ldx   RightScrollArrowXPos
      lda   #MTCharRightScrollArrow
      jsr   OutputCharInWindowAtXY
OUT:  rts
.endproc

.proc DrawVertScrollBarArrows
      bit   VScrollBarPresentFlag
      bpl   OUT ; branch if no
      ldx   CurrentContentWidthMinus1
      ldy   #$00
      lda   #MTCharUpScrollArrow
      jsr   OutputCharInWindowAtXY
      ldy   DownScrollArrowYPos
      lda   #MTCharDownScrollArrow
      jsr   OutputCharInWindowAtXY
OUT:  rts
.endproc

.proc DrawWindowBottomEdge
      ldy   CurrentContentLengthMinus1
      ldx   #$00
LOOP: lda   #MTCharOverscore
      jsr   OutputCharInWindowAtXY
      inx
      cpx   CurrentContentWidth
      bcc   LOOP
      rts
.endproc

DrawWindowRightEdgeLoopIndex:
      .byte $00
DrawWindowRightEdgeChar:
      .byte $00
DrawWindowRightEdgeSecondChar:
      .byte $00

;;; This draws a column of right vertical bars followed by a column of spaces.
DrawWindowRightEdge:
      lda   #CharSpace
      sta   DrawWindowRightEdgeSecondChar
DrawWindowRightEdge1:
      lda   #MTCharRightVerticalBar
      sta   DrawWindowRightEdgeChar
      lda   #$01
      sta   DrawWindowRightEdgeLoopIndex
      ldx   CurrentContentWidthMinus2
L8BC9:ldy   #$00
L8BCB:lda   DrawWindowRightEdgeChar
      jsr   OutputCharInWindowAtXY
      iny
      cpy   CurrentContentLength
      bcc   L8BCB
      dec   DrawWindowRightEdgeLoopIndex
      bne   L8BE8 ; looped twice; done
      lda   DrawWindowRightEdgeSecondChar
      sta   DrawWindowRightEdgeChar
      ldx   CurrentContentWidthMinus1
      jmp   L8BC9
L8BE8:rts

DrawHorizScrollBarGrayBarChar:
      .byte $00

.proc DrawHorizScrollBarGrayBar
      lda   #MTCharCheckerboard1
      sta   DrawHorizScrollBarGrayBarChar
      ldy   CurrentContentLengthMinus1
      ldx   #$00
LOOP: lda   #$01
      eor   DrawHorizScrollBarGrayBarChar ; toggles btw. checkboard1 & 2
      sta   DrawHorizScrollBarGrayBarChar
      jsr   OutputCharInWindowAtXY
      inx
      cpx   CurrentContentWidth
      bcc   LOOP
      rts
.endproc

.proc DrawVertScrollBarGrayBar
      lda   #MTCharCheckerboard1
      sta   DrawWindowRightEdgeSecondChar
      jmp   DrawWindowRightEdge1
.endproc

;;; Resize box consists of two characters, but which two depends on
;;; properties of the window (whether active, which scroll bars present)
ResizeBoxChars:
      .byte MTCharOverscore, CharSpace ; first set
      .byte MTCharOverscore, MTCharOverscore ; second set
      .byte MTCharRightVerticalBar, CharSpace ; third set
      .byte CharInvSpace, MTCharDottedBox     ; fourth set
      .byte MTCharRightVerticalBar, MTCharDottedBox ; fifth set

ResizeBoxChar1:
      .byte $00
ResizeBoxChar2:
      .byte $00

DrawResizeBox:
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000001
      bne   L8C26          ; branch if horiz scroll bar present
      ldx   #$08           ; use fifth set of characters
      bne   L8C42          ; branch always taken
L8C26:ldx   #$06           ; use fourth set of chars
      bne   L8C42          ; branch always taken
DrawResizeBox1:
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000011
      cmp   #%00000011
      bne   L8C38          ; branch if both scroll bars not present
      ldx   #$00           ; use first set of characters
      beq   L8C42          ;branch always taken
L8C38:cmp   #$01           ; is horizontal bar present?
      bne   L8C40          ; branch if no
      ldx   #$02           ; use second set of characters
      bne   L8C42          ; branch always taken
L8C40:ldx   #$04           ; use third set of characters
L8C42:lda   ResizeBoxChars,x
      sta   ResizeBoxChar1
      inx
      lda   ResizeBoxChars,x
      sta   ResizeBoxChar2
      ldx   CurrentContentWidthMinus2
      ldy   CurrentContentLengthMinus1
      lda   ResizeBoxChar1
      jsr   OutputCharInWindowAtXY
      inx
      lda   ResizeBoxChar2
      jsr   OutputCharInWindowAtXY
      rts

.proc DrawScrollBarsAndResizeBox
      jsr   DrawHorizScrollBar
      jsr   DrawVertScrollBar
      jsr   DrawResizeBoxIfEnabledAndPresent
      rts
.endproc

.proc DrawHorizScrollBar
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000001             ; horiz scroll bar present?
      beq   OUT                    ; branch if no
      ldy   #$10
      lda   (MenuBarOrWindowPtr),y ; horiz control option byte
      and   #%10000000             ; scroll bar present?
      bne   SKIP1                  ; branch if yes
      jsr   DrawWindowBottomEdge
      rts
SKIP1:lda   (MenuBarOrWindowPtr),y ; horiz control option byte
      and   #%00000001             ; scroll bar is active?
      bne   SKIP2                  ; branch if yes
      jsr   DrawWindowBottomEdge
      jsr   DrawHorizScrollBarArrows
      rts
SKIP2:jsr   DrawHorizScrollBarGrayBar
      jsr   DrawHorizScrollBarArrows
      jsr   DrawHorizScrollBox
OUT:  rts
.endproc

.proc DrawVertScrollBar
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000010             ; vert scroll bar present?
      beq   OUT                    ; branch if no
      ldy   #$11
      lda   (MenuBarOrWindowPtr),y ; vert control option byte
      and   #%10000000             ; scroll bar present?
      bne   SKIP1                  ; branch if yes
      jsr   DrawWindowRightEdge
      rts
SKIP1:lda   (MenuBarOrWindowPtr),y ; vert control option byte
      and   #%00000001             ; scroll bar is active?
      bne   SKIP2                  ; branch if yes
      jsr   DrawWindowRightEdge
      jsr   DrawVertScrollBarArrows
      rts
SKIP2:jsr   DrawVertScrollBarGrayBar
      jsr   DrawVertScrollBarArrows
      jsr   DrawVertScrollBox
OUT:  rts
.endproc

.proc DrawResizeBoxIfEnabledAndPresent
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000100             ; has resize box enabled?
      beq   OUT                  ; return if no
      ldy   #$01
      lda   (MenuBarOrWindowPtr),y ; window option byte
      and   #%00000100             ; has resize box?
      beq   SKIP                  ; branch if no
      jsr   DrawResizeBox
      rts
SKIP: jsr   DrawResizeBox1
OUT:  rts
.endproc

.proc DrawRightAndBottomEdgesOfInactiveWindow
      ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000001              ; horiz scroll bar present?
      beq   SKIP1                   ; branch if no
      jsr   DrawWindowBottomEdge
SKIP1:ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000010             ; vertical scroll bar present?
      beq   SKIP2                  ; branch if no
      jsr   DrawWindowRightEdge
SKIP2:ldy   #$16
      lda   (MenuBarOrWindowPtr),y ; window status byte
      and   #%00000100             ; resize box present?
      beq   OUT                    ; branch if no
      jsr   DrawResizeBox1
OUT:  rts
.endproc

DrawHorizScrollBox:
      bit   HBarScrollBoxPresentFlag
      bpl   L8D15          ; return if no
      ldy   #$13
      lda   (MenuBarOrWindowPtr),y ; horiz scroll box position
      jsr   CalcHorizScrollBoxPosition
DrawHorizScrollBoxAtPosInA:
      sta   HorizScrollBoxPosition
      ldy   CurrentContentLengthMinus1
      tax
      lda   #MTCharOverUnderScore
      jsr   OutputCharInWindowAtXY
L8D15:rts

DrawVertScrollBox:
      bit   VBarScrollBoxPresentFlag
      bpl   L8D2E
      ldy   #$15
      lda   (MenuBarOrWindowPtr),y
      jsr   CalcVertScrollBoxPosition
DrawVertScrollBoxAtPosInA:
      sta   VertScrollBoxPosition
      ldx   CurrentContentWidthMinus1
      tay
      lda   #MTCharOverUnderScore
      jsr   OutputCharInWindowAtXY
L8D2E:rts

.proc UndrawHorizScrollBox
      bit   HBarScrollBoxPresentFlag
      bpl   OUT ; branch if no
      ldy   CurrentContentLengthMinus1
      ldx   HorizScrollBoxPosition
      txa
      ror   a
      bcs   ODD ; branch if odd column
      lda   #MTCharCheckerboard2
      bne   SKIP ; branch always taken
ODD:  lda   #MTCharCheckerboard1
SKIP: jsr   OutputCharInWindowAtXY
OUT:  rts
.endproc

.proc UndrawVertScrollBox
      bit   VBarScrollBoxPresentFlag
      bpl   OUT ; branch if no
      ldx   CurrentContentWidthMinus1
      ldy   VertScrollBoxPosition
      lda   #MTCharCheckerboard1
      jsr   OutputCharInWindowAtXY
OUT:  rts
.endproc

.proc DrawHorizScrollBarGrayAreaAndScrollBox
      jsr   UndrawHorizScrollBox
      jsr   DrawHorizScrollBox
      rts
.endproc

.proc DrawVertScrollBarGrayAreaAndScrollBox
      jsr   UndrawVertScrollBox
      jsr   DrawVertScrollBox
      rts
.endproc

.proc MoveHorizScrollBoxToPosInA
      pha
      jsr   UndrawHorizScrollBox
      pla
      jsr   DrawHorizScrollBoxAtPosInA
      rts
.endproc

.proc MoveVertScrollBoxToPosInA
      pha
      jsr   UndrawVertScrollBox
      pla
      jsr   DrawVertScrollBoxAtPosInA
      rts
.endproc

.proc WhichScrollBarInParams
      jsr   GetFrontWindowOrFail
      bcs   ERR
      ldy   #$01
      lda   (ParamTablePtr),y
      cmp   #$02           ; horiz
      beq   HORIZ
      cmp   #$01           ; vert
      beq   VERT
      lda   #ErrInvalidControlID
      sta   LastError
ERR:  sec
      rts
HORIZ:lda   #$00           ; horizontal
      clc
      rts
VERT: lda   #$80           ; vertical
      clc
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $28 (40)
;;; ----------------------------------------
.proc SetCtlMax
      jsr   WhichScrollBarInParams
      bcs   ERR ; bad param
      bne   VERT ; branch if vertical
      iny
      lda   (ParamTablePtr),y
      ldy   #$12
      sta   (MenuBarOrWindowPtr),y ; set horiz scroll max
      sta   HScrollBarMaxPos
      jsr   ClampHorizScrollPos
      jsr   DrawHorizScrollBarGrayAreaAndScrollBox
ERR:  rts
VERT: iny
      lda   (ParamTablePtr),y
      ldy   #$14
      sta   (MenuBarOrWindowPtr),y ; set vertical scroll max
      sta   VScrollBarMaxPos
      jsr   ClampVertScrollPos
      jsr   DrawVertScrollBarGrayAreaAndScrollBox
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $2A (42)
;;; ----------------------------------------
.proc UpdateThumb
      jsr   WhichScrollBarInParams
      bcs   ERR ; bad param
      bne   VERT ; branch if vertical
      iny
      lda   (ParamTablePtr),y
      ldy   #$13
      sta   (MenuBarOrWindowPtr),y ; set horiz scroll box pos
      jsr   ClampHorizScrollPos
      jsr   DrawHorizScrollBarGrayAreaAndScrollBox
ERR:  rts
VERT: iny
      lda   (ParamTablePtr),y
      ldy   #$15
      sta   (MenuBarOrWindowPtr),y ; set vert scroll box pos
      jsr   ClampVertScrollPos
      jsr   DrawVertScrollBarGrayAreaAndScrollBox
      rts
.endproc

;;; ----------------------------------------
;;; ToolKit call $2B (43)
;;; ----------------------------------------
.proc ActivateCtl
      jsr   WhichScrollBarInParams
      bcs   ERR ; bad param
      bne   VERT ; branch if vertical
      iny
      lda   (ParamTablePtr),y ; new active status
      bne   L8DFC ; branch if activate
      ldy   #$10
      lda   (MenuBarOrWindowPtr),y ; clear enabled bit
      and   #%11111110
      sta   (MenuBarOrWindowPtr),y
      jmp   L8E04
L8DFC:ldy   #$10
      lda   (MenuBarOrWindowPtr),y ; set enabled bit
      ora   #%00000001
      sta   (MenuBarOrWindowPtr),y
L8E04:jsr   CacheWindowAndScrollBarGeometry
      jsr   DrawHorizScrollBar
ERR:  rts
VERT: iny
      lda   (ParamTablePtr),y
      bne   L8E1B
      ldy   #$11
      lda   (MenuBarOrWindowPtr),y ; clear enabled bit
      and   #%11111110
      sta   (MenuBarOrWindowPtr),y
      jmp   L8E23
L8E1B:ldy   #$11
      lda   (MenuBarOrWindowPtr),y ; set enabled bit
      ora   #%00000001
      sta   (MenuBarOrWindowPtr),y
L8E23:jsr   CacheWindowAndScrollBarGeometry
      jsr   DrawVertScrollBar
      rts
.endproc

ScrollBoxPositionChanged:
      .byte $00 ; $01 if yes, $00 if no

;;; ----------------------------------------
;;; ToolKit call $29 (41)
;;; ----------------------------------------
.proc TrackThumb
      lda   #TrackingModeScrollBox
      sta   MouseTrackingMode
      jsr   WhichScrollBarInParams
      bcs   DONE
      bne   VERT ; branch if vertical
      jsr   TrackHorizScrollBar
      ldy   #$13
      jmp   SKIP
VERT: jsr   TrackVertScrollBar
      ldy   #$15
SKIP: lda   (MenuBarOrWindowPtr),y
      ldy   #$02
      sta   (ParamTablePtr),y
      lda   ScrollBoxPositionChanged
      iny
      sta   (ParamTablePtr),y
DONE: lda   #TrackingModeNone
      sta   MouseTrackingMode
      rts
.endproc

MouseXOrYCoordInScrollBar:
      .byte $00
PrevMouseXOrYCoordInScrollBar:
      .byte $00
ScrollBoxXOrYCoord:
      .byte $00
CharUnderCursorForScrollBarTracking:
      .byte $00
CurrentWidthOrLengthMinusOneForScrollBarTracking:
      .byte $00

.proc TrackHorizScrollBar
      bit   HBarScrollBoxPresentFlag
      bpl   L8EA4 ; branch if no
      ldx   CurrentContentWidth
      dex
      stx   CurrentWidthOrLengthMinusOneForScrollBarTracking
      lda   MouseXCoord
      sta   MouseXOrYCoordInScrollBar
      sta   PrevMouseXOrYCoordInScrollBar
      sta   EventBuffer2XCoord
      sta   MouseDragTrackingLastXCoord
      jsr   DrawHorizScrollBoxGripAtDragPosition
L8E79:jsr   MouseDragTrackingRoutine
      bcs   L8E92
      lda   EventBuffer2XCoord
      cmp   PrevMouseXOrYCoordInScrollBar
      beq   L8E79
      sta   PrevMouseXOrYCoordInScrollBar
      jsr   RestoreCharUnderHorizScrollBox
      jsr   DrawHorizScrollBoxGripAtDragPosition
      jmp   L8E79
L8E92:jsr   RestoreCharUnderHorizScrollBox
      lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      bne   L8EA4
      lda   MouseXOrYCoordInScrollBar
      cmp   EventBuffer2XCoord
      bne   L8EAA
L8EA4:lda   #$00
      sta   ScrollBoxPositionChanged
      rts
L8EAA:lda   #$01
      sta   ScrollBoxPositionChanged
      jsr   ClampHorizScrollBoxDragPosition
      lda   ScrollBoxXOrYCoord
      jsr   ScaleHScrollBoxXCoordToPos
      ldy   #$13
      sta   (MenuBarOrWindowPtr),y ; current horiz scroll box pos
      lda   ScrollBoxXOrYCoord
      jsr   MoveHorizScrollBoxToPosInA
      rts
.endproc

.proc TrackVertScrollBar
      bit   VBarScrollBoxPresentFlag
      bpl   L8F0C
      ldx   CurrentContentLength
      dex
      stx   CurrentWidthOrLengthMinusOneForScrollBarTracking
      lda   MouseYCoord
      sta   MouseXOrYCoordInScrollBar
      sta   PrevMouseXOrYCoordInScrollBar
      sta   EventBuffer2YCoord
      sta   MouseDragTrackingLastYCoord
      jsr   DrawVertScrollBoxGripAtDragPosition
L8EE1:jsr   MouseDragTrackingRoutine
      bcs   L8EFA
      lda   EventBuffer2YCoord
      cmp   PrevMouseXOrYCoordInScrollBar
      beq   L8EE1
      sta   PrevMouseXOrYCoordInScrollBar
      jsr   RestoreCharUnderVertScrollBox
      jsr   DrawVertScrollBoxGripAtDragPosition
      jmp   L8EE1
L8EFA:jsr   RestoreCharUnderVertScrollBox
      lda   EventBuffer2EventType
      cmp   #EventTypeButtonUp
      bne   L8F0C
      lda   MouseXOrYCoordInScrollBar
      cmp   EventBuffer2YCoord
      bne   L8F12
L8F0C:lda   #$00
      sta   ScrollBoxPositionChanged
      rts
L8F12:lda   #$01
      sta   ScrollBoxPositionChanged
      jsr   ClampVertScrollBoxDragPosition
      lda   ScrollBoxXOrYCoord
      jsr   ScaleVScrollBoxXCoordToPos
      ldy   #$15
      sta   (MenuBarOrWindowPtr),y ; current vert scroll box pos
      lda   ScrollBoxXOrYCoord
      jsr   MoveVertScrollBoxToPosInA
      rts
.endproc

.proc ClampHorizScrollBoxDragPosition
      lda   #$00
      sta   ScreenCoordinatesX+1 ; convert event x coord to window coordinates
      lda   EventBuffer2XCoord
      sta   ScreenCoordinatesX
      jsr   ConvertScreenCoordToWindowCoord
      lda   WindowCoordinatesX+1
      bmi   L8F50 ; branch if negative
      bne   L8F54
      lda   WindowCoordinatesX
      cmp   #$01
      bcc   L8F50 ; branch if X coord < 1
      cmp   CurrentWidthOrLengthMinusOneForScrollBarTracking
      bcs   L8F54 ; branch if X coord >= max
L8F4C:sta   ScrollBoxXOrYCoord
      rts
L8F50:lda   #$01
      bne   L8F4C ; branch always taken
L8F54:ldx   CurrentWidthOrLengthMinusOneForScrollBarTracking
      dex
      txa
      jmp   L8F4C
.endproc

.proc ClampVertScrollBoxDragPosition
      lda   #$00
      sta   ScreenCoordinatesY+1
      lda   EventBuffer2YCoord
      sta   ScreenCoordinatesY
      jsr   ConvertScreenCoordToWindowCoord
      lda   WindowCoordinatesY+1
      bmi   L8F81
      bne   L8F85
      lda   WindowCoordinatesY
      cmp   #$01
      bcc   L8F81
      cmp   CurrentWidthOrLengthMinusOneForScrollBarTracking
      bcs   L8F85
L8F7D:sta   ScrollBoxXOrYCoord
      rts
L8F81:lda   #$01
      bne   L8F7D ; branch always taken
L8F85:ldx   CurrentWidthOrLengthMinusOneForScrollBarTracking
      dex
      txa
      jmp   L8F7D
.endproc

.proc DrawHorizScrollBoxGripAtDragPosition
      jsr   ClampHorizScrollBoxDragPosition
      jsr   SaveCharUnderHorizScrollBox
      jsr   DrawHorizScrollBoxGrip
      rts
.endproc

.proc DrawVertScrollBoxGripAtDragPosition
      jsr   ClampVertScrollBoxDragPosition
      jsr   SaveCharUnderVertScrollBox
      jsr   DrawVertScrollBoxGrip
      rts
.endproc

.proc DrawHorizScrollBoxGrip
      ldx   ScrollBoxXOrYCoord
      ldy   CurrentContentLengthMinus1
      lda   #CharCheckerboard
      jsr   OutputCharInWindowAtXY
      rts
.endproc

.proc DrawVertScrollBoxGrip
      ldy   ScrollBoxXOrYCoord
      ldx   CurrentContentWidthMinus1
      lda   #CharCheckerboard
      jsr   OutputCharInWindowAtXY
      rts
.endproc

.proc SaveCharUnderHorizScrollBox
      jsr   HideCursor
      ldy   CurrentContentLengthMinus1
      ldx   ScrollBoxXOrYCoord
      jsr   GetCharAtXYWithinWindow
      sta   CharUnderCursorForScrollBarTracking
      jsr   ShowCursor
      rts
.endproc

.proc SaveCharUnderVertScrollBox
      jsr   HideCursor
      ldx   CurrentContentWidthMinus1
      ldy   ScrollBoxXOrYCoord
      jsr   GetCharAtXYWithinWindow
      sta   CharUnderCursorForScrollBarTracking
      jsr   ShowCursor
      rts
.endproc

.proc RestoreCharUnderHorizScrollBox
      ldx   ScrollBoxXOrYCoord
      ldy   CurrentContentLengthMinus1
      lda   CharUnderCursorForScrollBarTracking
      jsr   OutputCharInWindowAtXY
      rts
.endproc

.proc RestoreCharUnderVertScrollBox
      ldy   ScrollBoxXOrYCoord
      ldx   CurrentContentWidthMinus1
      lda   CharUnderCursorForScrollBarTracking
      jsr   OutputCharInWindowAtXY
      rts
.endproc
