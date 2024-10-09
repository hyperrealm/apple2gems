
        .setcpu "6502"

        .include "Applesoft.s"
        .include "BASICSystem.s"
        .include "FileTypes.s"
        .include "Macros.s"
        .include "Monitor.s"
        .include "OpCodes.s"
        .include "ProDOS.s"
        .include "SoftSwitches.s"
        .include "ZeroPage.s"

        ;;; Inputs to routine
        InputFilename := $260
        ReadBuffer := $260
        OutputFilename := $220
        DestAddress := $19

        ;;; Zero page locations used by routine
        Pointer := $06          ; also used as code load address
        CodePointer := $08

        ErrorSave := $02FD
        ErrorLocation:= $02FE    
        
        .org    $0E00
        
        lda     BASICSystem::VPATH1
        sta     Pointer
        lda     BASICSystem::VPATH1+1
        sta     Pointer+1
        lda     #0
        tay
        sta     (Pointer),y
        lda     InputFilename,y
        cmp     #'/'
        beq     HavePrefix
        lda     ProDOS::PFIXPTR
        bne     HavePrefix
        lda     ProDOS::DEVNUM
        sta     BASICSystem::SREFNUM
        ldx     Pointer+1
        ldy     Pointer
        iny
        bne     L0E29
        inx
L0E29:  sty     BASICSystem::SBUFADR
        stx     BASICSystem::SBUFADR+1
        lda     #ProDOS::CONLINE
        jsr     BASICSystem::GOSYSTEM
        bcc     L0E39
        jsr     ExitWithError
L0E39:  ldy     #$01
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
        sta     PathLength
        tay
        lda     #'/'
        sta     (Pointer),y
HavePrefix:
        ldy     #$00
        lda     (Pointer),y
        tay
        iny
        ldx     #$00
L0E5A:  lda     InputFilename,x
        beq     L0E67
        sta     (Pointer),y
        inx
        iny
        cpy     #$28
        bcc     L0E5A
L0E67:  dey
        tya
        ldy     #$00
        sta     (Pointer),y
        lda     #$00
        sta     CodePointer
        sta     CodePointer+1
        lda     #$0A            ; GET_FILE_INFO
        sta     BASICSystem::SSGINFO
        lda     #ProDOS::CGETFILEINFO
        jsr     BASICSystem::GOSYSTEM
        bcc     L0E82
        jsr     ExitWithError
L0E82:  lda     BASICSystem::FIFILID
        cmp     #FileType::REL
        beq     L0E8E
        lda     #BASICSystem::EFILETYPE
        jsr     ExitWithError
L0E8E:  lda     BASICSystem::FIAUXID
        sta     Pointer
        lda     BASICSystem::FIAUXID+1
        sta     Pointer+1
        jsr     OpenFile
        lda     BASICSystem::OREFNUM
        sta     FileRefNum
        ldy     #$00
        lda     (ZeroPage::MEMSIZ),y
        sta     Operand
        sta     CodeLength
        iny
        lda     (ZeroPage::MEMSIZ),y
        sta     Operand+1
        sta     CodeLength+1
        tax
        lda     Operand
        beq     L0EBB
        inx
L0EBB:  txa
        sta     CodePointer+1
        lda     ZeroPage::MEMSIZ+1
        sec
        sbc     CodePointer+1
        sta     CodePointer+1
        lda     #$00
        sta     CodePointer
        lda     CodeEnd
        cmp     CodePointer
        lda     CodeEnd+1
        sbc     CodePointer+1
        bcc     L0EDD
        lda     #BASICSystem::EPROGTOOBIG
CloseFileAndExitWithError:
        jsr     CloseFile
        jsr     ExitWithError
L0EDD:  lda     CodeEnd+1
        tax
        lda     CodeEnd
        beq     L0EE7
        inx
L0EE7:  txa
        sta     CodePointer+1
        lda     DestAddress
        sec
        sbc     Pointer
        sta     AddressOffset
        lda     DestAddress+1
        sbc     Pointer+1
        sta     AddressOffset+1
        lda     CodePointer
        sta     CodeStartAddress
        lda     CodePointer+1
        sta     CodeStartAddress+1
        jsr     SetFileMark
        lda     Operand
        sta     BASICSystem::RWCOUNT
        clc
        adc     CodeStartAddress
        sta     Pointer
        lda     Operand+1
        sta     BASICSystem::RWCOUNT+1
        adc     CodeStartAddress+1
        sta     Pointer+1
        lda     CodeStartAddress
        sta     BASICSystem::RWDATA
        lda     CodeStartAddress+1
        sta     BASICSystem::RWDATA+1
        lda     FileRefNum
        sta     BASICSystem::RWREFNUM
        lda     #ProDOS::CREAD
        jsr     BASICSystem::GOSYSTEM
        bcc     L0F39
        jmp     CloseFileAndExitWithError

