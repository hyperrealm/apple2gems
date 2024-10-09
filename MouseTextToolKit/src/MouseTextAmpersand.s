
        .FEATURE string_escapes
        
        .include "Applesoft.s"
        .include "MouseTextToolKitDefines.s"
        .include "BASICSystem.s"
        .include "OpCodes.s"
        .include "Monitor.s"
        .include "ZeroPage.s"
        .include "Vectors.s"

        .setcpu "6502"


;;; Zero Page Pointers used by SetMenuHandler
MenuZPPointerTable         := $85
MenuKeyCharsArrayZPPointer := $85 ; this is also FORPNT
MenuOptionsArrayZPPointer  := $87
MenuNamesArrayZPPointer    := $89
MenuInfoArrayZPPointer     := $8B
MenuItemStructZPPointer    := $8D        
MenuStructBufferZPPointer  := $8F
MenuZPPointerTableSize = MenuStructBufferZPPointer + 2 - MenuZPPointerTable
        
        .org $1FFE
        
        .addr   $0DAC           ; code length

ToolkitEntryPointAddress:
        .addr   $0000           ; MTTK entry point address
InstallAmpersand:
        lda     InitializedFlag
        beq     @NotInitialized
        jmp     FailWithUndefdFnError
@NotInitialized:
        lda     Vector::AMPERV+2
        cmp     AmpersandEntryPointAddress+1
        bne     @SetAmperVector
        lda     Vector::AMPERV+1
        cmp     AmpersandEntryPointAddress
        bne     @SetAmperVector
        jmp     FailWithUndefdFnError
@SetAmperVector:
        lda     Vector::AMPERV+1
        sta     SavedAMPERV
        sec
        sbc     #1
        sta     NextAmperRoutine
        lda     Vector::AMPERV+2
        sta     SavedAMPERV+1
        sbc     #0
        sta     NextAmperRoutine+1
        lda     AmpersandEntryPointAddress
        sta     Vector::AMPERV+1
        lda     AmpersandEntryPointAddress+1
        sta     Vector::AMPERV+2
        rts

InitializedFlag:
        .byte   $00             ; BUG! never gets written
SavedAMPERV:
        .addr   $0000
NextAmperRoutine:
        .addr   $00
AmpersandEntryPointAddress:
        .addr   AmpersandEntryPoint
SavedTXTPTR:
        .addr   $0000
CommandChar:
        .byte   $00
MTTKCommandNUM:
        .byte   $00
InputOutputIntParamCountsOffset:
        .byte   $00
ParamCounter:
        .byte   $00
ParamOffset:
        .byte   $00
NumIntParams:
        .byte   $00
TempTXTPTR:
        .addr   $0000

        .byte   $00             ; unused

;;; Data locations used by SetMenuHandler
NumberOfMenus:
        .byte   $00
NumberOfMenuItems:
        .byte   $00
MenuItemCounter:
        .byte   $00
MenuCounter:
        .byte   $00
MenuArrayArgCounter:
        .byte   $00
MenuArrayPointerOffset: 
        .byte   $00
  
MTTKError:
        .byte   $00
MaxMenuItemsPlus1:
        .byte   $00
NumberOfPages:
        .byte   $00             ; temporary value used by AllocateBuffers
UnusedAddr:
        .addr   $0000           ; never read
        .byte   $00,$00         ; unused
WindowStructOffsetLoopIndex:
        .byte   $00
ContentXOffset:
        .word   $0000
ContentYOffset:
        .word   $0000
ContentWindowID:
        .byte   $00
TempValue2:
        .byte   $00             ; used in OpenWindowHandler
TempValue3:
        .byte   $00             ; used in WinStringHandler
WindowOptions:
        .byte   $00
MenuStructWritePointer:
        .addr   $0000
TempValue4:
        .byte   $00             ; used in SetMenuHandler
StructBufferStartPage:
        .byte   $00
SaveAreaBufferStartPage:
        .byte   $00
WindowStructBufferStartPage:
        .byte   $00
WindowSaveAreaBufferStartPage:
        .byte   $00
WindowStructBufferAddress: 
        .addr   $0000
MenuSaveAreaBufferStartPage:
        .byte   $00
TempValue1:
        .byte   $00             ; used in NextWindowHandler
;;; zero page locations $85 (FORPNT) through $90 are saved
SavedZeroPage:
SavedFORPNT:
        .addr   $A0A0
        .addr   $E1E6
        .addr   $F4B2
        .addr   $A0EE
        .addr   $A0A0
        .addr   $80A0
;;; Maps each byte of a window info structure to a corresponding
;;; offset in a window info array (of ints); $FF indicates that the
;;; byte should be ignored.
WindowStructOffsetToArrayOffsetMap:
        .byte   $FF,$00,$FF,$01,$05,$04,$07,$06
        .byte   $FF,$08,$FF,$09,$FF,$0A,$FF,$0B
        .byte   $FF,$0C,$FF,$0D,$FF,$10,$FF,$11
        .byte   $FF,$12,$FF,$13,$FF,$14,$FF,$15
        .byte   $23,$22,$25,$24

PointerTable:
WindowInfoArrayPointer:
        .addr   $80A0           ; KC% array pointer, WI% array pointer
WindowTitleStringPtr:
        .addr   $A0B7           ; OB% array pointer
RelativeArrayPointer:
        .addr   $E4A0           ; NA$ array pointer
        .addr   $A0B8           ; MI% array pointer
        .addr   $A0A0           ; menu item struct pointer
MenuStructBufferAddress:        ; menu struct pointer
        .addr   $A0A0

MenuArrayRowStrides:
        .byte   $E5             ; KC%
        .byte   $A0             ; OB%
        .byte   $A0             ; NA$
        .byte   $04             ; MI%

;;; Amounts by which to advance pointers in NextMenu loop.
PointerOffsetsForNextMenu:
        .byte   $02,$02,$03,$04,$04,$0A

;;; Amounts by which to advance pointers in NextMenuItem loop.
PointerOffsetsForNextMenuItem:
        .byte   $02,$02,$03,$00,$06,$00

;;; The same values are written here as are written to
;;; MenuArrayRowStrides, so these are redundant.
MenuArrayRowStrides2:
        .byte   $A0             ; KC%
        .byte   $AC             ; OB%
        .byte   $80             ; NA$

;;; Ampersand statement descriptors. Each consists of:
;;; - the statement string
;;; - the MTTK call number
;;; - the number of parameters to the MTTK call
;;; - the address of the handler function
;;; - for some statements, an offset into InputOutputIntParamCounts
        
StartDesktopStmt:
        .asciiz "STRTDSKTP"
        .byte   MTTKCall::StartDeskTop
        .byte   6
        .addr   StartDesktopHandler-1

StopDesktopStmt:
        .asciiz "STPDSKTP"
        .byte   MTTKCall::StopDeskTop
        .byte   0
        .addr   StopDesktopHandler-1

SetCursorStmt:
        .asciiz "STCRSR"
        .byte   MTTKCall::SetCursor
        .byte   1
        .addr   OneIntArgHandler-1

ShowCursorStmt:
        .asciiz "SHWCRSR"
        .byte   MTTKCall::ShowCursor
        .byte   0
        .addr   NoArgsHandler-1

HideCursorStmt:
        .asciiz "HDCRSR"
        .byte   MTTKCall::HideCursor
        .byte   0
        .byte   $00               ; erroneous byte (BUG!)
        .addr   NoArgsHandler-1

CheckEventsStmt:
        .asciiz "CHCKEVNTS"
        .byte   MTTKCall::CheckEvents
        .byte   0
        .addr   NoArgsHandler-1

GetEventStmt:
        .asciiz "GTEVNT"
        .byte   MTTKCall::GetEvent
        .byte   3
        .addr   AllIntOutputArgsHandler-1

FlushEventsStmt:
        .asciiz "FLSHEVNTS"
        .byte   MTTKCall::FlushEvents
        .byte   0
        .addr   NoArgsHandler-1

SetKeyEventStmt:
        .asciiz "STKYEVNT"
        .byte   MTTKCall::SetKeyEvent
        .byte   1
        .addr   OneIntArgHandler-1

InitMenuStmt:
        .asciiz "INITMNU"
        .byte   MTTKCall::InitMenu
        .byte   2
        .addr   InitMenuHandler-1

SetMenuStmt:
        .asciiz "STMNU"
        .byte   MTTKCall::SetMenu
        .byte   1
        .addr   SetMenuHandler-1

MenuSelectStmt:
        .asciiz "MNUSLCT"
        .byte   MTTKCall::MenuSelect
        .byte   2
        .addr   AllIntOutputArgsHandler-1

MenuKeyStmt:
        .asciiz "MNUKY"
        .byte   MTTKCall::MenuKey
        .byte   4
        .addr   InputAndOutputIntParamsHandler-1
        .byte   0 ; offset into InputOutputIntParamCounts

HiliteMenuStmt:
        .asciiz "HILTMNU"
        .byte   MTTKCall::HiliteMenu
        .byte   1
        .addr   OneIntArgHandler-1

DisableMenuStmt:
        .asciiz "DSABLMNU"
        .byte   MTTKCall::DisableMenu
        .byte   2
        .addr   OneIntArgHandler-1

DisableMenuItemStmt:
        .asciiz "DSABLITM"
        .byte   MTTKCall::DisableMenuItem
        .byte   3
        .addr   OneIntArgHandler-1

CheckMenuItemStmt:
        .asciiz "CHCKITM"
        .byte   MTTKCall::CheckMenuItem
        .byte   3
        .addr   OneIntArgHandler-1

DesktopErrorStmt:
        .asciiz "DSKTPERR"
        .byte   $FF
        .byte   $FF
        .addr   DesktopErrorHandler-1

VersionStmt:
        .asciiz "VRSN"
        .byte   MTTKCall::Version
        .byte   2
        .addr   VersionHandler-1

