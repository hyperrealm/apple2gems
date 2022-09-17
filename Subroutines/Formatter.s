;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;* *                                                 * *
;* * M U S T   B E   O N   P A G E   B O U N D A R Y * *
;* *                                                 * *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                                                     *
;*  ProDOS DISK ][ Formatter Device Driver             *
;*                                                     *
;*  Copyright Apple Computer, Inc., 1982, 1983         *
;*                                                     *
;*  Enter with ProDOS device number in A-register:     *
;*         Zero    = bits 1, 2, 3, 4                   *
;*         Slot No.= bits 4, 5, 6                      *
;*         Drive 1 = bit 7 off                         *
;*         Drive 2 = bit 7 on                          *
;*                                                     *
;*  Error codes returned in A-register:                *
;*         $00 : Good completion                       *
;*         $27 : Unable to format                      *
;*         $2B : Write-Protected                       *
;*         $33 : Drive too SLOW                        *
;*         $34 : Drive too FAST                        *
;*         NOTE: Carry flag is set if error occured.   *
;*                                                     *
;*  Uses zero page locations $D0 thru $DD              *
;*                                                     *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *

.MACPACK generic

        .include "IWM.s"
        .include "ProDOS.s"

           .setcpu "6502"

        .org $7800

;;; Zero Page usage
        Const_AA         := $D0
        WriteTrackNum    := $D1
        WriteSectorNum   := $D2
        WriteVolumeNum   := $D3
        WriteGap3Count   := $D4
        ReadNib96Count   := $D5
        NibCount1Hi      := $D6
        ReadChecksum     := $D7
        ReadSectorNum    := $D8
        ReadTrackNum     := $D9
        ReadVolumeNum    := $DA
        DelayCounter     := $D9 ; 2 byte counter
        ReadTempChecksum := $DB
        ReadNibCount2Hi  := $DC
        ReadTemp4and4    := $DD

.proc Format525Floppy

        TracksPerDisk     := 35
        SectorsPerTrack   := 16
        DataBytesPerDataField := 342

.enum ErrorCode
        Success = ProDOS::EOK
        UnableToFormat = ProDOS::EIO
        WriteProtected = ProDOS::EWRITEPROT
        DriveTooSlow = $33
        DriveTooFast = $34
.endenum

.enum StatusCode
        Success = $00
        FormatFailed = $01
        WriteProtected = $02
        DriveTooSlow = $03
        DriveTooFast = $04
.endenum


AddressPrologueByte1 := $D5
AddressPrologueByte2 := $AA
AddressPrologueByte3 := $96

DataPrologueByte1    := $D5
DataPrologueByte2    := $AA
DataPrologueByte3    := $AD

EpilogueByte1        := $DE
EpilogueByte2        := $AA
EpilogueByte3        := $EB

SyncByte             := $FF
DataByte             := $96

           php
           sei
           jsr   FormatDisk
           plp
           cmp   #StatusCode::Success
           bne   @TranslateError
           clc
           rts
@TranslateError:
           cmp   #StatusCode::WriteProtected
           bne   L7812
           lda   #ErrorCode::WriteProtected
           jmp   ReturnError
L7812:     cmp   #StatusCode::FormatFailed
           bne   L781B
           lda   #ErrorCode::UnableToFormat
           jmp   ReturnError
L781B:     clc
           adc   #(ErrorCode::DriveTooSlow - StatusCode::DriveTooSlow)
ReturnError:
           sec
           rts

;;; Seek to track number in A. X = Slot*16
SeekToTrack:
           asl   a
           asl   HalfTrack
           sta   Temp1
           txa
           lsr   a
           lsr   a
           lsr   a
           lsr   a
           tay   ; Y = slot #
           lda   Temp1
           jsr   SeekToHalfTrack
           lsr   HalfTrack
           rts

;;; A = %DSSS0000
FormatDisk:
           tax
           and   #%01110000
           sta   Slotx16
           txa
           ldx   Slotx16
           rol   a
           lda   #$00
           rol   a              ; shift drive # into LSB
           bne   L7850
           lda   IWM::DRV0EN,x  ; select drive 1
           jmp   L7853
L7850:     lda   IWM::DRV1EN,x  ; select drive 2
L7853:     lda   IWM::ENABLEH,x ; turn on motor
           lda   #$D7
           sta   DelayCounter+1
           lda   #$50
           sta   HalfTrack
           lda   #$00
           jsr   SeekToTrack    ; Seek to first track
;;; Wait for drive head to settle
L7864:     lda   DelayCounter+1
           beq   L786E
           jsr   DelayLoop
           jmp   L7864
L786E:     lda   #$01
           sta   WriteVolumeNum ; volume number = 1
           lda   #$AA
           sta   Const_AA
           lda   MaxGap3
           clc
           adc   #$02
           sta   WriteGap3Count
           lda   #$00
           sta   WriteTrackNum  ; Start with track 0
WriteTrackLoop:
           lda   WriteTrackNum  ; Track number
           ldx   Slotx16
           jsr   SeekToTrack
           ldx   Slotx16
           lda   IWM::Q6H,x     ; Check write-protect
           lda   IWM::Q7L,x     ;   status
           tay
           lda   IWM::Q7L,x     ; Enable read mode
           lda   IWM::Q6L,x     ; Read Shift Register
           tya
           bpl   WriteTrack
           lda   #StatusCode::WriteProtected
           jmp   ReturnWithStatus
WriteTrack:
           jsr   FormatTrack
           bcc   L78B5
           lda   #$01
           ldy   WriteGap3Count
           cpy   MinGap3
           bge   L78B2
           lda   #StatusCode::DriveTooFast
L78B2:     jmp   ReturnWithStatus
L78B5:     ldy   WriteGap3Count
           cpy   MinGap3
           bge   L78C1
           lda   #StatusCode::DriveTooFast
           jmp   ReturnWithStatus
L78C1:     cpy   MaxGap3
           blt   L78CB
           lda   #StatusCode::DriveTooSlow
           jmp   ReturnWithStatus
L78CB:     lda   Const_10
           sta   RetryCount
L78D1:     dec   RetryCount
           bne   L78DB
           lda   #StatusCode::FormatFailed
           jmp   ReturnWithStatus
L78DB:     ldx   Slotx16
           jsr   ReadAddressField
           bcs   L78D1
           lda   ReadSectorNum
           bne   L78D1
           ldx   Slotx16
           jsr   VerifySector
           bcs   L78D1
           inc   WriteTrackNum
           lda   WriteTrackNum
           cmp   #TracksPerDisk
           blt   WriteTrackLoop
           lda   #StatusCode::Success
ReturnWithStatus:
           pha                  ; save error code
           ldx   Slotx16
           lda   IWM::ENABLEL,x ; turn off motor
           lda   #$00           ; Seek back to first track
           jsr   SeekToTrack
           pla                  ; restore error code
           rts

VerifySector:
           ldy   #$20           ; nibble count
L7909:     dey
           beq   ReturnWithCarrySet
L790C:     lda   IWM::Q6L,x
           bpl   L790C
L7911:     eor   #DataPrologueByte1
           bne   L7909
           nop
L7916:     lda   IWM::Q6L,x
           bpl   L7916
           cmp   #DataPrologueByte2
           bne   L7911
           ldy   #$56
L7921:     lda   IWM::Q6L,x
           bpl   L7921
           cmp   #DataPrologueByte3
           bne   L7911
           lda   #$00
L792C:     dey
           sty   ReadNib96Count
L792F:     lda   IWM::Q6L,x
           bpl   L792F
           cmp   #DataByte
           bne   ReturnWithCarrySet
           ldy   ReadNib96Count
           bne   L792C
L793C:     sty   ReadNib96Count
L793E:     lda   IWM::Q6L,x
           bpl   L793E
           cmp   #DataByte
           bne   ReturnWithCarrySet
           ldy   ReadNib96Count
           iny
           bne   L793C
L794C:     lda   IWM::Q6L,x
           bpl   L794C
           cmp   #DataByte
           bne   ReturnWithCarrySet
L7955:     lda   IWM::Q6L,x
           bpl   L7955
           cmp   #EpilogueByte1
           bne   ReturnWithCarrySet
           nop
L795F:     lda   IWM::Q6L,x
           bpl   L795F
           cmp   #EpilogueByte2
           beq   L79C4
ReturnWithCarrySet:
           sec
           rts

ReadAddressField:
           ldy   #$FC
           sty   ReadNibCount2Hi
L796E:     iny
           bne   L7975
           inc   ReadNibCount2Hi
           beq   ReturnWithCarrySet
L7975:     lda   IWM::Q6L,x
           bpl   L7975
L797A:     cmp   #AddressPrologueByte1
           bne   L796E
           nop
L797F:     lda   IWM::Q6L,x
           bpl   L797F
           cmp   #AddressPrologueByte2
           bne   L797A
           ldy   #$03
L798A:     lda   IWM::Q6L,x
           bpl   L798A
           cmp   #AddressPrologueByte3
           bne   L797A
           lda   #$00
L7995:     sta   ReadTempChecksum
L7997:     lda   IWM::Q6L,x
           bpl   L7997
           rol   a
           sta   ReadTemp4and4
L799F:     lda   IWM::Q6L,x
           bpl   L799F
           and   ReadTemp4and4
           sta   ReadChecksum,y
           eor   ReadTempChecksum
           dey
           bpl   L7995
           tay
           bne   ReturnWithCarrySet
L79B1:     lda   IWM::Q6L,x
           bpl   L79B1
           cmp   #EpilogueByte1
           bne   ReturnWithCarrySet
           nop
L79BB:     lda   IWM::Q6L,x
           bpl   L79BB
           cmp   #EpilogueByte2
           bne   ReturnWithCarrySet
L79C4:     clc
           rts

SeekToHalfTrack:
           stx   Temp2
           sta   Temp1
           cmp   HalfTrack
           beq   L7A2D
           lda   #$00
           sta   Temp3
L79D6:     lda   HalfTrack
           sta   Temp4
           sec
           sbc   Temp1
           beq   L7A19
           bcs   L79EB
           eor   #%11111111
           inc   HalfTrack
           bcc   L79F0
L79EB:     adc   #$FE
           dec   HalfTrack
L79F0:     cmp   Temp3
           bcc   L79F8
           lda   Temp3
L79F8:     cmp   #$0C
           bcs   L79FD
           tay
L79FD:     sec
           jsr   L7A1D
           lda   DelayLengths1,y
           jsr   DelayLoop
           lda   Temp4
           clc
           jsr   L7A20
           lda   DelayLengths2,y
           jsr   DelayLoop
           inc   Temp3
           bne   L79D6
L7A19:     jsr   DelayLoop
           clc
L7A1D:     lda   HalfTrack
L7A20:     and   #%00000011
           rol   a
           ora   Temp2
           tax
           lda   IWM::PHASE0OFF,x
           ldx   Temp2
L7A2D:     rts

WriteGapDataFieldAndData:
           jsr   OnlyRTS
           lda   IWM::Q6H,x
           lda   IWM::Q7L,x
; Write gap2 (5 10-bit sync bytes)
           lda   #SyncByte
           sta   IWM::Q7H,x
           cmp   IWM::Q6L,x
           pha
           pla
           nop
           ldy   #$04
L7A44:     pha
           pla
           jsr   WriteByte1
           dey
           bne   L7A44
           lda   #DataPrologueByte1
           jsr   WriteByte
           lda   #DataPrologueByte2
           jsr   WriteByte
           lda   #DataPrologueByte3
           jsr   WriteByte
           ldy   #<DataBytesPerDataField ; write $56 (86) $96 bytes (data length is 86 + 256 = 342)
           nop
           nop
           nop
           bne   L7A65
L7A62:     jsr   OnlyRTS
L7A65:     nop
           nop
           lda   #DataByte
           sta   IWM::Q6H,x
           cmp   IWM::Q6L,x
           dey
           bne   L7A62
           bit   $00            ; write 256 more $96 bytes
           nop
L7A75:     jsr   OnlyRTS
           lda   #DataByte
           sta   IWM::Q6H,x
           cmp   IWM::Q6L,x
           lda   #DataByte
           nop
           iny
           bne   L7A75
           jsr   WriteByte      ; write checksum
           lda   #EpilogueByte1
           jsr   WriteByte
           lda   #EpilogueByte2
           jsr   WriteByte
           lda   #EpilogueByte3
           jsr   WriteByte
           lda   #SyncByte
           jsr   WriteByte
           lda   IWM::Q7L,x     ; out of write mode
           lda   IWM::Q6L,x     ; to read mode
           rts

WriteByte:
           nop
WriteByte1:
           pha
           pla
           sta   IWM::Q6H,x     ; load byte
           cmp   IWM::Q6L,x     ; shift out data
           rts

;;;       Y = gap length
WriteGapAndAddressField:
           sec
           lda   IWM::Q6H,x     ; enable pre-write state
           lda   IWM::Q7L,x
           bmi   L7B15          ; Branch if write-protected
           lda   #SyncByte
           sta   IWM::Q7H,x     ; write byte
           cmp   IWM::Q6L,x
           pha
           pla
L7AC1:     jsr   Out1          ; RTS
           jsr   Out1          ; RTS
           sta   IWM::Q6H,x
           cmp   IWM::Q6L,x
           nop
           dey
           bne   L7AC1
           lda   #AddressPrologueByte1
           jsr   WriteByte2
           lda   #AddressPrologueByte2
           jsr   WriteByte2
           lda   #AddressPrologueByte3
           jsr   WriteByte2
           lda   WriteVolumeNum
           jsr   WriteByte4and4
           lda   WriteTrackNum
           jsr   WriteByte4and4
           lda   WriteSectorNum
           jsr   WriteByte4and4
           lda   WriteVolumeNum
           eor   WriteTrackNum
           eor   WriteSectorNum
           pha
           lsr   a
           ora   Const_AA
           sta   IWM::Q6H,x
           lda   IWM::Q6L,x
           pla
           ora   #%10101010     ; $AA
           jsr   WriteByte3     ; write checksum
           lda   #EpilogueByte1
           jsr   WriteByte2
           lda   #EpilogueByte2
           jsr   WriteByte2
           lda   #EpilogueByte3
           jsr   WriteByte2
           clc
L7B15:     lda   IWM::Q7L,x
           lda   IWM::Q6L,x
Out1:      rts

WriteByte4and4:
           pha
           lsr   a
           ora   Const_AA
           sta   IWM::Q6H,x
           cmp   IWM::Q6L,x
           pla
           nop
           nop
           nop
           ora   #%10101010     ; $AA
WriteByte3:
           nop
WriteByte2:
           nop
           pha
           pla
           sta   IWM::Q6H,x     ; load byte
           cmp   IWM::Q6L,x     ; shift out data
           rts

           brk
           brk
           brk

;;; Delay for approximately A*102 cycles
DelayLoop:
           ldx   #$11
L7B3C:     dex
           bne   L7B3C
           inc   DelayCounter
           bne   L7B45
           inc   DelayCounter+1
L7B45:     sec
           sbc   #$01           ; Decrement accumulator
           bne   DelayLoop
           rts

;;; Delay lengths
DelayLengths1:
           .byte $01,$30,$28,$24,$20,$1E,$1D,$1C
           .byte $1C,$1C,$1C,$1C

DelayLengths2:
           .byte $70,$2C,$26,$22,$1F,$1E,$1D,$1C
           .byte $1C,$1C,$1C,$1C

FormatTrack:
           lda   Timeoutx256
           sta   NibCount1Hi
L7B68:     ldy   #$80
           lda   #$00
           sta   WriteSectorNum
           jmp   L7B73
FormatSectorLoop:
           ldy   WriteGap3Count
L7B73:     ldx   Slotx16
           jsr   WriteGapAndAddressField
           bcc   L7B7E
           jmp   OnlyRTS
L7B7E:     ldx   Slotx16
           jsr   WriteGapDataFieldAndData
           inc   WriteSectorNum
           lda   WriteSectorNum
           cmp   #SectorsPerTrack
           bcc   FormatSectorLoop
           ldy   #SectorsPerTrack-1
           sty   WriteSectorNum
           lda   Const_10
           sta   RetryCount
L7B96:     sta   SectorFlags,y
           dey
           bpl   L7B96
           lda   WriteGap3Count
           sec
           sbc   #$05
           tay
L7BA2:     jsr   OnlyRTS
           jsr   OnlyRTS
           pha
           pla
           nop
           nop
           dey
           bne   L7BA2
           ldx   Slotx16
           jsr   ReadAddressField
           bcs   L7BF3
           lda   ReadSectorNum
           beq   L7BCE
           dec   WriteGap3Count
           lda   WriteGap3Count
           cmp   MinGap3
           bcs   L7BF3
           sec
           rts
L7BC6:     ldx   Slotx16
           jsr   ReadAddressField
           bcs   L7BE8
L7BCE:     ldx   Slotx16
           jsr   VerifySector
           bcs   L7BE8 ; branch if verification failed
           ldy   ReadSectorNum
           lda   SectorFlags,y  ; read sector flag
           bmi   L7BE8          ; branch if set
           lda   #$FF           ; set sector flag
           sta   SectorFlags,y
           dec   WriteSectorNum
           bpl   L7BC6
           clc
           rts
L7BE8:     dec   RetryCount
           bne   L7BC6
           dec   NibCount1Hi
           bne   L7BF3
           sec
           rts
L7BF3:     lda   Const_10
           asl   a
           sta   RetryCount
L7BFA:     ldx   Slotx16
           jsr   ReadAddressField
           bcs   L7C08
           lda   ReadSectorNum
           cmp   #SectorsPerTrack-1
           beq   L7C0F
L7C08:     dec   RetryCount
           bne   L7BFA
           sec
OnlyRTS:   rts
L7C0F:     ldx   #$D6
L7C11:     jsr   OnlyRTS
           jsr   OnlyRTS
           bit   $00
           dex
           bne   L7C11
           jmp   L7B68

;;; Data area

MinGap3:   .byte $0E
MaxGap3:   .byte $1B
Timeoutx256:
           .byte $03
Const_10:  .byte $10
Slotx16:   .byte $00            ; %0SSS0000
HalfTrack: .byte $00
RetryCount:.byte $00
SectorFlags:
           .byte $00,$00,$00,$00,$00,$00,$00,$00
           .byte $00,$00,$00,$00,$00,$00,$00,$00
Temp1:     .byte $00
Temp2:     .byte $00
Temp3:     .byte $00
Temp4:     .byte $00

.endproc
