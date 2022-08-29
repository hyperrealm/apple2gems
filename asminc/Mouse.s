;;;  Mouse firmware

;;; Mouse firmware calls

.scope MouseCall

SetMouse    := $12
ServeMouse  := $13
ReadMouse   := $14
ClearMouse  := $15
PosMouse    := $16
ClampMouse  := $17
HomeMouse   := $18
InitMouse   := $19
GetClamp    := $1A
TimeData    := $1C

.endscope

.scope Mouse

;;; Mouse slot <s> screen holes. Add slot number to address.

MOUXL       := $0478 ; (+s) Mouse X position (low byte)
MOUYL       := $04F8 ; (+s) Mouse Y position (low byte)
MOUXH       := $0578 ; (+s) Mouse X position (high byte)
MOUYH       := $05F8 ; (+s) Mouse Y position (high byte)
MOUARM      := $0678 ; (+s) Mouse interrupt arming byte
MOUSTAT     := $0778 ; (+s) Mouse status
MOUMODE     := $07F8 ; (+s) Mouse mode


;;; Slot 0 mouse screen holes.

MINL        := $0478 ; Clamp min value (low byte)
MAXL        := $04F8 ; Clamp max value (low byte)
MINH        := $0578 ; Clamp min value (high byte)
MAXH        := $05F8 ; CLamp max value (high byte)

;;; IIc/IIc+ mouse screen holes (aux mem)
MINXL       := $047D ; Clamp X min value (low byte)
MINYL       := $04FD ; Clamp Y min value (low byte)
MINXH       := $057D ; Clamp X min value (high byte)
MINYH       := $05FD ; Clamp Y min value (high byte)
MAXXL       := $067D ; Clamp X max value (low byte)
MAXYL       := $06FD ; Clamp Y max value (low byte)
MAXXH       := $077D ; Clamp X max value (high byte)
MAXYH       := $07FD ; Clamp Y max value (high byte)

;;; Mouse modes

ModeOnMask                := %00000001
ModeInterruptOnMoveMask   := %00000010
ModeInterruptOnButtonMask := %00000100
ModeInterruptOnVBLMask    := %00001000

.endscope