SetMarkStmt:
        .asciiz "STMRK"
        .byte   MTTKCall::SetMark
        .byte   4
        .addr   OneIntArgHandler-1

PeekEventStmt:
        .asciiz "PKEVNT"
        .byte   MTTKCall::PeekEvent
        .byte   3
        .addr   AllIntOutputArgsHandler-1

ObscureCursorStmt:
        .asciiz "OBCRSR"
        .byte   MTTKCall::ObscureCursor
        .byte   0
        .addr   NoArgsHandler-1

InitWindowMgrStmt:
        .asciiz "INITWM"
        .byte   MTTKCall::InitWindowMgr
        .byte   2
        .addr   InitWindowMgrHandler-1

OpenWindowStmt:
        .asciiz "OPNWNDW"
        .byte   MTTKCall::OpenWindow
        .byte   1
        .addr   OpenWindowHandler-1

CloseWindowStmt:
        .asciiz "CLSWNDW"
        .byte   MTTKCall::CloseWindow
        .byte   1
        .addr   OneIntArgHandler-1

CloseAllWindowsStmt:
        .asciiz "CLSALL"
        .byte   MTTKCall::CloseAllWindows
        .byte   0
        .addr   NoArgsHandler-1

FindWindowStmt:
        .asciiz "FDWNDW"
        .byte   MTTKCall::FindWindow
        .byte   4
        .addr   InputAndOutputIntParamsHandler-1
        .byte   4 ; offset into InputOutputIntParamCounts

FrontWindowStmt:
        .asciiz "FRNTWNDW"
        .byte   MTTKCall::FrontWindow
        .byte   1
        .addr   AllIntOutputArgsHandler-1

SelectWindowStmt:
        .asciiz "SLCTWNDW"
        .byte   MTTKCall::SelectWindow
        .byte   1
        .addr   OneIntArgHandler-1

TrackGoAwayStmt:
        .asciiz "TRCKGA"
        .byte   MTTKCall::TrackGoAway
        .byte   1
        .addr   AllIntOutputArgsHandler-1

DragWindowStmt:
        .asciiz "DRGWNDW"
        .byte   MTTKCall::DragWindow
        .byte   3
        .addr   OneIntArgHandler-1

GrowWindowStmt:
        .asciiz "GWNDW"
        .byte   MTTKCall::GrowWindow
        .byte   1
        .addr   AllIntOutputArgsHandler-1

ActivateControlStmt:
        .asciiz "ACTVTCTL"
        .byte   MTTKCall::ActivateControl
        .byte   2
        .addr   OneIntArgHandler-1

FindControlStmt:
        .asciiz "FDCTL"
        .byte   MTTKCall::FindControl
        .byte   4
        .addr   FindControlHandler-1

SetControlMaxStmt:
        .asciiz "STCTLMX"
        .byte   MTTKCall::SetControlMax
        .byte   2
        .addr   OneIntArgHandler-1

TrackThumbStmt:
        .asciiz "TRCKTHMB"
        .byte   MTTKCall::TrackThumb
        .byte   3
        .addr   InputAndOutputIntParamsHandler-1
        .byte   8 ; offset into InputOutputIntParamCounts

UpdateThumbStmt:
        .asciiz "UPDTTHMB"
        .byte   MTTKCall::UpdateThumb
        .byte   2
        .addr   OneIntArgHandler-1

WindowToScreenStmt:
        .asciiz "WN2SCR"
        .byte   MTTKCall::WindowToScreen
        .byte   5
        .addr   WindowScreenCoordHandler-1

ScreenToWindowStmt:
        .asciiz "SCR2WN"
        .byte   MTTKCall::ScreenToWindow
        .byte   5
        .addr   WindowScreenCoordHandler-1

SetContentStatement:
        .asciiz "STCNTNT"
        .byte   $FF
        .byte   4
        .addr   SetContentHandler-1

GetWindowInfoStmt:
        .asciiz "GTWNFO"
        .byte   MTTKCall::GetWinPtr
        .byte   2
        .addr   GetWindowInfoHandler-1

PostEventStmt:
        .asciiz "PSTEVNT"
        .byte   MTTKCall::PostEvent
        .byte   3
        .addr   OneIntArgHandler-1

SetInterruptModeBitStmt:
        .asciiz "STIMB"
        .byte   $FF
        .byte   1
        .addr   SetInterruptModeBitHandler-1

NextWindowStmt:
        .asciiz "NXTWNDW"
        .byte   MTTKCall::GetWinPtr
        .byte   2
        .addr   NextWindowHandler-1

KeyboardMouseStmt:
        .asciiz "KYBRDMSE"
        .byte   MTTKCall::KeyboardMouse
        .byte   0
        .addr   NoArgsHandler-1

WinCharStmt:
        .asciiz "WNCHR"
        .byte   MTTKCall::WinChar
        .byte   4
        .addr   WinOpWinCharHandler-1

WinStringStmt:
        .asciiz "WNSTR"
        .byte   MTTKCall::WinString
        .byte   5
        .addr   WinStringHandler-1

WinOpStmt:
        .asciiz "WNOP"
        .byte   MTTKCall::WinOp
        .byte   4
        .addr   WinOpWinCharHandler-1

MTTKCopyrightStmt:
        .asciiz "MTXCPYRT"
        .byte   $FF
        .byte   1
        .addr   MTTKCopyrightHandler-1

DispatchTable:
        .addr   StartDesktopStmt
        .addr   StopDesktopStmt
        .addr   SetCursorStmt
        .addr   ShowCursorStmt
        .addr   HideCursorStmt
        .addr   CheckEventsStmt
        .addr   GetEventStmt
        .addr   FlushEventsStmt
        .addr   SetKeyEventStmt
        .addr   InitMenuStmt
        .addr   SetMenuStmt
        .addr   MenuSelectStmt
        .addr   MenuKeyStmt
        .addr   HiliteMenuStmt
        .addr   DisableMenuStmt
        .addr   DisableMenuItemStmt
        .addr   CheckMenuItemStmt
        .addr   DesktopErrorStmt
        .addr   VersionStmt
        .addr   SetMarkStmt
        .addr   PeekEventStmt
        .addr   ObscureCursorStmt
        .addr   InitWindowMgrStmt
        .addr   OpenWindowStmt
        .addr   CloseWindowStmt
        .addr   CloseAllWindowsStmt
        .addr   FindWindowStmt
        .addr   FrontWindowStmt
        .addr   SelectWindowStmt
        .addr   TrackGoAwayStmt
        .addr   DragWindowStmt
        .addr   GrowWindowStmt
        .addr   ActivateControlStmt
        .addr   FindControlStmt
        .addr   SetControlMaxStmt
        .addr   TrackThumbStmt
        .addr   UpdateThumbStmt
        .addr   WindowToScreenStmt
        .addr   ScreenToWindowStmt
        .addr   SetContentStatement
        .addr   GetWindowInfoStmt
        .addr   PostEventStmt
        .addr   SetInterruptModeBitStmt
        .addr   NextWindowStmt
        .addr   KeyboardMouseStmt
        .addr   WinCharStmt
        .addr   WinStringStmt
        .addr   WinOpStmt
        .addr   MTTKCopyrightStmt
        .addr   $0000

InputOutputIntParamCounts:
        .byte   $02,$03,$02,$01 ; MenuKey (2 outputs, then 2 inputs)
        .byte   $02,$01,$02,$03 ; FindWindow (2 inputs, then 2 outputs)
        .byte   $01,$01,$02,$02 ; TrackThumb (1 input, then 2 outputs)

CallMTTK:
        jsr     MTTKIndirectJump
MTTKCommand:
        .byte   $00
        .addr   MTTKParamTable
        sta     MTTKError
        beq     @OK
        jmp     FailWithIllegalQtyError
@OK:    rts
MTTKIndirectJump:
        jmp     (ToolkitEntryPointAddress)

MTTKParamTable:
MTTKParamTable_Count:
        .byte   $AA
MTTKParamTable_Params:
        .byte   $A0,$A0,$EC,$A0,$A0,$A0,$A0,$A0
        .byte   $A0,$B6,$A0,$A0,$A0,$A0,$A0,$B6
        .byte   $F4,$A0,$A0

AmpersandEntryPoint:
        lda     ZeroPage::TXTPTR ; Save original TXTPTR
        sta     SavedTXTPTR
        lda     ZeroPage::TXTPTR+1
        sta     SavedTXTPTR+1
        lda     ZeroPage::FORPNT ; Save original FORPNT
        sta     SavedFORPNT
        lda     ZeroPage::FORPNT+1
        sta     SavedFORPNT+1
        lda     DispatchTable
        sta     ZeroPage::FORPNT
        lda     DispatchTable+1
        sta     ZeroPage::FORPNT+1
        ldy     #$00
        ldx     #$00
L23BB:  jsr     ZeroPage::CHRGOT
L23BE:  cmp     $61             ; BUG! should be #'a' (#$61)
        bcc     L23CB
        cmp     $7A             ; BUG! should be #'z' (#$7A)
        beq     L23C8
        bcs     L23CB
L23C8:  sec
        sbc     #$20            ; convert to uppercase
L23CB:  sta     CommandChar
        lda     (ZeroPage::FORPNT),y
        beq     L23E3
        cmp     CommandChar
        bne     L23EC
        inc     ZeroPage::FORPNT
        bne     L23DD
        inc     ZeroPage::FORPNT+1
L23DD:  jsr     ZeroPage::CHRGET
        jmp     L23BE
L23E3:  jsr     ZeroPage::CHRGOT
        beq     L2414
        cmp     #'('
        beq     L2414
