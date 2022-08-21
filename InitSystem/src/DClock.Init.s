
.MACPACK generic
.FEATURE string_escapes

.include "MemoryMap.s"
.include "Monitor.s"
.include "ProDOS.s"
.include "SoftSwitches.s"
.include "Macros.s"

.struct ClockDataStruct
        frac_second     .byte   ; 1/00 second
        second          .byte   ; second
        minute          .byte   ; minute
        hour            .byte   ; hour
        day_of_week     .byte   ; day of week
        day             .byte   ; day of month
        month           .byte   ; month
        year            .byte   ; year
.endstruct

NumClockVals := 8 ; # of date/time components

;;; Zero page usage

Pointer   := $06 ; 2-byte pointer
SavedByte := $08
Scratch   := $09
BCDValue  := $3A

        .setcpu "65c02"
        .org  ProDOS::SysLoadAddress

;;; Main routine.

Init:
        ldx   #0
@Loop:  lda   CopyrightText,X
        beq   @Done
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Done:  jsr   ClockRead
        jsr   ClockValidate
        bcs   NoClock
        jsr   PrintDateTime
        jsr   InstallDriver
        rts

NoClock:
        ldx   #0
@Loop:  lda   NoClockErrorText,X
        beq   @Done
        jsr   Monitor::COUT
        inx
        bra   @Loop
@Done:  rts

;;; Install the clock driver

InstallDriver:

;;; Relocate the non-PIC LDA instruction
        clc
        lda   ProDOS::CLKENTRY+1
        adc   #<(ClockDriverUnlockSequence - ClockDriverStart)
        sta   OperandToReloc
        lda   ProDOS::CLKENTRY+2
        adc   #>(ClockDriverUnlockSequence - ClockDriverStart)
        sta   OperandToReloc+1

        lda   SoftSwitch::LCBANK1 ; make LCRAM writable
        lda   SoftSwitch::LCBANK1

        lda   ProDOS::CLKENTRY+1
        sta   Pointer
        lda   ProDOS::CLKENTRY+2
        sta   Pointer+1

        ldy   #0
@Loop:  lda   ClockDriver,Y
        sta   (Pointer),Y
        iny
        cpy   #(ClockDriverEnd - ClockDriverStart)
        bne   @Loop

        lda   SoftSwitch::RDROMLCB2 ; write protect LCRAM

;;; Make sure CLKENTRY is a JMP (it is an RTS if no clock is installed).

        lda   #$4C ; JMP
        sta   ProDOS::CLKENTRY

        lda   ProDOS::MACHID ; Indicate in MACHID
        ora   #$01 ; that clock is present
        sta   ProDOS::MACHID

        rts

;;; Enable slinky registers, set address and save byte we intend to trash.

SlinkyOn:
        lda   SoftSwitch::C8OFF ; release $C8xx firmware
        lda   MemoryMap::SLOT4ROM ; enable slinky registers
        jsr   ClockSelectAddr
        lda   SoftSwitch::DATA ; read byte
        sta   SavedByte ; and save it for later
        rts

;;; Restore byte trashed by SlinkyOn.

SlinkyRestore:
        jsr   ClockSelectAddr
        lda   SavedByte
        sta   SoftSwitch::DATA
        lda   SoftSwitch::C8OFF ; release $C8xx firmware
        rts

;;; Write a byte to the clock.

ClockWriteByte:
        jsr   ClockSelectAddr
@Loop:  sta   SoftSwitch::DATA
        lsr   ; next bit into 0 position
        dex
        bne   @Loop
        rts

;;; Read a byte form the clock.

ClockReadByte:
        jsr   ClockSelectAddr
@Loop:  pha   ; save accumulator
        lda   SoftSwitch::DATA ; read data byte
        lsr   ; bit 0 into carry
        pla   ; restore accumulator
        ror   ; put read bit into position
        dex
        bne   @Loop
        rts

ClockSelectAddr:
        ldx   #$08 ; set addr $080000
        stz   SoftSwitch::ADDRL
        stz   SoftSwitch::ADDRM
        stx   SoftSwitch::ADDRH
        rts

;;; Unlock clock by writing magic bit sequence.

ClockUnlock:
        ldy   #0
@Loop:  lda   ClockUnlockSeq,Y
        jsr   ClockWriteByte
        iny
        cpy   #8
        bne   @Loop
        rts

;;; Read clock data into ClockBuf

ClockRead:
        jsr   SlinkyOn
        jsr   ClockUnlock
        ldy   #0
@Loop:  jsr   ClockReadByte
        sta   ClockBuf,Y
        iny
        cpy   #8
        bne   @Loop
        jsr   SlinkyRestore
        rts

;;; Validate clock data. Return with Carry clear if it's valid.

ClockValidate:
        ldx   #0
@Loop:  phx   ; save X
        lda   MinValues,X
        pha
        lda   MaxValues,X
        pha
        lda   ClockBuf,X
        ply   ; pull max val
        plx   ; pull min val
        jsr   CheckBCDValue
        plx   ; restore X
        bcs   @Bad
        inx
        cpx   #NumClockVals
        bne   @Loop
        clc
@Bad:   rts

;;; Check BCD value in range [X,Y]. Return with carry set if Accumulator
;;; contains a value outside the range.

CheckBCDValue:
        sed   ; set decimal mode
        stx   Scratch
        cmp   Scratch ; A = X?
        blt   @Bad ; A < X ... bad
        sty   Scratch
        cmp   Scratch ; A = Y?
        beq   @OK ; A = Y ... ok
        bge   @Bad ; A > Y ... bad
