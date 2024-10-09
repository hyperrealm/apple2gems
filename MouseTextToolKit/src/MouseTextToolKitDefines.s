
.scope MTTKCall
        
StartDeskTop        := $00
StopDeskTop         := $01
SetCursor           := $02
ShowCursor          := $03
HideCursor          := $04
CheckEvents         := $05
GetEvent            := $06
FlushEvents         := $07
SetKeyEvent         := $08
InitMenu            := $09
SetMenu             := $0A
MenuSelect          := $0B
MenuKey             := $0C
HiliteMenu          := $0D
DisableMenu         := $0E
DisableMenuItem     := $0F
CheckMenuItem       := $10
PascIntAdr          := $11
SetBasAdr           := $12
Version             := $13
SetMark             := $14
PeekEvent           := $15
InitWindowMgr       := $16
OpenWindow          := $17
CloseWindow         := $18
CloseAllWindows     := $19
FindWindow          := $1A
FrontWindow         := $1B
SelectWindow        := $1C
TrackGoAway         := $1D
DragWindow          := $1E
GrowWindow          := $1F
WindowToScreen      := $20
ScreenToWindow      := $21
WinChar             := $22
WinString           := $23
WinBlock            := $24
WinOp               := $25
WinText             := $26
FindControl         := $27
SetControlMax       := $28
TrackThumb          := $29
UpdateThumb         := $2A
ActivateControl     := $2B
ObscureCursor       := $2C
GetWinPtr           := $2D
PostEvent           := $2E
SetUserHook         := $2F
KeyboardMouse       := $30

.endscope

.scope MTTKError
        
None			:= $00
InvalidCall		:= $01
WrongParamCount	        := $02
DesktopNotStarted	:= $03
OSNotSupported	        := $04
InvalidSlotNum	        := $05
MouseNotFound	        := $06
InterruptModeInUse	:= $07
InvalidMenuID	        := $08
InvalidMenuItemNum	:= $09
SaveAreaTooSmall	:= $0A
InstallIntFailed	:= $0B
WindowAlreadyOpen	:= $0C
WindowBufferTooSmall    := $0D
BadWindowInfo	        := $0E
InvalidWindowID	        := $0F
NoWindows		:= $10
UserHookRoutineError	:= $11
InvalidControlID	:= $12
EventQueueFull  	:= $13
InvalidEvent		:= $14
InvalidUserHookID	:= $15
CallFailed		:= $16

.endscope

.scope MTTKEventType
        
None            := $0
ButtonDown      := $1
ButtonUp        := $2
KeyPress        := $3
Drag            := $4
AppleKeyDown    := $5
Update          := $6

.endscope

.scope MTTKMenuOption
        
Disabled := %10000000

.endscope

.scope MTTKMenuItemOption
        
Disabled           := %10000000
IsFiller           := %01000000
IsChecked          := %00100000
HasMark            := %00000100
SolidAppleModifier := %00000010
OpenAppleModifier  := %00000001

.endscope
        
.scope MTTKKeyModifier
        
None            := $0
OpenApple       := $1
SolidApple      := $2

.endscope

.scope MTTKWindowStatus
        
Open               := %10000000
DrawResizeBox      := %00000100
DrawVertScrollbar  := %00000010
DrawHorizScrollbar := %00000001

.endscope
        
.scope MTTKWindowOption

;;; The document pointer points to a function that renders the
;;; window's contents, rather than to a document info structure.
DocPtrFn         := %10000000
;;; Text string pointer points to a BASIC string array element
BASICArrayElem   := %00010000
;;;  Text string pointer points to a BASIC string variable
BASICString      := %00001000
ResizeBoxPresent := %00000100
CloseBoxPresent  := %00000010
IsDialogOrAlert  := %00000001

.endscope

.scope MTTKScrollBarOption
        
ScrollbarPresent := %10000000
ScrollBoxPresent := %01000000
ScrollbarActive  := %00000001

.endscope

.scope MTTKControlArea
        
Desktop       := $0
MenuBar       := $1
ContentRegion := $2
DragRegion    := $3
ResizeBox     := $4
CloseBox      := $5

.endscope

.scope MTTKControlRegion

Content        := $0
VertScrollBar  := $1
HorizScrollBar := $2
DeadZone       := $3

.endscope
        
.scope MTTKWinOp
        
ClearToStartOfWindow := $1A
ClearToStartOfLine   := $1B
ClearWindow          := $1C
ClearToEndOfWindow   := $1D
ClearLine            := $1E
ClearToEndOfLine     := $1F

.endscope

.scope MTTKControlPart
        
UpOrLeftArrow         := $01
DownOrRightArrow      := $02
PageUpOrLeftRegion    := $03
PageDownOrRightRegion := $04
ScrollBox             := $05

.endscope

.scope MTTKScrollControlOption
        
ScrollBarPresent := %10000000
ScrollBoxPresent := %01000000
ScrollBarActive  := %00000001

.endscope

.scope MTTKTrackingMode
        
None            := $00
MenuInteraction := $01
;; mode 2 is undefined/unused
DragWindow      := $03
ResizeWindow    := $04
CloseBox        := $05
ScrollBox       := $06

.endscope
