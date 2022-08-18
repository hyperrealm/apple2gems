;;; Page 3 vectors

.scope Vector

DOSWARM     := $03D0 ; DOS 3.3 or BASIC.SYSTEM warm-start
DOSCOLD     := $03D3 ; DOS 3.3 cold start or BASIC.SYSTEM warm-start
FM          := $03D6 ; DOS 3.3 File Manager entry point
RWTS        := $03D9 ; DOS 3.3 RWTS entry point
LOCFPL      := $03DC ; DOS 3.3 File Manager parameter list subroutine
LOCRPL      := $03E3 ; DOS 3.3 RTWS parameter list subroutine
DOSHOOK     := $03EA ; DOS 3.3 I/O reconnect routine
XFERADR     := $03ED ; Destination address for XFER ($C314) routine
BRKV        := $03F0 ; JMP instruction to BRK and COP handler
SOFTEV      := $03F2 ; Control-Reset vector
PWREDUP     := $03F4 ; Control-Reset vector checksum byte
AMPERV      := $03F5 ; Applesoft BASIC Ampersand handler
USRADR      := $03F8 ; Monitor Control-Y handler
NMI         := $03FB ; NMI handler or System Monitor cold start
IRQLOC      := $03FE ; IRQ handler

SOFTEVMASK  := $A5   ; Control-Reset vector checksum XOR mask

.endscope
