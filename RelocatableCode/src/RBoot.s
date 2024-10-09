
        .setcpu "6502"

        .include "BASICSystem.s"
        .include "FileTypes.s"
        .include "Monitor.s"
        .include "ProDOS.s"
        .include "ZeroPage.s"
        
PathPtr := $06
TempVal := $08

        .org    $0218
        
RBoot:
        jmp     Start
EndPage:
        .byte   $A0
StartAddress:
        .addr   $0000
CodeLength:
        .word   $0000
DestAddress:
        .addr   $0000
EndAddress:
        .addr   $0000

Start:
        lda     #$FF
        sta     TempVal
        lda     BASICSystem::VPATH1
        sta     PathPtr
        lda     BASICSystem::VPATH1+1
        sta     PathPtr+1
        lda     #$00
        tay
        sta     (PathPtr),y
        lda     ProDOS::PFIXPTR
        bne     PrefixSet
        lda     ProDOS::DEVNUM
        sta     BASICSystem::SREFNUM
        ldx     PathPtr+1
        ldy     PathPtr
        iny
        bne     GetVolumeName
        inx
GetVolumeName:
        sty     BASICSystem::SBUFADR
        stx     BASICSystem::SBUFADR+1
        lda     #ProDOS::CONLINE
        jsr     BASICSystem::GOSYSTEM
        bcc     MakePath
        jmp     BASICSystem::ERROUT

        brk
MakePath:
        ldy     #1
        lda     (PathPtr),y
        and     #%00001111 ; get filename length (<= 15)
        tax
        lda     #'/'
        sta     (PathPtr),y
        inx
        inx
        txa
        dey
        sta     (PathPtr),y
        tay
        lda     #'/'
        sta     (PathPtr),y
PrefixSet:
        ldy     #0
        lda     (PathPtr),y
        ldx     #0
        tay
CopyFilename:
        iny
        lda     RLoadFilename,x
        sta     (PathPtr),y
        inx
        cpx     #5
        bcc     CopyFilename
        tya
        ldy     #0
        sta     (PathPtr),y
        beq     GetFileInfo
RLoadFilename:
        .byte   "RLOAD"
GetFileInfo:
        lda     #$0A ; GET_FILE_INFO parameter count
        sta     BASICSystem::SSGINFO
        lda     #ProDOS::CGETFILEINFO
        jsr     BASICSystem::GOSYSTEM
        bcc     CheckFileType
        jmp     BASICSystem::ERROUT
        brk
CheckFileType:
        lda     BASICSystem::FIFILID
        cmp     #FileType::BIN
        beq     OpenFile
        lda     #BASICSystem::EFILETYPE
ExitWithError:
        jmp     BASICSystem::ERROUT
        brk
OpenFile:
        lda     BASICSystem::FIAUXID
        sta     StartAddress
        lda     BASICSystem::FIAUXID+1 
        sta     StartAddress+1
        lda     ZeroPage::MEMSIZ
        sta     BASICSystem::OSYSBUF
        lda     ZeroPage::MEMSIZ+1
        sta     BASICSystem::OSYSBUF+1
        lda     #ProDOS::COPEN
        jsr     BASICSystem::GOSYSTEM
        bcs     ExitWithError
        lda     BASICSystem::OREFNUM
        sta     BASICSystem::SREFNUM
        lda     #ProDOS::CGETEOF
        jsr     BASICSystem::GOSYSTEM
        bcs     CloseAndExitWithError
        lda     BASICSystem::SBUFADR
        sta     CodeLength
        sta     EndAddress
        sta     BASICSystem::RWCOUNT
        lda     BASICSystem::SBUFADR+1
        sta     CodeLength+1
        sta     BASICSystem::RWCOUNT+1
        lda     #0
        sta     TempVal
        sta     BASICSystem::RWDATA
        sta     DestAddress
        ldx     ZeroPage::STREND+1
        inx
        inx
        stx     DestAddress+1
        stx     BASICSystem::RWDATA+1
        clc
        lda     BASICSystem::SBUFADR+1
        adc     DestAddress+1
        sta     EndAddress+1
        lda     EndAddress
        cmp     ZeroPage::MEMSIZ
        lda     EndAddress+1
        sbc     ZeroPage::MEMSIZ+1
        bcc     ReadFile
        lda     #BASICSystem::EPROGTOOBIG
        jmp     BASICSystem::ERROUT

ReadFile:
        lda     BASICSystem::OREFNUM
        sta     BASICSystem::RWREFNUM
        lda     #0
        sta     BASICSystem::RWTRANS
        sta     BASICSystem::RWTRANS+1
        lda     #ProDOS::CREAD
        jsr     BASICSystem::GOSYSTEM
        bcs     CloseAndExitWithError
        jsr     CloseFile
        jsr     RelocateCode
        lda     DestAddress
        sta     ZeroPage::USR+1
        lda     DestAddress+1
        sta     ZeroPage::USR+2
        lda     EndAddress
        sta     PathPtr
        lda     EndAddress+1
        sta     PathPtr+1
        rts

CloseAndExitWithError:
        sta     ZeroPage::ERRNUM
        sta     TempVal
        jsr     CloseFile
        lda     TempVal
        jmp     BASICSystem::ERROUT

CloseFile:
        lda     BASICSystem::OREFNUM
        sta     BASICSystem::CFREFNUM
        lda     #ProDOS::CCLOSE
        jsr     BASICSystem::GOSYSTEM
        bcc     CloseFileDone
        jmp     BASICSystem::ERROUT
CloseFileDone:
        rts

RelocateCode:
        lda     DestAddress
        sta     ZeroPage::A3L
        lda     DestAddress+1
        sta     ZeroPage::A3H
        lda     CodeLength+1
        sec
        adc     StartAddress+1
        sta     EndPage
RelocLoop:
        ldy     #0
        lda     (ZeroPage::A3L),y
        beq     RelocDone
        jsr     Monitor::INSDS2
        ldy     ZeroPage::OPCODELEN
        cpy     #2
        bne     NextInstruction
        lda     (ZeroPage::A3L),y
        cmp     EndPage
        bcs     NextInstruction
        cmp     StartAddress+1
        bcc     NextInstruction
        lda     DestAddress+1
        clc
        adc     (ZeroPage::A3L),y
        sec
        sbc     StartAddress+1
        sta     (ZeroPage::A3L),y
NextInstruction:
        tya
        sec
        adc     ZeroPage::A3L
        sta     ZeroPage::A3L
        lda     ZeroPage::A3H
        adc     #0
        sta     ZeroPage::A3H
        clv
        bvc     RelocLoop
RelocDone:
        rts