L23EC:  lda     SavedTXTPTR
        sta     ZeroPage::TXTPTR
        lda     SavedTXTPTR+1
        sta     ZeroPage::TXTPTR+1
        inx
        inx
        lda     DispatchTable+1,x
        beq     L2409
        sta     ZeroPage::FORPNT+1
        lda     DispatchTable,x
        sta     ZeroPage::FORPNT
        ldy     #$00
        jmp     L23BB
L2409:  lda     NextAmperRoutine+1        ; push address of next Amper routine onto stack
        pha
        lda     NextAmperRoutine
        pha
        jmp     L243A
L2414:  ldy     #$01
        lda     (ZeroPage::FORPNT),y     ; get command number
        sta     MTTKCommandNUM
        iny
        lda     (ZeroPage::FORPNT),y     ; get param count
        sta     MTTKParamTable
        ldy     #$05
        lda     (ZeroPage::FORPNT),y
        sta     InputOutputIntParamCountsOffset
        dey
        lda     (ZeroPage::FORPNT),y     ; push command handler address on stack
        pha
        dey
        lda     (ZeroPage::FORPNT),y
        pha
        lda     ZeroPage::FORPNT
        sta     UnusedAddr           ; never read
        lda     ZeroPage::FORPNT+1
        sta     UnusedAddr+1           ; never read
L243A:  lda     SavedFORPNT     ; restore original FORPNT
        sta     ZeroPage::FORPNT
        lda     SavedFORPNT+1
        sta     ZeroPage::FORPNT+1
        rts                     ; jumps to the command handler

GetIntInputParams:
        lda     #1
        sta     ParamCounter
L244A:  jsr     ApplesoftRoutine::GETBYT
        txa
        ldx     ParamOffset
        sta     MTTKParamTable,x
        lda     ParamCounter
        cmp     NumIntParams
        bne     L245D
        rts
L245D:  inc     ParamCounter
        inc     ParamOffset
        jsr     ApplesoftRoutine::CHKCOM
        jmp     L244A

        
SetIntOutputParams:
        lda     #1
        sta     ParamCounter
L246E:  jsr     ApplesoftRoutine::PTRGET
        ldy     #0
        lda     #0
        sta     (ZeroPage::VARPNT),y
        ldx     ParamOffset
        lda     MTTKParamTable,x
        iny
        sta     (ZeroPage::VARPNT),y
        lda     ParamCounter
        cmp     NumIntParams
        bne     L2489
        rts
L2489:  inc     ParamCounter
        inc     ParamOffset
        jsr     ApplesoftRoutine::CHKCOM
        jmp     L246E

;;; Get pointer to array, subtract ARYTAB from it, and return result in A,X
GetRelativeArrayPointer:
        jsr     ApplesoftRoutine::GETARYPT
        lda     ZeroPage::LOWTR
        sec
        sbc     ZeroPage::ARYTAB
        tax
        lda     ZeroPage::LOWTR+1
        sbc     ZeroPage::ARYTAB+1
        rts

MakeMTTKCall:
        lda     MTTKCommandNUM
        sta     MTTKCommand
        jsr     CallMTTK
        rts

NoArgsHandler:
        jsr     MakeMTTKCall
        jsr     ZeroPage::CHRGOT
        jmp     FinishStatement

StopDesktopHandler:
        jsr     MakeMTTKCall
        lda     SavedAMPERV
        sta     Vector::AMPERV+1
        lda     SavedAMPERV+1
        sta     Vector::AMPERV+2
        lda     #0
        sta     InitializedFlag
        jsr     ZeroPage::CHRGOT
        jmp     FinishStatement

OneIntArgHandler:
        jsr     ApplesoftRoutine::CHKOPN
        lda     MTTKParamTable
        sta     NumIntParams
        lda     #1
        sta     ParamOffset
        jsr     GetIntInputParams
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

SetInterruptModeBitHandler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETBYT
        txa
        beq     L24F7
        sei
        jmp     L24F8
L24F7:  cli
L24F8:  jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

AllIntOutputArgsHandler:
        jsr     ApplesoftRoutine::CHKOPN
        lda     MTTKParamTable
        sta     NumIntParams
        lda     #1
        sta     ParamOffset
        jsr     MakeMTTKCall
        jsr     SetIntOutputParams
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

VersionHandler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     MakeMTTKCall
        lda     #2            ; version: 2
        sta     MTTKParamTable+3
        lda     #1            ; revision: 1
        sta     MTTKParamTable+4
        lda     #4
        sta     NumIntParams
        lda     #1
        sta     ParamOffset
        jsr     SetIntOutputParams
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

InputAndOutputIntParamsHandler:
        jsr     ApplesoftRoutine::CHKOPN
        ldx     InputOutputIntParamCountsOffset
        lda     InputOutputIntParamCounts,x
        sta     NumIntParams
        lda     InputOutputIntParamCounts+1,x
        sta     ParamOffset
        jsr     GetIntInputParams
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCOM
        ldx     InputOutputIntParamCountsOffset
        lda     InputOutputIntParamCounts+2,x
        sta     NumIntParams
        lda     InputOutputIntParamCounts+3,x
        sta     ParamOffset
        jsr     SetIntOutputParams
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

FindControlHandler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::FRMEVL ; get X coordinate (word)
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACMO
        sta     MTTKParamTable+2
        lda     ZeroPage::FACLO
        sta     MTTKParamTable+1
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::FRMEVL ; get Y coordinate (word)
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACMO
        sta     MTTKParamTable+4
        lda     ZeroPage::FACLO
        sta     MTTKParamTable+3
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCOM
        lda     #2
        sta     NumIntParams
        lda     #5
        sta     ParamOffset
        jsr     SetIntOutputParams
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

GetWindowIDAndXYCoordArgs:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETBYT ; get Window ID (byte)
        stx     MTTKParamTable+1
        jsr     ApplesoftRoutine::CHKCOM ; get X coordinate (word)
        jsr     ApplesoftRoutine::FRMEVL
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACMO
        sta     MTTKParamTable+3
        lda     ZeroPage::FACLO
        sta     MTTKParamTable+2
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::FRMEVL ; get Y coordinate (word)
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACMO
        sta     MTTKParamTable+5
        lda     ZeroPage::FACLO
        sta     MTTKParamTable+4
        rts

WindowScreenCoordHandler:
        jsr     GetWindowIDAndXYCoordArgs
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::PTRGET
        ldy     #0            ; set output X coord
        lda     MTTKParamTable+7
        sta     (ZeroPage::VARPNT),y
        iny
        lda     MTTKParamTable+6
        sta     (ZeroPage::VARPNT),y
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::PTRGET
        ldy     #0            ; set output Y coord
        lda     MTTKParamTable+9
        sta     (ZeroPage::VARPNT),y
        iny
        lda     MTTKParamTable+8
        sta     (ZeroPage::VARPNT),y
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

WinOpWinCharHandler:
        jsr     GetWindowIDAndXYCoordArgs
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::GETBYT ; get char arg
        stx     MTTKParamTable+6
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

WinStringHandler:
        jsr     GetWindowIDAndXYCoordArgs
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::PTRGET
        sta     MTTKParamTable+6
        sty     MTTKParamTable+7
        sec
        sbc     ZeroPage::ARYTAB
        sta     TempValue3
        tya
        sbc     ZeroPage::ARYTAB+1
        bmi     L264B
        sta     MTTKParamTable+7
        lda     TempValue3
        sta     MTTKParamTable+6
        lda     #(MTTKWindowOption::BASICArrayElem | MTTKWindowOption::BASICString)
        bne     L264D
L264B:  lda     #MTTKWindowOption::BASICString
L264D:  sta     MTTKParamTable+8
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

CopyrightText:
        .byte   "MouseText Tool Kit Ampersand Package\r"
        .byte   "Copyright Apple Computer, Inc. 1985"
CopyrightTextAddr:
        .addr   CopyrightText

MTTKCopyrightHandler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::PTRGET
        lda     #(CopyrightTextAddr-CopyrightText) ; text length
        ldy     #$00
        sta     (ZeroPage::VARPNT),y
        lda     CopyrightTextAddr
        iny
        sta     (ZeroPage::VARPNT),y
        lda     CopyrightTextAddr+1
        iny
        sta     (ZeroPage::VARPNT),y
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

;;; Looks up the window struct for the given Window ID, and stores
;;; the content array pointer and x- and y-offsets of the content
;;; into the unused space after the end of the window struct. Then
;;; calls WriteTextToWindow to write the window contents, with the
;;; Window ID in A and the pointer to the window struct in X,Y.
SetContentHandler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETBYT ; get Window ID
        stx     MTTKParamTable+1
        lda     #$02
        sta     MTTKParamTable
        lda     #MTTKCall::GetWinPtr ; get window struct ptr
        sta     MTTKCommand
        jsr     CallMTTK
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::GETBYT ; get "reserved" parameter
        stx     DisableMenuStmt ; this must be a bug!
        jsr     ApplesoftRoutine::CHKCOM
        jsr     GetRelativeArrayPointer ; get pointer to content array
        stx     ContentStringArrayPtr
        sta     ContentStringArrayPtr+1
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::FRMEVL ; get x-offset
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACMO
        sta     ContentXOffset+1
        lda     ZeroPage::FACLO
        sta     ContentXOffset
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::FRMEVL ; get y-offset
        jsr     ApplesoftRoutine::AYINT
        lda     ZeroPage::FACMO
        sta     ContentYOffset+1
        lda     ZeroPage::FACLO
        sta     ContentYOffset
        lda     MTTKParamTable+2
        sta     ZeroPage::VARPNT
        lda     MTTKParamTable+3
        sta     ZeroPage::VARPNT+1
        ldy     #$20            ; offset pointer to after end of window struct
        lda     ContentStringArrayPtr ; store the content array pointer
        sta     (ZeroPage::VARPNT),y
        iny
        lda     ContentStringArrayPtr+1
        sta     (ZeroPage::VARPNT),y
        iny
        lda     ContentXOffset  ; store the x-offset
        sta     (ZeroPage::VARPNT),y
        iny
        lda     ContentXOffset+1
        sta     (ZeroPage::VARPNT),y
        iny
        lda     ContentYOffset  ; store the y-offset
        sta     (ZeroPage::VARPNT),y
        iny
        lda     ContentYOffset+1
        sta     (ZeroPage::VARPNT),y
        lda     MTTKParamTable+1 ; load window ID into A
        ldx     MTTKParamTable+2 ; and window struct ptr into X,Y
        ldy     MTTKParamTable+3
        jsr     WriteTextToWindow
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

