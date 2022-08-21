.MACPACK generic
.FEATURE string_escapes

.include "MemoryMap.s"
.include "Monitor.s"
.include "SoftSwitches.s"
.include "Macros.s"
.include "SerialPort.s"
.include "ProDOS.s"
.include "ControlChars.s"

.struct PortConfig
        mode            .byte   ; mode
        data_stop_bits  .byte   ; data/stop bits
        baud_rate       .byte   ; baud rate
        parity          .byte   ; parity
        echo            .byte   ; echo on/off
        cr_lf           .byte   ; CR+LF on/off
        line_length     .byte   ; line length
        slot            .byte   ; slot # (0 = invalid)
.endstruct

IOBuffer   := $2600
DataBuffer := $2500
BufferSize := $0100 ; 256 bytes read max
ScreenHole := $0478 ; ACIA control register contents (port 1)

;;; Zero page usage

Pointer     := $06
Pointer2    := $08
TempVal     := $1E
SavedError  := $1F
CurrentSlot := $EB ; current slot being parsed
ReadOffset  := $EC
CharCount   := $ED
EOF         := $EE ; eof-of-file flag

        .setcpu "65c02"
        .org  ProDOS::SysLoadAddress

Init:

;;; Check if this is a IIc or IIc+

        lda   ProDOS::MACHID
        and   #%11111000
        cmp   #%10111000
        beq   ReadConfig

        ldx   #0
@Loop:  lda   NotIIcText,X
        beq   @Skip
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Skip:  rts

;;; Read in the config file

ReadConfig:
        stz   SavedError
        jsr   ProDOS::MLI
        .byte ProDOS::COPEN
        .addr OpenFileParams
        bcc   @OK
        rts   ; no config file

@OK:    lda   RefNum1
        sta   RefNum2
        sta   RefNum3

        jsr   ProDOS::MLI
        .byte ProDOS::CREAD
        .addr ReadFileParams
        sta   SavedError

        jsr   ProDOS::MLI
        .byte ProDOS::CCLOSE
        .addr CloseFileParams

        lda   SavedError
        beq   ParseConfig
        jmp   Error

;;; Parse lines from the config file.

ParseConfig:
        stz   ReadOffset
        stz   EOF
@Loop:  jsr   ParseLine
        bcc   @Loop
        lda   EOF
        bne   ApplyConfig

ParseError:
        ldx   #0
@Loop:  lda   ParseErrorText,X
        beq   @Done
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Done:  lda   ReadOffset
        jsr   Monitor::PRBYTE
        jsr   Monitor::CROUT
        rts

;;; Apply the configuration.

ApplyConfig:
        lda   #<ConfigBuffer
        sta   Pointer
        lda   #>ConfigBuffer
        sta   Pointer+1
        lda   #<ScreenHole
        sta   Pointer2
        lda   #>ScreenHole
        sta   Pointer2+1

        jsr   ApplyPortConfig
        bcs   @Apply2
        jsr   PrintConfig

@Apply2:
        lda   Pointer
        clc
        adc   #8
        sta   Pointer
        lda   Pointer2
        clc
        adc   #4
        sta   Pointer2

        jsr   ApplyPortConfig
        bcs   @Done
        jsr   PrintConfig

@Done:  rts

Error:
        tax
        ldy   #0
@Loop:  lda   ReadErrorText,Y
        beq   @Skip
        jsr   Monitor::COUT
        iny
        bra   @Loop
@Skip:  jsr   Monitor::PRNTX
        jsr   Monitor::CROUT
        rts

;;; Parse line from the config file

ParseLine:
        stz   CharCount
        ldy   #0

ParseSlot:
        lda   #2
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    sta   CurrentSlot
        dec
        asl
        asl
        asl
        sta   TempVal
        lda   #<ConfigBuffer
        clc
        adc   TempVal
        sta   Pointer
        lda   #>ConfigBuffer
        sta   Pointer+1

        lda   #'='
        jsr   GetChar
        bcc   ParseMode
        rts

ParseMode:
        lda   #2
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny

ParseDataStopBits:
        lda   #6
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny

ParseBaud:
        lda   #7
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny
        lda   #'/'
        jsr   GetChar
        bcc   ParseParity
        rts

ParseParity:
        lda   #5
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny

ParseEcho:
        lda   #2
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny

ParseLineFeed:
        lda   #2
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny

ParseLineLength:
        lda   #5
        jsr   GetDigit
        bcc   @OK
        rts
@OK:    dec
        sta   (Pointer),Y
        iny

ParseEndOfLine:
        lda   #ControlChar::Return
        jsr   GetChar
        bcc   @OK
        rts
@OK:    lda   CurrentSlot
        sta   (Pointer),Y
        clc
        rts

;;; Apply serial port configuration at (Pointer) to screen holes at
;;; (Pointer2). Return with Carry clear if OK, set if config is not valid.

ApplyPortConfig:

;;; First, check if it's a valid config (slot # != 0)
        ldy   #7
        lda   (Pointer),Y
        bne   @OK
        sec
        rts