L0F39:  ldx     #$FF
ProcessNextInstruction:
        lda     #$00
        sta     Operand
        sta     Operand+1
        inx
        bne     L0F49
        jsr     L1156
L0F49:  lda     ReadBuffer,x
        beq     RelocationDone           ; end of relocation dictionary reached
        sta     FlagByte
        inx
        lda     ReadBuffer,x
        clc
        adc     CodeStartAddress
        sta     CodePointer
        php
        inx
        lda     ReadBuffer,x
        plp
        adc     CodeStartAddress+1
        sta     CodePointer+1
        lda     CodePointer
        cmp     CodeStartAddress
        lda     CodePointer+1
        sbc     CodeStartAddress+1
        bcc     L0F7C
        lda     CodePointer
        cmp     Pointer
        lda     CodePointer+1
        sbc     Pointer+1
        bcc     L0F81
L0F7C:  lda     #$10
        jsr     CloseFileAndExitWithError
L0F81:  ldy     #$00
        lda     #$FF
        bit     FlagByte
        bmi     RelocateSingleByteOperand           ; field size is 8 bits
        bvs     RelocateUpperByteOfOperand ; upper byte of 16 bit value
        lda     (CodePointer),y            ; otherwise relocate lower byte of operand
        sta     Operand
        jsr     AdjustOperand
        lda     Operand
        sta     (CodePointer),y
        inx
        jmp     ProcessNextInstruction

RelocationDone:
        jsr     CloseFile
        jsr     WriteOutputFile
        ldy     CodeStartAddress
        lda     CodeStartAddress+1
        jmp     ApplesoftRoutine::GIVAYF

RelocateUpperByteOfOperand:
        lda     (CodePointer),y
        sta     Operand+1
        inx
        lda     ReadBuffer,x
        sta     Operand
        jsr     AdjustOperand
        lda     Operand+1
        sta     (CodePointer),y
        jmp     ProcessNextInstruction

RelocateSingleByteOperand:
        lda     #$20            ; normal/reversed flag mask
        and     FlagByte
        bne     RelocateReversedOperand ; reversed bit is set
        lda     (CodePointer),y         ; otherwise adjust lo,hi operand
        sta     Operand
        iny
        lda     (CodePointer),y
        sta     Operand+1
        jsr     AdjustOperand
        lda     Operand+1
        sta     (CodePointer),y
        dey
        lda     Operand
        sta     (CodePointer),y
        inx
        jmp     ProcessNextInstruction


;;;  adjust hi,lo operand
RelocateReversedOperand:
        lda     (CodePointer),y
        sta     Operand+1
        iny
        lda     (CodePointer),y
        sta     Operand
        jsr     AdjustOperand
        lda     Operand
        sta     (CodePointer),y
        dey
        lda     Operand+1
        sta     (CodePointer),y
        inx
        jmp     ProcessNextInstruction

AdjustOperand:
        clc
        lda     AddressOffset
        adc     Operand
        sta     Operand
        lda     AddressOffset+1
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
        bcc     L102D
        jsr     ExitWithError
L102D:  pla
        tax
        pla
        tay
        pla
        rts

SetFileMark:
        lda     FileRefNum
        sta     BASICSystem::SREFNUM
        lda     #$02
        sta     BASICSystem::SMARK
        lda     #$00
        sta     BASICSystem::SMARK+1
        sta     BASICSystem::SMARK+2
        lda     #ProDOS::CSETMARK
        jsr     BASICSystem::GOSYSTEM
        bcc     L1050
        jsr     CloseFileAndExitWithError
L1050:  rts

WriteOutputFile:
        lda     BASICSystem::VPATH1
        sta     Pointer
        lda     BASICSystem::VPATH1+1
        sta     Pointer+1
        lda     #$00
        tay
        sta     (Pointer),y
        lda     OutputFilename,y
        cmp     #'/'
        beq     L1071
        lda     ProDOS::PFIXPTR
        bne     L1071
        lda     PathLength
        sta     (Pointer),y
L1071:  lda     (Pointer),y
        tay
        iny
        ldx     #$00
L1077:  lda     OutputFilename,x
        beq     L1084
        sta     (Pointer),y
        inx
        iny
        cpy     #$28
        bcc     L1077
L1084:  dey
        tya
        ldy     #$00
        sta     (Pointer),y
        jsr     CreateOutputFile
        jsr     OpenFile
        jsr     WriteFile
        jsr     CloseFile
        rts

