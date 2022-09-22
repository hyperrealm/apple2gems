
.scope ControlChar

ControlAt     := $00
Null          := $00
ControlA      := $01
ControlB      := $02
ControlC      := $03
Break         := $03
ControlD      := $04
CtrlCharsOff  := $04
ControlE      := $05
CtrlCharsOn   := $05
ControlF      := $06
CursorOn      := $06
ControlG      := $07
Bell          := $07
ControlH      := $08
Backspace     := $08
CursorLeft    := $08
LeftArrow     := $08
ControlI      := $09
Tab           := $09
ControlJ      := $0A
DownArrow     := $0A
CursorDown    := $0A
ControlK      := $0B
ClearToEOW    := $0B
UpArrow       := $0B
ControlL      := $0C
ClearWindow   := $0C
ControlM      := $0D
Return        := $0D
ControlN      := $0E
NormalVideo   := $0E
ControlO      := $0F
InverseVideo  := $0F
ControlP      := $10
ControlQ      := $11
Active40      := $11
ControlR      := $12
Active80      := $12
ControlS      := $13
ControlT      := $14
ControlU      := $15
RightArrow    := $15
TurnOff80Col  := $15
ControlV      := $16
ScrollDown    := $16
ControlW      := $17
ScrollUp      := $17
ControlX      := $18
Clear         := $18
MouseTextOff  := $18
ControlY      := $19
CursorHome    := $19
ControlZ      := $1A
ClearLine     := $1A
Esc           := $1B
MouseTextOn   := $1B
CursorRight   := $1C
ClearToEOL    := $1D
SetCursorChar := $1E
CursorUp      := $1F
Delete        := $7F


;;; IIGS + Extended Keyboard II only. These keys are
;;; read as numeric keypad keys.

F1            := $FA            ; 'z' - Undo
F2            := $F8            ; 'x' - Cut
F3            := $E3            ; 'c' - Copy
F4            := $F6            ; 'v' - Paste
F5            := $E0            ; '`'
F6            := $E1            ; 'a'
F7            := $E2            ; 'b'
F8            := $E4            ; 'd'
F9            := $E5            ; 'e'
F10           := $ED            ; 'm'
F11           := $E7            ; 'g'
F12           := $EF            ; 'o'
F13           := $E9            ; 'i' - Print Screen
F14           := $EB            ; 'k' - Scroll Lock
F15           := $F1            ; 'q' - Pause
Help          := $F2            ; 'r'
Home          := $F3            ; 's'
PageUp        := $F4            ; 't'
DeleteFwd     := $F5            ; 'u'
End           := $F7            ; 'w'
PageDown      := $F9            ; 'y'

.endscope