@OK:    cld
        clc
        rts
@Bad:   cld
        sec
        rts

;;; Print current date/time as: www dd-mmm-yy hh:mm:ss

PrintDateTime:
        lda   ClockBuf+ClockDataStruct::day_of_week ; Print weekday
        dec
        jsr   MultiplyBy3
        tay
        ldx   #3
@Loop1: lda   WeekdayNames,Y
        jsr   Monitor::COUT
        iny
        dex
        bne   @Loop1

        lda   #HICHAR(' ')
        jsr   Monitor::COUT

        lda   ClockBuf+ClockDataStruct::day ; print day
        jsr   Monitor::PRBYTE

        lda   #HICHAR('-')
        jsr   Monitor::COUT

        lda   ClockBuf+ClockDataStruct::month ; print month
        ; need to convert from BCD if >= $10
        cmp   #$10
        blt   @Skip
        sec
        sbc   #6

@Skip:  dec
        jsr   MultiplyBy3
        tay
        ldx   #3
@Loop2: lda   MonthNames,Y
        jsr   Monitor::COUT
        iny
        dex
        bne   @Loop2

        lda   #HICHAR('-')
        jsr   Monitor::COUT

        lda   ClockBuf+ClockDataStruct::year ; print year
        jsr   Monitor::PRBYTE

        lda   #HICHAR(' ')
        jsr   Monitor::COUT

        lda   ClockBuf+ClockDataStruct::hour ; print hour
        jsr   Monitor::PRBYTE

        lda   #HICHAR(':')
        jsr   Monitor::COUT

        lda   ClockBuf+ClockDataStruct::minute ; print minute
        jsr   Monitor::PRBYTE

        lda   #HICHAR(':')
        jsr   Monitor::COUT

        lda   ClockBuf+ClockDataStruct::second ; print seconds
        jsr   Monitor::PRBYTE

        jsr   Monitor::CROUT
        rts

; Multiply Accumulator by 3

MultiplyBy3:
        sta   Scratch
        asl   ; R = A * 2
        clc
        adc   Scratch ; R = R + A
        rts

; Data area

ClockUnlockSeq:
        .byte $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C

ClockBuf:
        .tag  ClockDataStruct

;;;  Min and max values for: 1/100 sec, sec, min, hour, day-of-week,
;;; day-of-month, month, year.

MinValues:
        .byte 0, 0, 0, 0, 1, 1, 1, 0
MaxValues:
        .byte 99, 59, 59, 23, 07, 31, 12, 99

MonthNames:
        highascii "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
WeekdayNames:
        highascii "SUNMONTUEWEDTHUFRISAT"

CopyrightText:
        highasciiz "Copyright (c) 1988 Applied Engineering\r"

NoClockErrorText:
        highasciiz "Clock not found!\r"

        nop
        nop
        nop

;;; Clock driver code. This code is position-independent other than the
;;; absolute-mode LDA instruction, whose operand is adjusted during driver
;;; installation.

ClockDriverStart := * ; start of clock driver code

ClockDriver:
        php
        sei
        lda   MemoryMap::SLOT4ROM ; activate slinky registers
        stz   SoftSwitch::ADDRL ; set slinky addr to $08xx00
        ldy   #8 ; also counter for unlock bytes
        sty   SoftSwitch::ADDRH
        lda   SoftSwitch::DATA ; get destroyed byte
                             ; (slinky now at $08xx01)
        pha   ; save value on stack

        ; unlock DClock registers

OperandToReloc := *+1 ; instruction operand needs relocation

@WriteByteLoop:
        lda   ClockDriverUnlockSequence,Y
        lda   #8 ; bit counter
@WriteBitLoop:
        stz   SoftSwitch::ADDRL ; reset pointer to $08xx00
        sta   SoftSwitch::DATA
        lsr   ; next bit into 0 position
        dex
        bne   @WriteBitLoop
        dey
        bne   @WriteByteLoop

;;; Now read 64 bits from clock

        ldx   #8 ; byte counter
@ReadByteLoop:
        ldy   #8 ; bit counter
@ReadBitLoop:
        pha
        lda   SoftSwitch::DATA ;data byte
        lsr   ; bit 0 into carry
        pla
        ror   ; carry into bit 7
        dey
        bne   @ReadBitLoop
;;; Got 8 bits, convert from BCD.
        pha
        and   #$0F
        sta   BCDValue
        pla
        and   #$F0
        lsr
        pha
        adc   BCDValue
        sta   BCDValue
        pla
        lsr
        lsr
        adc   BCDValue
        sta   MemoryMap::INBUF-1,X ; store in input buffer
        dex
        bne   @ReadByteLoop

;;; Now copy date/time components to ProDOS global page

        lda   MemoryMap::INBUF+4 ; hours
        sta   ProDOS::TIMEHI
        lda   MemoryMap::INBUF+5 ; minutes
        sta   ProDOS::TIMELO
        lda   MemoryMap::INBUF+1 ; month
        lsr
        ror
        ror
        ror
        ora   MemoryMap::INBUF+2 ; day of month
        sta   ProDOS::DATELO
        lda   MemoryMap::INBUF ; year and final bit of month
        rol
        sta   ProDOS::DATEHI
        stz   SoftSwitch::ADDRL ; set slinky back to $08xx00
        pla
        sta   SoftSwitch::DATA ; get saved byte and put it back
        plp
        rts

;;; Unlock sequence (in reverse).
ClockDriverUnlockSequence := *-1
        .byte $5C, $A3, $3A, $C5, $5C, $A3, $3A, $C5

ClockDriverEnd := * ; end of clock driver code
