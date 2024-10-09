        .setcpu "6502"

        .include "Applesoft.s"
        .include "BASICSystem.s"
        .include "FileTypes.s"
        .include "OpCodes.s"
        .include "ProDOS.s"
        .include "SoftSwitches.s"
        .include "ZeroPage.s"

        .MACPACK generic
        .FEATURE string_escapes
        
        .org    $0800


Pointer := $06
Address := $08

SavedError := $2FD
SavedErrorLocation := $2FE
        

RLoad: 
        lda     BASICSystem::VPATH1
        sta     Pointer
        lda     BASICSystem::VPATH1+1
        sta     Pointer+1
        lda     #0
        tay
        sta     (Pointer),y
        lda     ProDOS::PFIXPTR
        bne     PrefixSet
        lda     ProDOS::DEVNUM
        sta     BASICSystem::SREFNUM
        ldx     Pointer+1
        ldy     Pointer
        iny
        bne     GetVolumeName
        inx
GetVolumeName:
        sty     BASICSystem::SBUFADR
        stx     BASICSystem::SBUFADR+1
        lda     #ProDOS::CONLINE
        jsr     BASICSystem::GOSYSTEM
        bcc     MakePath
        jsr     PrintError
MakePath:
        ldy     #1
        lda     (Pointer),y
        and     #%00001111
        tax
        lda     #'/'
        sta     (Pointer),y
        inx
        inx
        txa
        dey
        sta     (Pointer),y
        tay
        lda     #'/'
        sta     (Pointer),y
PrefixSet:
        ldy     #0
        lda     (Pointer),y
        tay
        iny
        jsr     ZeroPage::CHRGOT
ParseUSR:
        bne     L085B
L0853:  lda     #BASICSystem::EINVALIDOPT
        bit     $02A9           ; ???
        jsr     PrintError
L085B:  bcc     L0853
        cmp     #','
        bne     L0867
        jsr     ZeroPage::CHRGET
        jmp     ParseUSR
L0867:  cmp     #'"'
        bne     L0853
        jmp     L0875
L086E:  sta     (Pointer),y
        iny
        cpy     #$7E            ; path < 128 chars ?
        bcs     L0885
L0875:  jsr     ZeroPage::CHRGET
        beq     L0885
        bcc     L086E
        cmp     #'"'
        bne     L086E
        jsr     ZeroPage::CHRGET
        bne     L0853
L0885:  dey
        tya
        ldy     #0
        sta     (Pointer),y
        lda     #0
        sta     Address
        sta     Address+1
        lda     #$0A            ; GET_FILE_INFO
        sta     BASICSystem::SSGINFO
        lda     #ProDOS::CGETFILEINFO
        jsr     BASICSystem::GOSYSTEM
        bcc     L08A0
        jsr     PrintError
L08A0:  lda     BASICSystem::FIFILID
        cmp     #FileType::REL
        beq     L08AC
        lda     #BASICSystem::EFILETYPE
L08A9:  jsr     PrintError
L08AC:  lda     BASICSystem::FIAUXID
        sta     Pointer
        lda     BASICSystem::FIAUXID+1
        sta     Pointer+1
        lda     ZeroPage::MEMSIZ
        sta     BASICSystem::OSYSBUF
        lda     ZeroPage::MEMSIZ+1
        sta     BASICSystem::OSYSBUF+1
        lda     #ProDOS::COPEN
        jsr     BASICSystem::GOSYSTEM
        bcs     L08A9
        lda     BASICSystem::OREFNUM
        sta     FileRefNum
        jsr     ReadNextByte
        sta     Operand
        jsr     ReadNextByte
        sta     Operand+1
        tax
        lda     Operand
        beq     L08E0
        inx
L08E0:  txa
        sta     Address+1
        lda     ZeroPage::MEMSIZ+1
        sec
        sbc     Address+1
        sta     Address+1
        lda     #$00
        sta     Address
        lda     EndOfCodeAddr
        cmp     Address
        lda     EndOfCodeAddr+1
        sbc     Address+1
        bcc     L0902
        lda     #BASICSystem::EPROGTOOBIG
CloseFileAndExitWithError:
        jsr     CloseFile
        jsr     PrintError
L0902:  ldx     Operand+1
        lda     Operand
        beq     L090B
        inx
L090B:  txa
        jsr     BASICSystem::GETBUFR
        bcc     L0916
        lda     #BASICSystem::EPROGTOOBIG
        jsr     CloseFileAndExitWithError
L0916:  sta     Address+1
        sec
        sbc     #$04
        sta     BASICSystem::SBUFADR+1
        lda     #$00
        sta     BASICSystem::SBUFADR
        lda     BASICSystem::OREFNUM
        sta     BASICSystem::SREFNUM
        lda     #ProDOS::CSETBUF
        jsr     BASICSystem::GOSYSTEM
        bcc     L0935
        lda     #BASICSystem::ENOBUFFERS
        jsr     CloseFileAndExitWithError