WriteFile:
        lda     BASICSystem::OREFNUM
        sta     FileRefNum
        sta     BASICSystem::RWREFNUM
        lda     CodeStartAddress
        sta     BASICSystem::RWDATA
        lda     CodeStartAddress+1
        sta     BASICSystem::RWDATA+1
        lda     CodeLength
        sta     BASICSystem::RWCOUNT
        lda     CodeLength+1
        sta     BASICSystem::RWCOUNT+1
        lda     #ProDOS::CWRITE
        jsr     BASICSystem::GOSYSTEM
        bcc     L10C2
        jsr     CloseFileAndExitWithError
L10C2:  rts

OpenFile:
        lda     ZeroPage::MEMSIZ
        sta     BASICSystem::OSYSBUF
        lda     ZeroPage::MEMSIZ+1
        sta     BASICSystem::OSYSBUF+1
        lda     #ProDOS::COPEN
        jsr     BASICSystem::GOSYSTEM
        bcc     L10D7
        jsr     ExitWithError
L10D7:  rts

CreateOutputFile:
        lda     #%11000011      ; all permissions on
        sta     BASICSystem::CRACCESS
        lda     #FileType::BIN
        sta     BASICSystem::CRFILID
        lda     DestAddress
        sta     BASICSystem::CRAUXID
        lda     DestAddress+1
        sta     BASICSystem::CRAUXID+1
        lda     #$01
        sta     BASICSystem::CRFKIND
        lda     #ProDOS::CCREATE
        jsr     BASICSystem::GOSYSTEM
        bcc     L10FF
        cmp     #BASICSystem::EDUPFILENAME
        beq     WarnAboutOverwrite
        jsr     ExitWithError
L10FF:  rts

WarnAboutOverwrite:
        jsr     PrintOvewritePrompt
        jsr     Monitor::RDKEY
        pha
        jsr     Monitor::COUT1
        pla
        and     #%01111111
        cmp     #'Y'
        beq     OverwriteOK
        cmp     #'y'
        beq     OverwriteOK
        pla
        pla
        pla
        pla
        lda     #$00
        tay
        jmp     ApplesoftRoutine::GIVAYF ; return with address of $0000

OverwriteOK:
        lda     #$07            ; SET_FILE_INFO
        sta     BASICSystem::SSGINFO
        lda     #ProDOS::CSETFILEINFO
        sta     BASICSystem::FIACESS
        lda     #FileType::BIN
        sta     BASICSystem::FIFILID
        lda     DestAddress
        sta     BASICSystem::FIAUXID
        lda     DestAddress+1
        sta     BASICSystem::FIAUXID+1
        lda     #$01
        sta     BASICSystem::FIFKIND
        lda     #ProDOS::CSETFILEINFO
        jsr     BASICSystem::GOSYSTEM
        bcc     L1147
        jsr     ExitWithError
L1147:  rts

PrintOvewritePrompt:
        ldx     #0
L114A:  lda     OverwritePrompt,x
        beq     L1155
        jsr     Monitor::COUT1
        inx
        bne     L114A
L1155:  rts

L1156:  tya
        pha
        txa
        pha
        lda     FileRefNum
        sta     BASICSystem::RWREFNUM
        lda     #$00
        sta     BASICSystem::RWCOUNT
        lda     #$01
        sta     BASICSystem::RWCOUNT+1
        lda     #<ReadBuffer
        sta     BASICSystem::RWDATA
        lda     #>ReadBuffer
        sta     BASICSystem::RWDATA+1
        lda     #ProDOS::CREAD
        jsr     BASICSystem::GOSYSTEM
        bcc     L1184
        cmp     #BASICSystem::EENDOFDATA
        bne     L118C
        lda     #$00
        sta     L11EE
L1184:  pla
        tax
        pla
        tay
        lda     L11EE
L118B:  rts
L118C:  jsr     CloseFileAndExitWithError

;;; Called as a subroutine, but does not return to the caller.
;;; Pulls the return address off the stack and saves it at
;;; ErrorLocation, as a debugging aid.
ExitWithError:
        sta     ErrorSave
        pla
        sta     ErrorLocation
        pla
        sta     ErrorLocation+1
        lda     ErrorSave
        jmp     BASICSystem::ERROUT

        bit     L11EE
        .byte   OpCode::BIT_Abs
CodeEnd:
        .addr   CodeEndAddr ;$11F0           

OverwritePrompt:
        .byte   $0D
        highascii "DUPLICATE OUTPUT FILENAME"
        .byte   $0D
        highasciiz "PRESS Y IF OK TO OVERWRITE FILE: "

PathLength:
        .byte   $EE
CodeLength:
        .word   $EEEE

AddressOffset:
        .addr   $EEEE
Operand:
        .addr   $EEEE

;;;  probably the original code base address
CodeStartAddress:
        .addr   $EEEE

        .byte   $00             ;unused
FlagByte:
        .byte   $01
L11EE:  .byte   $00             ; 0 written here, never read

FileRefNum: 
        .byte   $00

CodeEndAddr := *