StartDesktopHandler:
        jsr     ApplesoftRoutine::CHKOPN
        lda     #2
        sta     NumIntParams
        lda     #1
        sta     ParamOffset
        jsr     GetIntInputParams
        lda     #0
        sta     MTTKParamTable+3
        jsr     ApplesoftRoutine::CHKCOM
        lda     ZeroPage::TXTPTR
        sta     TempTXTPTR
        lda     ZeroPage::TXTPTR+1
        sta     TempTXTPTR+1
        lda     #4
        sta     ParamOffset
        lda     #3
        sta     NumIntParams
        jsr     GetIntInputParams
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jsr     FinishStatement
        lda     TempTXTPTR
        sta     ZeroPage::TXTPTR
        lda     TempTXTPTR+1
        sta     ZeroPage::TXTPTR+1
        lda     #4
        sta     ParamOffset
        lda     #2
        sta     NumIntParams
        jsr     SetIntOutputParams
        lda     #MTTKCall::SetBasAdr ; sets string base address to ARYTAB
        sta     MTTKCommand
        lda     #1
        sta     MTTKParamTable
        lda     #ZeroPage::ARYTAB
        sta     MTTKParamTable+1
        lda     #0
        sta     MTTKParamTable+2
        jsr     CallMTTK
        jsr     ApplesoftRoutine::DATA
        rts

InitWindowMgrHandler:
        jsr     AllocateBuffers
        lda     StructBufferStartPage
        sta     WindowStructBufferStartPage
        sta     WindowStructBufferAddress+1
        lda     #0
        sta     WindowStructBufferAddress
        lda     SaveAreaBufferStartPage
        sta     WindowSaveAreaBufferStartPage
        rts

InitMenuHandler:
        jsr     AllocateBuffers
        lda     StructBufferStartPage
        sta     MenuStructBufferAddress+1
        lda     #0
        sta     MenuStructBufferAddress
        lda     SaveAreaBufferStartPage
        sta     MenuSaveAreaBufferStartPage
        rts

;;; Allocate a buffer for the data structure (window or menu)
;;; and another one for the save area (window or menu)
AllocateBuffers: 
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETBYT ; # of pages for save area
        txa
        sta     NumberOfPages
        jsr     BASICSystem::GETBUFR
        bcc     L27FC
        jmp     FailWithOutOfMemoryError
L27FC:  sta     MTTKParamTable+2 ; high byte of save area buffer address
        lda     NumberOfPages
        sta     MTTKParamTable+4 ; high byte of save area buffer size
        lda     #$00
        sta     MTTKParamTable+1 ; low byte of save area buffer address
        sta     MTTKParamTable+3 ; low byte of save area buffer size
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::GETBYT ; # of pages for data structure
        txa
        sta     NumberOfPages
        jsr     BASICSystem::GETBUFR
        bcc     L281F
        jmp     FailWithOutOfMemoryError
L281F:  sta     StructBufferStartPage ; high byte of struct buffer address
        clc
        adc     NumberOfPages
        sta     SaveAreaBufferStartPage ; high byte of save area buffer address
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jsr     FinishStatement
        rts

SetMenuHandler:
        lda     MenuStructBufferAddress+1
        cmp     MenuSaveAreaBufferStartPage
        bne     @MemOK
        jmp     FailWithOutOfMemoryError
@MemOK: jsr     ApplesoftRoutine::CHKOPN
        lda     #2
        sta     NumIntParams
        lda     #3
        sta     ParamOffset
        jsr     GetIntInputParams ; get menu count and max menu items
        lda     MTTKParamTable+4
        clc
        adc     #1
        sta     MaxMenuItemsPlus1
        asl     a
        sta     MenuArrayRowStrides ; (max menu items + 1) * 2 [2 = integer value size]
        sta     MenuArrayRowStrides+1 ; ditto
        sta     MenuArrayRowStrides2   ; ditto
        sta     MenuArrayRowStrides2+1 ; ditto
        clc
        adc     MaxMenuItemsPlus1
        sta     MenuArrayRowStrides+2 ; (max menu items + 1) * 3 [3 = string value size]
        sta     MenuArrayRowStrides2+2 ; ditto
        lda     #3            ; number of array pointers to copy
        sta     MenuArrayArgCounter
        lda     #6
        sta     MenuArrayPointerOffset           ; saved array pointer offset
NextMenuArrayArg:
        jsr     ApplesoftRoutine::CHKCOM ; loop over array arguments
        jsr     ApplesoftRoutine::GETARYPT ; and store pointers to them
        ldx     MenuArrayPointerOffset     ; in PointerTable
        ldy     MenuArrayArgCounter
        clc
        lda     #9            ; advance past array header (9 bytes for 2-dimensional array)
        adc     MenuArrayRowStrides,y
        adc     ZeroPage::LOWTR
        sta     PointerTable,x
        lda     ZeroPage::LOWTR+1
        adc     #0
        sta     PointerTable+1,x
        dec     MenuArrayPointerOffset
        dec     MenuArrayPointerOffset
        dec     MenuArrayArgCounter
        bpl     NextMenuArrayArg
        lda     RelativeArrayPointer
        sec
        sbc     ZeroPage::ARYTAB
        sta     RelativeArrayPointer
        lda     RelativeArrayPointer+1
        sbc     ZeroPage::ARYTAB+1
        sta     RelativeArrayPointer+1
        ldx     #MenuZPPointerTableSize-1 ; save zero page locations
@CopyPointersToZP:
        lda     MenuZPPointerTable,x
        sta     SavedZeroPage,x
        lda     PointerTable,x  ; copy pointers computed above to zero page locations
        sta     MenuZPPointerTable,x
        dex
        bpl     @CopyPointersToZP
        lda     MTTKParamTable+3
        ldy     #0
        sta     (MenuStructBufferZPPointer),y
        sta     NumberOfMenus
        lda     #0
        ldy     #1
        sta     (MenuStructBufferZPPointer),y
        lda     MenuStructBufferZPPointer     ; advance MenuStructBufferZPPointer by 2
        clc
        adc     #2
        sta     MenuStructBufferZPPointer
        bcc     L28DC
        inc     MenuStructBufferZPPointer+1
