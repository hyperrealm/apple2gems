
CallStartDeskTop        := $00
CallStopDeskTop         := $01
CallSetCursor           := $02
CallShowCursor          := $03
CallHideCursor          := $04
CallCheckEvents         := $05
CallGetEvent            := $06
CallFlushEvents         := $07
CallSetKeyEvent         := $08
CallInitMenu            := $09
CallSetMenu             := $0A
CallMenuSelect          := $0B
CallMenuKey             := $0C
CallHiliteMenu          := $0D
CallDisableMenu         := $0E
CallDisableMenuItem     := $0F
CallCheckMenuItem       := $10
CallPascIntAdr          := $11
CallSetBasAdr           := $12
CallVersion             := $13
CallSetMark             := $14
CallPeekEvent           := $15
CallInitWindowMgr       := $16
CallOpenWindow          := $17
CallCloseWindow         := $18
CallCloseAllWindows     := $19
CallFindWindow          := $1A
CallFrontWindow         := $1B
CallSelectWindow        := $1C
CallTrackGoAway         := $1D
CallDragWindow          := $1E
CallGrowWindow          := $1F
CallWindowToScreen      := $20
CallScreenToWindow      := $21
CallWinChar             := $22
CallWinString           := $23
CallWinBlock            := $24
CallWinOp               := $25
CallWinText             := $26
CallFindControl         := $27
CallSetCtlMax           := $28
CallTrackThumb          := $29
CallUpdateThumb         := $2A
CallActivateCtl         := $2B
CallObscureCursor       := $2C
CallGetWinPtr           := $2D
CallPostEvent           := $2E
CallSetUserHook         := $2F
CallKeyboardMouse       := $30


ErrNone			:= $00
ErrInvalidCall		:= $01
ErrWrongParamCount	:= $02
ErrDesktopNotStarted	:= $03
ErrOSNotSupported	:= $04
ErrInvalidSlotNum	:= $05
ErrMouseNotFound	:= $06
ErrInterruptModeInUse	:= $07
ErrInvalidMenuID	:= $08
ErrInvalidMenuItemNum	:= $09
ErrSaveAreaTooSmall	:= $0A
ErrInstallIntFailed	:= $0B
ErrWindowAlreadyOpen	:= $0C
ErrWindowBufferTooSmall := $0D
ErrBadWindowInfo	:= $0E
ErrInvalidWindowID	:= $0F
ErrNoWindows		:= $10
ErrUserHookRoutineError	:= $11
ErrInvalidControlID	:= $12
ErrEventQueueFull	:= $13
ErrInvalidEvent		:= $14
ErrInvalidUserHookID	:= $15
ErrCallFailed		:= $16

EventTypeNone := $0
EventTypeButtonDown := $1
EventTypeButtonUp := $2
EventTypeKeyPress := $3
EventTypeDrag := $4
EventTypeAppleKeyDown := $5
EventTypeUpdate := $6

MouseTextCharPointer := $02
MouseTextCharHourglass := $03
MouseTextCharCheckmark := $04
MouseTextCharTextCursor := $14
MouseTextCharCellCursor := $1D

MenuOptionMaskDisabled := $80

MenuItemOptionMaskDisabled := $80
MenuItemOptionMaskIsFiller := $40
MenuItemOptionMaskIsChecked := $20
MenuItemOptionMaskHasMark := $4
MenuItemOptionMaskSolidAppleModifier := $2
MenuItemOptionMaskOpenAppleModifier := $1

KeyModifierNone := $0
KeyModifierOpenApple := $1
KeyModifierSolidApple := $2

WindowStatusMaskOpen := $80
WindowStatusMaskMysteryBit3 := $08
WindowStatusMaskDrawResizeBox := $04
WindowStatusMaskDrawVertScrollbar := $02
WindowStatusMaskDrawHorizScrollbar := $01

WindowOptionMaskDocPtrFn := $80
WindowOptionMaskResizeBoxPresent := $4
WindowOptionMaskCloseBoxPresent := $2
WindowOptionMaskIsDialogOrAlert := $1

ScrollbarOptionMaskScrollbarPresent := $80
ScrollbarOptionMaskScrollBoxPresent := $40
ScrallbarOptionMaskScrollbarActive := $01

ControlAreaDesktop := $0
ControlAreaMenuBar := $1
ControlAreaContentRegion := $2
ControlAreaDragRegion := $3
ControlAreaResizeBox := $4
ControlAreaCloseBox := $5

ControlRegionContent := $0
ControlRegionVertScrollBar := $1
ControlRegionHorizScrollBar := $2
ControlRegionDeadZone := $3

WinOpClearToStartOfWindow := $1A
WinOpClearToStartOfLine := $1B
WinOpClearWindow := $1C
WinOpClearToEndOfWindow := $1D
WinOpClearLine := $1E
WinOpClearToEndOfLine := $1F

ControlPartUpOrLeftArrow := $01
ControlPartDownOrRightArrow := $02
ControlPartPageUpOrLeftRegion := $03
ControlPartPageDownOrRightRegion := $04
ControlPartScrollBox := $05

ScrollControlOptionMaskScrollBarPresent := $80
ScrollControlOptionMaskScrollBoxPresent := $40
ScrollControlOptionMaskScrollBarActive := $01

CharInvSpace := $20
CharInvAsterisk := $2A
CharSpace := $A0
CharUnderscore := $DF
CharCheckerboard := $FF

TrackingModeNone := $00
TrackingModeMenuInteraction := $01
;; mode 2 is undefined/unused
TrackingModeDragWindow := $03
TrackingModeResizeWindow := $04
TrackingModeCloseBox := $05
TrackingModeScrollBox :=$06