L0935:  lda     Address
        sec
        sbc     Pointer
        sta     Offset
        lda     Address+1
        sbc     Pointer+1
        sta     Offset+1
        lda     Address
        sta     DestAddr
        lda     Address+1
        sta     DestAddr+1
        lda     Operand
        clc
        adc     DestAddr
        sta     Pointer
        lda     Operand+1
        adc     DestAddr+1
        sta     Pointer+1
        lda     Operand
        sta     BASICSystem::RWCOUNT
        lda     Operand+1
        sta     BASICSystem::RWCOUNT+1
        lda     DestAddr
        sta     BASICSystem::RWDATA
        lda     DestAddr+1
        sta     BASICSystem::RWDATA+1
        lda     FileRefNum
        sta     BASICSystem::RWREFNUM
        lda     #ProDOS::CREAD
        jsr     BASICSystem::GOSYSTEM
        bcc     ProcessNextInstruction
        jmp     CloseFileAndExitWithError
ProcessNextInstruction:
        lda     #$00
        sta     Operand
        sta     Operand+1
        jsr     ReadNextByte
        sta     RelocationFlags
        jsr     ReadNextByte
        clc
        adc     DestAddr
        sta     Address
        php
        jsr     ReadNextByte
        plp
        adc     DestAddr+1
        sta     Address+1
        lda     Address
        cmp     DestAddr
        lda     Address+1
        sbc     DestAddr+1
        bcc     L09BE
        lda     Address
        cmp     Pointer
        lda     Address+1
        sbc     Pointer+1
        bcc     L09C3
L09BE:  lda     #BASICSystem::ESYNTAX
        jsr     CloseFileAndExitWithError
L09C3:  ldy     #$00
        lda     #%11111111
        bit     RelocationFlags
        beq     EndOfRelocationTable
        bmi     RelocateSingleByteOperand
        bvs     RelocateUpperByteOfOperand
        lda     (Address),y
        sta     Operand
        jsr     AddOffsetToOperand
        lda     Operand
        sta     (Address),y
        jsr     ReadNextByte
        jmp     ProcessNextInstruction
RelocateUpperByteOfOperand:
        lda     (Address),y
        sta     Operand+1
        jsr     ReadNextByte
        sta     Operand
        jsr     AddOffsetToOperand
        lda     Operand+1
        sta     (Address),y
        jmp     ProcessNextInstruction
RelocateSingleByteOperand:
        lda     #%00100000
        and     RelocationFlags
        bne     RelocateReversedOperand
        lda     (Address),y
        sta     Operand
        iny
        lda     (Address),y
        sta     Operand+1
        jsr     AddOffsetToOperand
        lda     Operand+1
        sta     (Address),y
        dey
        lda     Operand
        sta     (Address),y
        jsr     ReadNextByte
        jmp     ProcessNextInstruction
RelocateReversedOperand:
        lda     (Address),y
        sta     Operand+1
        iny
        lda     (Address),y
        sta     Operand
        jsr     AddOffsetToOperand
        lda     Operand
        sta     (Address),y
        dey
        lda     Operand+1
        sta     (Address),y
        jsr     ReadNextByte
        jmp     ProcessNextInstruction
EndOfRelocationTable:
        jsr     CloseFile
        ldy     DestAddr
        lda     DestAddr+1
        bit     SoftSwitch::ROMIN
        jmp     ApplesoftRoutine::GIVAYF

AddOffsetToOperand:
        clc
        lda     Offset
        adc     Operand
        sta     Operand
        lda     Offset+1
        adc     Operand+1
        sta     Operand+1
        rts

CloseFile:
        pha
        tya
        pha
        txa
        pha
        lda     FileRefNum
        sta     BASICSystem::CFREFNUM
        lda     #ProDOS::CCLOSE
        jsr     BASICSystem::GOSYSTEM
        bcc     @OK
        jsr     PrintError
@OK:    pla
        tax
        pla
        tay
        pla
        rts

ReadNextByte:
        tya
        pha
        txa
        pha
        lda     FileRefNum
        sta     BASICSystem::RWREFNUM
        lda     #1
        sta     BASICSystem::RWCOUNT
        lda     #0
        sta     BASICSystem::RWCOUNT+1
        lda     Data
        sta     BASICSystem::RWDATA
        lda     Data+1
        sta     BASICSystem::RWDATA+1
        lda     #ProDOS::CREAD
        jsr     BASICSystem::GOSYSTEM
        bcc     @OK
        cmp     #BASICSystem::EENDOFDATA
        bne     @Error
        lda     #0
        sta     ByteBuf
@OK:    pla
        tax
        pla
        tay
        lda     ByteBuf
        rts
@Error: jsr     CloseFileAndExitWithError

PrintError:
        sta     SavedError
        pla
        sta     SavedErrorLocation
        pla
        sta     SavedErrorLocation+1
        lda     SavedError
        jmp     BASICSystem::ERROUT

        .byte   OpCode::BIT_Abs
Data:   .addr   ByteBuf
        .byte   OpCode::BIT_Abs
EndOfCodeAddr:
        .addr   EndOfCode
        .byte   $00
Offset:
        .word   $EEEE
Operand:
        .word   $EEEE
DestAddr:
        .addr   $EEEE
        .byte   $00
RelocationFlags:
        .byte   $01
ByteBuf:
        .byte   $00
FileRefNum:
        .byte   $00
EndOfCode := *