L28DC:  lda     NumberOfMenus
        asl     a               ; multiply by 10 (the size of a menu block)
        asl     a
        clc
        adc     NumberOfMenus
        asl     a
        adc     MenuStructBufferZPPointer     ; compute pointer to menu item structure
        sta     MenuItemStructZPPointer
        lda     MenuStructBufferZPPointer+1
        adc     #0
        sta     MenuItemStructZPPointer+1
        lda     NumberOfMenus   ; menu count * 4 (# of bytes in all menu structure headers)
        asl     a
        asl     a
        clc
        adc     MenuItemStructZPPointer
        sta     MenuStructWritePointer
        lda     MenuItemStructZPPointer+1
        adc     #0
        sta     MenuStructWritePointer+1
        jsr     BoundsCheckMenuStructWritePointer
        lda     #1
        sta     MenuCounter
        lda     #0
        sta     MenuItemCounter
NextMenu:
        ldy     #1 ; set menu ID
        lda     (MenuInfoArrayZPPointer),y
        ldy     #0
        sta     (MenuStructBufferZPPointer),y
        iny
        lda     (MenuOptionsArrayZPPointer),y  ; set menu options
        ora     #(MTTKWindowOption::BASICArrayElem | MTTKWindowOption::BASICString)
        sta     (MenuStructBufferZPPointer),y
        lda     MenuNamesArrayZPPointer     ; set pointer to menu title string
        iny
        sta     (MenuStructBufferZPPointer),y
        lda     MenuNamesArrayZPPointer+1
        iny
        sta     (MenuStructBufferZPPointer),y
        lda     MenuItemStructZPPointer     ; set pointer to menu info structure
        iny
        sta     (MenuStructBufferZPPointer),y
        lda     MenuItemStructZPPointer+1
        iny
        sta     (MenuStructBufferZPPointer),y
        ldy     #3
        lda     (MenuInfoArrayZPPointer),y
        ldy     #0
        sta     (MenuItemStructZPPointer),y
        sta     NumberOfMenuItems
        asl     a               ; multiply by 6 (size of menu item block)
        sta     TempValue4
        asl     a
        adc     TempValue4
        clc
        adc     MenuStructWritePointer ; and add it to MenuStructWritePointer
        sta     MenuStructWritePointer ; to advance to next menu item block
        lda     #0
        adc     MenuStructWritePointer+1
        sta     MenuStructWritePointer+1
        jsr     BoundsCheckMenuStructWritePointer
        ldx     #$0A
        ldy     #5
InitMenuArrayPointers:
        lda     MenuZPPointerTable,x
        clc
        adc     PointerOffsetsForNextMenu,y
        sta     MenuZPPointerTable,x
        lda     MenuZPPointerTable+1,x
        adc     #0
        sta     MenuZPPointerTable+1,x
        dex
        dex
        dey
        bpl     InitMenuArrayPointers
NextMenuItem:
        ldy     #1            ; set menu item options byte
        lda     (MenuOptionsArrayZPPointer),y
        ora     #(MTTKWindowOption::BASICArrayElem | MTTKWindowOption::BASICString)
        ldy     #0
        sta     (MenuItemStructZPPointer),y
        lda     #0            ; set mark character (0 = default)
        iny
        sta     (MenuItemStructZPPointer),y
        ldy     #0            ; set key character 1
        lda     (MenuKeyCharsArrayZPPointer),y
        ldy     #2
        sta     (MenuItemStructZPPointer),y
        ldy     #1            ; set key character 2
        lda     (MenuKeyCharsArrayZPPointer),y
        ldy     #3
        sta     (MenuItemStructZPPointer),y
        lda     MenuNamesArrayZPPointer     ; set pointer to menu item title string
        ldy     #4
        sta     (MenuItemStructZPPointer),y
        lda     MenuNamesArrayZPPointer+1
        iny
        sta     (MenuItemStructZPPointer),y
        ldx     #$0A
        ldy     #5
AdvancePointersToNextMenuItem:
        lda     MenuZPPointerTable,x
        clc
        adc     PointerOffsetsForNextMenuItem,y
        sta     MenuZPPointerTable,x
        lda     MenuZPPointerTable+1,x
        adc     #0
        sta     MenuZPPointerTable+1,x
        dex
        dex
        dey
        bpl     AdvancePointersToNextMenuItem
        inc     MenuItemCounter
        lda     NumberOfMenuItems
        cmp     MenuItemCounter
        bne     NextMenuItem
        lda     NumberOfMenus
        cmp     MenuCounter
        beq     MenusDone
        inc     MenuCounter
        ldx     #4
        ldy     #2
AdvancePointersToNextMenu:
        lda     PointerTable,x
        clc
        adc     MenuArrayRowStrides2,y
        sta     PointerTable,x
        sta     ZeroPage::FORPNT,x
        lda     PointerTable+1,x
        adc     #0
        sta     PointerTable+1,x
        sta     ZeroPage::FORPNT+1,x
        dex
        dex
        dey
        bpl     AdvancePointersToNextMenu
        lda     #0
        sta     MenuItemCounter ; reset menu item counter
        jmp     NextMenu
MenusDone:
        jsr     RestoreZeroPage
        lda     MenuStructBufferAddress ; make the SetMenu call
        sta     MTTKParamTable+1
        lda     MenuStructBufferAddress+1
        sta     MTTKParamTable+2
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

RestoreZeroPage:
        ldx     #MenuZPPointerTableSize-1
@Loop:  lda     SavedZeroPage,x
        sta     MenuZPPointerTable,x
        dex
        bpl     @Loop
        rts

BoundsCheckMenuStructWritePointer:
        lda     MenuSaveAreaBufferStartPage
        cmp     MenuStructWritePointer+1
        bcc     @OutOfRange
        bne     @OK
        lda     MenuStructWritePointer
        beq     @OK
@OutOfRange:
        jsr     RestoreZeroPage
        jmp     FailWithOutOfMemoryError
@OK:    rts

OpenWindowHandler:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     GetRelativeArrayPointer
        tay                     ; store pointer to window info array at PointerTable
        txa
        clc
        adc     #9              ; skip past array header (9 bytes for 2-dimensional array)
        sta     WindowInfoArrayPointer
        tya
        adc     #0
        sta     WindowInfoArrayPointer+1
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::PTRGET ; get pointer to window title string
        sta     WindowTitleStringPtr
        sty     WindowTitleStringPtr+1
        sec                     ; find out if it's an array element
        sbc     ZeroPage::ARYTAB
        sta     TempValue2
        tya
        sbc     ZeroPage::ARYTAB+1
        bmi     L2A61
        sta     WindowTitleStringPtr+1
        lda     TempValue2
        sta     WindowTitleStringPtr
        lda     #(MTTKWindowOption::DocPtrFn | MTTKWindowOption::BASICArrayElem | MTTKWindowOption::BASICString)
        sta     WindowOptions
        jmp     L2A66
L2A61:  lda     #(MTTKWindowOption::DocPtrFn | MTTKWindowOption::BASICString)
        sta     WindowOptions
L2A66:  lda     WindowInfoArrayPointer
        clc
        adc     ZeroPage::ARYTAB
        sta     WindowInfoArrayPointer
        lda     WindowInfoArrayPointer+1
        adc     ZeroPage::ARYTAB+1
        sta     WindowInfoArrayPointer+1
        jsr     ApplesoftRoutine::CHKCOM
        jsr     ApplesoftRoutine::GETARYPT ; get pointer to window content string array
        lda     ZeroPage::LOWTR            ; and convert it to a relative pointer
        sec
        sbc     ZeroPage::ARYTAB
        sta     RelativeArrayPointer
        lda     ZeroPage::LOWTR+1
        sbc     ZeroPage::ARYTAB+1
        sta     RelativeArrayPointer+1
        ldx     #$03
L2A8E:  lda     ZeroPage::FORPNT,x
        sta     SavedFORPNT,x
        dex
        bpl     L2A8E
        lda     #0            ; allocate a window struct buffer ($2A bytes)
        sta     ZeroPage::FORPNT ; $20 for struct + $A extra bytes, of which $6 are ever used
        lda     WindowStructBufferStartPage ; pointer to struct goes into FORPNT
        sta     ZeroPage::FORPNT+1
L2A9F:  lda     WindowStructBufferAddress
        cmp     ZeroPage::FORPNT
        bne     L2AAD
        lda     WindowStructBufferAddress+1
        cmp     ZeroPage::FORPNT+1
        beq     L2AC5
L2AAD:  ldy     #$16
        lda     (ZeroPage::FORPNT),y ; read window status byte
        and     #MTTKWindowStatus::Open ; check if it's open
        beq     L2AE1           ; no
        clc                     ; otherwise advance to next window struct
        lda     ZeroPage::FORPNT
        adc     #$2A
        sta     ZeroPage::FORPNT
        lda     ZeroPage::FORPNT+1
        adc     #$00
        sta     ZeroPage::FORPNT+1
        jmp     L2A9F
L2AC5:  lda     ZeroPage::FORPNT
        clc
        adc     #$2A
        sta     WindowStructBufferAddress
        lda     ZeroPage::FORPNT+1
        adc     #$00
        sta     WindowStructBufferAddress+1
        cmp     WindowSaveAreaBufferStartPage
        bne     L2AE1
        lda     WindowStructBufferAddress
        beq     L2AE1
        jmp     FailWithOutOfMemoryError
L2AE1:  lda     ZeroPage::FORPNT ; set the window struct ptr in the param table
        sta     MTTKParamTable+1
        lda     ZeroPage::FORPNT+1
        sta     MTTKParamTable+2
        lda     WindowInfoArrayPointer
        sta     MenuOptionsArrayZPPointer
        lda     WindowInfoArrayPointer+1
        sta     MenuOptionsArrayZPPointer+1
        lda     #$23
        sta     WindowStructOffsetLoopIndex
L2AFA:  ldy     WindowStructOffsetLoopIndex
        lda     (MenuOptionsArrayZPPointer),y
        ldx     WindowStructOffsetLoopIndex
        ldy     WindowStructOffsetToArrayOffsetMap,x
        bmi     L2B09
        sta     (ZeroPage::FORPNT),y
L2B09:  dec     WindowStructOffsetLoopIndex
        bpl     L2AFA
        ldy     #$01
        lda     (ZeroPage::FORPNT),y ; window option byte
        ora     WindowOptions
        sta     (ZeroPage::FORPNT),y
        ldy     #$0E            ; pointer to user window routine
        lda     WriteTextToWindowAddress
        sta     (ZeroPage::FORPNT),y
        iny
        lda     WriteTextToWindowAddress+1
        sta     (ZeroPage::FORPNT),y
        ldy     #$1C            ; screen area covered
        lda     #$00
        sta     (ZeroPage::FORPNT),y
        iny
        sta     (ZeroPage::FORPNT),y
        iny
        sta     (ZeroPage::FORPNT),y
        iny
        sta     (ZeroPage::FORPNT),y
        ldy     #$20            ; content array pointer
        lda     RelativeArrayPointer
        sta     (ZeroPage::FORPNT),y
        iny
        lda     RelativeArrayPointer+1
        sta     (ZeroPage::FORPNT),y
        ldy     #$02            ; pointer to title string
        lda     WindowTitleStringPtr
        sta     (ZeroPage::FORPNT),y
        iny
        lda     WindowTitleStringPtr+1
        sta     (ZeroPage::FORPNT),y
        ldx     #$03
L2B4F:  lda     SavedFORPNT,x
        sta     ZeroPage::FORPNT,x
        dex
        bpl     L2B4F
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

GetWindowInfoHandler:
        lda     ZeroPage::FORPNT ; save FORPNT
        sta     WindowInfoArrayPointer
        lda     ZeroPage::FORPNT+1
        sta     WindowInfoArrayPointer+1
        jsr     GetWindowPointer
        jsr     ApplesoftRoutine::GETARYPT ; get pointer to window info array into LOWTR
        ldy     #$06                       ; check array size
        lda     (ZeroPage::LOWTR),y
        sec
        sbc     #$13            ; 19 elements needed
        dey
        lda     (ZeroPage::LOWTR),y
        sbc     #$00
        bpl     L2B81
        jmp     FailWithBadSubscriptError ; array too small
L2B81:  lda     ZeroPage::LOWTR
        clc
        adc     #$09            ; start element 1 (element 0 is reserved)
        sta     ZeroPage::LOWTR ; store element address in LOWTR
        lda     ZeroPage::LOWTR+1
        adc     #$00
        sta     ZeroPage::LOWTR+1
        lda     MTTKParamTable+2 ; store address of window structure in FORPNT
        sta     ZeroPage::FORPNT
        lda     MTTKParamTable+3
        sta     ZeroPage::FORPNT+1
        lda     #$23            ; loop over the 36 bytes of the window structure
        sta     WindowStructOffsetLoopIndex
L2B9D:  ldx     WindowStructOffsetLoopIndex
        ldy     WindowStructOffsetToArrayOffsetMap,x
        bpl     L2BA9
        lda     #$00            ; value was $FF, indicating this byte is ignored
        bpl     L2BAB
L2BA9:  lda     (ZeroPage::FORPNT),y ; copy byte from window struct...
L2BAB:  ldy     WindowStructOffsetLoopIndex
        sta     (ZeroPage::LOWTR),y ; ...to window info array
        dec     WindowStructOffsetLoopIndex
        bpl     L2B9D
        lda     WindowInfoArrayPointer
        sta     ZeroPage::FORPNT
        lda     WindowInfoArrayPointer+1
        sta     ZeroPage::FORPNT+1
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

NextWindowHandler:
        jsr     GetWindowPointer
        lda     MTTKParamTable+2 ; copy window struct pointer to LOWTR
        sta     ZeroPage::LOWTR
        lda     MTTKParamTable+3
        sta     ZeroPage::LOWTR+1
        ldy     #$19            ; read pointer to next window struct
        lda     (ZeroPage::LOWTR),y
        bne     L2BDD
        sta     MTTKParamTable+1
        beq     L2BF1           ; If high byte is 0, this is the last window
L2BDD:  sta     TempValue1
        dey
        lda     (ZeroPage::LOWTR),y
        sta     ZeroPage::LOWTR ; and store it in LOWTR
        lda     TempValue1
        sta     ZeroPage::LOWTR+1
        ldy     #$00
        lda     (ZeroPage::LOWTR),y ; get the window ID
        sta     MTTKParamTable+1
L2BF1:  lda     #$01
        sta     NumIntParams
        sta     ParamOffset
        jsr     SetIntOutputParams
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

GetWindowPointer:
        jsr     ApplesoftRoutine::CHKOPN
        jsr     ApplesoftRoutine::GETBYT
        stx     MTTKParamTable+1
        jsr     MakeMTTKCall
        jsr     ApplesoftRoutine::CHKCOM
        rts

DesktopErrorHandler:
        jsr     ApplesoftRoutine::CHKOPN
        lda     MTTKCommand
        sta     MTTKParamTable+1
        lda     MTTKError
        sta     MTTKParamTable+2
        lda     #2
        sta     NumIntParams
        lda     #1
        sta     ParamOffset
        jsr     SetIntOutputParams
        jsr     ApplesoftRoutine::CHKCLS
        jmp     FinishStatement

WriteTextToWindowAddress:
       .addr   WriteTextToWindow
WriteTextToWindow:
        sta     ContentWindowID ; Window ID
        lda     ZeroPage::FORPNT ; save FORPNT
        sta     TempPointer02
        lda     ZeroPage::FORPNT+1
        sta     TempPointer02+1
        stx     ZeroPage::FORPNT ; save window struct ptr in FORPNT
        sty     ZeroPage::FORPNT+1
        ldy     #$09
        lda     (ZeroPage::FORPNT),y ; current content length
        sta     CurrentContentLength
        ldy     #$20            ; offset past end of window struct
        lda     (ZeroPage::FORPNT),y ; get pointer to content array
        clc
        adc     ZeroPage::ARYTAB ; and add it to ARYTAB to get absolute pointer
        sta     ContentStringArrayPtr
        iny
        lda     (ZeroPage::FORPNT),y
        adc     ZeroPage::ARYTAB+1
        sta     ContentStringArrayPtr+1
        ldy     #$22            ; get content x-offset
        lda     #$00
        sec
        sbc     (ZeroPage::FORPNT),y
        sta     XOffset1
        lda     #$00
        iny
        sbc     (ZeroPage::FORPNT),y
        sta     XOffset1+1
        ldy     #$25            ; get content y-offset
        lda     (ZeroPage::FORPNT),y
        sta     ContentYOffset+1
        dey
        lda     (ZeroPage::FORPNT),y
        sta     ContentYOffset
        clc
        adc     ContentYOffset
        sta     YOffset1
        lda     ContentYOffset+1
        adc     ContentYOffset+1
        sta     YOffset1+1
        lda     YOffset1
        clc
        adc     ContentYOffset
        sta     YOffset2
        lda     YOffset1+1
        adc     ContentYOffset+1
        sta     YOffset2+1
        lda     ContentStringArrayPtr
        sta     ZeroPage::FORPNT
        clc
        adc     #$07
        sta     ContentStringArrayPtr
        lda     ContentStringArrayPtr+1
        sta     ZeroPage::FORPNT+1
        adc     #$00
        sta     ContentStringArrayPtr+1
        lda     ContentStringArrayPtr
        clc
        adc     YOffset2
        sta     ContentStringArrayPtr
        lda     ContentStringArrayPtr+1
        adc     YOffset2+1
        sta     ContentStringArrayPtr+1
        ldy     #$06
        lda     (ZeroPage::FORPNT),y
        sta     ContentYEndOffset
        dey
        lda     (ZeroPage::FORPNT),y
        sta     ContentYEndOffset+1
        lda     ContentWindowID
        sta     MTTKParamTable+1
        lda     #MTTKWinOp::ClearWindow
        sta     MTTKParamTable+6
        lda     #$04
        sta     MTTKParamTable
        lda     #MTTKCall::WinOp
        sta     MTTKCommand
        jsr     CallMTTK
        lda     #$00
        sta     CurrentContentLine
WriteCurrentContentLine:
        lda     CurrentContentLength
        cmp     CurrentContentLine
        bcc     WriteContentDone
        lda     ContentYEndOffset+1
        cmp     ContentYOffset+1
        bcc     WriteContentDone
        bne     L2D0E
        lda     ContentYOffset
        cmp     ContentYEndOffset
        bcs     WriteContentDone
L2D0E:  lda     ContentYOffset+1
        bmi     AdvanceToNextContentLine
        lda     #MTTKCall::WinString ; write line of content to window
        sta     MTTKCommand
        lda     #$05            ; param count
        sta     MTTKParamTable
        lda     ContentWindowID ; Window ID
        sta     MTTKParamTable+1
        lda     CurrentContentLine
        sta     MTTKParamTable+4 ; y-coord
        lda     #$00
        sta     MTTKParamTable+5
        lda     XOffset1
        sta     MTTKParamTable+2 ; x-coord
        lda     XOffset1+1
        sta     MTTKParamTable+3 ; pointer to string
        lda     ContentStringArrayPtr
        sta     MTTKParamTable+6
        lda     ContentStringArrayPtr+1
        sta     MTTKParamTable+7
        lda     #MTTKWindowOption::BASICString  ; pointer type (BASIC string)
        sta     MTTKParamTable+8
        jsr     CallMTTK
AdvanceToNextContentLine:
        inc     CurrentContentLine
        lda     ContentStringArrayPtr
        clc
        adc     #$03            ; advance to next content array element
        sta     ContentStringArrayPtr
        lda     ContentStringArrayPtr+1
        adc     #$00
        sta     ContentStringArrayPtr+1
        lda     ContentYOffset  ; increment ContentYOffset
        clc
        adc     #$01
        sta     ContentYOffset
        bcc     L2D70
        inc     ContentYOffset+1
L2D70:  jmp     WriteCurrentContentLine
WriteContentDone:
        lda     TempPointer02   ; restore FORPNT and return
        sta     ZeroPage::FORPNT
        lda     TempPointer02+1
        sta     ZeroPage::FORPNT+1
        clc
        lda     #$00
        rts

TempPointer02:  
        .addr   $0000

;;; Used by WriteTextToWindow:
ContentStringArrayPtr:
        .addr   $0000
CurrentContentLength:
        .byte   $00
CurrentContentLine:
        .byte   $00
        .byte   $00             ; unused
ContentYEndOffset:
        .word   $0000
;;; some x-offset
XOffset1:
        .word   $0000
;;; some y-offset
YOffset1:
        .word   $0000
;;; some y-offset
YOffset2:
        .word   $0000

FinishStatement:
        bne     FailWithSyntaxError
        rts

FailWithIllegalQtyError:
        ldx     #ApplesoftError::IllegalQuantity
        jmp     ApplesoftRoutine::ERROR

FailWithSyntaxError:
        ldx     #ApplesoftError::SyntaxError
        jmp     ApplesoftRoutine::ERROR

FailWithOutOfMemoryError:
        ldx     #ApplesoftError::OutOfMemory
        jmp     ApplesoftRoutine::ERROR

FailWithUndefdFnError:
        ldx     #ApplesoftError::UndefdFunction
        jmp     ApplesoftRoutine::ERROR

FailWithBadSubscriptError:
        ldx     #ApplesoftError::BadSubscript
        jmp     ApplesoftRoutine::ERROR

RelocationTable:
        .byte   $81,$03,$00,$00,$81,$08,$00,$00
        .byte   $81,$0E,$00,$00,$81,$16,$00,$00
        .byte   $81,$1B,$00,$00,$81,$21,$00,$00
        .byte   $81,$27,$00,$00,$81,$2D,$00,$00
        .byte   $81,$32,$00,$00,$81,$35,$00,$00
        .byte   $81,$3B,$00,$00,$81,$46,$00,$00
        .byte   $81,$CF,$00,$00,$81,$DC,$00,$00
        .byte   $81,$E7,$00,$00,$81,$F3,$00,$00
        .byte   $81,$FF,$00,$00,$81,$0D,$01,$00
        .byte   $81,$18,$01,$00,$81,$26,$01,$00
        .byte   $81,$33,$01,$00,$81,$3F,$01,$00
        .byte   $81,$49,$01,$00,$81,$55,$01,$00
        .byte   $81,$5F,$01,$00,$81,$6C,$01,$00
        .byte   $81,$79,$01,$00,$81,$86,$01,$00
        .byte   $81,$92,$01,$00,$81,$9F,$01,$00
        .byte   $81,$A8,$01,$00,$81,$B2,$01,$00
        .byte   $81,$BD,$01,$00,$81,$C8,$01,$00
        .byte   $81,$D3,$01,$00,$81,$DF,$01,$00
        .byte   $81,$EB,$01,$00,$81,$F6,$01,$00
        .byte   $81,$01,$02,$00,$81,$0F,$02,$00
        .byte   $81,$1C,$02,$00,$81,$27,$02,$00
        .byte   $81,$33,$02,$00,$81,$3D,$02,$00
        .byte   $81,$4A,$02,$00,$81,$54,$02,$00
        .byte   $81,$60,$02,$00,$81,$6D,$02,$00
        .byte   $81,$7B,$02,$00,$81,$86,$02,$00
        .byte   $81,$91,$02,$00,$81,$9D,$02,$00
        .byte   $81,$A8,$02,$00,$81,$B4,$02,$00
        .byte   $81,$BE,$02,$00,$81,$CA,$02,$00
        .byte   $81,$D7,$02,$00,$81,$E1,$02,$00
        .byte   $81,$EB,$02,$00,$81,$F4,$02,$00
        .byte   $81,$01,$03,$00,$81,$03,$03,$00
        .byte   $81,$05,$03,$00,$81,$07,$03,$00
        .byte   $81,$09,$03,$00,$81,$0B,$03,$00
        .byte   $81,$0D,$03,$00,$81,$0F,$03,$00
        .byte   $81,$11,$03,$00,$81,$13,$03,$00
        .byte   $81,$15,$03,$00,$81,$17,$03,$00
        .byte   $81,$19,$03,$00,$81,$1B,$03,$00
        .byte   $81,$1D,$03,$00,$81,$1F,$03,$00
        .byte   $81,$21,$03,$00,$81,$23,$03,$00
        .byte   $81,$25,$03,$00,$81,$27,$03,$00
        .byte   $81,$29,$03,$00,$81,$2B,$03,$00
        .byte   $81,$2D,$03,$00,$81,$2F,$03,$00
        .byte   $81,$31,$03,$00,$81,$33,$03,$00
        .byte   $81,$35,$03,$00,$81,$37,$03,$00
        .byte   $81,$39,$03,$00,$81,$3B,$03,$00
        .byte   $81,$3D,$03,$00,$81,$3F,$03,$00
        .byte   $81,$41,$03,$00,$81,$43,$03,$00
        .byte   $81,$45,$03,$00,$81,$47,$03,$00
        .byte   $81,$49,$03,$00,$81,$4B,$03,$00
        .byte   $81,$4D,$03,$00,$81,$4F,$03,$00
        .byte   $81,$51,$03,$00,$81,$53,$03,$00
        .byte   $81,$55,$03,$00,$81,$57,$03,$00
        .byte   $81,$59,$03,$00,$81,$5B,$03,$00
        .byte   $81,$5D,$03,$00,$81,$5F,$03,$00
        .byte   $81,$61,$03,$00,$81,$63,$03,$00
        .byte   $81,$74,$03,$00,$81,$77,$03,$00
        .byte   $81,$7A,$03,$00,$81,$7F,$03,$00
        .byte   $81,$83,$03,$00,$81,$9C,$03,$00
        .byte   $81,$A1,$03,$00,$81,$A6,$03,$00
        .byte   $81,$AB,$03,$00,$81,$AE,$03,$00
        .byte   $81,$B3,$03,$00,$81,$CC,$03,$00
        .byte   $81,$D3,$03,$00,$81,$E1,$03,$00
        .byte   $81,$ED,$03,$00,$81,$F2,$03,$00
        .byte   $81,$F9,$03,$00,$81,$00,$04,$00
        .byte   $81,$07,$04,$00,$81,$0A,$04,$00
        .byte   $81,$0E,$04,$00,$81,$12,$04,$00
        .byte   $81,$19,$04,$00,$81,$1F,$04,$00
        .byte   $81,$26,$04,$00,$81,$33,$04,$00
        .byte   $81,$38,$04,$00,$81,$3B,$04,$00
        .byte   $81,$40,$04,$00,$81,$48,$04,$00
        .byte   $81,$4F,$04,$00,$81,$52,$04,$00
        .byte   $81,$55,$04,$00,$81,$58,$04,$00
        .byte   $81,$5E,$04,$00,$81,$61,$04,$00
        .byte   $81,$67,$04,$00,$81,$6C,$04,$00
        .byte   $81,$78,$04,$00,$81,$7B,$04,$00
        .byte   $81,$81,$04,$00,$81,$84,$04,$00
        .byte   $81,$8A,$04,$00,$81,$8D,$04,$00
        .byte   $81,$93,$04,$00,$81,$A4,$04,$00
        .byte   $81,$A7,$04,$00,$81,$AA,$04,$00
        .byte   $81,$AE,$04,$00,$81,$B4,$04,$00
        .byte   $81,$B7,$04,$00,$81,$BA,$04,$00
        .byte   $81,$C0,$04,$00,$81,$C8,$04,$00
        .byte   $81,$CE,$04,$00,$81,$D4,$04,$00
        .byte   $81,$D7,$04,$00,$81,$DC,$04,$00
        .byte   $81,$DF,$04,$00,$81,$E2,$04,$00
        .byte   $81,$E8,$04,$00,$81,$F5,$04,$00
        .byte   $81,$FC,$04,$00,$81,$02,$05,$00
        .byte   $81,$05,$05,$00,$81,$0A,$05,$00
        .byte   $81,$0D,$05,$00,$81,$10,$05,$00
        .byte   $81,$16,$05,$00,$81,$1C,$05,$00
        .byte   $81,$21,$05,$00,$81,$26,$05,$00
        .byte   $81,$2B,$05,$00,$81,$30,$05,$00
        .byte   $81,$33,$05,$00,$81,$39,$05,$00
        .byte   $81,$3F,$05,$00,$81,$42,$05,$00
        .byte   $81,$45,$05,$00,$81,$48,$05,$00
        .byte   $81,$4B,$05,$00,$81,$4E,$05,$00
        .byte   $81,$51,$05,$00,$81,$57,$05,$00
        .byte   $81,$5A,$05,$00,$81,$5D,$05,$00
        .byte   $81,$60,$05,$00,$81,$63,$05,$00
        .byte   $81,$66,$05,$00,$81,$6C,$05,$00
        .byte   $81,$7A,$05,$00,$81,$7F,$05,$00
        .byte   $81,$8D,$05,$00,$81,$92,$05,$00
        .byte   $81,$95,$05,$00,$81,$9D,$05,$00
        .byte   $81,$A2,$05,$00,$81,$A5,$05,$00
        .byte   $81,$AB,$05,$00,$81,$B4,$05,$00
        .byte   $81,$C2,$05,$00,$81,$C7,$05,$00
        .byte   $81,$D5,$05,$00,$81,$DA,$05,$00
        .byte   $81,$DE,$05,$00,$81,$E1,$05,$00
        .byte   $81,$EC,$05,$00,$81,$F2,$05,$00
        .byte   $81,$FF,$05,$00,$81,$05,$06,$00
        .byte   $81,$0D,$06,$00,$81,$10,$06,$00
        .byte   $81,$19,$06,$00,$81,$1C,$06,$00
        .byte   $81,$22,$06,$00,$81,$25,$06,$00
        .byte   $81,$2E,$06,$00,$81,$31,$06,$00
        .byte   $81,$37,$06,$00,$81,$3F,$06,$00
        .byte   $81,$42,$06,$00,$81,$45,$06,$00
        .byte   $81,$4E,$06,$00,$81,$51,$06,$00
        .byte   $81,$57,$06,$00,$81,$A1,$06,$00
        .byte   $81,$B0,$06,$00,$81,$B6,$06,$00
        .byte   $81,$BF,$06,$00,$81,$C8,$06,$00
        .byte   $81,$CD,$06,$00,$81,$D2,$06,$00
        .byte   $81,$D5,$06,$00,$81,$DE,$06,$00
        .byte   $81,$E4,$06,$00,$81,$E7,$06,$00
        .byte   $81,$EA,$06,$00,$81,$F8,$06,$00
        .byte   $81,$FD,$06,$00,$81,$0B,$07,$00
        .byte   $81,$10,$07,$00,$81,$13,$07,$00
        .byte   $81,$18,$07,$00,$81,$1F,$07,$00
        .byte   $81,$25,$07,$00,$81,$2B,$07,$00
        .byte   $81,$31,$07,$00,$81,$37,$07,$00
        .byte   $81,$3D,$07,$00,$81,$42,$07,$00
        .byte   $81,$45,$07,$00,$81,$48,$07,$00
        .byte   $81,$4B,$07,$00,$81,$51,$07,$00
        .byte   $81,$59,$07,$00,$81,$5E,$07,$00
        .byte   $81,$61,$07,$00,$81,$66,$07,$00
        .byte   $81,$6E,$07,$00,$81,$73,$07,$00
        .byte   $81,$78,$07,$00,$81,$7D,$07,$00
        .byte   $81,$80,$07,$00,$81,$83,$07,$00
        .byte   $81,$89,$07,$00,$81,$8C,$07,$00
        .byte   $81,$91,$07,$00,$81,$98,$07,$00
        .byte   $81,$9D,$07,$00,$81,$A0,$07,$00
        .byte   $81,$A5,$07,$00,$81,$AA,$07,$00
        .byte   $81,$AF,$07,$00,$81,$B4,$07,$00
        .byte   $81,$B7,$07,$00,$81,$BE,$07,$00
        .byte   $81,$C1,$07,$00,$81,$C4,$07,$00
        .byte   $81,$C7,$07,$00,$81,$CC,$07,$00
        .byte   $81,$CF,$07,$00,$81,$D2,$07,$00
        .byte   $81,$D6,$07,$00,$81,$D9,$07,$00
        .byte   $81,$DC,$07,$00,$81,$E1,$07,$00
        .byte   $81,$E4,$07,$00,$81,$E7,$07,$00
        .byte   $81,$F2,$07,$00,$81,$FA,$07,$00
        .byte   $81,$FD,$07,$00,$81,$00,$08,$00
        .byte   $81,$03,$08,$00,$81,$08,$08,$00
        .byte   $81,$0B,$08,$00,$81,$15,$08,$00
        .byte   $81,$1D,$08,$00,$81,$20,$08,$00
        .byte   $81,$24,$08,$00,$81,$27,$08,$00
        .byte   $81,$2A,$08,$00,$81,$30,$08,$00
        .byte   $81,$34,$08,$00,$81,$37,$08,$00
        .byte   $81,$3C,$08,$00,$81,$44,$08,$00
        .byte   $81,$49,$08,$00,$81,$4C,$08,$00
        .byte   $81,$4F,$08,$00,$81,$55,$08,$00
        .byte   $81,$59,$08,$00,$81,$5C,$08,$00
        .byte   $81,$5F,$08,$00,$81,$62,$08,$00
        .byte   $81,$66,$08,$00,$81,$69,$08,$00
        .byte   $81,$6C,$08,$00,$81,$71,$08,$00
        .byte   $81,$76,$08,$00,$81,$7F,$08,$00
        .byte   $81,$82,$08,$00,$81,$88,$08,$00
        .byte   $81,$8D,$08,$00,$81,$94,$08,$00
        .byte   $81,$97,$08,$00,$81,$9A,$08,$00
        .byte   $81,$9D,$08,$00,$81,$A2,$08,$00
        .byte   $81,$A8,$08,$00,$81,$AB,$08,$00
        .byte   $81,$B0,$08,$00,$81,$B7,$08,$00
        .byte   $81,$BA,$08,$00,$81,$C2,$08,$00
        .byte   $81,$C9,$08,$00,$81,$DD,$08,$00
        .byte   $81,$E3,$08,$00,$81,$F1,$08,$00
        .byte   $81,$F9,$08,$00,$81,$00,$09,$00
        .byte   $81,$03,$09,$00,$81,$08,$09,$00
        .byte   $81,$0D,$09,$00,$81,$3B,$09,$00
        .byte   $81,$3F,$09,$00,$81,$43,$09,$00
        .byte   $81,$47,$09,$00,$81,$4A,$09,$00
        .byte   $81,$4F,$09,$00,$81,$52,$09,$00
        .byte   $81,$55,$09,$00,$81,$5F,$09,$00
        .byte   $81,$A0,$09,$00,$81,$B0,$09,$00
        .byte   $81,$B3,$09,$00,$81,$B6,$09,$00
        .byte   $81,$BB,$09,$00,$81,$BE,$09,$00
        .byte   $81,$C3,$09,$00,$81,$CA,$09,$00
        .byte   $81,$CE,$09,$00,$81,$D1,$09,$00
        .byte   $81,$D6,$09,$00,$81,$DB,$09,$00
        .byte   $81,$E7,$09,$00,$81,$EA,$09,$00
        .byte   $81,$ED,$09,$00,$81,$F0,$09,$00
        .byte   $81,$F3,$09,$00,$81,$F6,$09,$00
        .byte   $81,$F9,$09,$00,$81,$FC,$09,$00
        .byte   $81,$02,$0A,$00,$81,$07,$0A,$00
        .byte   $81,$10,$0A,$00,$81,$13,$0A,$00
        .byte   $81,$1A,$0A,$00,$81,$1F,$0A,$00
        .byte   $81,$22,$0A,$00,$81,$29,$0A,$00
        .byte   $81,$31,$0A,$00,$81,$37,$0A,$00
        .byte   $81,$40,$0A,$00,$81,$43,$0A,$00
        .byte   $81,$49,$0A,$00,$81,$51,$0A,$00
        .byte   $81,$54,$0A,$00,$81,$57,$0A,$00
        .byte   $81,$5C,$0A,$00,$81,$5F,$0A,$00
        .byte   $81,$64,$0A,$00,$81,$67,$0A,$00
        .byte   $81,$6D,$0A,$00,$81,$70,$0A,$00
        .byte   $81,$75,$0A,$00,$81,$83,$0A,$00
        .byte   $81,$8A,$0A,$00,$81,$91,$0A,$00
        .byte   $81,$9B,$0A,$00,$81,$A0,$0A,$00
        .byte   $81,$A7,$0A,$00,$81,$C3,$0A,$00
        .byte   $81,$CB,$0A,$00,$81,$D2,$0A,$00
        .byte   $81,$D5,$0A,$00,$81,$DA,$0A,$00
        .byte   $81,$DF,$0A,$00,$81,$E4,$0A,$00
        .byte   $81,$E9,$0A,$00,$81,$EC,$0A,$00
        .byte   $81,$F1,$0A,$00,$81,$F8,$0A,$00
        .byte   $81,$FB,$0A,$00,$81,$00,$0B,$00
        .byte   $81,$03,$0B,$00,$81,$0A,$0B,$00
        .byte   $81,$13,$0B,$00,$81,$1A,$0B,$00
        .byte   $81,$20,$0B,$00,$81,$36,$0B,$00
        .byte   $81,$3C,$0B,$00,$81,$43,$0B,$00
        .byte   $81,$49,$0B,$00,$81,$50,$0B,$00
        .byte   $81,$58,$0B,$00,$81,$5E,$0B,$00
        .byte   $81,$63,$0B,$00,$81,$68,$0B,$00
        .byte   $81,$6B,$0B,$00,$81,$7F,$0B,$00
        .byte   $81,$8F,$0B,$00,$81,$94,$0B,$00
        .byte   $81,$9B,$0B,$00,$81,$9E,$0B,$00
        .byte   $81,$A1,$0B,$00,$81,$AC,$0B,$00
        .byte   $81,$B1,$0B,$00,$81,$B6,$0B,$00
        .byte   $81,$BB,$0B,$00,$81,$C3,$0B,$00
        .byte   $81,$C6,$0B,$00,$81,$C9,$0B,$00
        .byte   $81,$CE,$0B,$00,$81,$D9,$0B,$00
        .byte   $81,$DE,$0B,$00,$81,$E6,$0B,$00
        .byte   $81,$EF,$0B,$00,$81,$F4,$0B,$00
        .byte   $81,$F7,$0B,$00,$81,$FA,$0B,$00
        .byte   $81,$00,$0C,$00,$81,$09,$0C,$00
        .byte   $81,$0C,$0C,$00,$81,$16,$0C,$00
        .byte   $81,$19,$0C,$00,$81,$1C,$0C,$00
        .byte   $81,$1F,$0C,$00,$81,$24,$0C,$00
        .byte   $81,$29,$0C,$00,$81,$2C,$0C,$00
        .byte   $81,$32,$0C,$00,$81,$34,$0C,$00
        .byte   $81,$37,$0C,$00,$81,$3C,$0C,$00
        .byte   $81,$41,$0C,$00,$81,$4C,$0C,$00
        .byte   $81,$56,$0C,$00,$81,$5E,$0C,$00
        .byte   $81,$68,$0C,$00,$81,$70,$0C,$00
        .byte   $81,$77,$0C,$00,$81,$7D,$0C,$00
        .byte   $81,$81,$0C,$00,$81,$84,$0C,$00
        .byte   $81,$87,$0C,$00,$81,$8A,$0C,$00
        .byte   $81,$8D,$0C,$00,$81,$90,$0C,$00
        .byte   $81,$94,$0C,$00,$81,$97,$0C,$00
        .byte   $81,$9A,$0C,$00,$81,$9D,$0C,$00
        .byte   $81,$A0,$0C,$00,$81,$A3,$0C,$00
        .byte   $81,$AB,$0C,$00,$81,$AE,$0C,$00
        .byte   $81,$B5,$0C,$00,$81,$B8,$0C,$00
        .byte   $81,$BC,$0C,$00,$81,$BF,$0C,$00
        .byte   $81,$C2,$0C,$00,$81,$C5,$0C,$00
        .byte   $81,$C8,$0C,$00,$81,$CF,$0C,$00
        .byte   $81,$D5,$0C,$00,$81,$D8,$0C,$00
        .byte   $81,$DB,$0C,$00,$81,$E0,$0C,$00
        .byte   $81,$E5,$0C,$00,$81,$EA,$0C,$00
        .byte   $81,$ED,$0C,$00,$81,$F2,$0C,$00
        .byte   $81,$F5,$0C,$00,$81,$F8,$0C,$00
        .byte   $81,$FD,$0C,$00,$81,$00,$0D,$00
        .byte   $81,$07,$0D,$00,$81,$0A,$0D,$00
        .byte   $81,$0F,$0D,$00,$81,$16,$0D,$00
        .byte   $81,$1B,$0D,$00,$81,$1E,$0D,$00
        .byte   $81,$21,$0D,$00,$81,$24,$0D,$00
        .byte   $81,$27,$0D,$00,$81,$2C,$0D,$00
        .byte   $81,$2F,$0D,$00,$81,$32,$0D,$00
        .byte   $81,$35,$0D,$00,$81,$38,$0D,$00
        .byte   $81,$3B,$0D,$00,$81,$3E,$0D,$00
        .byte   $81,$41,$0D,$00,$81,$44,$0D,$00
        .byte   $81,$49,$0D,$00,$81,$4C,$0D,$00
        .byte   $81,$4F,$0D,$00,$81,$52,$0D,$00
        .byte   $81,$58,$0D,$00,$81,$5B,$0D,$00
        .byte   $81,$60,$0D,$00,$81,$63,$0D,$00
        .byte   $81,$69,$0D,$00,$81,$6E,$0D,$00
        .byte   $81,$71,$0D,$00,$81,$74,$0D,$00
        .byte   $81,$79,$0D,$00,$00,$00