@OK:    stz   SoftSwitch::STORE80ON
        stz   SoftSwitch::LORES ; turn off hi-res
        stz   SoftSwitch::TXTPAGE2

;;; Clear all the bits we're going to modify in the first 3 screen holes,
;;; and set the RCS bit

        ldy   #0
        lda   #%00010000 ; set RCS bit only
        sta   (Pointer2),Y
        iny
        lda   #%00001111
        and   (Pointer2),Y
        sta   (Pointer2),Y
        iny
        lda   #%00111110
        and   (Pointer2),Y
        sta   (Pointer2),Y

;;; First byte of input is the mode

        ldy   #0
        lda   (Pointer),Y
        tax
        lda   ModeMasks,X
        ldy   #2
        ora   (Pointer2),Y
        sta   (Pointer2),Y

;;; Second byte of input is data/stop bits

        ldy   #1
        lda   (Pointer),Y
        tax
        lda   DataStopBitsMasks,X
        ldy   #0
        ora   (Pointer2),Y
        sta   (Pointer2),Y

;;; Third byte of input is baud rate

        ldy   #2
        lda   (Pointer),Y
        tax
        lda   BaudRateMasks,X
        ldy   #0
        ora   (Pointer2),Y
        sta   (Pointer2),Y

;;; Fourth byte of input is parity

        ldy   #3
        lda   (Pointer),Y
        tax
        lda   ParityMasks,X
        ldy   #1
        ora   (Pointer2),Y
        sta   (Pointer2),Y

;;; Fifth byte of input is echo

        ldy   #4
        lda   (Pointer),Y
        tax
        lda   EchoMasks,X
        ldy   #1
        ora   (Pointer2),Y
        sta   (Pointer2),Y
        iny
        lda   EchoMasksF,X
        ora   (Pointer2),Y
        sta   (Pointer2),Y

;;; Sixth byte of input is LF

        ldy   #5
        lda   (Pointer),Y
        tax
        lda   LineFeedMasks,X
        ldy   #2
        ora   (Pointer2),Y
        sta   (Pointer2),Y

;;; Seventh byte is line length

        ldy   #6
        lda   (Pointer),Y
        tax
        lda   LineLengths,X
        ldy   #3
        sta   (Pointer2),Y

        stz   SoftSwitch::TXTPAGE1
        stz   SoftSwitch::STORE80OFF
        clc
        rts

;;; Print the configuration at (Pointer) in format:
;;; Slot n: (device) d/s baud parity [echo] [lf] linelen

PrintConfig:

;;; Print "Slot n:"
        ldy   #0
@Loop1: lda   SlotText,X
        beq   @Skip1
        jsr   Monitor::COUT
        inx
        bra   @Loop1

@Skip1: ldy   #7
        lda   (Pointer),Y
        clc
        adc   #HICHAR('0')
        jsr   Monitor::COUT
        lda   #HICHAR(':')
        jsr   Monitor::COUT

;;; print device type
        ldy   #0
        lda   (Pointer),Y
        asl
        asl   ; * 4
        tax
@Loop2: lda   DeviceText,X
        beq   @Skip2
        jsr   Monitor::COUT
        inx
        bra   @Loop2

;;; print " "
@Skip2: lda   #HICHAR(' ')
        jsr   Monitor::COUT

;;; print data/stop bits
        iny
        lda   (Pointer),Y
        asl   ; * 2
        tax
        lda   DataStopBitsText,X
        jsr   Monitor::COUT
        lda   #HICHAR('/')
        jsr   Monitor::COUT
        inx
        lda   DataStopBitsText,X
        jsr   Monitor::COUT

;;; print "/"
        lda   #HICHAR('/')
        jsr   Monitor::COUT

;;; print parity
        iny
        iny
        lda   (Pointer),Y
        asl
        asl
        asl   ; * 8
        tax
@Loop3: lda   ParityText,X
        beq   @Skip3
        jsr   Monitor::COUT
        inx
        bra   @Loop3

;;; print " "
@Skip3: lda   #HICHAR(' ')
        jsr   Monitor::COUT

;;; print baud rate
        dey
        lda   (Pointer),Y
        asl
        asl   ; * 4
        tax
@Loop4: lda   BaudRateText,X
        bpl   @Skip4
        jsr   Monitor::COUT
        inx
        bra   @Loop4
@Skip4: tax
        lda   #HICHAR('0')
@ZLoop: jsr   Monitor::COUT
        dex
        bne   @ZLoop

;;; print " "
        lda   #HICHAR(' ')
        jsr   Monitor::COUT

;;; print "echo " if on
        iny
        iny
        lda   (Pointer),Y
        beq   @Skip6
        ldx   #0
@Loop6: lda   EchoText,X
        beq   @Skip6
        jsr   Monitor::COUT
        inx
        bra   @Loop6

;;; print "lf " if on
@Skip6: iny
        lda   (Pointer),Y
        beq   @Skip7
        ldx   #0
