SetMouseEP	 := $12
ServeMouseEP	 := $13
ReadMouseEP	 := $14
ClearMouseEP	 := $15
PosMouseEP	 := $16
ClampMouseEP	 := $17
HomeMouseEP	 := $18
InitMouseEP	 := $19
MouseTimeDataEP	 := $1C

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

MTCharSolidApple := $40
MTCharOpenApple := $41
MTCharArrowCursor := $42
MTCharHourglass := $43
MTCharCheckmark := $44
MTCharInvCheckmark := $45
MTCharLeftArrow := $48
MTCharEllipsis := $49
MTCharDownArrow := $4A
MTCharUpArrow := $4B
MTCharOverscore := $4C
MTCharReturn := $4D
MTCharBlock := $4E
MTCharLeftScrollArrow := $4F
MTCharRightScrollArrow := $50
MTCharDownScrollArrow := $51
MTCharUpScrollArrow := $52
MTCharHorizLine := $53
MTCharTextCursor := $54
MTCharRightArrow := $55
MTCharCheckerboard1 := $56
MTCharCheckerboard2 := $57
MTCharFolder1 := $58
MTCharFolder2 := $59
MTCharRightVerticalBar := $5A
MTCharDiamond := $5B
MTCharOverUnderScore := $5C
MTCharCellCursor := $5D
MTCharDottedBox := $5E
MTCharLeftVerticalBar := $5F

CharInvSpace := $20
CharInvAsterisk := $2A

CharLeftArrow := $08
CharTab := $09
CharDownArrow := $0A
CharUpArrow := $0B
CharReturn := $0D
CharRightArrow := $15
CharEsc := $1B
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

MaskBit0 := $1
MaskBit1 := $2
MaskBit2 := $4
MaskBit3 := $8
MaskBit4 := $10
MaskBit5 := $20
MaskBit6 := $40
MaskBit7 := $80