@Loop7: lda   LineFeedText,X
        beq   @Skip7
        jsr   Monitor::COUT
        inx
        bra   @Loop7

;;; print line length
@Skip7: iny
        lda   (Pointer),Y
        asl
        asl   ; * 4
        tax
@Loop8: lda   LineLengthText,X
        beq   @Skip8
        jsr   Monitor::COUT
        inx
        bra   @Loop8

@Skip8: jsr   Monitor::CROUT ; print CR

@Done:  rts

;;; Read a character, skipping over spaces and tabs, and return it in the
;;; Accumulator. Return with Carry set if EOF.

ReadChar:
        phx
        phy
        ldx   ReadOffset
        dex
@Loop:  inx
        cpx   TransferCount
        beq   @AtEOF
        lda   DataBuffer,X
        and   #%01111111 ; strip off hi bit
        cmp   #ControlChar::Return
        bne   @NotCR
;;; If it's a CR, only return it if the current line hasn't been all
;;; whitespace.
        ldy   CharCount
        bne   @Done1
        bra   @Loop

@NotCR: cmp   #' '
        beq   @Loop
        cmp   #ControlChar::Tab
        beq   @Loop

@Done:  inc   CharCount
@Done1: inx
        stx   ReadOffset
        ply
        plx
        clc
        rts
@AtEOF: ply
        plx
        inc   EOF
        sec
        rts

;;; Read a character, and check if it's equal to the contents of A.
;;; Returns Carry clear if so, Carry set if not.

GetChar:
        sta   TempVal
        jsr   ReadChar
        bcs   @Bad
        cmp   TempVal
        bne   @Bad
        clc
        rts
@Bad:   sec
        rts

;;; Read a character, and check if it's a digit between 1 and the value
;;; in A. If yes, clears Carry and returns its value. Otherwise, sets
;;; Carry.

GetDigit:
        clc
        adc   #'0'
        sta   TempVal
        jsr   ReadChar
        cmp   #'1'
        blt   @Bad
        cmp   TempVal
        beq   @OK
        bge   @Bad
@OK:    sec
        sbc   #'0'
        clc
        rts
@Bad:   sec
        rts

;;; Data area

ConfigFileName:
        pstring "SERIALPORT.CFG"

ConfigBuffer:
        .tag  PortConfig        ; first serial port config
        .tag  PortConfig        ; second serial port config

; mapping of data/stop bits PIN value to
; bitmask

ModeMasks:
        .byte %00000000, %00000001
DataStopBitsMasks:
        .byte %01000000, %11000000
        .byte %00100000, %10100000
        .byte %00000000, %10000000
BaudRateMasks:
        .byte %00000011, %00000110
        .byte %00001000, %00001010
        .byte %00001100, %00001110
        .byte %00001111
ParityMasks:
        .byte %00000000, %01100000
        .byte %00100000, %10100000
        .byte %11100000
EchoMasks:
        .byte %00000000, %00010000
EchoMasksF:
        .byte %00000000, %10000000

LineFeedMasks:
        .byte %00000000, %01000000

SlotText:
        highasciiz "Slot "

DeviceText:     ; 4 bytes each
        highasciiz "PRN"
        highasciiz "COM"

DataStopBitsText: ; 2 bytes each
        highascii "61"
        highascii "62"
        highascii "71"
        highascii "72"
        highascii "81"
        highascii "82"

BaudRateText: ; 4 bytes each
        highascii "11"
        .byte $01, $00
        highascii "3"
        .byte $02, $00, $00
        highascii "12"
        .byte $02, $00
        highascii "24"
        .byte $02, $00
        highascii "48"
        .byte $02, $00
        highascii "96"
        .byte $02, $00
        highascii "192"
        .byte $02

ParityText:       ; 8 bytes each
        highasciiz "none"
        .byte $00, $00, $00
        highasciiz "even"
        .byte $00, $00, $00
        highasciiz "odd"
        .byte $00, $00, $00, $00
        highasciiz "mark"
        .byte $00, $00, $00
        highasciiz "space"
        .byte $00, $00

EchoText:
        highasciiz "echo "
LineFeedText:
        highasciiz "lf "
LineLengthText: ; 4 bytes each
        .byte $00, $00, $00, $00 ; unlimited line len.
        highasciiz "40"
        .byte $00
        highasciiz "72"
        .byte $00
        highasciiz "80"
        .byte $00
        highasciiz "132"

LineLengths:
        .byte 0, 40, 72, 80, 132

ReadErrorText:
        highasciiz "Error reading config file: $"
ParseErrorText:
        highasciiz "Parse error at: $"
NotIIcText:
        highasciiz "Not an Apple IIc/IIc+\r"

OpenFileParams:
        .byte $03
        .addr ConfigFileName
        .addr IOBuffer
RefNum1:
        .byte $00

ReadFileParams:
        .byte $04
RefNum2:
        .byte $00
        .addr DataBuffer
        .word BufferSize
TransferCount:
        .word $0000

CloseFileParams:
        .byte $01
RefNum3:
        .byte $00



