
        .setcpu "65C02"

        .include "Columns80.s"
        .include "ControlChars.s"
        .include "FileTypes.s"
        .include "MemoryMap.s"
        .include "Monitor.s"
        .include "Mouse.s"
        .include "MouseText.s"
        .include "OpCodes.s"
        .include "ProDOS.s"
        .include "SoftSwitches.s"
        .include "Vectors.s"
        .include "ZeroPage.s"

;;; Zero Page Usage

Pointer       := $06
Pointer2      := $08
Pointer3      := $0A
Pointer4      := $0C
ParamTablePtr := $1A
MouseSlot     := $E1
Pointer5      := $E5
Pointer6      := $E7
DialogHeight  := $EA
DialogWidth   := $EB
ScreenYCoord  := $EC
ScreenXCoord  := $ED
StringPtr     := $EE

DataBuffer    := $B800             ; 4K I/O buffer up to $BC00
BlockBuffer:  := $1000             ; buffer for reading a disk block

;;; also used: $E0, $E2, $E3, $E4, $E9


        jmp     SysStart

        .byte   ProDOS::InterpreterID
        .byte   ProDOS::InterpreterID
        .byte   $41             ; buffer length
DocumentPath:
        .byte   $00             ; length byte
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

L2047:  .addr   $0000           ; never written to?

DocumentPath2:                  ; ???
L2049:  .byte   $00
L204A:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

SysStart:
        lda     SoftSwitch::RDROMLCB2
        sta     SoftSwitch::CLR80VID
        sta     SoftSwitch::CLRALTCHAR
        sta     SoftSwitch::STORE80OFF
        jsr     Monitor::SETNORM
        jsr     Monitor::INIT
        jsr     Monitor::SETVID
        jsr     Monitor::SETKBD
        lda     #ControlChar::TurnOff80Col
        jsr     Monitor::COUT
        jsr     Monitor::HOME
        lda     Monitor::MACHID
        bpl     UnsupportedSystem
        and     #%00110000
        cmp     #$30
        bne     UnsupportedSystem
        lda     Monitor::SUBID1
        cmp     #$EA
        bne     SupportedSystem
UnsupportedSystem:
        ldy     #$00
L20BE:  lda     RequiresText,y
        beq     L20C9
        jsr     Monitor::COUT
        iny
        bne     L20BE
L20C9:  sta     SoftSwitch::KBDSTRB ; Wait for keypress
L20CC:  lda     SoftSwitch::KBD
        bpl     L20CC
        sta     SoftSwitch::KBDSTRB
        cli
L20D5:  jsr     ProDOS::MLI     ; Quit to ProDOS
        .byte   ProDOS::CQUIT
        .addr   QuitParams
        brk
QuitParams:
        .byte   $04
        .byte   $00
        .addr   $0000
        .byte   $00
        .word   $0000

SupportedSystem:
        lda     #HICHAR(' ')
        jsr     MemoryMap::SLOT3ROM
        jsr     Monitor::HOME   ; Clear screen and display title screen
        lda     DocumentPath2
        bne     L2114
        lda     #<TitleScreenText
        sta     Pointer
        lda     #>TitleScreenText
        sta     Pointer+1
        ldy     #$00
L20FA:  lda     (Pointer),y
        beq     L2108
        jsr     Monitor::COUT
        iny
        bne     L20FA
        inc     Pointer+1
        bra     L20FA
L2108:  ldy     #$14            ; Delay loop
L210A:  phy
        lda     #$FF
        jsr     Monitor::WAIT
        ply
        dey
        bne     L210A
;;; Relocate code at $5A2D-$5D09 to $BC00 (3a2d-3d09 in file, bytes 14893 - 15625, 733 bytes)
L2114:  lda     #$00            ; A4 = $BC00
        sta     ZeroPage::A4L
        lda     #$BC
        sta     ZeroPage::A4H
        ldy     #$2D            ; A1 = $5A2D
        lda     #$5A
        sty     ZeroPage::A1L
        sta     ZeroPage::A1H
        ldy     #$09            ; A2 = $5D09
        lda     #$5D
        sty     ZeroPage::A2L
        sta     ZeroPage::A2H
        ldy     #$00
        jsr     Monitor::MOVE
        ldy     #$00
L2133:  lda     Page3_Code,y         ; Copy 256 bytes from $6C2E to $0300
        sta     L0300,y
        dey
        bne     L2133
;;; Turn on AUX LC RAM bank 1, and copy code at $2ABC-$5A2C to it @ $D000.
;;; (abc - 3a2c in file, bytes 2748-14892, 12145 bytes)
        sei
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        lda     #$00            ; A4 = $D000
        sta     ZeroPage::A4L
        lda     #$D0
        sta     ZeroPage::A4H
        ldy     #<MainEditorCode ; A1 = $2ABC
        lda     #>MainEditorCode
        sty     ZeroPage::A1L
        sta     ZeroPage::A1H
        ldy     #$2D            ; A2 = $5A2D
        lda     #$5A
        sty     ZeroPage::A2L
        sta     ZeroPage::A2H
L215E:  lda     (ZeroPage::A1)
        sta     (ZeroPage::A4)
        lda     ZeroPage::A1L
        cmp     ZeroPage::A2L
        bne     L216E
        lda     ZeroPage::A1H
        cmp     ZeroPage::A2H
        beq     L217C
L216E:  inc     ZeroPage::A1L
        bne     L2174
        inc     ZeroPage::A1H
L2174:  inc     ZeroPage::A4L
        bne     L215E
        inc     ZeroPage::A4H
        bra     L215E
;;; Turn on AUX LC RAM bank 2, and copy $1000 bytes of data from $5D09 to it at $D000.
L217C:  sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB2
        lda     SoftSwitch::WRLCRAMB2
        lda     #$00            ; A4 = $D000
        sta     ZeroPage::A4L
        lda     #$D0
        sta     ZeroPage::A4H
        lda     #$09            ; A1 = $5D09
        sta     ZeroPage::A1L
        lda     #$5D
        sta     ZeroPage::A1H
L2195:  lda     (ZeroPage::A1)
        sta     (ZeroPage::A4)
        inc     ZeroPage::A4L
        bne     L219F
        inc     ZeroPage::A4H
L219F:  inc     ZeroPage::A1L
        bne     L21A5
        inc     ZeroPage::A1H
L21A5:  lda     ZeroPage::A4H
        cmp     #$E0
        bne     L2195
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        lda     Monitor::SUBID1
        cmp     #$E0
        bne     L21BE
        sec
        jsr     Monitor::IDROUTINE
        bcc     L21E7
L21BE:  sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        stz     $D06F
        lda     #$1C            ; MouseText over/underscore character
        sta     TitleBarChar
        lda     #$03
        sta     CursorBlinkRate
        lda     #OpCode::NOP_Imp
        sta     LoadKeyModReg+2
        stz     LoadKeyModReg+1
L21DD           := * + 1
        lda     #OpCode::LDX_Imm
        sta     LoadKeyModReg
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
L21E7:  ldx     #$1E
L21E9:  lda     $BF11,x
        cmp     #$FF
        beq     L21F7
        dex
        dex
        bne     L21E9
L21F4:  jmp     L22CD

L21F7:  sta     LBC3A+1
        lda     ProDOS::DEVADR0,x
        sta     LBC3A
        txa
        tay
        asl     a
        asl     a
        asl     a
        sta     ReadBlockUnitNum
        ldx     ProDOS::DEVCNT
        inx
L220C:  lda     ProDOS::DEVCNT,x
        lda     ProDOS::DEVCNT,x
        and     #%11110000
        cmp     ReadBlockUnitNum
        beq     L2234
        dex
        bne     L220C
        stx     LBC3A+1
        stx     LBC3A
        stx     ReadBlockUnitNum
        lda     ProDOS::DEVADR0
        sta     ProDOS::DEVADR0,y
        lda     $BF11
        sta     $BF11,y
        jmp     L22CD

L2234:  jsr     ProDOS::MLI
        .byte   ProDOS::CRDBLOCK
        .addr   ReadBlockParams
        bne     L21F4
        ldy     #$2A
        lda     BlockBuffer,y
        bne     L21F4
        dey
        lda     BlockBuffer,y
        cmp     #$80
        bcs     L21F4
        ldy     #$25
        lda     BlockBuffer,y
        ora     BlockBuffer+1,y
        beq     L2290
        ldy     #$00
L2257:  lda     RemoveRamDiskPrompt,y
        beq     L2262
        jsr     Monitor::COUT
        iny
        bne     L2257
L2262:  lda     BlockBuffer+4
        and     #%00001111
        tax
        ldy     #$00
L226A:  lda     BlockBuffer+5,y
        ora     #%10000000
        jsr     Monitor::COUT
        iny
        dex
        bne     L226A
        lda     #HICHAR('?')
        jsr     Monitor::COUT
L227B:  lda     #HICHAR(ControlChar::Bell)
        jsr     Monitor::COUT
        jsr     Monitor::RDKEY
        and     #%11011111      ; to uppercase
        cmp     #HICHAR('Y')
        beq     L2290
        cmp     #HICHAR('N')
        bne     L227B
        jmp     L20D5

L2290:  lda     ReadBlockUnitNum
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     ProDOS::DEVADR0
        sta     ProDOS::DEVADR0,x
        lda     $BF11
        sta     $BF11,x
        ldx     ProDOS::DEVCNT
        inx
L22A7:  lda     ProDOS::DEVCNT,x
        and     #%11110000
        cmp     ReadBlockUnitNum
        beq     L22B6
        dex
        bne     L22A7
        bra     L22CD
L22B6:  lda     ProDOS::DEVCNT,x
        sta     LBEBB
L22BC:  lda     ProDOS::DEVLST,x
        sta     ProDOS::DEVCNT,x
        inx
        cpx     ProDOS::DEVCNT
        bcc     L22BC
        beq     L22BC
        dec     ProDOS::DEVCNT
L22CD:  lda     DocumentPath2
        beq     L22DB
        lda     DocumentPath2+1
        and     #%01111111
        cmp     #'/'
        beq     L234D
L22DB:  lda     ProDOS::SysPathBuf
        beq     L2333
        cmp     #'A'
        bcs     L2333
        tay
L22E5:  lda     ProDOS::SysPathBuf,y
        sta     Pathname2Buffer,y
        dey
        bpl     L22E5
        lda     Pathname2Buffer+1
        and     #%01111111
        cmp     #'/'
        beq     L234A
        jsr     ProDOS::MLI
        byte    ProDOS::CGETPREFIX
        .addr   GetSetPrefixParams
        beq     L2302
        jmp     L249C

L2302:  lda     PrefixBuffer
        beq     L2333
        tay
        pha
L2309:  lda     PrefixBuffer,y
        sta     Pathname2Buffer,y
        dey
        bne     L2309
        ply
        ldx     ProDOS::SysPathBuf
        stx     L2AB4
        ldx     #$01
L231B:  iny
        cpy     #$41
        bcs     L2333
        lda     ProDOS::SysPathBuf,x
        sta     Pathname2Buffer,y
        inx
        cpx     L2AB4
        bcc     L231B
        beq     L231B
        sty     Pathname2Buffer
        bra     L234A
L2333:  stz     Pathname2Buffer
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        lda     #$03
        sta     $FB3C
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
L234A:  jmp     L2449

L234D:  lda     DocumentPath2
        tay
L2351:  lda     DocumentPath2,y
        sta     LBCA3,y
        dey
        bpl     L2351
        lda     L2047
        sta     LBCA0+1
        lda     L2047+1
        ora     L2047
        bne     L236C
        lda     #$20
        bra     L236F
L236C:  lda     L2047+1
L236F:  sta     LBCA0+2
        lda     DocumentPath2
        tay
L2376:  lda     DocumentPath2,y
        and     #%01111111
        cmp     #'/'
        beq     L2385
        dey
        bne     L2376
        jmp     L22DB

L2385:  sty     L2AB4
        ldy     #$01
L238A:  lda     DocumentPath2,y
        sta     ProDOS::SysPathBuf,y
        sta     Pathname2Buffer,y
        cpy     L2AB4
        beq     L239B
        iny
        bra     L238A
L239B:  ldx     #$00
L239D:  iny
        lda     L2A37,x
        beq     L23A9
        sta     ProDOS::SysPathBuf,y
        inx
        bra     L239D
L23A9:  dey
        sty     ProDOS::SysPathBuf
        ldy     L2AB4
        ldx     #$00
L23B2:  iny
        lda     L2A42,x
        beq     L23BE
        sta     Pathname2Buffer,y
        inx
        bra     L23B2
L23BE:  dey
        sty     Pathname2Buffer
        jsr     ProDOS::MLI
        .byte   ProDOS::COPEN
        .addr   OpenParams

        bne     L2449
        lda     OpenRefNum
        sta     ReadRefNum
        sta     CloseRefNum
        stz     L2AB4
        jsr     ProDOS::MLI
        .byte   ProDOS::CREAD
        .addr   ReadParams
        bne     L23EF
        lda     MemoryMap::INBUF+1
        sta     L2AB4
        lda     #$DD
        sta     ReadReqCount
        jsr     ProDOS::MLI
        dex
        txs
        rol     a
L23EF:  jsr     ProDOS::MLI
        .byte   ProDOS::CCLOSE
        .addr   CloseParams
        lda     L2AB4
        beq     L2449
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        lda     L2AB4
        beq     L2443
        cmp     #$08
        bcs     L2443
        sta     PrinterSlot
        ldy     #$14
L2411:  lda     $02C9,y
        sta     Monitor::MAINID,y
        dey
        bpl     L2411
        ldy     #$01
        ldx     #$01
L241E:  lda     $02C9,y
        cmp     #$20
        bcs     L2430
        pha
        lda     #HICHAR('^')
        sta     PrinterInitString,x
        inx
        pla
        clc
        adc     #$40
L2430:  ora     #%10000000
        sta     PrinterInitString,x
        cpy     $02C9
        beq     L2440
        iny
        inx
        cpx     #$14
        bcc     L241E
L2440:  stx     PrinterInitString
L2443:  sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
L2449:  jsr     ProDOS::MLI
        .byte   ProDOS::CGETPREFIX
        .addr   GetPrefixParams
        bne     L249C
        lda     PrefixBuffer
        bne     L24AF
        lda     DocumentPath+1
        and     #%01111111
        cmp     #'/'
        beq     L24AF
        lda     ProDOS::DEVNUM
        sta     OnLineUnitNum
        jsr     ProDOS::MLI
        .byte   ProDOS::ON_LINE
        .addr   OnLineParams
        bne     L249C
        lda     OnLineBuffer
        and     #%00001111
        beq     L249C
        sta     PrefixBuffer
        inc     PrefixBuffer
        ldy     #$01
        lda     #'/'
        sta     PrefixBuffer+1
        ldy     PrefixBuffer
        lda     PrefixBuffer,y
        cmp     #'/'
        beq     L2494
        iny
        lda     #'/'
        sta     PrefixBuffer,y
        sty     PrefixBuffer
L2494:  jsr     ProDOS::MLI
        .byte   ProDOS::CSETPREFIX
        .addr   GetSetPrefixParams
        beq     L24AF
L249C:  jsr     Monitor::HOME
        ldy     #$00
L24A1:  lda     DiskErrorOccurredText,y
        beq     L24AC
        jsr     Monitor::COUT
        iny
        bne     L24A1
L24AC:  jmp     L20C9

L24AF:  lda     Monitor::MACHID
        lsr     a
        bcs     L24B6
        iny
L24B6:  sty     $E0
        lda     #$08
        sta     MouseSlot
L24BC:  dec     MouseSlot
        lda     MouseSlot
        beq     L24D9
        ora     #%11000000
        sta     Pointer+1
        lda     #$00
        sta     Pointer
        ldx     #$05
L24CC:  ldy     L2A27,x
        lda     (Pointer),y
        cmp     L2A2D,x
        bne     L24BC
        dex
        bpl     L24CC
L24D9:  sta     SoftSwitch::KBDSTRB
        lda     #<ResetHandler
        sta     Vector::SOFTEV
        lda     #>ResetHandler
        sta     Vector::SOFTEV+1
        jsr     Monitor::SETPWRC
;;;  Copy zero page from main to aux mem.
        ldy     #$00
L24EB:  sty     SoftSwitch::SETSTDZP
        lda     $00,y
        sty     SoftSwitch::SETALTZP
        sta     $00,y
        dey
        bne     L24EB
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        lda     MouseSlot
        beq     L2532
        ora     #%11000000
        sta     Pointer+1
        sta     CallSetMouse+2
        sta     CallInitMouse+2
        sta     CallReadMouse+2
        sta     CallPosMouse+2
        stz     Pointer
        ldy     #MouseCall::SetMouse
        lda     (Pointer),y
        sta     CallSetMouse+1
        ldy     #MouseCall::ReadMouse
        lda     (Pointer),y
        sta     CallReadMouse+1
        ldy     #MouseCall::PosMouse
        lda     (Pointer),y
        sta     CallPosMouse+1
        ldy     #MouseCall::InitMouse
        lda     (Pointer),y
        sta     CallInitMouse+1
L2532:  lda     #$00
        sta     Pointer
        lda     #$08
        sta     Pointer+1
        lda     #$13
        sta     L2A33
        lda     #$02
        sta     L2A34
        lda     #$00
        sta     L2A35
        lda     #$12
        sta     L2A36
        jsr     L25CA
        lda     #$45
        sta     L2A33
        lda     #$02
        sta     L2A34
        lda     #$31
        sta     L2A35
        lda     #$0A
        sta     L2A36
        jsr     L25CA
        lda     DocumentPath
        bne     L2570
        jmp     L25AD

L2570:  sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        lda     #$06
        sta     L2AAB
        lda     #$20
        sta     L2AAC
        jsr     ProDOS::MLI
        .byte   ProDOS::CGETFILEINFO
        .addr   GetFileInfoParams
        bne     L25A4
        lda     L2AAE
        cmp     #$0F
        beq     L25A4
        lda     DocumentPath
        sta     ProDOS::SysPathBuf
        tay
L2596:  lda     DocumentPath,y
        sta     ProDOS::SysPathBuf,y
        dey
        bne     L2596
        lda     #$FF
        sta     PathnameLength
L25A4:  sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
L25AD:  jsr     LF738
        jsr     LF5B7
        jsr     LF786
        lda     #$80
        sta     $1200
        ldy     DocumentPath
L25BE:  lda     DocumentPath,y
        sta     PathnameBuffer,y
        dey
        bpl     L25BE
        jmp     LD000

L25CA:  ldy     #$00
        lda     L2A35
        sta     (Pointer),y
        iny
        lda     L2A36
        sta     (Pointer),y
        lda     Pointer
        clc
        adc     #$02
        sta     Pointer
        bcc     L25E2
        inc     Pointer+1
L25E2:  lda     L2A35
        clc
        adc     #$50
        sta     L2A35
        bcc     L25F0
        inc     L2A36
L25F0:  dec     L2A33
        lda     L2A33
        cmp     #$FF
        bne     L25FD
        dec     L2A34
L25FD:  lda     L2A34
        ora     L2A33
        bne     L25CA
        rts

TitleScreenText:
        .highascii "\r\r______________________________"
        .highascii "_______________________________"
        .highascii "___________________\r"
        .highascii "                        "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "["
        .byte   ControlChar::NormalVideo+$80, ControlChar::MouseTextOff+$80
        .highascii "\r                         "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "["
        .byte   ControlChar::NormalVideo+$80, ControlChar::MouseTextOff+$80
        .highascii "  Ed-It! - A Text File Editor\r"
        .highascii "                        "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "["
        .byte   ControlChar::NormalVideo+$80, ControlChar::MouseTextOff+$80
        .highascii "\r                               "
        .highascii "   by Bill Tudor\r"
        .highascii "                            ___"
        .highascii "______________________\r"
        .highascii "                           "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "Z"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii " Northeast Micro Systems "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "_"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "\r                           "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "Z"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "   1220 Gerling Street   "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "_"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "\r                           "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "Z"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "  Schenectady, NY 12308  "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "_"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "\r                           "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "Z"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "   Tel. (518) 370-3976   "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "_"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "\r                            "
        .byte   ControlChar::InverseVideo, ControlChar::MouseTextOn
        .highascii "LLLLLLLLLLLLLLLLLLLLLLLLL"
        .byte   ControlChar::NormalVideo, ControlChar::MouseTextOff
        .highascii "\r                               "
        .highascii " Copyright 1988-89\r"
        .highascii "                               "
        .highascii "ALL RIGHTS RESERVED\r"
        .highascii "                               "
        .highascii "  Sept. 89  v3.00\r"
        .highascii "_______________________________"
        .highascii "_______________________________"
        .highascii "__________________"
        .byte   $00

RequiresText:
        .highascii "ED-IT! REQUIRES AN APPLE //C\r"
        .highascii "ENHANCED //E, OR APPLE IIGS\r"
        .highascii "WITH AT LEAST 128K RAM AND\r"
        .highasciiz "AN 80-COLUMN CARD."
DiskErrorOccurredText:
L29BB:  .highascii "DISK-RELATED ERROR OCCURRED!"
        .byte   HICHAR(ControlChar::Bell)
        .byte   $00
RemoveRamDiskPrompt:
        .highascii "\r\rAuxillary 64K RamDisk found!\r"
        .highasciiz "OK to remove files on /\r"
        .highasciiz "Loading EDIT.CONFIG.."
L2A27:  .byte   $05,$07,$0B,$0C
        .highascii "{"
        .byte   $11
L2A2D:  .byte   $38,$18,$01,$20
        .highascii "V"
        .byte   $00
L2A33:  .byte   $00
L2A34:  .byte   $00
L2A35:  .byte   $00
L2A36:  .byte   $00
L2A37:  .asciiz "TIC.CONFIG"
L2A42:  .asciiz "TIC.EDITOR"
;;; 64-byte buffer (unused?)
L2A4D:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

GetSetPrefixParams:
        .byte   $01,
        .addr   PrefixBuffer

OnLineParams:
        .byte   $02
OnLineUnitNum:
        .byte   $00
        .addr   OnLineBuffer

OpenParams:
        .byte  $03
        .addr  ProDOS::SysPathBuf
        .addr  $8000
OpenRefNum:
        .byte   $00

ReadParams:
        .byte   $04
ReadRefNum:
        .byte   $00
        .addr   MemoryMap::INBUF
ReadReqCount:
        .word   $0002
        .word   $0000

CloseParams:
        .byte   $01
CloseRefNum:
        .byte   $00

ReadBlockParams:
        .byte   $03
ReadBlockUnitNum:
        .byte   $00
        .addr   BlockBuffer
        .word   $0002

GetFileInfoParams:
        .byte   $0A
L2AAB:  .byte   $00
L2AAC:  .byte   $00,$00
L2AAE:  .byte   $00,$00,$00,$00,$00,$00

L2AB4:  .byte   $00,$00,$00,$00,$00,$00,$00,$00

        .reloc


;;; This code gets relocated to $D000 (bank 1) to $FF70 in LCRAM

MainEditorCodeStart := *

        .org $D000

        jsr     ClearTextWindow
        jsr     DrawMenuBarAndMenuTitles
LD006:  jsr     OutputStatusBarLine
        lda     #3
        sta     ZeroPage::WNDTOP
        lda     #22
        sta     ZeroPage::WNDBTM
        jsr     ClearTextWindow
        bit     PathnameLength
        beq     LD01C
        jmp     LD0C6

LD01C:  jsr     LEF42
        jsr     LEF49
        jsr     LEF58
LD025:  jsr     LEF10
        bra     MainEditorInputLoop
LD02A:  ldy     CurrentCursorYPos
        ldx     CurrentCursorXPos
        jsr     SetCursorPosToXY
        jsr     LEED9

;;; Main input loop starts here?
MainEditorInputLoop:
MainEditorInputLoop:  jsr     LEF67
        ldy     CurrentCursorYPos
        ldx     CurrentCursorXPos
        jsr     SetCursorPosToXY
        jsr     GetKeypress
        bmi     LD063
        cmp     #ControlChar::Esc
        beq     LD067
LD04B:  ldy     OpenAppleKeyComboTable
LD04E:  cmp     OpenAppleKeyComboTable,y
        beq     LD05C
        dey
        bne     LD04E
        jsr     LF1A3
        jmp     MainEditorInputLoop

LD05C:  dey
        tya
        asl     a
        tax
        jmp     (OpenAppleKeyComboJumpTable,x)

LD063:  cmp     #HICHAR(ControlChar::Esc)
        bne     LD06C
LD067:  jsr     LD986
        bra     LD01C
LD06C:  pha
        txa
        and     #%00010000
        beq     LD085
        pla
        ldy     FunctionKeys
LD076:  cmp     FunctionKeys,y
        beq     LD080
        dey
        bne     LD076
        bra     LD086
LD080:  lda     FunctionKeysRemapped-1,y
        bra     LD04B
LD085:  pla
LD086:  cmp     #$FF
        bne     LD08D
        jmp     LD439

LD08D:  cmp     #$A0
        bcc     LD094
        jmp     LD2FF

LD094:  ldy     LFB21
LD097:  cmp     LFB21,y
        beq     LD0A5
        dey
        bne     LD097
        jsr     LF1A3
        jmp     MainEditorInputLoop

LD0A5:  dey
        tya
        asl     a
        tax
        jmp     (LFB2A,x)

;;; Handlers for menu items in "Utilities" menu
LD0AC:  ldx     #$01            ; New Prefix
        bra     LD0B6
LD0B0:  ldx     #$02            ; Volumes
        bra     LD0B6
LD0B4:  ldx     #$00            ; Directory
LD0B6:  lda     #$01            ; Menu number 1
        bra     LD0DD

;;; Handlers for menu items in "File" menu
LD0BA:  ldx     #$00            ; About
        bra     LD0DB
LD0BE:  ldx     #$03            ; Print
        bra     LD0DB
LD0C2:  ldx     #$05            ; Quit
        bra     LD0DB
LD0C6:  ldx     #$01            ; Load File
        bra     LD0DB
LD0CA:  ldx     #$02            ; Save/Save As
        lda     PathnameBuffer
        beq     LD0DB
        sta     PathnameLength
        sta     LFBAD
        bra     LD0DB
LD0D9:  ldx     #$04            ; Clear Memory
LD0DB:  lda     #$00            ; Menu number 0

;;; Dispatch to menu item handler; menu # in A, menu item # in X.
LD0DD:  jsr     LD97C
        jmp     LD01C

ForwardTab:
        ldy     CurrentCursorXPos           ; current cursor x
@Loop:  cpy     LastEditableColumn
        beq     @Done
        iny
        lda     TabStops,y
        beq     @Loop
@Done:  sty     CurrentCursorXPos
        jmp     MainEditorInputLoop

BackwardTab:
        ldy     CurrentCursorXPos
@Loop:  cpy     #$00
        beq     @Done
        dey
        lda     TabStops,y
        beq     @Loop
@Done:  sty     CurrentCursorXPos
        jmp     MainEditorInputLoop

ToggleInsertOverwrite:
        lda     OverwriteCursorChar
        cmp     CurrentCursorChar
        bne     LD115
        lda     InsertCursorChar
LD115:  sta     CurrentCursorChar
        jmp     MainEditorInputLoop

;;;  Process left arrow key
MoveLeftOneChar:
        lda     CurrentCursorXPos
        beq     LD126
        dec     CurrentCursorXPos
        jmp     MainEditorInputLoop
LD126:  jsr     LF65B
        beq     LD157
        jsr     LF6D1
        jsr     LF9EA
        and     #%01111111
        sta     CurrentCursorXPos
        jmp     LD025

MoveUpOneLine:
        jsr     LF65B
        beq     @Done
        jsr     LF6D1
@Done:  jmp     MainEditorInputLoop

MoveRightOneChar:
LD144:  lda     CurrentCursorXPos
        cmp     LastEditableColumn
        beq     LD152
        inc     CurrentCursorXPos
        jmp     MainEditorInputLoop

LD152:  jsr     LF61C
        bne     LD15A
LD157:  jmp     MainEditorInputLoop

LD15A:  stz     CurrentCursorXPos

MoveDownOneLine:
        jsr     LF61C
        beq     @Done
        jsr     LF6E9
@Done:  jmp     MainEditorInputLoop

;;; Move up one page
LD168:  jsr     LF65B
        beq     LD165
        lda     CurrentCursorYPos
        cmp     #$03
        beq     LD186
        sec
        sbc     #$03
        tay
LD178:  jsr     LF666
        dey
        bne     LD178
        lda     #$03
        sta     CurrentCursorYPos
        jmp     MainEditorInputLoop

LD186:  ldy     #$13
LD188:  jsr     LF666
        dey
        bne     LD188
        lda     LBEA9+1
        cmp     #$FF
        beq     LD19A
        ora     LBEA9
        bne     LD19D
LD19A:  jsr     LF738
LD19D:  lda     #$03
        sta     CurrentCursorYPos
        jsr     LD025

;;; Move down one page
LD1A5:  jsr     LF61C
        beq     LD165
        lda     #21
        cmp     CurrentCursorYPos
        beq     LD1D3
        sec
        sbc     CurrentCursorYPos
        sta     LBE9C
        ldy     #$00
LD1BA:  jsr     LF61C
        beq     LD1C8
        jsr     LF6A9
        iny
        cpy     LBE9C
        bne     LD1BA
LD1C8:  tya
        clc
        adc     CurrentCursorYPos
        sta     CurrentCursorYPos
        jmp     MainEditorInputLoop

LD1D3:  ldy     #$13
LD1D5:  jsr     LF6A9
        jsr     LF61C
        beq     LD1E0
        dey
        bne     LD1D5
LD1E0:  jmp     LD025

;;;  Move left one word
LD1E3:  lda     CurrentCursorXPos
        bne     LD1F2
        jsr     LF65B
        beq     LD20F
        jsr     LF6D1
        bra     LD246
LD1F2:  jsr     LF62B
        bcc     LD246
        ldy     CurrentCursorXPos
        jsr     LF9F1
        cmp     #$20
        bne     LD204
        jsr     LF701
LD204:  jsr     LF71C
        cpy     #$00
        beq     LD20C
        dey
LD20C:  sty     CurrentCursorXPos
LD20F:  jmp     MainEditorInputLoop

;;;  Move right one word
LD212:  lda     CurrentCursorXPos
        cmp     #77
        bcs     LD236
        ldy     CurrentCursorXPos
        iny
        jsr     LF9F1
        cmp     #$20
        beq     LD227
        jsr     LF72A
LD227:  jsr     LF70E
        dey
        sty     CurrentCursorXPos
        jsr     LF62B
        bcc     LD236
        jmp     MainEditorInputLoop

LD236:  jsr     LF61C
        beq     LD246
        jsr     LF6E9

;;; Move to beginning of line
LD23E:  lda     #$00
        sta     CurrentCursorXPos
        jmp     MainEditorInputLoop

;;; Move to end of line
LD246:  jsr     LF9EA
        and     #%01111111
        cmp     CurrentLineLength
        bne     LD251
        dec     a
LD251:  sta     CurrentCursorXPos
        jmp     MainEditorInputLoop

;;;  Move to beginning of document
LD257:  jsr     LF738
        stz     CurrentCursorXPos
        lda     #$03
        sta     CurrentCursorYPos
        jmp     LD025

;;; Move to end of document
LD265:  jsr     LF61C
        beq     LD275
LD26A:  jsr     LF6A9
        jsr     LF61C
        bne     LD26A
        jsr     LEF10
LD275:  jmp     LD246

ShowHideCRKeyCommand:
        lda     LBEAD
        eor     #%10000000
        sta     LBEAD
        jmp     LD025

ClearToEndOfCurrentLine:
        jsr     LF62B
        bcc     LD2C6
        stz     LFBAF
        jsr     LF9EA
        and     #%10000000
        ora     CurrentCursorXPos
        jsr     LFA2C
        jsr     LF65B
        beq     LD2C0
        jsr     LF666
        jsr     LF9EA
        bmi     LD2BD
        and     #%01111111
        clc
        adc     CurrentCursorXPos
        cmp     LastEditableColumn
        bcs     LD2BD
        sta     CurrentCursorXPos
        jsr     LF888
        jsr     LF6A9
        jsr     LF6D1
        jmp     LD025

LD2BD:  jsr     LF6A9
LD2C0:  jsr     LF888
        jsr     LD025
LD2C6:  jmp     MainEditorInputLoop

CarriageReturn:
        jsr     LF634
        beq     LD2C6
        stz     LFBAF
        jsr     LF76D
        jsr     LF62B
        bcc     LD2E1
        beq     LD2E1
        ldy     CurrentCursorXPos
        jsr     LF7A2
LD2E1:  stz     CurrentCursorXPos
        jsr     LF9EA
        ora     #%10000000
        jsr     LFA2C
        jsr     LF6E9
        jsr     LF9EA
        bne     LD2F9
        ora     #%10000000
        jsr     LFA2C
LD2F9:  jsr     LF888
        jmp     LD025

LD2FF:  stz     LFBAF
        and     #%01111111
        pha
        jsr     LF62B
        beq     LD374
        bcc     LD371
        lda     CurrentCursorChar
        cmp     InsertCursorChar
        bne     LD317
        jmp     LD3CD

LD317:  ldy     CurrentCursorXPos
        iny
        pla
        jsr     LFA33
        sty     CurrentCursorXPos
LD322:  cmp     #$20
        bne     LD36E
        jsr     LF954
        cmp     CurrentCursorXPos
        bcc     LD36E
        ldy     CurrentCursorXPos
LD331:  jsr     LF9F1
        sta     MemoryMap::INBUF,y
        dey
        bne     LD331
        ldx     CurrentCursorXPos
        stx     MemoryMap::INBUF
        stz     CurrentCursorXPos
LD343:  ldy     #$01
        jsr     LF977
        dex
        bne     LD343
        jsr     LF666
        jsr     LF9EA
        tay
        ldx     #$00
LD354:  iny
        inx
        lda     MemoryMap::INBUF,x
        jsr     LFA33
        dec     MemoryMap::INBUF
        bne     LD354
        tya
        jsr     LFA2C
        jsr     LF6A9
        jsr     LF888
        jmp     LD025

LD36E:  jmp     LD02A

LD371:  jsr     LF74B
LD374:  ldy     CurrentCursorXPos
        cpy     LastEditableColumn
        bcs     LD386
        jsr     LF9EA
        inc     a
        jsr     LFA2C
        jmp     LD317

LD386:  jsr     LF634
        bne     LD38E
        jmp     LD435

LD38E:  jsr     LF76D
        ldy     LastEditableColumn
LD394:  jsr     LF9F1
        cmp     #$20
        beq     LD3A5
        dey
        bne     LD394
        jsr     LF9EA
        and     #%01111111
        bra     LD3B0
LD3A5:  sty     CurrentCursorXPos
        jsr     LF7A2
        jsr     LF9EA
        and     #%01111111
LD3B0:  jsr     LFA2C
        jsr     LF6E9
        jsr     LF9EA
        inc     a
        jsr     LFA2C
        and     #%01111111
        tay
        pla
        jsr     LFA33
        sty     CurrentCursorXPos
        jsr     LF888
        jmp     LD025

LD3CD:  jsr     LF9EA
        sta     LBE9C
        and     #%01111111
        cmp     LastEditableColumn
        bcs     LD401
        inc     a
        tay
        bit     LBE9C
        bpl     LD3E3
        ora     #%10000000
LD3E3:  jsr     LFA2C
LD3E6:  dey
        jsr     LF9F1
        iny
        jsr     LFA33
        dey
        cpy     CurrentCursorXPos
        beq     LD3F6
        bcs     LD3E6
LD3F6:  pla
        iny
        jsr     LFA33
        inc     CurrentCursorXPos
        jmp     LD322

LD401:  jsr     LF634
        beq     LD435
        jsr     LF9A2
        jsr     LF6E9
        jsr     LF888
        jsr     LEF10
        jsr     LF6D1
        jsr     LF62B
        bcs     LD3CD
        jsr     LF9EA
        and     #%01111111
        sta     LBE9C
        lda     CurrentCursorXPos
        sec
        sbc     LBE9C
        sta     CurrentCursorXPos
        jsr     LF6E9
        jmp     LD3CD

        jsr     LF1A3
LD435:  pla
        jmp     MainEditorInputLoop

LD439:  stz     LFBAF
        lda     CurrentCursorXPos
        beq     LD4B1
LD441:  jsr     LF62B
        bcs     LD465
        jsr     LF9EA
        and     #%01111111
        sta     CurrentCursorXPos
        beq     LD477
        jsr     LF9EA
        bpl     LD465
        and     #%01111111
        jsr     LFA2C
LD45A:  jsr     LF888
        beq     LD462
        jmp     LD025

LD462:  jmp     LD02A

LD465:  dec     CurrentCursorXPos
        ldy     CurrentCursorXPos
        iny
        cpy     CurrentLineLength
        bcs     LD474
        jsr     LF977
LD474:  jsr     LF9EA
LD477:  beq     LD4EC
        and     #%01111111
        sta     LBE9C
        ldy     #$00
LD480:  iny
        jsr     LF9F1
        cmp     #$20
        beq     LD48E
        iny
        cpy     LBE9C
        bcc     LD480
LD48E:  sty     LBE9C
        jsr     LF954
        cmp     LBE9C
        bcc     LD45A
        beq     LD45A
        sta     LBE9E
        lda     CurrentLineLength
        sec
        sbc     LBE9E
        clc
        adc     CurrentCursorXPos
        sta     CurrentCursorXPos
        jsr     LF6D1
        bra     LD45A
LD4B1:  jsr     LF65B
        beq     LD532
        jsr     LF9EA
        pha
        and     #%01111111
        bne     LD4DE
        jsr     LF61C
        beq     LD4C6
        jsr     LF84D
LD4C6:  jsr     LF793
        pla
        bpl     LD4DE
        jsr     LF6D1
        jsr     LF9EA
        and     #%01111111
        sta     CurrentCursorXPos
        ora     #%10000000
        jsr     LFA2C
        bra     LD512
LD4DE:  jsr     LF6D1
        jsr     LF9EA
        sta     CurrentCursorXPos
        beq     LD4EC
        jmp     LD441

LD4EC:  jsr     LF61C
        beq     LD4F4
        jsr     LF84D
LD4F4:  jsr     LF793
        lda     LBEA5
        ora     LBEA5
        bne     LD515
        jsr     LF786
LD502:  jsr     LF9EA
        and     #%01111111
        sta     CurrentCursorXPos
        jmp     LD025

        lda     #$80
        jsr     LFA2C
LD512:  jmp     LD025

LD515:  lda     LBEA9+1
        cmp     LBEA6
        bcc     LD512
        lda     LBEA5
        cmp     LBEA9
        bcs     LD512
        jsr     LF6D1
        bra     LD502

DeleteForwardChar:
        lda     CurrentCursorXPos
        cmp     LastEditableColumn
        bcc     LD538
LD532:  jsr     LF1A3
LD535:  jmp     MainEditorInputLoop

LD538:  jsr     LF62B
        bcc     LD535
        beq     LD545
LD53F:  inc     CurrentCursorXPos
        jmp     LD439

LD545:  jsr     LF9EA
        bmi     LD53F
        bra     LD535

ClearCurrentLine:
        jsr     LF61C
        bne     LD568
        jsr     LF65B
        bne     LD55C
        stz     CurrentCursorXPos
        jmp     ClearToEndOfCurrentLine

LD55C:  jsr     LF793
        jsr     LF6D1
LD562:  stz     LFBAF
        jmp     LD025

LD568:  jsr     LF84D
        jsr     LF793
        bra     LD562

;;; Block delete
LD570:  lda     CurrentCursorXPos
        pha
        lda     CurrentCursorYPos
        pha
        jsr     LF1BF
        bcc     LD588
        pla
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        jmp     LD01C

LD588:  lda     Pointer3
        cmp     LBEAE
        bne     LD5AF
        lda     Pointer3+1
        cmp     LBEAE+1
        bne     LD5AF
        jsr     LEF42
        jsr     LEF49
        pla
        sta     CurrentCursorYPos
        tay
        pla
        sta     CurrentCursorXPos
        tax
        jsr     SetCursorPosToXY
        jsr     LEF58
        jmp     ClearCurrentLine

LD5AF:  stz     LFBAF
        lda     #<TD964
        ldx     #>TD964
        jsr     DisplayStringInStatusLine
        lda     LBEA9+1
        cmp     LBEB0+1
        bcc     LD5E3
        beq     LD5DB
LD5C3:  lda     LBEA9
        sec
        sbc     LBEB0
        sta     LBE9C
        lda     LBEA9+1
        sbc     LBEB0+1
        sta     LBE9E
        jsr     LF5D7
        bra     LD5F6
LD5DB:  lda     LBEA9
        cmp     LBEB0
        bcs     LD5C3
LD5E3:  lda     LBEB0
        sec
        sbc     LBEA9
        sta     LBE9C
        lda     LBEB0+1
        sbc     LBEA9+1
        sta     LBE9E
LD5F6:  jsr     LF84D
        jsr     LF793
        dec     LBE9C
        lda     LBE9C
        cmp     #$FF
        bne     LD5F6
        dec     LBE9E
        lda     LBE9E
        cmp     #$FF
        bne     LD5F6
        pla
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        lda     LBEA6
        cmp     LBEA9+1
        bcs     LD62A
LD620:  jsr     LF65B
        beq     LD632
        jsr     LF666
        bra     LD632
LD62A:  lda     LBEA5
        cmp     LBEA9
        bcc     LD620
LD632:  lda     LBEA5
        ora     LBEA5
        bne     LD645
        jsr     LF738
        jsr     LF786
        lda     #$00
        jsr     LFA2C
LD645:  lda     LBEA9+1
        bne     LD667
        lda     LBEA9
        cmp     #$14
        bcs     LD667
        lda     CurrentCursorYPos
        sec
        sbc     #$02
        cmp     LBEA9
        bcc     LD667
        beq     LD667
        lda     LBEA9
        clc
        adc     #$02
        sta     CurrentCursorYPos
LD667:  jmp     LD01C

;;;  Copy text to/from clipboard
LD66A:  lda     #<TD5D0
        ldx     #>TD5D0
        jsr     DisplayStringInStatusLineWithEscToGoBack
LD671:  jsr     GetKeypress
        and     #%11011111      ; to uppercase
        cmp     #HICHAR(ControlChar::Esc)
        beq     LD6A4
        cmp     #HICHAR('T')
        beq     LD6E1
        cmp     #HICHAR('F')
        beq     LD687
        jsr     LF1A3
        bra     LD671
LD687:  lda     DataBuffer
        beq     LD69A
        lda     DataBuffer+1
        cmp     #$FF
        bne     LD69A
        lda     DataBuffer+2
        cmp     #$FF
        beq     LD6A7
LD69A:  lda     #<TD5F8
        ldx     #>TD5F8
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     LEAB4
LD6A4:  jmp     LD01C

LD6A7:  jsr     LD77E
        jsr     LF5EE
        lda     DataBuffer
        sta     LD77D
LD6B3:  jsr     LF634
        beq     LD6DB
        jsr     LF76D
        jsr     LF6A9
        lda     (Pointer5)
        and     #%01111111
        tay
LD6C3:  lda     (Pointer5),y
        jsr     LFA33
        dey
        bpl     LD6C3
        and     #%01111111
        sec
        adc     Pointer5
        sta     Pointer5
        bcc     LD6D6
        inc     Pointer5+1
LD6D6:  dec     LD77D
        bne     LD6B3
LD6DB:  jsr     LF605
        jmp     LD01C

LD6E1:  lda     CurrentCursorXPos
        pha
        lda     CurrentCursorYPos
        pha
        jsr     LF1BF
        bcc     LD6F9
LD6EE:  pla
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        jmp     LD01C

LD6F9:  jsr     LD77E
        lda     LBEA9+1
        cmp     LBEB0+1
        bcc     LD716
        bne     LD70E
        lda     LBEA9
        cmp     LBEB0
        bcc     LD716
LD70E:  jsr     LF5EE
        jsr     LF5D7
        bra     LD721
LD716:  ldy     #$03
LD718:  lda     LBEAE,y
        sta     LBEB2,y
        dey
        bpl     LD718
LD721:  stz     DataBuffer
        lda     #$FF
        sta     DataBuffer+1
        sta     DataBuffer+2
LD72C:  jsr     LF9EA
        and     #%01111111
        tay
LD732:  jsr     LF9F1
        sta     (Pointer5),y
        dey
        bpl     LD732
        and     #%01111111
        sec
        adc     Pointer5
        sta     Pointer5
        bcc     LD745
LD743:  inc     Pointer5+1
LD745:  inc     DataBuffer
        lda     Pointer5+1
        cmp     #$BB
        bcc     LD754
        lda     Pointer5
        cmp     #$B0
        bcs     LD771
LD754:  lda     LBEA9+1
        cmp     LBEB4+1
        bcc     LD766
        bne     LD76B
        lda     LBEA9
        cmp     LBEB4
        bcs     LD76B
LD766:  jsr     LF6A9
        bra     LD72C
LD76B:  jsr     LF5D7
        jmp     LD6EE

LD771:  lda     #<TD60C
        ldx     #>TD60C
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     LEAB4
        bra     LD76B
LD77D:  .byte   $00

LD77E:  lda     #<TD964
        ldx     #>TD964
        jsr     DisplayStringInStatusLine
        lda     #<DataBuffer+3
        sta     Pointer5
        lda     #>DataBuffer
        sta     Pointer5+1
        rts

;;; Edit tabs
LD78E:  lda     CurrentCursorXPos
        sta     LFBAE
        lda     #$18
        sta     ZeroPage::WNDBTM
        lda     #<TD6A2
        ldx     #>TD6A2
        jsr     DisplayStringInStatusLine
LD79F:  ldy     #22
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     #80
        jsr     OutputDashedLine
        ldy     #22
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     #$00
LD7B4:  lda     TabStops,y
        beq     LD7BF
        sty     Columns80::OURCH
        jsr     OutputDiamond
LD7BF:  iny
        cpy     CurrentLineLength
        bcc     LD7B4
LD7C5:  ldy     #23
        ldx     #75
        jsr     SetCursorPosToXY
        lda     LFBAE
        inc     a
        ldx     #$00
        ldy     #$02
        jsr     LF55C
        ldy     #22
        ldx     LFBAE
        jsr     SetCursorPosToXY
LD7DF:  jsr     GetKeypress
        jsr     CharToUppercase
        cmp     #HICHAR(ControlChar::LeftArrow)
        beq     LD81F
        cmp     #HICHAR(ControlChar::RightArrow)
        beq     LD831
        cmp     #HICHAR(ControlChar::Esc)
        beq     LD843
        cmp     #HICHAR(ControlChar::Return)
        beq     LD843
        cmp     #HICHAR('T')
        beq     LD80E
        cmp     #HICHAR('C')
        beq     LD846
        cmp     #HICHAR(ControlChar::Tab)
        beq     LD851
        cmp     #ControlChar::Tab
        beq     LD865
        cmp     #HICHAR(ControlChar::ControlX)
        beq     LD846
        jsr     PlayTone
        bra     LD7DF
LD80E:  ldy     LFBAE
        lda     TabStops,y
        beq     LD81C
        inc     a
LD817:  sta     TabStops,y
        bra     LD79F
LD81C:  dec     a
        bne     LD817
LD81F:  lda     LFBAE
        beq     LD829
        dec     LFBAE
        bra     LD7C5
LD829:  lda     LastEditableColumn
        sta     LFBAE
        bra     LD7C5
LD831:  lda     LFBAE
        cmp     LastEditableColumn
        bne     LD83E
        stz     LFBAE
        bra     LD7C5
LD83E:  inc     LFBAE
        bne     LD7C5
LD843:  jmp     LD006

LD846:  ldx     LastEditableColumn
LD849:  stz     TabStops,x
        dex
        bpl     LD849
        bra     LD862
LD851:  ldx     LFBAE
LD854:  cpx     LastEditableColumn
        beq     LD85F
        inx
        lda     TabStops,x
        beq     LD854
LD85F:  stx     LFBAE
LD862:  jmp     LD79F

LD865:  ldx     LFBAE
LD868:  cpx     #$00
        beq     LD85F
        dex
        lda     TabStops,x
        beq     LD868
        bne     LD85F

;;; Show help text
LD874:  jsr     ClearTextWindow
        jsr     DisplayHelpText
        jsr     WaitForSpaceToContinueInStatusLine
        jmp     LD01C

SearchForString:
        jsr     LD94E
        lda     #<TD59E
        ldx     #>TD59E
        jsr     DisplayStringInStatusLineWithEscToGoBack
        ldy     SearchText
LD88D:  lda     SearchText,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LD88D
        lda     #$14            ; 20
        jsr     LF4DF
        bcc     LD8A0
LD89D:  jmp     LD948

LD8A0:  ldx     ProDOS::SysPathBuf
        beq     LD89D
        stx     SearchText
        inx
        stz     SearchText,x
        dex
LD8AD:  lda     ProDOS::SysPathBuf,x
        jsr     CharToUppercase
        sta     SearchText,x
        dex
        bne     LD8AD
        lda     #<TD5AA
        ldx     #>TD5AA
        jsr     DisplayStringInStatusLine
        jsr     LD961
        ldx     CurrentCursorXPos
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        inc     CurrentCursorXPos
        lda     CurrentCursorXPos
        cmp     CurrentLineLength
        bcs     LD90A
        jsr     LF62B
        bcc     LD90A
        jsr     LF9EA
        and     #%01111111
        clc
        sbc     CurrentCursorXPos
        bmi     LD90A
        beq     LD90A
        tax
        ldy     CurrentCursorXPos
        bra     LD906
LD8EF:  jsr     LF9EA
        and     #%01111111
        beq     LD90A
        tax
        ldy     #$01
LD8F9:  jsr     LF9F1
        ora     #%10000000
        jsr     CharToUppercase
        cmp     LFB8F
        beq     LD914
LD906:  iny
        dex
        bne     LD8F9
LD90A:  jsr     LF61C
        beq     LD93E
        jsr     LD96E
        bra     LD8EF
LD914:  phx
        phy
        ldx     #$02
LD918:  iny
        lda     SearchText,x
        beq     LD933
        sta     Pointer6+1
        jsr     LF9F1
        ora     #%10000000
        jsr     CharToUppercase
        cmp     Pointer6+1
        bne     LD92F
        inx
        bra     LD918
LD92F:  ply
        plx
        bra     LD906
LD933:  ply
        plx
        dey
        sty     CurrentCursorXPos
        jsr     LD94E
        bra     LD948
LD93E:  lda     #<TD5B8
        ldx     #>TD5B8
        jsr     DisplayStringInStatusLine
        jsr     LEAB4
LD948:  jsr     LD95E
        jmp     LD01C

LD94E:  jsr     LF5C0
        lda     CurrentCursorXPos
        sta     LBE9C
        lda     CurrentCursorYPos
        sta     LBE9E
        rts

LD95E:  jsr     LF5D7
LD961:  lda     LBE9C
        sta     CurrentCursorXPos
        lda     LBE9E
        sta     CurrentCursorYPos
        rts

LD96E:  lda     CurrentCursorYPos
        cmp     #21
        beq     LD978
        inc     CurrentCursorYPos
LD978:  jsr     LF6A9
        rts

LD97C:  sta     $E2             ; menu #
        stx     $E3             ; menu item #
        lda     #$FF
        sta     $E4
        bra     LD98C
LD986:  stz     $E4
        stz     $E2
        stz     $E3
LD98C:  lda     #HICHAR(ControlChar::Return)
        sta     LBEC8+4
        lda     #$97
        sta     LFB8C
        lda     #$69
        sta     LFB8D
LD99B:  lda     #<TD65C
        ldx     #>TD65C
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     SaveScreenAreaUnderMenus
LD9A5:  jsr     LDFFE
        lda     $E2
        jsr     LE04C
LD9AD:  jsr     LDFAC
        lda     $E4
        bne     LDA2C
LD9B4:  ldy     #23
        ldx     #54
        jsr     SetCursorPosToXY
        ldx     #$06
        jsr     GetSpecificKeypress
        bcs     LD9D6
        txa
        asl     a
        tax
        jmp     (LD9C8,x)

LD9C8:  .addr   LD9EC
        .addr   LDA2C
        .addr   LD9EC
        .addr   LDA0E
        .addr   LDA2C
        .addr   LD9F1
        .addr   LDA00

LD9D6:  jsr     RestoreScreenAreaUnderMenus
        jsr     DrawMenuBarAndMenuTitles
        lda     #HICHAR(ControlChar::Esc)
        sta     LBEC8+4
        lda     #$83
        sta     LFB8C
        lda     #$7D
        sta     LFB8D
        rts

LD9EC:  jsr     PlayTone
        bra     LD9B4

LD9F1:  lda     $E3
        dec     a
        bpl     LD9FC
        ldy     $E2
        lda     MenuLengths,y
        dec     a
LD9FC:  sta     $E3
        bra     LD9AD

LDA00:  lda     $E3
        inc     a
        ldy     $E2
        cmp     MenuLengths,y
        bcc     LD9FC
        lda     #$00
        bra     LD9FC

LDA0E:  lda     $E2
        dec     a
        bpl     LDA17
        lda     LFB43
        dec     a
LDA17:  sta     $E2
        jsr     RestoreScreenAreaUnderMenus
        stz     $E3
        bra     LD9A5
        lda     $E2
        inc     a
        cmp     LFB43
        bcc     LDA17
        lda     #$00
        bra     LDA17
LDA2C:  jsr     LDF97
        lda     $E2
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $E2
        lda     $E3
        asl     a
        clc
        adc     $E2
        tax
        jmp     (MenuItemJumpTable,x)

ShowVolumesDialog:
;;;  Draw Volumes Online dialog
        jsr     DrawDialogBox
        .byte   17              ; height
        .byte   35              ; width
        .byte   4               ; y-coord
        .byte   36              ; x-coord
        .byte   46              ; x-coord of title
        .addr   TDCCC
        lda     #ProDOS::CONLINE
        ldx     #<EditorOnLineParams
        ldy     #>EditorOnLineParams
        jsr     MakeMLICall
        bcc     LDA61
        jsr     LE7A9
        bra     LDA5E
LDA5B:  jsr     WaitForSpaceToContinueInStatusLine
LDA5E:  jmp     LD9D6

LDA61:  lda     #$00
        sta     LFBAE
        ldy     #6
LDA68:  ldx     #41
        jsr     SetCursorPosToXY
        ldy     LFBAE
        lda     DataBuffer,y
        beq     LDA5B
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        and     #%00000111
        pha
        lda     #$D3
        jsr     OutputCharAndAdvanceScreenPos
        pla
        ora     #%10110000
        jsr     OutputCharAndAdvanceScreenPos
        lda     #$AC
        jsr     OutputCharAndAdvanceScreenPos
        lda     #$C4
        jsr     OutputCharAndAdvanceScreenPos
        ldx     #$B1
        ldy     LFBAE
        lda     DataBuffer,y
        bpl     LDA9C
        inx
LDA9C:  txa
        jsr     OutputCharAndAdvanceScreenPos
        ldy     #$04
        jsr     OutputSpaces
        ldy     LFBAE
        lda     DataBuffer,y
        and     #%00001111
        beq     LDAC3
        pha
        lda     #$AF
        jsr     OutputCharAndAdvanceScreenPos
        pla
        tax
LDAB7:  iny
        lda     DataBuffer,y
        ora     #%10000000
        jsr     OutputCharAndAdvanceScreenPos
        dex
        bne     LDAB7
LDAC3:  lda     LFBAE
        clc
        adc     #$10
        sta     LFBAE
        ldy     ZeroPage::CV
        iny
        bra     LDA68

ShowPrintDialog:
        jsr     LF5C0
        jsr     LF2C3
        jsr     LF5D7
        jmp     LD9D6

ShowQuitDialog:
        jsr     DrawDialogBox
        .byte   $07,$24,$05,$20,$30
        .addr   TD741
        ldy     #7
        ldx     #38
        jsr     SetCursorPosToXY
        lda     #<TD748         ; Q - Quit...
        ldx     #>TD748
        jsr     DisplayMSB1String
        ldy     #8
        ldx     #38
        jsr     SetCursorPosToXY
        lda     #<TD761         ; E - Exit ...
        ldx     #>TD761
        jsr     DisplayMSB1String
        ldx     #50
        ldy     #9
        jsr     DrawAbortButton
        jsr     DisplayHitEscToEditDocInStatusLine
LDB0D:  jsr     PlayTone
        ldx     #$01
        jsr     GetSpecificKeypress
        bcs     LDB4E
        ora     #%10000000      ; set MSB
        and     #%11011111      ; convert to uppercase
        cmp     #HICHAR('E')
        beq     @Exit
        cmp     #HICHAR('Q')
        bne     LDB0D
        lda     LBEA6
        bne     LDB36
        lda     LBEA5
        cmp     #$01
        bne     LDB36
        jsr     LF9EA
        and     #%01111111
        beq     LDB4B
LDB36:  lda     LFBAF
        bne     LDB4B
        lda     PathnameBuffer
        beq     LDB46
        sta     LFBAD
        sta     PathnameLength
LDB46:  jsr     LE4F8
        bcs     LDB4E
@Exit:  jmp     LBC00

LDB4E:  jmp     LD9D6

ShowAboutBox:
        jsr     DrawDialogBox
        .byte   14
        .byte   60
        .byte   6
        .byte   10
        .byte   36
        .addr   TD99A
        ldy     #8
        ldx     #23
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #9
        ldx     #27
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #9
        ldx     #27
        jsr     SetCursorPosToXY
        lda     #<TD9A3
        ldx     #>TD9A3
        jsr     DisplayMSB1String
        ldy     #10
        ldx     #23
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #11
        ldx     #34
        jsr     SetCursorPosToXY
        lda     #<TD9C1
        ldx     #>TD9C1
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TD9D1
        ldx     #>TD9D1
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TDA36
        ldx     #>TDA36
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TDA4D
        ldx     #>TDA4D
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TD9EA
        ldx     #>TD9EA
        jsr     DisplayMSB1String
        lda     #16
        sta     Columns80::OURCH
        lda     #<TDA02
        ldx     #>TDA02
        jsr     DisplayMSB1String
        jsr     WaitForSpaceToContinueInStatusLine
        jmp     LD9D6

ShowSaveAsDialog:
        jsr     LE4F8
        jmp     LD9D6

ShowListDirectoryDialog:
        jsr     LE098
        jmp     LD9D6

ShowSetPrefixDialog:
        lda     #$73
        ldx     #$D7
        jsr     LE723
        ldy     #$0F
        ldx     #$03
        jsr     SetCursorPosToXY
        ldy     #$49
        jsr     OutputSpaces
        jsr     DisplayHitEscToEditDocInStatusLine
        ldy     PrefixBuffer
LDBFC:  lda     PrefixBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDBFC
LDC05:  ldy     #$10
        ldx     #$1C
        jsr     SetCursorPosToXY
        lda     #<TD780
        ldx     #>TD780
        jsr     DisplayMSB1String
LDC13:  ldy     #$0C
        ldx     #$0B
        lda     #$40
        jsr     LE64D
        bcc     LDC29
        cmp     #$73
        beq     LDC33
        cmp     #$53
        beq     LDC33
        jmp     LDD1C

LDC29:  lda     ProDOS::SysPathBuf
        cmp     #$02
        bcc     LDC13
        jmp     LDCDB

LDC33:  stz     EditorOnLineUnitNum
        ldy     #16
        ldx     #25
        jsr     SetCursorPosToXY
        ldy     #$32
        jsr     OutputSpaces
        ldx     #$1F
        stx     Columns80::OURCH
        lda     #<TD799
        ldx     #>TD799
        jsr     DisplayMSB1String
        bra     LDC53
LDC50:  jsr     PlayTone
LDC53:  jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDC05
        cmp     #HICHAR('1')
        bcc     LDC50
        cmp     #HICHAR('8')
        bcs     LDC50
        jsr     OutputCharAndAdvanceScreenPos
        asl     a
        asl     a
        asl     a
        asl     a
        sta     EditorOnLineUnitNum
        lda     #$2C
        sta     Columns80::OURCH
        lda     #<TD79F
        ldx     #>TD79F
        jsr     DisplayMSB1String
LDC78:  jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDC33
        cmp     #HICHAR('1')
        beq     LDC96
        cmp     #HICHAR('2')
        beq     LDC8C
        jsr     PlayTone
        bra     LDC78
LDC8C:  pha
        lda     EditorOnLineUnitNum
        ora     #%10000000
        sta     EditorOnLineUnitNum
        pla
LDC96:  jsr     OutputCharAndAdvanceScreenPos
        lda     #$81
        sta     EditorOnLineDataBuffer
        lda     #$02
        sta     EditorOnLineDataBuffer+1
        lda     #ProDOS::CONLINE
        ldx     #<EditorOnLineParams
        ldy     #>EditorOnLineParams
        jsr     MakeMLICall
        pha
        php
        stz     EditorOnLineUnitNum
        lda     #<DataBuffer
        sta     EditorOnLineDataBuffer
        lda     #>DataBuffer
        sta     EditorOnLineDataBuffer+1
        plp
        pla
        bcs     LDCC7
        lda     ProDOS::SysPathBuf+1
        bne     LDCCD
        lda     ProDOS::SysPathBuf+2
LDCC7:  jsr     LE7A9
        jmp     ShowSetPrefixDialog
LDCCD:  and     #%00001111
        inc     a
        sta     ProDOS::SysPathBuf
        lda     #'/'
        sta     ProDOS::SysPathBuf+1
        jmp     LDC05

LDCDB:  ldx     #$00
        ldy     ProDOS::SysPathBuf
LDCE0:  lda     ProDOS::SysPathBuf,x
        sta     ProDOS::SysPathBuf-1,x
        inx
        dey
        bpl     LDCE0
        lda     #ProDOS::CSETPREFIX
        ldy     #>EditorSetPrefixParams
        ldx     #<EditorSetPrefixParams
        jsr     MakeMLICall
        beq     LDCFB
        jsr     LE7A9
        jmp     ShowSetPrefixDialog

LDCFB:  ldy     ProDOS::SysPathBuf-1
LDCFE:  lda     ProDOS::SysPathBuf-1,y
        sta     PrefixBuffer,y
        dey
        bpl     LDCFE
        ldy     PrefixBuffer
        lda     PrefixBuffer,y
        and     #%01111111
        cmp     #'/'
        beq     LDD1C
        iny
        lda     #'/'
        sta     PrefixBuffer,y
        sty     PrefixBuffer
LDD1C:  jmp     LD9D6

ShowOpenFileDialog:
        jsr     LE28A
        jmp     LD9D6

ShowChangeMouseStatusDialog:
        jsr     DrawDialogBox
        .byte   $09,$28,$09,$14,$1E
        .addr   TDDC7
        ldy     #$0D
        ldx     #$17
        jsr     DrawAbortButton
        ldy     #$0D
        ldx     #$2B
        jsr     DrawAcceptButton
        ldy     #$0B
        ldx     #$1E
        jsr     SetCursorPosToXY
        lda     MouseSlot
        beq     LDD61
        lda     #<TD8BB
        ldx     #>TD8BB
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     LEAB7
        bcs     LDD5E
        lda     MouseSlot
        sta     SavedMouseSlot
        stz     MouseSlot
LDD5E:  jmp     LD9D6

LDD61:  lda     SavedMouseSlot
        beq     LDD7D
        lda     #<TD8CB
        ldx     #>TD8CB
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     LEAB7
        bcs     LDD5E
        lda     SavedMouseSlot
        sta     MouseSlot
        jmp     LD9D6

LDD7D:  lda     #<TD8A7
        ldx     #>TD8A7
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     GetKeypress
        jmp     LD9D6

ChangeBlinkRate:
        lda     #<TD8DA
        ldx     #>TD8DA            ; "Enter new rate..."
        ldy     CursorBlinkRate
        jsr     LDF54
        bcs     LDD9F
        bne     LDD9C
        inc     a
LDD9C:  sta     CursorBlinkRate
LDD9F:  jmp     LD9D6

ShowClearMemoryDialog:
        jsr     DrawDialogBox
        .byte   $07,$28,$06,$19,$27
        .addr   TD974
        ldy     #$08
        ldx     #$20
        jsr     SetCursorPosToXY
        lda     #<TD983
        ldx     #>TD983
        jsr     DisplayMSB1String
        ldy     #$0A
        ldx     #$1C
        jsr     DrawAbortButton
        ldy     #$0A
        ldx     #$30
        jsr     DrawAcceptButton
        jsr     LF01C
LDDCB:  jsr     PlayTone
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDDEA
        cmp     #HICHAR(ControlChar::Return)
        bne     LDDCB
        jsr     LF738
        jsr     LF786
        jsr     LF5B7
        lda     #$80
        jsr     LFA2C
        stz     PathnameBuffer
LDDEA:  jmp     LD9D6

SetLineLengthPrompt:
        lda     LBEA6
        bne     LDE00
        lda     LBEA5
        cmp     #$01
        bne     LDE00
        jsr     LF9EA
        and     #%01111111
        beq     LDE0F
LDE00:  lda     #<TD90F
        ldx     #>TD90F
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     PlayTone
        jsr     WaitForSpaceKeypress
        bra     LDE88
LDE0F:  jsr     LF5B7
LDE12:  lda     #<TD8F0
        ldx     #>TD8F0
        jsr     DisplayStringInStatusLineWithEscToGoBack
        lda     CurrentLineLength
        ldx     #$00
        ldy     #$02
        jsr     LF567
        ldy     LFC23
LDE26:  lda     LFC23,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDE26
        lda     #$03
        jsr     LF4DF
        bcc     LDE41
        jmp     LDE88

LDE39:  jsr     PlayTone
        stz     Columns80::OURCH
        bra     LDE12
LDE41:  stz     LDE8B
        stz     LDE8C
        lda     ProDOS::SysPathBuf
        cmp     #$02
        bcc     LDE39
        lda     ProDOS::SysPathBuf+1
        cmp     #$B3
        bcc     LDE39
        cmp     #$B8
        bcs     LDE39
        and     #%00001111
        sta     LDE8C
        lda     ProDOS::SysPathBuf+2
        cmp     #$B0
        bcc     LDE39
        cmp     #$BA
        bcs     LDE39
        and     #%00001111
        sta     LDE8B
        ldy     LDE8C
        beq     LDE79
LDE73:  clc
        adc     #$0A
        dey
        bne     LDE73
LDE79:  cmp     #$27
        bcc     LDE39
        cmp     #$50
        bcs     LDE39
        sta     CurrentLineLength
        dec     a
        sta     LastEditableColumn
LDE88:  jmp     LD9D6

LDE8B:  .byte   $00
LDE8C:  .byte   $00

ShowEditMacrosScreen:
LDE8D:  jsr     DrawMenuBar
        ldy     #$01
        ldx     #$05
        jsr     SetCursorPosToXY
        jsr     LEFF3
        lda     #<TDDF3
        ldx     #>TDDF3
        jsr     DisplayMSB1String
        jsr     LEFF6
LDEA4:  jsr     ClearTextWindow
        jsr     L0350
        lda     #<TDB5F
        ldx     #>TDB5F
        jsr     DisplayStringInStatusLineWithEscToGoBack
LDEB1:  jsr     GetKeypress
        cmp     #HICHAR('1')
        blt     LDEBC
        cmp     #HICHAR(':')
        blt     LDED1
LDEBC:  and     #%11011111
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDECE
        cmp     #HICHAR('S')
        beq     LDECB
        jsr     PlayTone
        bra     LDEB1
LDECB:  jsr     LDED8
LDECE:  jmp     LD9D6

LDED1:  and     #%00001111
        jsr     L0300
        bra     LDEA4
LDED8:  ldy     Pathname2Buffer
LDEDB:  lda     Pathname2Buffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDEDB
LDEE4:  lda     #<TDBE6
        ldx     #>TDBE6
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     LE61A
        beq     LDEFF
        lda     #<TDBC5
        ldx     #>TDBC5
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        bne     LDEE4
        rts

LDEFF:  lda     EditorGetFileInfoFileType
        cmp     #FileType::SYS
        beq     LDF0B
        lda     #$4B
LDF08:  jmp     LE7A9

LDF0B:  jsr     LE624
        bne     LDF08
        lda     #ProDOS::CSETMARK
        ldx     #<EditorSetMarkParams
        ldy     #>EditorSetMarkParams
        jsr     MakeMLICall
        beq     LDF1E
LDF1B:  jmp     LE483

LDF1E:  lda     #<ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        stz     EditorReadWriteRequestCount+1
        lda     #$47
        sta     EditorReadWriteRequestCount
        lda     #$01
LDF32:  sta     $03E4
        jsr     L0364
        lda     #ProDOS::CWRITE
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        bne     LDF1B
        lda     $03E4
        inc     a
        cmp     #$0A
        bcc     LDF32
        jsr     LE643
        rts

LDF4F:  sta     LDF96
        bra     LDF5A
LDF54:  sty     LDF96
        jsr     DisplayStringInStatusLineWithEscToGoBack
LDF5A:  lda     Columns80::OURCH
        sta     LDF95
LDF60:  lda     LDF95
        sta     Columns80::OURCH
        lda     LDF96
        ora     #%10110000
        sta     ProDOS::SysPathBuf+1
        lda     #$01
        sta     ProDOS::SysPathBuf
        lda     #$02
        jsr     LF4DF
        bcs     LDF93
        lda     ProDOS::SysPathBuf
        beq     LDF8A
        lda     ProDOS::SysPathBuf+1
        cmp     #$B0
        bcc     LDF8A
        cmp     #$BA
        bcc     LDF8F
LDF8A:  jsr     PlayTone
        bra     LDF60
LDF8F:  and     #%00001111
        clc
        rts

LDF93:  sec
        rts

LDF95:  .byte   $00
LDF96:  .byte   $00

LDF97:  ldy     $E2
        lda     MenuXPositions,y
        tax
        lda     #$02
        clc
        adc     $E3
        tay
        jsr     SetCursorPosToXY
        lda     #$05            ; inverse checkmark char?
        jsr     OutputCharAndAdvanceScreenPos
        rts

;;; Draws a menu probably:
LDFAC:  lda     #$02
        jsr     ComputeTextOutputPos
        stz     $E9
        ldy     $E2
        lda     MenuXPositions,y
        dec     a
        sta     Pointer6+1
LDFBB:  lda     Pointer6+1
        sta     Columns80::OURCH
        jsr     OutputRightVerticalBar
        lda     $E9
        cmp     $E3
        bne     LDFCC
        jsr     LEFF3
LDFCC:  lda     $E9
        asl     a
        tay
        iny
        lda     (Pointer5),y
        tax
        dey
        lda     (Pointer5),y
        jsr     DisplayMSB1String
        jsr     LEFF6
        jsr     OutputLeftVerticalBar
        jsr     MoveTextOutputPosToStartOfNextLine
        inc     $E9
        lda     $E9
        ldy     $E2
        cmp     MenuLengths,y
        bcc     LDFBB
        lda     Pointer6+1
        inc     a
        sta     Columns80::OURCH
        ldy     $E2
        lda     MenuWidths,y
        tay
        jsr     OutputOverscoreLine
        rts

LDFFE:  lda     $E2
        asl     a
        tay
        lda     MenuItemListAddresses,y
        sta     Pointer5
        iny
        lda     MenuItemListAddresses,y
        sta     Pointer5+1
        rts


DrawMenuBar:
        ldx     #1
        ldy     #0
        jsr     SetCursorPosToXY
        ldy     #78
        jsr     OutputUnderscoreLine
        ldx     #0
        ldy     #1
        jsr     SetCursorPosToXY
        lda     #$1A            ; MouseText right vbar
        jsr     OutputCharAndAdvanceScreenPos
        ldy     #39
LE028:  lda     #$17            ; MouseText checkboard2
        jsr     OutputCharAndAdvanceScreenPos
        lda     #$16            ; MouseText checkerboard1
        jsr     OutputCharAndAdvanceScreenPos
        dey
        bne     LE028
        lda     #$1F            ; MouseText left vbar
        jsr     OutputCharAndAdvanceScreenPos
        ldx     #1
        ldy     #2
        jsr     SetCursorPosToXY
        ldy     #78
        jsr     OutputOverscoreLine
        lda     #$FF
        rts

DrawMenuBarAndMenuTitles:
        jsr     DrawMenuBar
LE04C:  sta     $E9
        inc     $E9
        ldy     #$01
        ldx     MenuXPositions
        jsr     SetCursorPosToXY
        dec     $E9
        beq     LE05F
        jsr     LEFF3
LE05F:  lda     #<TDCDD
        ldx     #>TDCDD
        jsr     DisplayMSB1String
        jsr     LEFF6
        lda     LFB3E
        sta     Columns80::OURCH
        dec     $E9
        beq     LE076
        jsr     LEFF3
LE076:  lda     #<TDCE4
        ldx     #>TDCE4
        jsr     DisplayMSB1String
        jsr     LEFF6
        lda     LFB3F
        sta     Columns80::OURCH
        dec     $E9
        beq     LE08D
        jsr     LEFF3
LE08D:  lda     #<TDCF0
        ldx     #>TDCF0
        jsr     DisplayMSB1String
        jsr     LEFF6
        rts

LE098:  jsr     DrawDialogBox
        .byte   $0E, $45, $06, $04, $20
        .addr   TDC19
        ldy     #$08
        ldx     #$06
        jsr     SetCursorPosToXY
        lda     #<TDC25
        ldx     #>TDC25
        jsr     DisplayMSB1String
        ldx     #$01
        ldy     PrefixBuffer
LE0B5:  lda     PrefixBuffer,x
        ora     #%10000000
        jsr     OutputCharAndAdvanceScreenPos
        inx
        dey
        bne     LE0B5
        ldy     #$09
        ldx     #$05
        jsr     SetCursorPosToXY
        ldy     #$45
        jsr     OutputHorizontalLineX
        ldy     #$0A
        ldx     #$06
        jsr     SetCursorPosToXY
        lda     #<TDC29
        ldx     #>TDC29
        jsr     DisplayMSB1String
        lda     #<TDC54
        ldx     #>TDC54
        jsr     DisplayMSB1String
        ldy     #11
        ldx     #5
        jsr     SetCursorPosToXY
        ldy     #$34
        jsr     OutputHorizontalLineX
        jsr     OutputLeftVerticalBar
        ldy     #$03
        jsr     OutputSpaces
        ldy     #$06
        jsr     OutputHorizontalLineX
        ldy     #12
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC69
        ldx     #>TDC69
        jsr     DisplayMSB1String
        ldy     #13
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC71
        ldx     #>TDC71
        jsr     DisplayMSB1String
        ldy     #14
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC79
        ldx     #>TDC79
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        ldy     #16
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        ldy     #17
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC81
        ldx     #>TDC81
        jsr     DisplayMSB1String
        ldy     #18
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC90
        ldx     #>TDC90
        jsr     DisplayMSB1String
        ldy     #19
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        jsr     DisplayHitEscToEditDocInStatusLine
        ldy     PrefixBuffer
LE174:  lda     PrefixBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LE174
        sta     LBE9C
        ldy     #$02
LE182:  lda     ProDOS::SysPathBuf,y
        ora     #%10000000
        cmp     #HICHAR('/')
        beq     LE191
        iny
        cpy     ProDOS::SysPathBuf
        bcc     LE182
LE191:  sty     ProDOS::SysPathBuf
        jsr     LE61A
        beq     LE19C
LE199:  jmp     LE615

LE19C:  lda     LBE9C
        sta     ProDOS::SysPathBuf
        ldx     #65
        ldy     #12
        jsr     SetCursorPosToXY
        lda     EditorGetFileInfoAuxType
        ldx     EditorGetFileInfoAuxType+1
        ldy     #$05
        jsr     LF55C
        ldx     #65
        ldy     #13
        jsr     SetCursorPosToXY
        lda     EditorGetFileInfoBlocksUsed
        ldx     EditorGetFileInfoBlocksUsed+1
        ldy     #$05
        jsr     LF55C
        ldx     #65
        ldy     #14
        jsr     SetCursorPosToXY
LE1CD:  lda     EditorGetFileInfoAuxType
        sec
        sbc     EditorGetFileInfoBlocksUsed
        pha
        lda     EditorGetFileInfoAuxType+1
        sbc     $BF70           ; TODO - check
        tax
        pla
        ldy     #$05
        jsr     LF55C
        jsr     LE99F
        bcs     LE199
        .byte   $B2          ; ???

LE1E7:  lda     #$08
        sta     LBE9B
        ldy     #$0C
        ldx     #$06
        jsr     SetCursorPosToXY
LE1F3:  lda     LBE9F
        ora     LBEA0
        beq     LE26A
        jsr     LE9E8
        bcs     LE199
        dec     LBE9F
        lda     LBE9F
        cmp     #$FF
        bne     LE20D
        dec     LBEA0
LE20D:  ldy     #$32
        jsr     OutputSpaces
        lda     #$06
        sta     Columns80::OURCH
        jsr     LEA03
        lda     #$00
        ldx     #$02
        jsr     DisplayMSB1String
        lda     #$32
        sta     Columns80::OURCH
        lda     #$A4
        jsr     OutputCharAndAdvanceScreenPos
        ldx     $029F
        lda     $02A0
        jsr     LF542
        jsr     MoveTextOutputPosToStartOfNextLine
        lda     #$06
        sta     Columns80::OURCH
        dec     LBE9B
        beq     LE244
        jmp     LE1F3

LE244:  lda     LBE9F
        ora     LBEA0
        beq     LE27C
        ldy     #$17
        ldx     #$19
        jsr     SetCursorPosToXY
LE253:  jsr     GetKeypress
        cmp     #HICHAR(' ')
        beq     LE25E
        cmp     #HICHAR(ControlChar::Return)
        bne     LE261
LE25E:  jmp     LE1E7

LE261:  cmp     #HICHAR(ControlChar::Esc)
        beq     LE286
        jsr     PlayTone
        bra     LE253
LE26A:  ldy     #$32
        jsr     OutputSpaces
        jsr     MoveTextOutputPosToStartOfNextLine
        lda     #$06
        sta     Columns80::OURCH
        dec     LBE9B
        bne     LE26A
LE27C:  lda     #<TDC9C
        ldx     #>TDC9C
        jsr     DisplayStringInStatusLine
        jsr     GetKeypress
LE286:  jsr     LE643
        rts

LE28A:  lda     PathnameLength
        bne     LE2A7
        lda     LBEA6
        bne     LE2A2
        lda     LBEA5
        cmp     #$01
        bne     LE2A2
        jsr     LF9EA
        and     #%01111111
LE2A0:  beq     LE2A7
LE2A2:  lda     LFBAF
        beq     LE2AA
LE2A7:  jmp     LE30C

LE2AA:  jsr     DrawDialogBox
        .byte   $0C, $38, $09, $0B, $23
        .addr   TDA88
        ldy     #12
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TD7F5
        ldx     #>TD7F5
        jsr     DisplayMSB1String
        ldy     #14
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TD81B
        ldx     #>TD81B
        jsr     DisplayMSB1String
        ldy     #17
        ldx     #22
        jsr     DrawAbortButton
        ldy     #17
        ldx     #44
        jsr     DrawAcceptButton
        jsr     DisplayHitEscToEditDocInStatusLine
        lda     #HICHAR(ControlChar::Return)
        sta     LBEC8+4
LE2E6:  jsr     PlayTone
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LE308
        cmp     #HICHAR(ControlChar::Return)
        beq     LE30C
        cmp     #HICHAR('S')
        bne     LE2E6
        lda     PathnameBuffer
        beq     LE303
        sta     LFBAD
        sta     PathnameLength
LE303:  jsr     LE4F8
        bcc     LE309
LE308:  rts

LE309:  stz     PathnameLength
LE30C:  lda     #$88
        ldx     #$DA
        jsr     LE723
        lda     #$4C
        sta     LBEC8+4
        lda     PathnameLength
        bne     LE32E
        ldy     #$11
        ldx     #$19
        jsr     SetCursorPosToXY
        lda     #<TD7D4
        ldx     #>TD7D4
        jsr     DisplayMSB1String
        stz     ProDOS::SysPathBuf
LE32E:  ldy     #$0C
        ldx     #$0B
        lda     #$40
        jsr     LE64D
        bcc     LE34E
        and     #%11011111      ; to uppercase
        cmp     #'N'
        beq     LE348
        cmp     #'L'
        bne     LE34D
        jsr     LE7E7
        bra     LE30C
LE348:  jsr     LE48B
        bra     LE30C
LE34D:  rts

LE34E:  jsr     LE61A
        beq     LE358
LE353:  jsr     LE7A9
        bra     LE30C
LE358:  lda     EditorGetFileInfoFileType
        cmp     #FileType::DIR
        bne     LE363
        lda     #$4B
        bra     LE353
LE363:  sta     EditorCreateFileType
        ldy     ProDOS::SysPathBuf
LE369:  lda     ProDOS::SysPathBuf,y
        sta     PathnameBuffer,y
        dey
        bpl     LE369
        jsr     LE624
        bne     LE353
        lda     #$FF
        ldx     #$DB
        jsr     LE6E4
        jsr     ClearStatusLine
        stz     EditorReadWriteRequestCount+1
        lda     #$01
        sta     EditorReadWriteRequestCount
        lda     #<ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        jsr     LF738
        jsr     LF786
LE399:  lda     #$00
        jsr     LFA2C
LE39E:  lda     #ProDOS::CREAD
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        beq     LE3AC
        jmp     LE43D

LE3AC:  lda     ProDOS::SysPathBuf
        and     #%01111111
        cmp     #ControlChar::Return
        beq     LE427
        cmp     #' '
        bcc     LE39E
        tax
        jsr     LF9EA
        inc     a
        cmp     CurrentLineLength
        beq     LE3CD
        jsr     LFA2C
        tay
        txa
        jsr     LFA33
        bra     LE39E
LE3CD:  jsr     LF634
        beq     LE441
        phx
        jsr     LF7F1
        plx
        ldy     CurrentLineLength
        cpx     #$20
        bne     LE3DF
        dey
LE3DF:  dey
        beq     LE3E9
        jsr     LF9F1
        cmp     #$20
        bne     LE3DF
LE3E9:  cpy     #$00
        beq     LE3F2
        cpy     LastEditableColumn
        bne     LE3F6
LE3F2:  ldx     #$01
        bra     LE411
LE3F6:  tya
        jsr     LFA2C
        ldx     #$01
LE3FC:  iny
        cpy     CurrentLineLength
        beq     LE411
        jsr     LF9F1
        phy
        phx
        ply
        jsr     LFA57
        phy
        plx
        ply
        inx
        bra     LE3FC
LE411:  txa
        tay
        jsr     LFA50
        lda     ProDOS::SysPathBuf
        and     #%01111111
        jsr     LFA57
        jsr     LF6A9
        jsr     LF77D
        jmp     LE39E

LE427:  jsr     LF9EA
        ora     #%10000000
        jsr     LFA2C
        jsr     LF634
        beq     LE441
        jsr     LF6A9
        jsr     LF77D
        jmp     LE399

LE43D:  cmp     #$4C            ; 76
        bne     LE471
LE441:  sta     LFBAF
        jsr     LE643
        jsr     LF5B7
        jsr     LF786
        jsr     LF9EA
        cmp     #$00
        bne     LE463
        lda     LBEA6
        bne     LE460
        lda     LBEA5
        cmp     #$01
        beq     LE463
LE460:  jsr     LF793
LE463:  jsr     LF738
        lda     EditorCreateFileType
        cmp     #$04
        beq     LE470
        stz     PathnameBuffer
LE470:  rts

LE471:  jsr     LF738
        lda     #$00
        jsr     LFA2C
        jsr     LF786
        jsr     LF5B7
        bra     LE483
        lda     #$4B
LE483:  pha
        jsr     LE643
        pla
        jmp     LE615

LE48B:  ldy     PrefixBuffer
LE48E:  lda     PrefixBuffer,y
        ora     #%10000000
        sta     ProDOS::SysPathBuf-1,y
        dey
        bne     LE48E
        ldy     PrefixBuffer
        dey
        sty     ProDOS::SysPathBuf
        lda     #<TDAAA
        ldx     #>TDAAA
        jsr     DisplayStringInStatusLine
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TD7B8
        ldx     #>TD7B8
        jsr     DisplayMSB1String
        ldy     #$0F
        ldx     #$0B
        lda     #$3F
        jsr     LE64D
        bcs     LE4F7
        ldy     ProDOS::SysPathBuf
LE4C3:  iny
        sty     ProDOS::SysPathBuf-1
        lda     #$AF
        sta     ProDOS::SysPathBuf
        lda     #ProDOS::CSETPREFIX
        ldy     #>EditorSetPrefixParams
        ldx     #<EditorSetPrefixParams
        jsr     MakeMLICall
        beq     LE4DA
        jmp     LE615

LE4DA:  ldy     ProDOS::SysPathBuf-1
LE4DD:  lda     ProDOS::SysPathBuf-1,y
        sta     PrefixBuffer,y
        dey
        bpl     LE4DD
        lda     #$AF
        ldx     PrefixBuffer
        cmp     PrefixBuffer,x
        beq     LE4F7
        inx
        sta     PrefixBuffer,x
        stx     PrefixBuffer
LE4F7:  rts

;;; Do Save File Dialog
LE4F8:  lda     #<TD7A6
        ldx     #>TD7A6
        jsr     LE723
        ldy     #17
        ldx     #23
        jsr     SetCursorPosToXY
        lda     #<TD883
        ldx     #>TD883
        jsr     DisplayMSB1String
        ldy     PathnameBuffer
        sty     ProDOS::SysPathBuf
        bne     LE51C
        lda     #FileType::TXT
        sta     EditorCreateFileType
        bra     LE525
LE51C:  lda     PathnameBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bne     LE51C
LE525:  ldy     #$0C
        ldx     #$0B
        lda     #$40
        jsr     LE64D
        bcc     LE544
        and     #%11011111
        cmp     #$0D
        beq     LE541
        cmp     #$4E            ; 'N' ?
        bne     LE53F
        jsr     LE48B
        bra     LE4F8
LE53F:  sec
        rts

LE541:  ldy     #$FF
        .byte   OpCode::BIT_Abs
LE544:  ldy     #$00
        sty     LFBDD
        lda     #$E6
        ldx     #$DB
        jsr     LE6E4
        jsr     ClearStatusLine
        jsr     LE61A
        beq     LE55F
        cmp     #$46
        beq     LE590
        jmp     LE615

LE55F:  lda     EditorGetFileInfoFileType
        sta     EditorCreateFileType
        lda     LFBAD
        beq     LE56F
        stz     LFBAD
        bra     LE588
LE56F:  ldy     #$17
        ldx     #$00
        jsr     SetCursorPosToXY
        lda     #<TDA65
        ldx     #>TDA65
        jsr     DisplayMSB1String
        jsr     PlayTone
        jsr     GetConfirmationKeypress
        bcs     LE53F
        jsr     ClearStatusLine
LE588:  jsr     LE639
        beq     LE590
        jmp     LE615

LE590:  ldy     ProDOS::SysPathBuf
LE593:  lda     ProDOS::SysPathBuf,y
        sta     PathnameBuffer,y
        dey
        bpl     LE593
        lda     #ProDOS::CCREATE
        ldy     #>EditorCreateParams
        ldx     #<EditorCreateParams
        jsr     MakeMLICall
        bne     LE615
        jsr     LE624
        bne     LE60D
        jsr     LF5C0
        jsr     LF738
        stz     EditorReadWriteRequestCount+1
LE5B5:  jsr     LFA74
        lda     #<ProDOS::SysPathBuf+1
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        lda     ProDOS::SysPathBuf
        and     #%01111111
LE5C7:  sta     EditorReadWriteRequestCount
        beq     LE5D7
        lda     #ProDOS::CWRITE
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        bne     LE60D
LE5D7:  lda     #$BD
        cmp     EditorReadWriteBufferAddr+1
        beq     LE5F6
        lda     LFBDD
        bne     LE5E8
        lda     ProDOS::SysPathBuf
        bpl     LE5F6
LE5E8:  lda     #<LBD98            ; this is odd...
        sta     EditorReadWriteBufferAddr
        lda     #>LBD98
        sta     EditorReadWriteBufferAddr+1
        lda     #$01
        bra     LE5C7
LE5F6:  jsr     LF61C
        beq     LE600
        jsr     LF6A9
        bra     LE5B5
LE600:  jsr     LE643
        jsr     LF5D7
        lda     #$01
        sta     LFBAF
        clc
        rts

LE60D:  pha
        jsr     LE643
        jsr     LE639
        pla
LE615:  jsr     LE7A9
        sec
        rts

LE61A:  lda     #ProDOS::CGETFILEINFO
        ldx     #<EditorGetFileInfoParams
        ldy     #>EditorGetFileInfoParams
        jsr     MakeMLICall
        rts

LE624:  lda     #ProDOS::COPEN
        ldx     #<EditorOpenParams
        ldy     #>EditorOpenParams
        jsr     MakeMLICall
        pha
        lda     EditorOpenRefNum
        sta     EditorReadWriteRefNum
        sta     EditorSetMarkRefNum
        pla
        rts

LE639:  lda     #PrODOS::CDESTROY
        ldx     #<EditorDestroyParams
        ldy     #>EditorDestroyParams
        jsr     MakeMLICall
        rts

LE643:  lda     #ProDOS::CCLOSE
        ldx     #<EditorCloseParams
        ldy     #>EditorCloseParams
        jsr     MakeMLICall
        rts

LE64D:  stx     ScreenXCoord
        sty     ScreenYCoord
        sta     DialogWidth
LE653:  ldx     ScreenXCoord
        ldy     ScreenYCoord
        jsr     SetCursorPosToXY
        lda     #$80
        ldx     #$02
        jsr     DisplayString
        lda     DialogWidth
        sec
        sbc     ProDOS::SysPathBuf
        beq     LE675
        tay
        lda     Columns80::OURCH
        pha
        jsr     OutputSpaces
        pla
        sta     Columns80::OURCH
LE675:  lda     PathnameLength
        bne     LE6CC
LE67A:  jsr     GetKeypress
        ldx     #$07
LE67F:  cmp     LE6DC,x
        beq     LE6DA
        dex
        bpl     LE67F
        cmp     #HICHAR(ControlChar::Return)
        beq     LE6D1
        cmp     #HICHAR(ControlChar::Delete)
        beq     LE6BA
        cmp     #HICHAR(ControlChar::LeftArrow)
        beq     LE6BA
        cmp     #HICHAR(ControlChar::ControlX)
        beq     LE6C6
        cmp     #HICHAR(' ')
        bcs     LE6A9
LE69B:  jsr     PlayTone
        bra     LE67A
        cmp     #$AF
        beq     LE6A9
        ldy     ProDOS::SysPathBuf
        beq     LE69B
LE6A9:  ldy     ProDOS::SysPathBuf
        cpy     DialogWidth
        beq     LE69B
        iny
        sta     ProDOS::SysPathBuf,y
        sty     ProDOS::SysPathBuf
        jmp     LE653

LE6BA:  lda     ProDOS::SysPathBuf
        beq     LE69B
        dec     a
        sta     ProDOS::SysPathBuf
        jmp     LE653

LE6C6:  stz     ProDOS::SysPathBuf
        jmp     LE653

LE6CC:  stz     PathnameLength
        lda     #$8D
LE6D1:  tay
        lda     ProDOS::SysPathBuf
        beq     LE69B
        tya
        clc
        rts

LE6DA:  sec
        rts

LE6DC:  .byte   'N'
        .byte   'n'
        .byte   'L'
        .byte   'l'
        .byte   'S'
        .byte   's'
        .byte   $0D
        .byte   $9B

;;; probably outputs a pathname in a box
;;; (surrounded by spaces)
LE6E4:  pha
        phx
        ldy     #17
        ldx     #16
        jsr     SetCursorPosToXY
        ldy     #50
        jsr     OutputSpaces
        ldy     #18
        ldx     #16
        jsr     SetCursorPosToXY
        ldy     #50
        jsr     OutputSpaces
        ldy     #19
        ldx     #16
        jsr     SetCursorPosToXY
        ldy     #50
        jsr     OutputSpaces
        ldy     #20
        ldx     #16
        jsr     SetCursorPosToXY
        ldy     #50
        jsr     OutputSpaces
        ldy     #18
        ldx     #28
        jsr     SetCursorPosToXY
        plx
        pla
        jsr     DisplayMSB1String
        rts

LE723:  pha
        phx
        lda     #$4C
        sta     DialogWidth
        lda     #$0C
        sta     DialogHeight
        ldx     #$01
        ldy     #$09
        jsr     DrawDialogBoxFrameAtXY_1
        lda     #$42
        sta     DialogWidth
        lda     #$03
        sta     DialogHeight
        ldx     #$09
        ldy     #$0B
        jsr     DrawDialogBoxFrameAtXY
        ldy     #$0B
        ldx     #$0A
        jsr     SetCursorPosToXY
        ldy     #$42
        jsr     OutputOverscoreLine
        ldy     #$09
        ldx     #$23
        jsr     SetCursorPosToXY
        jsr     LEFF3
        plx
        pla
        jsr     DisplayMSB1String
        jsr     LEFF6
        ldy     #12
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TD7B2
        ldx     #>TD7B2
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TD7B8
        ldx     #>TD7B8
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #10
        jsr     SetCursorPosToXY
        lda     #<PrefixBuffer
        ldx     #>PrefixBuffer
        jsr     DisplayString
        ldy     #18
        ldx     #18
        jsr     DrawAbortButton
        ldy     #18
        ldx     #48
        jsr     DrawAcceptButton
        jsr     DisplayHitEscToEditDocInStatusLine
        ldy     #61
        sty     Columns80::OURCH
        lda     #<TD7C1
        ldx     #>TD7C1
        jsr     DisplayMSB1String
        rts

LE7A9:  sta     MLIError
        jsr     ClearStatusLine
        ldy     #23
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     MLIErrorTable
        lda     MLIError
LE7BC:  cmp     MLIErrorTable,y
        beq     LE7C9
        dey
        bne     LE7BC
        jsr     LFDDA
        ldy     #$00
LE7C9:  tya
        asl     a
        tay
        lda     MLIErrorMessageTable+1,y
        tax
        lda     MLIErrorMessageTable,y
        jsr     DisplayMSB1String
        lda     #<TDE09
        ldx     #>TDE09
        jsr     DisplayMSB1String
        jsr     PlayTone
        sta     KBDSTRB
        jsr     GetKeypress
        rts

LE7E7:  lda     #HICHAR(ControlChar::Return)
        sta     LBEC8+4
        lda     #$FF
        sta     LFBAF
        jsr     DrawDialogBox
        .byte   12
        .byte   44
        .byte   9
        .byte   17
        .byte   34
        .addr   TD83D
        ldy     #$0A
        ldx     #$13
        jsr     SetCursorPosToXY
        lda     #<TDC29
        ldx     #>TDC29
        jsr     DisplayMSB1String
        ldy     #$0B
        ldx     #$12
        jsr     SetCursorPosToXY
        ldy     #$2C
        jsr     OutputHorizontalLineX
        lda     #<TD84B
        ldx     #>TD84B
        jsr     DisplayStringInStatusLine
        ldy     PrefixBuffer
LE81F:  lda     PrefixBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LE81F
        jsr     LE99F
        bcs     LE88B
        jsr     LF738
        lda     LBE9F
        sta     LE99D
        sta     LBEA5
        lda     LBEA0
        sta     LE99E
        sta     LBEA6
LE842:  lda     LE99E
        ora     LE99D
        beq     LE890
        jsr     LE9E8
        bcs     LE886
        jsr     LEA03
        lda     MemoryMap::INBUF
        tay
        jsr     LFA2C
LE859:  lda     MemoryMap::INBUF,y
        jsr     LFA33
        dey
        bne     LE859
        dec     LE99D
        lda     LE99D
        cmp     #$FF
        bne     LE86F
        dec     LE99E
LE86F:  jsr     LF6A9
        bra     LE842
LE874:  jsr     LF738
        jsr     LF786
        lda     #$80
        jsr     LFA2C
        jsr     LF5C0
        jsr     LF5B7
        rts

LE886:  pha
        jsr     LE643
        pla
LE88B:  jsr     LE7A9
        bra     LE874
LE890:  jsr     LE643
        lda     LBEA5
        ora     LBEA6
        bne     LE8AA
        lda     #<TD86C
        ldx     #>TD86C
        jsr     DisplayStringInStatusLine
        jsr     PlayTone
        jsr     GetKeypress
LE8A8:  bra     LE874
LE8AA:  lda     #$0C
        sta     LE99C
        jsr     LF738
LE8B2:  jsr     LF5C0
        ldy     #$0C
LE8B7:  ldx     #$13
        jsr     SetCursorPosToXY
        lda     ZeroPage::CV
        cmp     LE99C
        bne     LE8C6
        jsr     LEFF3
LE8C6:  ldx     Pointer3+1
        lda     Pointer3
        lsr     a
        php
        rol     a
        plp
        bcc     LE8D3
        sta     SoftSwitch::RDCARDRAM
LE8D3:  jsr     DisplayString
        sta     SoftSwitch::RDMAINRAM
        jsr     LEFF6
        jsr     LF61C
        beq     LE8EE
        jsr     LF6A9
        ldy     ZeroPage::CV
        iny
        cpy     #$15
        bcc     LE8B7
        jsr     LF666
LE8EE:  ldy     #23
        ldx     #32
        jsr     SetCursorPosToXY
LE8F5:  jsr     GetKeypress
        cmp     #HICHAR(ControlChar::UpArrow)
        beq     LE93B
        cmp     #HICHAR(ControlChar::Return)
        beq     LE966
        cmp     #HICHAR(ControlChar::Esc)
        beq     LE8A8
        cmp     #HICHAR(ControlChar::DownArrow)
        bne     LE8F5
        lda     LBEA6
        bne     LE91C
        lda     LBEA5
        cmp     #$09
        bcs     LE91C
        clc
        adc     #$0A
        cmp     LE99C
        bcc     LE8F5
LE91C:  lda     LE99C
        cmp     #$14
        bcc     LE931
        jsr     LF61C
        beq     LE8F5
        jsr     LF5D7
        jsr     LF6A9
        jmp     LE8B2

LE931:  inc     a
        sta     LE99C
        jsr     LF5D7
        jmp     LE8B2

LE93B:  jsr     LF5EE
        jsr     LF5D7
        jsr     LF65B
        bne     LE952
        lda     LE99C
        cmp     #$0C
        bne     LE95F
        jsr     LF605
        bra     LE8F5
LE952:  lda     LE99C
        cmp     #$0D
        bcs     LE95F
        jsr     LF666
        jmp     LE8B2

LE95F:  dec     a
        sta     LE99C
        jmp     LE8B2

LE966:  jsr     LF5D7
        lda     LE99C
        sec
        sbc     #$0C
        clc
        adc     LBEA9
        sta     LBEA9
        bcc     LE97B
        inc     LBEA9+1
LE97B:  jsr     LF67F
        sta     Pointer3
        stx     Pointer3+1
        ldy     #$00
        ldx     #$00
LE986:  inx
        iny
        jsr     LF9F1
        sta     ProDOS::SysPathBuf,x
        cmp     #HICHAR(' ')
        bne     LE986
        dex
        stx     ProDOS::SysPathBuf
        stx     PathnameLength
        jmp     LE874

LE99C:  .byte   $00
LE99D:  .byte   $00
LE99E:  .byte   $00

LE99F:  jsr     LE624
        bne     LE9D3
        lda     #<ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        lda     #$2B
        sta     EditorReadWriteRequestCount
        stz     EditorReadWriteRequestCount+1
        jsr     LE9DE
        bne     LE9CE
        lda     #$0D
        sta     LBE9A
        lda     $02A5
        sta     LBE9F
        lda     $02A6
        sta     LBEA0
        clc
        rts

LE9CE:  pha
        jsr     LE643
        pla
LE9D3:  sec
        rts

LE9D5:  lda     #$05
        bra     LE9DB
LE9D9:  lda     #$27
LE9DB:  sta     EditorReadWriteRequestCount
LE9DE:  lda     #ProDOS::CREAD
        ldy     #>EditorReadWriteParams
        ldx     #<EditorReadWriteParams
        jsr     MakeMLICall
        rts

LE9E8:  dec     LBE9A
        bne     LE9F7
        lda     #$0D
        sta     LBE9A
        jsr     LE9D5
        bne     LE9CE
LE9F7:  jsr     LE9D9
        bne     LE9CE
        lda     ProDOS::SysPathBuf
        beq     LE9E8
        clc
        rts

LEA03:  lda     ProDOS::SysPathBuf
        and     #%00001111
        sta     MemoryMap::INBUF
        tay
LEA0C:  lda     ProDOS::SysPathBuf,y
        ora     #%10000000
        sta     MemoryMap::INBUF,y
        dey
        bne     LEA0C
        lda     #$10
        tax
        sec
        sbc     MemoryMap::INBUF
        tay
        lda     #$A0
LEA21:  sta     MemoryMap::INBUF+1,x
        dex
        dey
        bpl     LEA21
        ldy     #$00
LEA2A:  lda     FileTypeTable,y
        beq     LEA3A
        cmp     $0290
        beq     LEA65
        iny
        iny
        iny
        iny
        bra     LEA2A
LEA3A:  lda     #$A4
        sta     $0212
        lda     $0290
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #%10110000
        cmp     #$BA
        bcc     LEA4F
        clc
        adc     #$07
LEA4F:  sta     $0213
        lda     $0290
        and     #%00001111
        ora     #%10110000
        cmp     #$BA
        bcc     LEA60
        clc
        adc     #$07
LEA60:  sta     $0214
        bra     LEA73
LEA65:  ldx     #$00
LEA67:  iny
        lda     FileTypeTable,y
        sta     $0212,x
        inx
        cpx     #$03
        bcc     LEA67
LEA73:  lda     #$A0
        sta     $0215
        sta     $0216
        lda     $0293
        ldx     $0294
        ldy     #$05
        jsr     LF567
        ldy     #$05
LEA88:  lda     LFC23,y
        sta     $0215,y
        dey
        bne     LEA88
        lda     $02A1
        ldx     $02A2
        jsr     FormatDateInAX
        lda     $02A3
        ldx     $02A4
        jsr     FormatTimeInAX
        ldy     #$10
LEAA5:  lda     DateTimeFormatString,y
        sta     $021A,y
        dey
        bne     LEAA5
        lda     #$2A
        sta     MemoryMap::INBUF
        rts

LEAB4:  jsr     PlayTone
LEAB7:  ldx     #$01
        jsr     GetSpecificKeypress
        bcs     LEAC3
        cpx     #$00
        beq     LEAB4
        clc
LEAC3:  rts

;;;  Wait for a special key (from SpecialKeyTable, any key in first X entries), or Esc.
;;;  Return with carry clear if that key was pressed, carry set
;;;  if Esc was pressed.

GetSpecificKeypress:
        phx
        jsr     GetKeypress
        plx
        cmp     #HICHAR(ControlChar::Esc)
        beq     LEAD6
LEACD:  cmp     SpecialKeyTable-1,x
        beq     LEAD5
        dex
        bne     LEACD
LEAD5:  clc
LEAD6:  rts

SpecialKeyTable:
        .byte   HICHAR(ControlChar::Return)
        .byte   HICHAR(ControlChar::LeftArrow)
        .byte   HICHAR(' ')
        .byte   HICHAR(ControlChar::RightArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControLChar::DownArrow)

LEADD:  jsr     PlayTone
GetConfirmationKeypress:
        ldx     #$01
        jsr     GetSpecificKeypress
        bcs     LEAF2
        and     #%11011111      ; conver t to uppercase
        cmp     #HICHAR('N')
        beq     LEAF2
        cmp     #HICHAR('Y')
        bne     LEADD
        clc
LEAF2:  rts

OutputCharAndAdvanceScreenPos:
        pha                     ; save registers
        phy
        phx
        cmp     #$20            ; MouseText?
        bge     LEB14           ; branch if no
        clc
        adc     #$40            ; remap MouseText
LEAFD:  jsr     WriteCharToScreen
        lda     Columns80::OURCH
        inc     a
        cmp     #80             ; last column?
        bcc     LEB0D
LEB08:  jsr     MoveTextOutputPosToStartOfNextLine
        lda     #$00
LEB0D:  sta     Columns80::OURCH
LEB10:  plx                     ; restore registers
        ply
        pla
        rts

LEB14:  cmp     #$A0
        bcs     LEB1C
        cmp     #$80
        bcs     LEB2E
LEB1C:  and     LFBAA
        bmi     LEAFD
        cmp     #$40
        bcc     LEAFD
        cmp     #$60
        bcs     LEAFD
        sec
        sbc     #$40
        bra     LEAFD
LEB2E:  cmp     #$8D
        beq     LEB08
        cmp     #$8F
        beq     LEB3C
        cmp     #$8E
        beq     LEB3F
        bra     LEB10
LEB3C:  lda     #%01111111
        .byte   OpCode::BIT_Abs
LEB3F:  lda     #%11111111
        sta     $FBAA
LEB44:  bra     LEB10
LEB46:  lda     ZeroPage::CV
LEB48:  bra     ComputeTextOutputPos
MoveTextOutputPosToStartOfNextLine:
LEB4A:  stz     Columns80::OURCH
        lda     ZeroPage::CV
        inc     a

;;;  for row in A
ComputeTextOutputPos:
        sta     ZeroPage::CV
        phy
        tay
        lda     TextRowBaseAddrLo,y
        sta     ZeroPage::BASL
        lda     TextRowBaseAddrHi,y
        sta     ZeroPage::BASH
        ply
        rts

;;; Table of text row base addresses
TextRowBaseAddrLo:
        .byte   $00,$80,$00,$80,$00,$80,$00,$80
        .byte   $28,$A8,$28,$A8,$28,$A8,$28,$A8
        .byte   $50,$D0,$50,$D0,$50,$D0,$50,$D0
TextRowBaseAddrHi:
        .byte   $04,$04,$05,$05,$06,$06,$07,$07
        .byte   $04,$04,$05,$05,$06,$06,$07,$07
        .byte   $04,$04,$05,$05,$06,$06,$07,$07

ClearTextWindow:
        lda     ZeroPage::WNDTOP
        jsr     ComputeTextOutputPos
        stz     Columns80::OURCH
LEB98:  lda     Columns80::OURCH
        sta     LEBC0
        lda     ZeroPage::CV
        sta     LEBBF
LEBA3:  jsr     ComputeTextOutputPos
        jsr     ClearToEndOfLine
        stz     Columns80::OURCH
        lda     ZeroPage::CV
        inc     a
        cmp     ZeroPage::WNDBTM
        bcc     LEBA3
        lda     LEBC0
        sta     Columns80::OURCH
        lda     LEBBF
        jmp     ComputeTextOutputPos

LEBBF:  .byte   $00             ; saved CV
LEBC0:  .byte   $00             ; saved OURCH

;;; clears to end of line, without moving cursor pos
ClearToEndOfLine:
        lda     #79
        sec
        sbc     Columns80::OURCH
        beq     @Out
        tay
        lda     Columns80::OURCH
        pha
        jsr     OutputSpaces
        ldy     #39
        sta     (ZeroPage::BAS),y
        pla
        sta     Columns80::OURCH
@Out:   rts

LEBDA:  lda     ZeroPage::CV
        pha
        lda     Columns80::OURCH
        pha
        stz     Columns80::OURCH
        lda     ZeroPage::WNDTOP
        jsr     ComputeTextOutputPos
LEBE9:  lda     ZeroPage::BASL
        sta     ZeroPage::A1L
        lda     ZeroPage::BASH
        sta     ZeroPage::A1H
        lda     ZeroPage::CV
        inc     a
        cmp     ZeroPage::WNDBTM
        bcs     LEC10
        jsr     ComputeTextOutputPos
        ldy     #39
LEBFD:  lda     (ZeroPage::BAS),y
        sta     (ZeroPage::A1),y
        sta     SoftSwitch::TXTPAGE2
        lda     (ZeroPage::BAS),y
        sta     (ZeroPage::A1),y
        sta     SoftSwitch::TXTPAGE1
        dey
        bpl     LEBFD
        bra     LEBE9
LEC10:  jsr     ClearToEndOfLine
        plx
        ply

;;; X = row, Y = column
SetCursorPosToXY:
        stx     Columns80::OURCH
        tya
        jmp     ComputeTextOutputPos

LEC1C:  lda     ZeroPage::CV
        pha
        lda     Columns80::OURCH
        pha
        stz     Columns80::OURCH
        lda     ZeroPage::WNDBTM
        dec     a
        jsr     ComputeTextOutputPos
LEC2C:  lda     ZeroPage::BASL
        sta     ZeroPage::A1L
        lda     ZeroPage::BASH
        sta     ZeroPage::A1H
        lda     ZeroPage::CV
        dec     a
        cmp     ZeroPage::WNDTOP
        bcc     LEC10
        jsr     ComputeTextOutputPos
        ldy     #39
LEC40:  lda     (ZeroPage::BAS),y
        sta     (ZeroPage::A1),y
        sta     SoftSwitch::TXTPAGE2
        lda     (ZeroPage::BAS),y
        sta     (ZeroPage::A1),y
        sta     SoftSwitch::TXTPAGE1
        dey
        bpl     LEC40
        bra     LEC2C
        bra     LEC10

OutputDiamond:
        lda     #$1B            ; MouseText diamond
        .byte   OpCode::BIT_Abs
OutputReturnSymbol:
        lda     #$0D            ; MouseText carriage return
        .byte   OpCode::BIT_Abs
OutputLeftVerticalBar:
        lda     #$1F            ; MouseText left v-bar
        .byte   OpCode::BIT_Abs
OutputRightVerticalBar:
        lda     #$1A            ; MouseText right v-bar
        jmp     OutputCharAndAdvanceScreenPos

;;; These routines output a given character Y times (in a row).
OutputHorizontalLine:
        lda     #$13
        .byte   OpCode::BIT_Abs
OutputHorizontalLineX:
        lda     #$13            ; MouseText horiz ctr line
        .byte   OpCode::BIT_Abs
OutputDashedLine:
        lda     #HICHAR('-')    ; dash
        .byte   OpCode::BIT_Abs
OutputOverscoreLine:
        lda     #$0C            ; MouseText overscore
        .byte   OpCode::BIT_Abs
OutputUnderscoreLine:
        lda     #HICHAR('_')    ; underscore
        .byte   OpCode::BIT_Abs
OutputSpaces:
        lda     #HICHAR(' ')    ; space
OutputRowOfChars:
        jsr     OutputCharAndAdvanceScreenPos
        dey
        bne     OutputRowOfChars
        rts

GetKeypress:
        lda     LFBB1           ; some kind of type-ahead logic or input redirect?
        beq     LEC90
        lda     (Pointer2)
        pha
        inc     Pointer2
        bne     LEC89
        inc     Pointer2+1
LEC89:  dec     LFBB1
        ldx     #$00
        pla
        rts

LEC90:  jsr     LEB46
        jsr     ReadCharFromScreen
        sta     CharUnderCursor
        lda     CurrentCursorChar
        sta     LFBA5
        lda     MouseSlot
        beq     LECCF
        sei
        jsr     LoadXYForMouseCall
        jsr     CallInitMouse
        cli
        jsr     LoadXYForMouseCall
        lda     #$01
        sei
        jsr     CallSetMouse
        cli
        ldx     MouseSlot
        lda     #$80
        sta     Mouse::MOUXL,x
        sta     Mouse::MOUYL,x
        lda     #$00
        sta     Mouse::MOUXH,x
        sta     Mouse::MOUYH,x
        jsr     LoadXYForMouseCall
        sei
        jsr     CallPosMouse
        cli
LECCF:  jsr     LEE10
        jsr     ReadCharFromScreen
        pha
        lda     LFBA5
        jsr     WriteCharToScreen
        pla
        sta     LFBA5
        lda     CursorBlinkRate
        sta     CursorBlinkCounter
LECE6:  lda     #$28
        sta     CursorBlinkCounter+1
LECEB:  ldy     #$00
LECED:  lda     SoftSwitch::STORE80OFF
        bmi     LED5F
        dey
        bne     LECED
        lda     MouseSlot
        beq     LED44
        jsr     LoadXYForMouseCall
        sei
        jsr     CallReadMouse
        ldx     MouseSlot
        ldy     #$04
        lda     Mouse::MOUSTAT,x
        bpl     LED23
LED09:  cli
        jsr     LoadXYForMouseCall
        sei
        jsr     CallReadMouse
        ldx     MouseSlot
        ldy     #$04
        lda     Mouse::MOUSTAT,x
        bmi     LED09
        lda     #$80
        jsr     CallWaitMonitorRoutine
        ldy     #$04
        bra     LED5B
LED23:  dey
        lda     Mouse::MOUXL,x
        cmp     LFB8D
        blt     LED5B
        dey
        cmp     LFB8C
        bge     LED5B
        dey
        lda     Mouse::MOUYL,x
        cmp     LFB8D
        blt     LED5B
        dey
        cmp     LFB8C
        bge     LED5B
        cli
        bra     LED4E
LED44:  ldy     #$4B
LED46:  lda     SoftSwitch::KBD
        bmi     LED5F
        dey
        bne     LED46
LED4E:  dec     CursorBlinkCounter+1
        bne     LECEB
        dec     CursorBlinkCounter
        bne     LECE6
        jmp     LECCF

LED5B:  cli
        lda     LBEC8,y
LED5F:  bit     SoftSwitch::RDBTN0
        bmi     LED71
        bit     SoftSwitch::RDBTN1
        bpl     LED73
        cmp     #HICHAR('1')
        blt     LED71
        cmp     #HICHAR(':')
        bge     LED9C
LED71:  and     #%01111111      ; clear MSB
LED73:  pha
        lda     CharUnderCursor
        jsr     WriteCharToScreen
LoadKeyModReg: ; ($ED7A-$ED7C)
        ldx     SoftSwitch::KEYMODREG
        txa
        and     #%00010000      ; check if numeric keypad key pressed?
        beq     LED8E
        ldy     #$08
        pla
LED85:  cmp     LED93,y
        beq     LEDA0
        dey
        bpl     LED85
        pha
LED8E:  stz     SoftSwitch::KBDSTRB
        pla
        rts

LED93:  highascii "zxcv`abde"   ; more function key mappings? F1-F4 (undo/cut/copy/paste), ...?

LED9C:  and     #%00001111
        dec     a
        tay
LEDA0:  jsr     LEDC8
        lda     (Pointer2)
        sta     LFBB1
        beq     LEDBC
        inc     Pointer2
        bne     LEDB0
        inc     Pointer2+1
LEDB0:  lda     CharUnderCursor
        jsr     WriteCharToScreen
        stz     SoftSwitch::KBDSTRB
        jmp     GetKeypress

LEDBC:  stz     SoftSwitch::KBDSTRB
        lda     CharUnderCursor
        jsr     WriteCharToScreen
        jmp     GetKeypress

LEDC8:  lda     #$F2
        sta     Pointer2
        lda     #$FC
        sta     Pointer2+1
        cpy     #$00
        beq     LEDE2
LEDD4:  lda     Pointer2
        clc
        adc     #$47
        sta     Pointer2
        bcc     LEDDF
        inc     Pointer2+1
LEDDF:  dey
        bne     LEDD4
LEDE2:  rts

;;; Loads $Cs and $s0 values for the mouse slot into X and Y, respectively.
LoadXYForMouseCall:
        lda     MouseSlot
        ora     #%11000000
        tax
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        rts

WriteCharToScreen:
        pha
        lda     Columns80::OURCH
        lsr     a
        bcs     LEDF8
        ldy     SoftSwitch::TXTPAGE2
LEDF8:  tay
        pla
        sta     (ZeroPage::BAS),y
        sta     SoftSwitch::TXTPAGE1
        rts

ReadCharFromScreen:
        lda     Columns80::OURCH
        lsr     a
        bcs     LEE09
        ldy     SoftSwitch::TXTPAGE2
LEE09:  tay
        lda     (ZeroPage::BAS),y
        sta     SoftSwitch::TXTPAGE1
        rts

LEE10:  lda     #ProDOS::CGETTIME
        ldx     #$00
        ldy     #$00
        jsr     MakeMLICall
        jsr     FormatCurrentDate
        jsr     FormatCurrentTime
        lda     ProDOS::MACHID
        lsr     a
        bcc     LEE45
        lda     ZeroPage::CV
        pha
        lda     Columns80::OURCH
        pha
        ldx     #60
        ldy     #1
        jsr     SetCursorPosToXY
        jsr     LEFF3
        lda     <DateTimeFormatString
        ldx     >DateTimeFormatString
        jsr     DisplayMSB1String
        jsr     LEFF6
        plx
        ply
        jsr     SetCursorPosToXY
LEE45:  rts

FormatDateInAX:
        sta     DateLoByte
        stx     DateHiByte
        bra     FormatDate
FormatCurrentDate:
        lda     ProDOS::DATELO
        sta     DateLoByte
        lda     ProDOS::DATEHI
        sta     DateHiByte
FormatDate:
        lda     DateLoByte
        and     #%00011111
        ldx     #HICHAR('0')-1
        jsr     ConvertToBase10
        cpx     #HICHAR('0')
        bne     LEE6A
        ldx     #HICHAR(' ')
LEE6A:  stx     DateTimeFormatString+2
        sta     DateTimeFormatString+3
        lda     DateLoByte
        and     #%11100000
        lsr     DateHiByte
        ror     a
        lsr     a
        lsr     a
        tay
        ldx     #$00
LEE7E:  lda     MonthNames-3,y
        sta     DateTimeFormatString+5,x
        iny
        inx
        cpx     #$04
        bcc     LEE7E
        lda     DateHiByte
        ldx     #HICHAR('0')-1
        jsr     ConvertToBase10
        stx     DateTimeFormatString+9
        sta     DateTimeFormatString+10
        rts

DateLoByte:
        .byte   $00
DateHiByte:
        .byte   $00

FormatTimeInAX:
        sta     TimeLoByte
        stx     TimeHiByte
        bra     FormatTime
FormatCurrentTime:
        lda     ProDOS::TIMELO
        sta     TimeLoByte
        lda     ProDOS::TIMEHI
        sta     TimeHiByte
FormatTime:
        lda     TimeHiByte
        ldx     #HICHAR('0')-1
        jsr     ConvertToBase10
        stx     DateTimeFormatString+12 ; hour hi digit
        sta     DateTimeFormatString+13 ; hour lo digit
        lda     TimeLoByte
        ldx     #HICHAR('0')-1
        jsr     ConvertToBase10
        stx     DateTimeFormatString+15 ; minute hi digit
        sta     DateTimeFormatString+16 ; minute lo digit
        rts

TimeLoByte:
        .byte   $00             ; time lo
TimeHiByte:
        .byte   $00             ; time hi

ConvertToBase10:
        sec
        sbc     #10
        inx
        bcs     ConvertToBase10
        adc     #10
        ora     #%10110000
        rts

LEED9:  stz     Columns80::OURCH
        ldx     Pointer3+1
        lda     Pointer3
        lsr     a
        php
        rol     a
        plp
        bcc     LEEE9
        sta     SoftSwitch::RDCARDRAM
LEEE9:  jsr     DisplayString
        sta     SoftSwitch::RDMAINRAM
        jsr     ClearToEndOfLine
        bit     LBEAD
        bpl     LEF0F
        jsr     LF9EA
        bpl     LEF0F
        jsr     OutputReturnSymbol
        lda     Columns80::OURCH
        bne     LEF0F
        lda     ZeroPage::CV
        dec     a
        jsr     ComputeTextOutputPos
        lda     #$4F
        sta     Columns80::OURCH
LEF0F:  rts

LEF10:  jsr     LF5C0
        ldy     CurrentCursorYPos
LEF16:  cpy     #$03
        beq     LEF20
        jsr     LF666
        dey
        bra     LEF16
LEF20:  ldx     #$00
        jsr     SetCursorPosToXY
LEF25:  jsr     LEED9
        lda     ZeroPage::CV
        cmp     #$15
        beq     LEF3E
        jsr     LF61C
        beq     LEF3B
        jsr     MoveTextOutputPosToStartOfNextLine
        jsr     LF6A9
        bra     LEF25
LEF3B:  jsr     LEB98
LEF3E:  jsr     LF5D7
        rts

LEF42:  lda     #<TD61F
        ldx     #>TD61F
        jmp     DisplayStringInStatusLine

LEF49:  ldx     #$43
        ldy     #$17
        jsr     SetCursorPosToXY
        lda     #<TD591
        ldx     #>TD591
        jsr     DisplayMSB1String
        rts

LEF58:  ldy     #$17
        ldx     #$2C
        jsr     SetCursorPosToXY
        lda     #<TD649
        ldx     #>TD649
        jsr     DisplayMSB1String
        rts

LEF67:  ldy     #23
        ldx     #49
        jsr     SetCursorPosToXY
        ldx     LBEA9+1
        lda     LBEA9
        ldy     #$04
        jsr     LF55C
        lda     #59
        sta     Columns80::OURCH
        ldx     #$00
        lda     CurrentCursorXPos
        inc     a
        ldy     #$03
        jsr     LF55C
        rts

;;; Routine that displays the help text.
DisplayHelpText:
        lda     SoftSwitch::RWLCRAMB2
        lda     SoftSwitch::RWLCRAMB2
        lda     #$00
        sta     Pointer
        lda     #$D0
        sta     Pointer+1
LEF98:  lda     (Pointer)
        beq     LEFA7
        jsr     OutputCharAndAdvanceScreenPos
        inc     Pointer
        bne     LEF98
        inc     Pointer+1
        bra     LEF98
LEFA7:  lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        rts

;;; Routine that displays one of the strings in LCRAM bank 2
;;; pointer is in A (lo), X (hi)
;;; displays an msb-off string
DisplayString:
        sta     StringPtr
        stx     StringPtr+1
        lda     #$80
        sta     LFBAB
        ldy     #$00
        lda     (StringPtr),y
        and     #%01111111
        bra     LEFD0

;;;  displays an msb-on string
DisplayMSB1String:
        sta     StringPtr
        stx     StringPtr+1
        stz     LFBAB
        lda     SoftSwitch::RWLCRAMB2
        lda     SoftSwitch::RWLCRAMB2
        ldy     #$00
LEFCE:  lda     (StringPtr),y
LEFD0:  beq     LEFDF
        tax
LEFD3:  iny
        lda     (StringPtr),y
        ora     LFBAB
        jsr     OutputCharAndAdvanceScreenPos
        dex
        bne     LEFD3
LEFDF:  lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        rts

OutputStatusBarLine:
        ldx     #0
        ldy     #22
        jsr     SetCursorPosToXY
        ldy     #80
        jsr     OutputHorizontalLine
        rts

LEFF3:  lda     #%01111111
        .byte   OpCode::BIT_Abs
LEFF6:  lda     #%11111111
        sta     LFBAA
        rts

DrawAbortButton:
        jsr     DrawButtonFrame
        ldx     ScreenXCoord
        inx
        ldy     ScreenYCoord
        iny
        jsr     SetCursorPosToXY
        lda     #<TD6EE
        ldx     #>TD6EE         ; Abort button
        jsr     DisplayMSB1String
        jsr     LEFF6
        rts

DrawAcceptButton:
        jsr     DrawButtonFrame
        ldx     ScreenXCoord
        inx
        ldy     ScreenYCoord
        iny
        jsr     SetCursorPosToXY
        lda     #<TD6FD
        ldx     #>TD6FD         ; Accept button
        jsr     DisplayMSB1String
        jsr     LEFF6
        rts

DrawButtonFrame:
        sty     ScreenYCoord
        stx     ScreenXCoord
        inx
        jsr     SetCursorPosToXY
        ldy     #$0E
        jsr     OutputUnderscoreLine
        ldy     ScreenYCoord
        iny
        ldx     ScreenXCoord
        jsr     SetCursorPosToXY
        jsr     OutputRightVerticalBar
        lda     Columns80::OURCH
        clc
        adc     #$0E
        sta     Columns80::OURCH
        jsr     OutputLeftVerticalBar
        ldy     ScreenYCoord
        ldx     ScreenXCoord
        iny
        iny
        inx
        jsr     SetCursorPosToXY
        ldy     #$0E
        jsr     OutputOverscoreLine
        rts

;;;  This is like a MLI call; it reads 7 bytes from memory after the JSR.
        // byte    0: ($EA): height of box
        // byte    1: ($EB): width of box
        // byte    2: ($EC): y-coordinate of top-left corner of box
        // byte    3: ($ED): x-coordinate of top-left corner of box
        // byte    4: x-coordinate of title string
        // bytes 5-6: pointer to title string

DrawDialogBox:
        pla
        sta     ParamTablePtr
        pla
        sta     ParamTablePtr+1
;;;  ParamTablePtr now points to 1 byte before the start of the param table
;;;  copy first 4 bytes of param table to $EA - $ED
        ldy     #$04
LF066:  lda     (ParamTablePtr),y
        sta     DialogHeight-1,y
        dey
        bne     LF066
        jsr     DrawDialogBoxFrame
        jsr     LEFF3           ; stores 0x7F at $FBAA
        ldy     #$05
        lda     (ParamTablePtr),y
        tax
        ldy     ScreenYCoord
        jsr     SetCursorPosToXY
;;; Draw the title string
        ldy     #$07
        lda     (ParamTablePtr),y
        tax
        dey
        lda     (ParamTablePtr),y
        jsr     DisplayMSB1String
        jsr     LEFF6
;;;  Calculate return address and push it on the stack.
        lda     ParamTablePtr
        clc
        adc     #$07
        sta     ParamTablePtr
        bcc     LF097
        inc     ParamTablePtr+1
LF097:  lda     ParamTablePtr+1
        pha
        lda     ParamTablePtr
        pha
        rts

DrawDialogBoxFrameAtXY:
        sty     ScreenYCoord
        stx     ScreenXCoord
        bra     DrawDialogBoxFrame
DrawDialogBoxFrameAtXY_1:
        sty     ScreenYCoord
        stx     ScreenXCoord
DrawDialogBoxFrame:
        ldx     ScreenXCoord
        ldy     ScreenYCoord
        jsr     SetCursorPosToXY
        jsr     OutputRightVerticalBar
        ldy     DialogWidth
TitleBarChar := *+1
        lda     #$07            ; IIGS title bar MouseText char
        jsr     OutputRowOfChars
        jsr     OutputLeftVerticalBar
@DrawSides:
        jsr     MoveTextOutputPosToStartOfNextLine
        dec     DialogHeight
        beq     @DrawBottomEdge
        lda     ScreenXCoord
        sta     Columns80::OURCH
        jsr     OutputRightVerticalBar
        ldy     DialogWidth
        jsr     OutputSpaces
        jsr     OutputLeftVerticalBar
        bra     @DrawSides
@DrawBottomEdge:
        lda     ScreenXCoord
        inc     a
        sta     Columns80::OURCH
        ldy     DialogWidth
        jsr     OutputOverscoreLine
        rts

DisplayStringInStatusLineWithEscToGoBack:
        pha
        phx
        jsr     ClearStatusLine
        lda     #65
        sta     Columns80::OURCH
        lda     #<TD693
        ldx     #>TD693         ; "Esc to go back"
        jsr     DisplayMSB1String
LF0F2:  stz     Columns80::OURCH
        plx
        pla
        jmp     DisplayMSB1String

DisplayStringInStatusLine:
        pha
        phx
        jsr     ClearStatusLine
        bra     LF0F2

ClearStatusLine:
        ldy     #23
        ldx     #0
        jsr     SetCursorPosToXY
        jsr     ClearToEndOfLine
        rts

DisplayHitEscToEditDocInStatusLine:
        lda     #<TD70C
        ldx     #>TD70C
        jmp     DisplayStringInStatusLine

WaitForSpaceToContinueInStatusLine:
        lda     #<TD726
        ldx     #>TD726
        jsr     DisplayStringInStatusLine
WaitForSpaceKeypress:
        ldx     #$02
        jsr     GetSpecificKeypress
        cpx     #$00
        beq     WaitForSpaceKeypress
        rts

CharToUppercase:
        cmp     #HICHAR('a')
        blt     @Out
        cmp     #HICHAR('{')
        bge     @Out
        and     #%11011111
@Out:   rts

;;; This appears to be restoring the text screen (rows 2-9,
;;; under the menus) from $800 in aux mem
RestoreScreenAreaUnderMenus:
        lda     #$00
        sta     Pointer6
        lda     #$08
        sta     Pointer6+1
        lda     #$02
LF139:  jsr     ComputeTextOutputPos
        lda     #79
        sta     Columns80::OURCH
LF141:  ldy     Columns80::OURCH
        sta     SoftSwitch::RDCARDRAM
        lda     (Pointer6),y
        sta     SoftSwitch::RDMAINRAM
        jsr     WriteCharToScreen
        dec     Columns80::OURCH
        bpl     LF141
        lda     Pointer6
        clc
        adc     #80
        sta     Pointer6
        bcc     LF15F
        inc     Pointer6+1
LF15F:  lda     ZeroPage::CV
        cmp     #$09
        bcs     LF168
        inc     a
        bra     LF139
LF168:  rts

;;; This appears to be storing text rows 2-9 (which are obscured by
;;; menus) to $800 in aux mem
SaveScreenAreaUnderMenus:
LF169:  lda     #$00
        sta     Pointer6
        lda     #$08
        sta     Pointer6+1
        lda     #$02
LF173:  jsr     ComputeTextOutputPos
        lda     #$4F
        sta     Columns80::OURCH
LF17B:  jsr     ReadCharFromScreen
        ldy     Columns80::OURCH
        sta     SoftSwitch::WRCARDRAM
        sta     (Pointer6),y
        sta     SoftSwitch::WRMAINRAM
        dec     Columns80::OURCH
        bpl     LF17B
        lda     Pointer6
        clc
        adc     #$50
        sta     Pointer6
        bcc     LF199
        inc     Pointer6+1
LF199:  lda     ZeroPage::CV
        cmp     #$09
        bcs     LF1A2
        inc     a
        bra     LF173
LF1A2:  rts

PlayTone:
        lda     #$20
        sta     PlayToneCounter
@Loop:  lda     #$02
        jsr     CallWaitMonitorRoutine
        sta     SoftSwitch::SPKR
        lda     #$24
        jsr     CallWaitMonitorRoutine
        sta     SoftSwitch::SPKR
        dec     PlayToneCounter
        bne     @Loop
        rts
PlayToneCounter:
        .byte   $00

LF1BF:  jsr     LF5C0
        stz     CurrentCursorXPos
        lda     #<TD93A
        ldx     #>TD93A
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     LF298
        jsr     LEF58
        jsr     LF2B1
LF1D5:  jsr     LEF67
        lda     #41
LF1DA:  sta     Columns80::OURCH
LF1DD:  jsr     GetKeypress
        cmp     #ControlChar::UpArrow
        beq     LF248
        cmp     #ControlChar::DownArrow
        beq     LF205
        cmp     #HICHAR(ControlChar::DownArrow)
        beq     LF209
        cmp     #HICHAR(ControlChar::UpArrow)
        beq     LF24C
        cmp     #HICHAR(ControlChar::Esc)
        bne     LF1F7
        jmp     LF290

LF1F7:  cmp     #HICHAR(ControlChar::Return)
        bne     LF200
        jsr     LF298
        clc
        rts

LF200:  jsr     PlayTone
        bra     LF1DD
LF205:  lda     #$13
        bra     LF20B
LF209:  lda     #$01
LF20B:  sta     LFBAE
LF20E:  jsr     LF61C
        beq     LF1D5
        lda     LBEA9+1
        cmp     LBEB0+1
        beq     LF21F
        bcs     LF232
        bcc     LF227
LF21F:  lda     LBEA9
        cmp     LBEB0
        bcs     LF232
LF227:  ldx     #$00
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     LEED9
LF232:  ldx     #$00
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     LF6E9
        jsr     LF2B1
        dec     LFBAE
        bne     LF20E
        jmp     LF1D5

LF248:  lda     #$13
        bra     LF24E
LF24C:  lda     #$01
LF24E:  sta     LFBAE
LF251:  jsr     LF65B
        bne     LF259
        jmp     LF1D5

LF259:  lda     LBEA9+1
        cmp     LBEB0+1
        beq     LF265
        bcc     LF27A
        bcs     LF26F
LF265:  lda     LBEA9
        cmp     LBEB0
        bcc     LF27A
        beq     LF27A
LF26F:  ldx     #$00
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     LEED9
LF27A:  ldx     #$00
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     LF6D1
        jsr     LF2B1
        dec     LFBAE
        bne     LF251
        jmp     LF1D5

LF290:  jsr     LF5D7
        jsr     LF298
        sec
        rts

;;; swaps these two lists of control characters
LF298:  ldy     #$04
LF29A:  lda     LBEC8,y
        pha
        lda     LF2AC,y
        sta     LBEC8,y
        pla
        sta     $F2AC,y
        dey
        bpl     LF29A
        rts

;;; Remapped Control chars during block selection
LF2AC:  .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::Return)

LF2B1:  ldx     #$00
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     LEFF3
        jsr     LEED9
        jsr     LEFF6
        rts

LF2C3:  jsr     DrawDialogBox
        .byte   10
        .byte   42
        .byte   5
        .byte   18
        .byte   34
        .addr   TDAD0
        ldx     #$26
        ldy     #$0C
        jsr     DrawAbortButton
        jsr     DisplayHitEscToEditDocInStatusLine
LF2D7:  ldy     #$07
        ldx     #$14
        jsr     SetCursorPosToXY
        lda     #<TDADD
        ldx     #>TDADD
        jsr     DisplayMSB1String
        lda     PrinterSlot
        jsr     LDF4F
        bcs     LF31E
        cmp     #$08
        bcs     LF2F5
        cmp     #$00
        bne     LF2FA
LF2F5:  jsr     PlayTone
        bra     LF2D7
LF2FA:  sta     PrinterSlot
        ldy     #$08
        ldx     #$14
        jsr     SetCursorPosToXY
        lda     #<TDAF1
        ldx     #>TDAF1
        jsr     DisplayMSB1String
        ldy     PrinterInitString
LF30E:  lda     PrinterInitString,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LF30E
        lda     #$14
        jsr     LF4DF
        bcc     LF31F
LF31E:  rts

LF31F:  ldy     ProDOS::SysPathBuf
LF322:  lda     ProDOS::SysPathBuf,y
        sta     PrinterInitString,y
        dey
        bpl     LF322
        ldx     #$01
        ldy     #$01
LF32F:  lda     ProDOS::SysPathBuf,x
        and     #%01111111
        cmp     #$5E
        bne     LF33E
        inx
        lda     ProDOS::SysPathBuf,x
        and     #%00011111
LF33E:  sta     LFBB3,y
        cpx     ProDOS::SysPathBuf
        bcs     LF34A
        inx
        iny
        bra     LF32F
LF34A:  lda     ProDOS::SysPathBuf
        bne     LF351
        ldy     #$00
LF351:  sty     LFBB3
        ldy     #$09
        ldx     #$14
        jsr     SetCursorPosToXY
        lda     #<TDB46
        ldx     #>TDB46
        jsr     DisplayMSB1String
        lda     PrinterLeftMargin
        jsr     LDF4F
        bcs     LF31E
        sta     PrinterLeftMargin
        ldy     #$0A
        ldx     #$14
        jsr     SetCursorPosToXY
        lda     #<TDB06
        ldx     #>TDB06
        jsr     DisplayMSB1String
LF37B:  jsr     GetKeypress           ; input routine
        jsr     CharToUppercase
        cmp     #HICHAR(ControlChar::Esc)
        beq     LF31E
        cmp     #HICHAR('C')
        beq     LF397
        cmp     #HICHAR('S')
        beq     LF392
        jsr     PlayTone
        bra     LF37B
LF392:  pha
        jsr     LF738
        pla
LF397:  jsr     OutputCharAndAdvanceScreenPos
        ldy     #11
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TDB27
        ldx     #>TDB27         ; "Printing..."
        jsr     DisplayMSB1String
        lda     PrinterSlot
        ora     #%11000000
        sta     Pointer+1
        stz     Pointer
        ldy     #$07
        lda     (Pointer),y
        cmp     #$18
        bne     LF3CF
        ldy     #$05
        lda     (Pointer),y
        cmp     #$38
        bne     LF3CF
        ldy     #$0C
        lda     (Pointer),y
        and     #%11110000
        cmp     #$30
        beq     LF3FA
        cmp     #$10
        beq     LF3FA
LF3CF:  ldy     #$01
        lda     (Pointer),y
        cmp     #$20
        bne     LF3EF
        ldy     #$03
        lda     (Pointer),y
        bne     LF3EF
LF3DD:  ldy     #$05
        lda     (Pointer),y
        cmp     #$03
        bne     LF3EF
        lda     #<TDB33
        ldx     #>TDB33
        jsr     DisplayMSB1String  ; "Printer not found"
        jmp     LEAB4

LF3EF:  jsr     DeterminePrinterOutputRoutineAddress
        lda     #$FF
        sta     LFBDB
        jmp     LF417

LF3FA:  ldy     #$0D
        lda     (Pointer),y
        sta     PrinterOutputRoutineAddress
        stz     LFBDB
        lda     Pointer+1
        sta     PrinterOutputRoutineAddress+1
        lda     #' '
        jsr     SendCharacterToPrinter
        stz     Pointer
        ldy     #$0F
        lda     (Pointer),y
        sta     PrinterOutputRoutineAddress
LF417:  jsr     DisableCSW
        lda     LFBB3
        beq     LF437
        lda     #<LFBB3
        ldx     #>LFBB3
        jsr     LF482
        lda     SoftSwitch::RD80VID
        bmi     LF437
        jsr     ResetTextScreen
        jsr     ClearTextWindow
        jsr     DrawMenuBarAndMenuTitles
        jsr     OutputStatusBarLine
LF437:  lda     #$35
        bra     LF442
LF43B:  lda     #ControlChar::ControlL ; form feed
        jsr     SendCharacterToPrinter
        lda     #$36
LF442:  sta     LBE9C
LF445:  jsr     LF46C
        lda     SoftSwitch::KBD
        bpl     LF454
        sta     SoftSwitch::KBDSTRB
        cmp     #HICHAR(ControlChar::Esc)
        beq     LF463
LF454:  jsr     LF61C
        beq     LF463
        jsr     LF6A9
        dec     LBE9C
        bne     LF445
        bra     LF43B
LF463:  lda     #$0C
        jsr     SendCharacterToPrinter
        jsr     RestoreCSW
        rts

LF46C:  ldy     PrinterLeftMargin
        beq     LF47B
LF471:  lda     #$20
        phy
        jsr     SendCharacterToPrinter
        ply
        dey
        bne     LF471
LF47B:  jsr     LFA74
        lda     #$80
        ldx     #$02
LF482:  sta     Pointer
        stx     Pointer+1
        lda     (Pointer)
        and     #%01111111
        sta     LFBAE
        beq     LF4A4
        lda     #$01
        sta     LBE9E
LF494:  ldy     LBE9E
        lda     (Pointer),y
        jsr     SendCharacterToPrinter
        inc     LBE9E
        dec     LFBAE
        bne     LF494
LF4A4:  lda     #$0D
        jsr     SendCharacterToPrinter
        lda     LFBDB
        bne     LF4B3
        lda     #$8A
        jsr     SendCharacterToPrinter
LF4B3:  rts

DisableCSW:
        lda     ZeroPage::CSWL
        sta     SavedCSW
        lda     ZeroPage::CSWH
        sta     SavedCSW+1
        lda     #<KnownRTS
        sta     ZeroPage::CSWL
        lda     #>KnownRTS
        sta     ZeroPage::CSWH
        stz     Columns80::OURCH
        lda     #1
        sta     ZeroPage::WNDWDTH
KnownRTS:
        rts

SavedCSW:
        .addr   $0000

RestoreCSW:
        lda     SavedCSW
        sta     ZeroPage::CSWL
        lda     SavedCSW+1
        sta     ZeroPage::CSWH
        lda     #80
        sta     ZeroPage::WNDWDTH
        rts

LF4DF:  sta     Pointer6+1
        lda     Columns80::OURCH
        sta     $E9
LF4E6:  lda     $E9
        sta     Columns80::OURCH
        ldy     Pointer6+1
        jsr     OutputSpaces
        lda     $E9
        sta     Mouse::MOUXH+3
        lda     #<ProDOS::SysPathBuf
        ldx     #>ProDOS::SysPathBuf
        jsr     DisplayMSB1String
LF4FC:  jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LF540
        cmp     #HICHAR(ControlChar::Return)
        beq     LF53E
        cmp     #HICHAR(ControlChar::Delete)
        beq     LF52C
        cmp     #HICHAR(ControlChar::LeftArrow)
        beq     LF52C
        cmp     #HICHAR(ControlChar::ControlX)
        beq     LF538
        cmp     #HICHAR(' ')
        bcs     LF51C
LF517:  jsr     PlayTone
        bra     LF4FC
LF51C:  ldy     ProDOS::SysPathBuf
        iny
        cpy     Pointer6+1
        bcs     LF517
        sta     ProDOS::SysPathBuf,y
        sty     ProDOS::SysPathBuf
        bra     LF4E6
LF52C:  lda     ProDOS::SysPathBuf
        beq     LF517
        dec     a
        sta     ProDOS::SysPathBuf
        jmp     LF4E6

LF538:  stz     ProDOS::SysPathBuf
        jmp     LF4E6

LF53E:  clc
        rts

LF540:  sec
        rts

LF542:  jsr     LF546
        txa
LF546:  pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     LF551
        pla
        and     #%00001111
LF551:  ora     #%10110000
        cmp     ##HICHAR(':')
        bcc     LF559
        adc     #$06
LF559:  jmp     OutputCharAndAdvanceScreenPos

LF55C:  jsr     LF567
        lda     #<LFC23
        ldx     #>LFC23
        jsr     DisplayMSB1String
        rts

LF567:  sta     LBE9C
        stx     LBE9D
        sty     LFC23
LF570:  jsr     LF591
        lda     LBE9E
        ora     #%10110000
        sta     LFC23,y
        dey
        lda     LBE9C
        ora     LBE9D
        bne     LF570
        lda     #$A0
        cpy     #$00
        beq     LF590
LF58A:  sta     LFC23,y
        dey
        bne     LF58A
LF590:  rts

LF591:  ldx     #$10
        lda     #$00
        sta     LBE9E
LF598:  jsr     LF5B0
        rol     LBE9E
        sec
        lda     LBE9E
        sbc     #$0A
        bcc     LF5AC
        sta     LBE9E
        inc     LBE9C
LF5AC:  dex
        bne     LF598
        rts

LF5B0:  asl     LBE9C
        rol     LBE9D
        rts

LF5B7:  lda     #$03
        sta     CurrentCursorYPos
        stz     CurrentCursorXPos
        rts

LF5C0:  lda     Pointer3
        asl     a
        sta     LBEAE
        lda     Pointer3+1
        sta     LBEAE+1
LF5CA:  lda     LBEA9
        sta     LBEB0
        lda     LBEA9+1
        sta     LBEB0+1
        rts

LF5D7:  lda     LBEB0+1
        sta     LBEA9+1
        lda     LBEB0
        sta     LBEA9
        lda     LBEAE+1
        sta     Pointer3+1
        lda     LBEAE
        sta     Pointer3
        rts

LF5EE:  lda     Pointer3
        sta     LBEB2
        lda     Pointer3+1
        sta     LBEB2+1
        lda     LBEA9
        sta     LBEB4
        lda     LBEA9+1
        sta     LBEB4+1
        rts

LF605:  lda     LBEB4+1
        sta     LBEA9+1
        lda     LBEB4
        sta     LBEA9
        lda     LBEB2+1
        sta     Pointer3+1
        lda     LBEB2
        sta     Pointer3
        rts

LF61C:  lda     LBEA9
        cmp     LBEA5
        bne     LF62A
        lda     LBEA9+1
        cmp     LBEA6
LF62A:  rts

LF62B:  jsr     LF9EA
        and     #%01111111
        cmp     CurrentCursorXPos
        rts

LF634:  lda     LBEA5
        cmp     #$58
        bne     LF65A
        lda     LBEA6
        cmp     #$04
        bne     LF65A
        lda     #<TDA94
        ldx     #>TDA94
        jsr     DisplayStringInStatusLine
        jsr     LEAB4
        jsr     LEF42
        jsr     LEF49
        jsr     LEF58
        lda     #$00
        sta     PathnameBuffer
LF65A:  rts

LF65B:  lda     LBEA9
        cmp     #$01
        bne     LF665
        lda     LBEA9+1
LF665:  rts

LF666:  jsr     LF671
        jsr     LF67F
        sta     Pointer3
        stx     Pointer3+1
        rts

LF671:  dec     LBEA9
        lda     LBEA9
        cmp     #$FF
        bne     LF67E
        dec     LBEA9+1
LF67E:  rts

LF67F:  lda     LBEA9
        ldx     LBEA9+1
LF685:  dec     a
        cmp     #$FF
        bne     LF68B
        dex
LF68B:  asl     a
        sta     Pointer
        txa
        rol     a
        sta     Pointer+1
        lda     Pointer
        clc
        adc     #$00
        sta     Pointer
        lda     Pointer+1
        adc     #$08
        sta     Pointer+1
        phy
        ldy     #$01
        lda     (Pointer),y
        tax
        lda     (Pointer)
        ply
        rts

LF6A9:  jsr     LF6B4
        jsr     LF67F
        sta     Pointer3
        stx     Pointer3+1
        rts

LF6B4:  inc     LBEA9
        bne     LF6BC
        inc     LBEA9+1
LF6BC:  rts

        ldx     LBEA9+1
        lda     LBEA9
        clc
        adc     #$02
        bcc     LF6C9
        inx
LF6C9:  jsr     LF685
        sta     Pointer4
        stx     Pointer4+1
        rts

LF6D1:  lda     CurrentCursorYPos
        cmp     #$03
        beq     LF6DF
        dec     CurrentCursorYPos
        jsr     LF666
        rts

LF6DF:  jsr     LEC1C
        jsr     LF666
        jsr     LEED9
        rts

LF6E9:  lda     CurrentCursorYPos
        cmp     #$15
        beq     LF6F7
        inc     CurrentCursorYPos
        jsr     LF6A9
        rts

LF6F7:  jsr     LEBDA
        jsr     LF6A9
        jsr     LEED9
        rts

LF701:  cpy     #$02
        bcc     LF70D
        dey
        jsr     LF9F1
        cmp     #$20
        beq     LF701
LF70D:  rts

LF70E:  cpy     LastEditableColumn
        beq     LF71B
        iny
        jsr     LF9F1
        cmp     #$20
        beq     LF70E
LF71B:  rts

LF71C:  cpy     #$02
        bcc     LF729
        dey
        jsr     LF9F1
        cmp     #$20
        bne     LF71C
        iny
LF729:  rts

LF72A:  cpy     LastEditableColumn
        beq     LF737
        iny
        jsr     LF9F1
        cmp     #$20
        bne     LF72A
LF737:  rts

LF738:  stz     LBEA9+1
        lda     #$01
        sta     LBEA9
        ldx     LBEA9+1
        jsr     LF685
        sta     Pointer3
        stx     Pointer3+1
        rts

LF74B:  jsr     LF9EA
        and     #%01111111
        tay
        lda     #$20
LF753:  cpy     CurrentCursorXPos
        beq     LF75E
        iny
        jsr     LFA33
        bra     LF753
LF75E:  jsr     LF9EA
        bpl     LF768
        tya
        ora     #%10000000
        bra     LF769
LF768:  tya
LF769:  jsr     LFA2C
        rts

LF76D:  jsr     LF7F1
        jsr     LF61C
        beq     LF778
        jsr     LF7FF
LF778:  lda     #$00
        jsr     LFA50
LF77D:  inc     LBEA5
        bne     LF785
        inc     LBEA6
LF785:  rts

LF786:  lda     LBEA9
        sta     LBEA5
        lda     LBEA9+1
        sta     LBEA6
        rts

LF793:  lda     LBEA5
        dec     a
        sta     LBEA5
        cmp     #$FF
        bne     LF7A1
        dec     LBEA6
LF7A1:  rts

LF7A2:  jsr     LF9EA
        bpl     LF7B1
        lda     #$80
        jsr     LFA50
        jsr     LF9EA
        and     #%01111111
LF7B1:  sta     LBE9C
        sec
        sbc     CurrentCursorXPos
        sta     LBE9C
        beq     LF7E8
        tya
        ora     #%10000000
        jsr     LFA2C
        ldx     #$01
LF7C5:  iny
        jsr     LF9F1
        phy
        phx
        ply
        jsr     LFA57
        phy
        plx
        ply
        inx
        dec     LBE9C
        bne     LF7C5
        dex
        jsr     LFA0B
        bpl     LF7E3
        txa
        ora     #%10000000
        bra     LF7E4
LF7E3:  txa
LF7E4:  jsr     LFA50
LF7E7:  rts

LF7E8:  jsr     LF9EA
        bmi     LF7E7
        lda     #$00
        bra     LF7E4
LF7F1:  ldx     LBEA9+1
        lda     LBEA9
        jsr     LF68B
        sta     Pointer4
        stx     Pointer4+1
        rts

LF7FF:  jsr     LF5C0
        inc     LBEB0
        bne     LF80A
        inc     LBEB0+1
LF80A:  ldx     LBEA6
        lda     LBEA5
        sta     LBEA9
        stx     LBEA9+1
        jsr     LF68B
        pha
        phx
        bra     LF820
LF81D:  jsr     LF666
LF820:  jsr     LF67F
        ldy     #$02
        sta     (Pointer),y
        iny
        txa
        sta     (Pointer),y
        lda     LBEA9
        cmp     LBEB0
        bne     LF81D
        lda     LBEA9+1
        cmp     LBEB0+1
        bne     LF81D
        ldy     #$01
        pla
        sta     (Pointer),y
        pla
        sta     (Pointer)
        jsr     LF5D7
        jsr     LF666
        jsr     LF7F1
        rts

LF84D:  jsr     LF61C
        beq     LF887
        jsr     LF5EE
LF855:  jsr     LF67F
        ldy     #$03
        lda     (Pointer),y
        ldy     #$01
        sta     (Pointer),y
        iny
        lda     (Pointer),y
        sta     (Pointer)
        jsr     LF6B4
        jsr     LF61C
        bne     LF855
        ldy     #$03
        lda     LBEB2+1
        sta     (Pointer),y
        dey
        lda     LBEB2
        sta     (Pointer),y
        jsr     LF605
        jsr     LF67F
        sta     Pointer3
        stx     Pointer3+1
        jsr     LF7F1
LF887:  rts

LF888:  jsr     LF5C0
        stz     LBEBA
LF88E:  jsr     LF61C
        bne     LF896
LF893:  jmp     LF94D

LF896:  jsr     LF9EA
        bmi     LF893
        cmp     CurrentLineLength
        bcs     LF893
        jsr     LF7F1
        jsr     LF9EA
        sta     LBEB6
        jsr     LFA0B
        bpl     LF8B2
        and     #%01111111
        beq     LF893
LF8B2:  sta     LBEB7
        lda     CurrentLineLength
        sec
        sbc     LBEB6
        cmp     #$02
        bcc     LF893
        tay
        cmp     LBEB7
        bcc     LF8DD
        ldy     LBEB7
        jsr     LFA0B
        and     #%10000000
        sta     LFBB0
        jsr     LF9EA
        ora     LFBB0
        jsr     LFA2C
        jmp     LF8E9

LF8DD:  jsr     LFA12
        cmp     #$20
        beq     LF8E9
        dey
        bne     LF8DD
        beq     LF94D
LF8E9:  sty     LBEBA
        sty     LBEB8
LF8EF:  jsr     LFA12
        sta     ProDOS::SysPathBuf,y
        dey
        bne     LF8EF
        lda     LBEB6
        tay
        clc
        adc     LBEB8
        sta     LBE9C
        jsr     LF9EA
        and     #%10000000
        ora     LBE9C
        jsr     LFA2C
        lda     LBEB8
        sta     LBE9C
        ldx     #$01
LF916:  iny
        lda     ProDOS::SysPathBuf,x
        jsr     LFA33
        inx
        dec     LBE9C
        bne     LF916
        jsr     LF61C
        beq     LF94D
        jsr     LF6A9
LF92B:  ldy     #$01
        jsr     LF977
        lda     LBE9C
        beq     LF93A
        dec     LBEB8
        bne     LF92B
LF93A:  jsr     LF9EA
        and     #%01111111
        beq     LF944
        jmp     LF88E

LF944:  jsr     LF84D
        jsr     LF666
        jsr     LF793
LF94D:  jsr     LF5D7
        lda     LBEBA
        rts

LF954:  jsr     LF65B
        beq     LF974
        jsr     LF666
        jsr     LF9EA
        bmi     LF971
        sta     LFBB0
        lda     CurrentLineLength
        sec
        sbc     LFBB0
        pha
        jsr     LF6A9
        pla
        rts

LF971:  jsr     LF6A9
LF974:  lda     #$00
        rts

LF977:  jsr     LF9EA
        and     #%01111111
        sta     LBE9C
        beq     LF9A1
LF981:  cpy     LBE9C
        bcs     LF993
        iny
        jsr     LF9F1
        dey
        beq     LF990
        jsr     LFA33
LF990:  iny
        bra     LF981
LF993:  dec     LBE9C
        jsr     LF9EA
        and     #%10000000
        ora     LBE9C
        jsr     LFA2C
LF9A1:  rts

LF9A2:  jsr     LF76D
        ldy     LastEditableColumn
        dey
LF9A9:  jsr     LF9F1
        cmp     #$20
        beq     LF9B6
        dey
        bne     LF9A9
        ldy     LastEditableColumn
LF9B6:  cpy     LastEditableColumn
        bne     LF9CA
        ldy     #$01
        jsr     LFA57
        tya
        jsr     LFA50
        jsr     LF9EA
        dec     a
        bra     LF9DB
LF9CA:  lda     CurrentCursorXPos
        pha
        sty     CurrentCursorXPos
        jsr     LF7A2
        pla
        sta     CurrentCursorXPos
        jsr     LF9EA
LF9DB:  and     #%01111111
        jsr     LFA2C
        jsr     LF6A9
        jsr     LF888
        jsr     LF666
        rts

LF9EA:  sty     LBE9F
        ldy     #$00
        bra     LF9F4
LF9F1:  sty     LBE9F
LF9F4:  lda     Pointer3
        lsr     a
        bcc     LFA07
        sta     SoftSwitch::RDCARDRAM
        lda     (Pointer3),y
        sta     SoftSwitch::RDMAINRAM
LFA01:  pha
        ldy     LBE9F
        pla
        rts

LFA07:  lda     (Pointer3),y
        bra     LFA01
LFA0B:  sty     LBE9F
        ldy     #$00
        bra     LFA15
LFA12:  sty     LBE9F
LFA15:  lda     Pointer4
        lsr     a
        bcc     LFA28
        sta     SoftSwitch::RDCARDRAM
        lda     (Pointer4),y
        sta     SoftSwitch::RDMAINRAM
LFA22:  pha
        ldy     LBE9F
        pla
        rts

LFA28:  lda     (Pointer4),y
        bra     LFA22
LFA2C:  sty     LBE9F
        ldy     #$00
        bra     LFA36
LFA33:  sty     LBE9F
LFA36:  pha
        lda     Pointer3
        lsr     a
        bcc     LFA49
        sta     SoftSwitch::WRCARDRAM
        pla
        sta     (Pointer3),y
        sta     SoftSwitch::WRMAINRAM
        ldy     LBE9F
        rts

LFA49:  pla
        sta     (Pointer3),y
        ldy     LBE9F
        rts

LFA50:  sty     LBE9F
        ldy     #$00
        bra     LFA5A
LFA57:  sty     LBE9F
LFA5A:  pha
        lda     Pointer4
        lsr     a
        bcc     LFA6D
        sta     SoftSwitch::WRCARDRAM
        pla
        sta     (Pointer4),y
        sta     SoftSwitch::WRMAINRAM
        ldy     LBE9F
        rts

LFA6D:  pla
        sta     (Pointer4),y
        ldy     LBE9F
        rts

LFA74:  jsr     LF9EA
        sta     ProDOS::SysPathBuf
        and     #%01111111
LFA7C:  beq     LFA88
        tay
LFA7F:  jsr     LF9F1
        sta     ProDOS::SysPathBuf,y
        dey
LFA86:  bne     LFA7F
LFA88:  rts

;;; Function keys, probably for the Extended Keyboard II,
;;; remapped to Apple key combos
;;; Help, Home, Page Up, Del Forward, End, Page Down
;;; Some mystery characters here....

FunctionKeys:
        .byte   $06
        .byte   $F2,$F3,$F4,$F5,$F7,$F9 ; Help, Home, Page Up, Del Fwd, End, Page Down

FunctionKeysRemapped:
        .byte   '?'
        .byte   '1'
        .byte   ControlChar::UpArrow
        .byte   'F'
        .byte   '9'
        .byte   ControlChar::DownArrow

;;;  Table of Open-Apple key commands and handlers

OpenAppleKeyComboTable:
        .byte   $2E

        .byte   'A'             ; About
        .byte   'Q'             ; Quit
        .byte   'L'             ; Load File
        .byte   'S'             ; Save
        .byte   'M'             ; Clear Memory
        .byte   'N'             ; New Prefix
        .byte   'D'             ; Directory

        .byte   'a'
        .byte   'q'
        .byte   'l'
        .byte   's'
        .byte   'm'
        .byte   'n'
        .byte   'd'

        .byte   'E'             ; Toggle Insert/Edit
        .byte   'e'
        .byte   '<'             ; Beginning of line
        .byte   ','
        .byte   '>'             ; End of line
        .byte   '.'
        .byte   '1'             ; Beginning of file
        .byte   '9'             ; End of file

        .byte   ControlChar::Delete ; Block delete
        .byte   ControlChar::UpArrow ; Page up
        .byte   ControlChar::DownArrow  ; Page down
        .byte   ControlChar::LeftArrow  ; Previous word
        .byte   ControlChar::RightArrow ; Next word
        .byte   ControlChar::Tab ; Reverse tab

        .byte   'F'             ; Delete char right
        .byte   'f'
        .byte   'Z'             ; Show/hide CRs
        .byte   'z'
        .byte   '/'             ; Help
        .byte   '?'
        .byte   'Y'             ; Clear to end of line
        .byte   'y'

        .byte   'T'             ; Tab stops
        .byte   't'
        .byte   'X'             ; Clear line
        .byte   'x'
        .byte   'P'             ; Print
        .byte   'p'
        .byte   'V'             ; Volumes
        .byte   'v'

        .byte   'C'             ; Copy text
        .byte   'c'

OpenAppleKeyComboJumpTable:
        .addr   LD0BA           ; A
        .addr   LD0C2           ; Q
        .addr   LD0C6           ; L
        .addr   LD0CA           ; S
        .addr   LD0D9           ; M
        .addr   LD0AC           ; N
        .addr   LD0B4           ; D
        .addr   LD0BA           ; a
        .addr   LD0C2           ; q
        .addr   LD0C6           ; l
        .addr   LD0CA           ; s
        .addr   LD0D9           ; m
        .addr   LD0AC           ; n
        .addr   LD0B4           ; d
        .addr   ToggleInsertOverwrite ; E
        .addr   ToggleInsertOverwrite ; e
        .addr   LD23E           ; <
        .addr   LD23E           ; ,
        .addr   LD246           ; >
        .addr   LD246           ; .
        .addr   LD257           ; 1
        .addr   LD265           ; 9
        .addr   LD570           ; Delete
        .addr   LD168           ; UpArrow
        .addr   LD1A5           ; DownArrow
        .addr   LD1E3           ; LeftArrow
        .addr   LD212           ; RightArrow
        .addr   BackwardTab     ; Tab
        .addr   DeleteForwardChar ; F
        .addr   DeleteForwardChar ; f
        .addr   ShowHideCRKeyCommand ; Z
        .addr   ShowHideCRKeyCommand ; z
        .addr   LD874           ; /
        .addr   LD874           ; ?
        .addr   ClearToEndOfCurrentLine           ; Y
        .addr   ClearToEndOfCurrentLine           ; y
        .addr   LD78E           ; T
        .addr   LD87E           ; t
        .addr   ClearCurrentLine ; X
        .addr   ClearCurrentLine ; x
        .addr   LD0BE           ; P
        .addr   LD0BE           ; p
        .addr   LD0B0           ; V
        .addr   LD0B0           ; v
        .addr   LD66A           ; C
        .addr   LD66A           ; c

;;; Table of other key commands and handlers
        .byte   $08
        .byte   HICHAR(ControlChar::Tab)
        .byte   HICHAR(ControlChar::Return)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::LeftArrow)
        .byte   HICHAR(ControlChar::RightArrow)
        .byte   HICHAR(ContorlChar::ControlX)
        .byte   HICHAR(ControLChar::ControlS)

        .addr   ForwardTab
        .addr   CarriageReturn
        .addr   MoveUpOneLine
        .addr   MoveDownOneLine
        .addr   MoveLeftOneChar
        .addr   MoveRightOneChar
        .addr   ClearCurrentLine
        .addr   SearchForString

MenuLengths:
        .byte   $06,$03,$04     ; number of items in each menu

MenuXPositions:
        .byte   $03,$0D,$1C     ; menu x-positions

MenuWidths:
        .byte   $13,$11,$15     ; menu widths

LFB43:
        .byte   $03             ; menu count?

;;; Pointers into Menu Item strings table below (for each menu)
MenuItemListAddresses:
        .addr   FileMenuItemTitles
        .addr   UtilitiesMenuItemTitles
        .addr   OptionsMenuItemTitles

;;;  Addresses of Menu Item strings
MenuItemTitleTable:
FileMenuItemTitles:
        .addr   TDCFA
        .addr   TDD0F
        .addr   TDD24
        .addr   TDD39
        .addr   TDD4E
        .addr   TDD63
UtilitiesMenuItemTitles:
        .addr   TDD78
        .addr   TDD8B
        .addr   TDD9E
OptionsMenuItemTitles:
        .addr   TDDB1
        .addr   TDDC7
        .addr   TDDDD
        .addr   TDDF3

MenuItemJumpTable:
        .addr   ShowAboutBox
        .addr   ShowOpenFileDialog ; Open File...
        .addr   ShowSaveAsDialog   // Save as...
        .addr   ShowPrintDialog   // Print...
        .addr   ShowClearMemoryDialog
        .addr   ShowQuitDialog
        .addr   $0000
        .addr   $0000

        .addr   ShowListDirectoryDialog   // Directory
        .addr   ShowSetPrefixDialog   // New Prefix
        .addr   ShowVolumesDialog
        .addr   $0000
        .addr   $0000
        .addr   $0000
        .addr   $0000
        .addr   $0000

        .addr   SetLineLengthPrompt ; Set Line Length ?
        .byte   ShowChangeMouseStatusDialog ; Change Mouse Status
        .addr   ChangeBlinkRate ;  Change Blink Rate
        .addr   ShowMacrosScreen ;  Macros

LFB8C:
        ;;  sometimes set to $83,$7D - compared to mouse coordinates
        .byte   $97,$69         ; something to do with mouse clamping values?
;;; search text, probably (20 chars):
SearchText:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
CursorBlinkCounter:
        .addr   $0000
CursorBlinkRate:
        .byte   $05
        .byte   $00
CurrentCursorChar:
        .byte   HICHAR('_')     ; current cursor
CharUnderCursor:
        .byte   $00             ; char under cursor?
InsertCursorChar:
        .byte   HICHAR('_')     ; insert cursor
OverwriteCursorChar:
        .byte   ' '             ; overwrite cursor
LFBBA:  .byte   $FF             ; unused?
LFBAB:  .byte   $00             ; character output mask (ie., for inverse)?
SavedMouseSlot:
        .byte   $00             ; saved mouse slot
LFBAD:  .byte   $00             ; copy of $BDA5 ? (prefix length byte)
LFBAE:  .byte   $00             ; some kind of boolean $00/$01
LFBAF:  .byte   $FF
LFBB0:  .byte   $00

LFBB1:  .byte   $00             ; something to do with keyboard input

PrinterSlot:
        .byte   $01             ; printer slot

        ;;  20 byte mystery buffer
LFBB3:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00

;;;  up to 20 chars long
PrinterInitString:
         msb1pstring "^I80N"
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00

PrinterLeftMargin:
        .byte   $03

LFBDD:  .byte   $00             ; flag $00/$FF - maybe related to storing CR after each line?

CurrentLineLength:
        .byte   79

LastEditableColumn:
        .byte   78

DateTimeFormatString:
        msb1pstring " DD-MMM-YY HH:MM "

MonthNames:
        highascii "-Jan-Feb-Mar-Apr-May-Jun-Jul-Aug-Sep-Oct-Nov-Dec-"

;;; Mystery buffer (10 bytes)
LFC23:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00

TabStops:
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$FF
        .byte   $00,$00,$00,$00,$00

FileTypeTable:
        .byte   FileType::BAD
        .highascii "Bad"
        .byte   FileType::TXT
        .highascii "Txt"
        .byte   FileType::BIN
        .highascii "Bin"
        .byte   FileType::DIR
        .highascii "Dir"
        .byte   FileType::ADB
        .highascii "Adb"
        .byte   FileType::AWP
        .highascii "Awp"
        .byte   FileType::ASP
        .highascii "Asp"
        .byte   FileType::SRC
        .highascii "Src"
        .byte   FileType::OBJ
        .highascii "Obj"
        .byte   FileType::LIB
        .highascii "Lib"
        .byte   FileType::A16
        .highascii "S16"
        .byte   FileType::RTL
        .highascii "Rtl"
        .byte   FileType::EXE
        .highascii "Exe"
        .byte   FileType::PIF
        .highascii "Str"
        .byte   FileType::TIF
        .highascii "Tsf"
        .byte   FileType::NDA
        .highascii "Nda"
        .byte   FileType::CDA
        .highascii "Cda"
        .byte   FileType::TOL
        .highascii "Tol"
        .byte   FileType::DRV
        .highascii "Drv"
        .byte   FileType::DOC
        .highascii "Doc"
        .byte   FileType::PNT
        .highascii "Pnt"
        .byte   FileType::PIC
        .highascii "Pic"
        .byte   FileType::FON
        .highascii "Fon"
        .byte   FileType::CMD
        .highascii "Cmd"
        .byte   FileType::P16
        .highascii "P16"
        .byte   FileType::BAS
        .highascii "Bas"
        .byte   FileType::VAR
        .highascii "Var"
        .byte   FileType::REL
        .highascii "Rel"
        .byte   FileType::SYS
        .highascii "Sys"

        .byte   $00,$44
        .highascii "\r EdIt! - by Bill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$0E
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems\r"

        .byte   $45,$4D,$00
        .highascii "This is a testill Tudor\r"
        .highascii "   Copyright 1988-89\r"
        .highascii "Northeast Micro Systems"

        .byte   $45,$4D

        ;;  + 61D3
        .org    $BC00

BC00_Code:                      ; $5A2D
;;; This is evidently the shutdown code:
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        lda     LBEBB
        beq     LBC40
        sei
        ldx     ProDOS::DEVCNT
        sta     $BF33,x
        inc     ProDOS::DEVCNT
        and     #%11110000
        sta     $43
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     LBC3A
        sta     ProDOS::DEVADR0,x
        lda     LBC3A+1
        sta     $BF11,x
        lda     #$03
        sta     $42
        stz     $44
        lda     #$20
        sta     $45
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
LBC3A:  = * + 1
        jsr     L0000
LBC3D           := * + 1        ; this is odd...
        bit     SoftSwitch::RDROMLCB2
        cli
LBC40:  lda     LBCA3
        beq     LBC8A
        tay
LBC46:  lda     LBCA3,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LBC46
        jsr     ProDOS::MLI
        .byte   ProDOS::CGETFILEINFO
        .addr   EditorGetFileInfoParams
        bne     LBC8A           ; $D0 $33
        lda     L33D0,x
        lda     EditorGetFileInfoFileType
        cmp     #FileType::SYS
        bne     LBC8A
        sta     EditorReadWriteRequestCount
        sta     EditorReadWriteRequestCount+1
        jsr     ProDOS::MLI
        .byte   ProDOS::COPEN
        .addr   EditorOpenParams
        bne     LBC8A           ; $D0 $1E
        sta     EditorReadWriteBufferAddr ; stores a 0
        lda     EditorOpenRefNum
        sta     EditorReadWriteRefNum
        lda     #$20
        sta     EditorReadWriteBufferAddr+1
        jsr     ProDOS::MLI
        .byte   ProDOS::CREAD
        bcc     LBC3D
        php
        jsr     ProDOS::MLI
        .byte   ProDOS::CCLOSE
        .addr   EditorCloseParams
        plp
        bcc     LBCA0
LBC8A:  jsr     Monitor::HOME
        lda     #ControlChar::TurnOff80Col
        jsr     Monitor::COUT
        cli
        jsr     ProDOS::MLI
        .byte   ProDOS::CQUIT
        .addr   EditorQuitParams

EditorQuitParams:
        .byte   $04
        .byte   $00
        .addr   $0000
        .byte   $00
        .word   $0000

LBCA0:  jmp     $0000

;;; Path buffer; copied from $2049
LBCA3:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

;;; Reset routine (hooked to reset vector)
ResetHandler:
        jsr     ResetTextScreen
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        jmp     $D000

ResetTextScreen:
        lda     #0
        sta     ZeroPage::WNDTOP
        lda     #24
        sta     ZeroPage::WNDBTM
        lda     #HICHAR(' ')
        jsr     MemoryMap::SLOT3ROM
        jsr     ClearTextWindow
        rts

DeterminePrinterOutputRoutineAddress:
        lda     ZeroPage::CSWL
        pha
        lda     ZeroPage::CSWH
        pha
        ldx     PrinterSlot
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        txa
        jsr     Monitor::OUTPORT
        lda     ZeroPage::CSWL
        sta     PrinterOutputRoutineAddress
        lda     ZeroPage::CSWH
        sta     PrinterOutputRoutineAddress+1
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        pla
        sta     ZeroPage::CSWH
        pla
        sta     ZeroPage::CSWL
        rts

CallWaitMonitorRoutine:
        tax
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        txa
        jsr     Monitor::WAIT
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        rts

;;; Makes a MLI call; call # in A, param list address in X (lo), Y (hi)
MakeMLICall:                    ; $BD46
        sta     MLICallNumber
        stx     MLICallParamTableAddr
        sty     MLICallParamTableAddr+1
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        jsr     ProDOS::MLI
MLICallNumber:                  ; $BD58
        .byte   $00
MLICallParamTableAddr:          ; $BD59
        .addr   $0000
        sta     SoftSwitch::SETALTZP
        pha
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        pla
        rts

;;; BD67 - GET_FILE_INFO param list
;;; BD79 - DESTROY param list
;;; BD7C - CREATE param list
;;; BD88 - OPEN param list
;;; BD8E - CLOSE param list
;;; BD90 - READ/WRITE param list
;;; BD99 - SET_PREFIX param list
;;; BD9C - ON_LINE param list
;;; BDA0 - SET_MARK param list

EditorGetFileInfoParams:        ; $BD67
        .byte   $0A   ; param_count
        .addr   ProDOS::SysPathBuf ; pathname
        .byte   $00   ; access
EditorGetFileInfoFileType:
        .byte   $00   ; file_type
EditorGetFileInfoAuxType:
        .word   $0000 ; aux_type
        .byte   $00   ; storage_type
EditorGetFileInfoBlocksUsed:
        .word   $0000 ; blocks_used ; $BD6F
        .word   $0000 ; mod_date
        .word   $0000 ; mod_time
        .word   $0000 ; create_date
        .word   $0000 ; create_time

EditorDestroyParams:            ; $BD79
        .byte   $01   ; param_count
        .addr   ProDOS::SysPathBuf ; pathname

EditorCreateParams:             ; $BD7C
        .byte   $07           ; param_count
        .addr   PathnameBuffer         ; pathname
        .byte   %11000011     ; access
EditorCreateFileType:
        .byte   FileType::TXT ; file_type
        .word   $0000         ; aux_type
        .byte   ProDOS::StorageType::Seedling ; storage_type
        .word   $0000         ; create_date
        .word   $0000         ; create_time

EditorOpenParams:       ; $BD88
        .byte   $03   ; param_count
        .addr   ProDOS::SysPathBuf ; pathname
        .addr   DataBuffer ; io_buffer
EditorOpenRefNum:
        .byte   $00   ; ref_num

EditorCloseParams:              ; $BD8E
        .byte   $01 ; param_count
EditorCloseRefNum:
        .byte   $00 ; ref_num

EditorReadWriteParams:          ; $BD90
        .byte   $04   ; param_count
EditorReadWriteRefNum:
        .byte   $00   ; ref_num
EditorReadWriteBufferAddr:
        .addr   $0000 ; data_buffer
EditorReadWriteRequestCount:
        .word   $0000 ; request_count
        .word   $0000 ; transfer_count

;;;  just a lonely carriage return? is this a dummy buffer?
;;;  it's address is written to EditorReadWriteBufferAddr in one place
LBD98:
        .byte   ControlChar::Return

EditorSetPrefixParams:          ; $BD99
        .byte   $01   ; param_count
        .addr   ProDOS::SysPathBuf-1 ; pathname

EditorOnLineParams:             ; $BD9C
        .byte   $02   ; param_count
EditorOnLineUnitNum:
        .byte   $00   ; unit_num
EditorOnLineDataBuffer:
        .addr   DataBuffer ; data_buffer

EditorSetMarkParams:        ; $BDA0
        .byte   $02         ; param_count
EditorSetMarkRefNum:
        .byte   $00         ; ref_num
        .byte   $AE,$37,$00 ; position

PathnameLength:                 ; copy of first byte of PathnameBuffer ($BDA5)
        .byte   $00

PrefixBuffer:                   ; $(BDA6)
        .byte   $00
OnLineBuffer:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

PathnameBuffer: ; ($BDE7)
        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

Pathname2Buffer: ; $(BE28)
        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

MLIError:
        .byte   $00

MLIErrorTable:
        .byte   $0F
        .byte   ProDOS::EIO
        .byte   ProDOS::ENODEVCONN
        .byte   ProDOS::EWRITEPROT
        .byte   ProDOS::EDUPFNAME
        .byte   ProDOS::ENODISK
        .byte   ProDOS::EBADBLOCK
        .byte   ProDOS::EBADSTYPE
        .byte   ProDOS::EBADPATH
        .byte   ProDOS::EDIRNOTF
        .byte   PrODOS::EVOLNOTF
        .byte   ProDOS::EFILENOTF
        .byte   ProDOS::EDUPFNAME
        .byte   ProDOS::EVOLFULL
        .byte   ProDOS::EDIRFULL
        .byte   ProDOS::EFLOCKED

;;; Addresses of error messages

MLIErrorMessageTable:
        .addr   TDE18
        .addr   TDE30
        .addr   TDE3A
        .addr   TDE4E
        .addr   TDE63
        .addr   TDE76
        .addr   TDE87
        .addr   TDE91
        .addr   TDE9F
        .addr   TDEB0
        .addr   TDEC4
        .addr   TDED5
        .addr   TDEE4
        .addr   TDEF7
        .addr   TDF03
        .addr   TDF19

LBE9A:  .byte   $00
LBE9B:  .byte   $00
LBE9C:  .byte   $00
LBE9D:  .byte   $00
LBE9E:  .byte   $00
LBE9F:  .byte   $00
LBEA0:  .byte   $00

CurrentCursorXPos:
        .byte   $00
CurrentCursorYPos:
        .byte   $00

LBEA3:  .byte   $00,$00         ; not used?
LBEA5:  .byte   $00
LBEA6:  .byte   $00
LBEA7:  .byte   $00             ; not used?
LBEA8:  .byte   $00             ; not used?
LBEA9:  .addr   $0000
LBEAB:  .byte   $00,$00         ; not used?
LBEAD:  .byte   $00
LBEAE:  .addr   $0000
LBEB0:  .addr   $0000
LBEB2:  .addr   $0000
LBEB4:  .addr   $0000
LBEB6:  .byte   $00
LBEB7:  .byte   $00
LBEB8:  .byte   $00
LBEB9:  .byte   $00             ; not used?
LBEBA:  .byte   $00
LBEBB:  .byte   $00

CallSetMouse:
         jmp    $0000
CallInitMouse:
         jmp    $0000
CallReadMouse:
         jmp    $0000
CallPosMouse:
         jmp    $0000

LBEC8:  .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::RightArrow)
        .byte   HICHAR(ControlChar::LeftArrow)
        .byte   HICHAR(ControlChar::Esc)

;;; Sends character in A to printer:
SendCharacterToPrinter:
        pha
        ldx     PrinterOutputRoutineAddress+1
        txa
        asl
        asl
        asl
        asl
        tay
        pla
PrinterOutputRoutineAddress := *+1
        jsr     $0000           ; operand is BED9-BEDA
        rts

;;; End of code that gets relocated to $BC00

;;; $1000 bytes starting here gets copied to $D000, LC RAM bank 2

        .reloc

        D000_Bank2_Data := *

        .reloc

        .org $D000

;;; Top edge of Help box
TD000:  .byte   $1A,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$1F

TD050:  .byte   $1A         ; MouseText left and right vbar chars
        .highascii "  "
        .byte $0A               ; MouseText down arrow
        .highascii " "
        .byte   $0B             ; MouseText up arrow
        .highascii " "
        .byte   $15             ; MouseText right arrow
        .highascii " "
        .byte   $08             ; MouseText left arrow
        .highascii "      - Position cursor        "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-A           - About Ed-It!       "
        .byte   $1F

TD0A0:  .byte   $1A
        .highascii "  "
        .byte   $01             ; MouseText Open Apple
        .highascii "- "
        .byte   $0B             ; MouseText up arrow
        .highascii "         - Move up one page       "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-L           - Load File          "
        .byte   $1F

TD0F0:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "- "
        .byte   $15
        .highascii "         - Go right one word      "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-S           - Quick Save         "
        .byte   $1F

TD140:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "- "
        .byte   $08
        .highascii "         - Go left one word       "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-Q           - Quit Ed-It!        "
        .byte   $1F

TD190:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "- "
        .byte   $0A
        .highascii "         - Move down one page     "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-C           - Copy text          "
        .byte   $1F

TD1E0:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "-<          - To begining of line    "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-M           - Clear memory       "
        .byte   $1F


TD230:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "->          - To end of line         "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-V           - Volumes online     "
        .byte   $1F

TD280:  .byte $1A
        .highascii "  "
        .byte   $01
        .highascii "-1          - To start of document   "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-E           - Toggle insert/edit "
        .byte   $1F

TD2D0:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "-9          - To end of document     "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-Z           - Show/hide CR's     "
        .byte   $1F

TD320:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "-Y          - Clear cursor to end    "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-T           - Set tab stops      "
        .byte   $1F

TD370:  .byte   $1A
        .highascii "  Tab          - Tab right              "

        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-X (clear)   - Clear current line "
        .byte   $1F

TD3C0:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "-Tab        - Tab left               "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-Delete      - Begin block delete "
        .byte   $1F

TD410:  .byte   $1A
        .highascii "  Delete       - Delete character left  "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-D           - Directory of disk  "
        .byte   $1F

TD460:  .byte   $1A
        .highascii "  "
        .byte   $01
        .highascii "-F          - Delete character right "
        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-N           - New ProDOS prefix  "
        .byte   $1F

TD4B0:  .byte   $1A
        .highascii "  Cntrl-S      - Search for a string    "

        .byte   $1F
        .highascii "  "
        .byte   $01
        .highascii "-P           - Print file         "
        .byte   $1F

;;; bottom of Help box
TD500:  .byte   $1A
        .highascii "________________________________________"
        .byte   $14
        .highascii "_____________________________________"
        .byte   $1F

TD550:  .highascii "\r                 "
        .byte   $1B             ; MouseText diamond
        .highascii " Copyright 1988-89  Northeast Micro Systems "

        .byte   $1B             ; MouseText diamond
        .byte  $00

TD591:  .byte   $0C
        .byte   $01             ; MouseText Open Apple
        .highascii "-? for Help"

TD59E:  msb1pstring "Search for:"
TD5AA:  msb1pstring "Searching...."
TD5B8:  msb1pstring "Not Found; press a key."
TD5D0:  msb1pstring "Copy Text [T]o or [F]rom the clipboard?"
TD5F8:  msb1pstring "Clipboard is empty."
TD60C:  msb1pstring "Clipboard is full."

TD61F:        .byte   $29
        .highascii "Enter text or use "
        .byte   $01             ; MouseText Open Apple
        .highascii "-cmds; Esc for menus. "

TD649:  msb1pstring "Line       Col.   "

TD65C:  .byte   $36
        .highascii "Use arrows or mouse to select an option; then press "
        .byte   $0D             ; MouseText Carriage Return
        highascii "."

TD693:  msb1pstring "ESC to go back"

TD6A2:  .byte   $4C
        highascii "Use "
        .byte   $08             ; MouseText Left Arrow
        highascii " "
        .byte   $15             ; MouseText Right Arrow
        highascii ", TAB to move; [T]-set/remove tabs; [C]-clear all; "
        .byte   $0D             ; MouseText Carriage Return
        highascii "-accept.   Pos: "

TD6EE:  .byte   $0E,$17,$16,
        .ascii  " Abort "
        highascii " Esc "

TD6FD:  .byte   $0E,$17,$16
        .ascii  " Accept "
        .highascii " "
        .byte   $0D,$1A,$17

TD70C:  msb1pstring "Hit ESC to edit document."

TD726:  msb1pstring "Press <space> to continue."

TD741:  msb1pstring " Quit "

TD748:  msb1pstring "Q - Quit; saving changes"

TD761:  msb1pstring "E - Exit; no save"

TD773:  msb1pstring " New Prefix "

TD780:  .byte   $18
        .highascii "Press "
        .byte   $01             ; MouseText Open Apple
        .highascii "-S for Slot/Drive"

TD799:  msb1pstring "Slot?"
TD79F:  msb1pstring "Drive?"
TD7A6:  msb1pstring " Save File "
TD7B2:  msb1pstring "Path:"
TD7B8:  msb1pstring "Prefix:/"

TD7C1:  .byte   $12,$01
        .highascii "-N for New Prefix"

TD7D4:  .byte   $20,$01
        .highascii "-L or click mouse to List Files"

TD7F5:  msb1pstring "WARNING: File in memory will be lost."
TD81B:  msb1pstring "Press 'S' to save file in memory."
TD83D:  msb1pstring  " Select File  "

TD84B:  .byte   $20
        .highascii "Use "
        .byte   $0B             ; MouseText Up Arrow
        .highascii " "
        .byte   $0A             ; MouseText Down Arrow
        .highascii " to select; then press "
        .byte   $0D             ; MouseText Carriage Return
        .highascii "."

TD86C:  msb1pstring "No files; press a key."

TD883:  .byte   $23
        .highascii "Use "
        .byte   $01
        .highascii "-"
        .byte   $0D
        .highascii " to save with "
        .byte   $0D
        .highascii " on each line"

TD8A7:  msb1pstring "No mouse in system!"
TD8BB:  msb1pstring "Turn OFF mouse?"
TD8CB:  msb1pstring "Turn ON mouse?"
TD8DA:  msb1pstring "Enter new rate (1-9):"
TD8F0:  msb1pstring "Enter new line length (39-79):"

TD90F:  .byte   $2A
        .highascii "You MUST clear file in memory ("
        .byte   $01
        .highascii "-M) FIRST."

TD93A:  .byte   $29
        .highascii "Use "
        .byte   $0B             ; MouseText Up Arrow
        .highascii " "
        .byte   $0A             ; MouseText Down Arrow
        .highascii " to highlight block; then press"
        .highascii " "
        .byte   $0D             ; MouseText Carriage Return
        .highascii "."

TD964:  .byte   $0F
        .byte   $03         ; MoueText Hour Glass
        .highascii " Please Wait.."

TD974:  msb1pstring " Clear Memory "
TD983:  msb1pstring "Erase memory contents?"
TD99A:  msb1pstring " Ed-It! "
TD9A3:  msb1pstring "Ed-It! - A Text File Editor\r\r"
TD9C1:  msb1pstring "by Bill Tudor\r\r"
TD9D1:  msb1pstring "Northeast Micro Systems\r"
TD9EA:  msb1pstring "  v3.00    Sept. 1989\r\r"
TDA02:  msb1pstring "Copyright 1988-89               All Rights Reserved"
TDA36:  msb1pstring "  1220 Gerling Street\r"
TDA4D:  msb1pstring " Schenectady, NY 12308\r"
TDA65:  msb1pstring "Replace old version of file (Y/N)?"
TDA88:  msb1pstring " Load File "

TDA94:  .byte   $15
        .highascii "Memory Full; Press "
        .byte   $0D             ; MouseText Carriage Return
        .highascii "."

TDAAA:  msb1pstring "Enter new prefix above; ESC to abort."
TDAD0:  msb1pstring " Print File "
TDADD:  msb1pstring "Printer Slot (1-7)?"
TDAF1:  msb1pstring "Printer init string:"
TDB06:  msb1pstring "Print from Start or Cursor(S/C)?"
TDB27:  msb1pstring "Printing..."
TDB33:  msb1pstring "Printer NOT found!"
TDB46:  msb1pstring "Enter left margin (0-9):"
TDB5F:  msb1pstring "Enter # to edit; [S] to save to disk."

TDB85:  .byte   $3F

        .highasciiz "Enter macro; "
        .highasciiz "-DEL deletes left; "
        .highasciiz "-Esc = abort; "
        .highascii "-Rtn = accept."

TDBC5:  .byte   $20
        .highascii "Insert PROGRAM disk and press "
        .byte   $0D
        .highascii "."

TDBE6:  .byte   $18
        .byte   $03             ; MouseText Hour Glass
        .highascii " Saving.. Please wait.."

TDBFF:  .byte   $19
        .byte   $03             ; MouseText Hour Glass
        .highascii " Loading.. Please wait.."

TDC19:  msb1pstring " Directory "

TDC25:  .byte   $03
        .byte   $18,$19         ; MouseText Folder
        .highascii " "

TDC29:  msb1pstring "Filename        Type  Size  Date Modified "

TDC54:  .byte   $14
        .highascii " AuxType "
        .byte   $1F             ; MouseText Left VBar
        .highascii "   Blocks:"

TDC69:  msb1pstring " Total:"
TDC71:  msb1pstring "  Used:"
TDC79:  msb1pstring "  Free:"
TDC81:  msb1pstring "Use <SPACE> to"

TDC90:  .byte   $0B
        .highascii "continue"
        .byte   $09,$09,$09     ; MouseText Ellipses

TDC9C:  msb1pstring "Directory complete; Press any key to continue. "
TDCCC:  msb1pstring " Volumes Online "
TDCDD:  msb1pstring " File "
TDCE4:  msb1pstring " Utilities "
TDCF0:  msb1pstring " Options "

TDCFA:  .byte   $14
        .highascii " About Ed-It! "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-A "

TDD0F:  .byte   $14
        .highascii " Load File..  "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-L "

TDD24:  .byte   $14
        .highascii " Save as..    "
        .byte   $8E
        .highascii "     "

TDD39:  .byte   $14
        .highascii " Print..      "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-P "

TDD4E:  .byte   $14
        .highascii " Clear Memory "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-M "

TDD63:  .byte   $14
        .highascii " Quit         "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-Q "

TDD78:  .byte   $12
        .highascii " Directory  "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-D "

TDD8B:  .byte   $12
        .highascii " New Prefix "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-N "

TDD9E:  .byte   $12
        .highascii " Volumes    "
        .byte   $8E
        .highascii " "
        .byte   $01
        .highascii "-V "

TDDB1:  msb1pstring " Set Line Length     "
TDDC7:  msb1pstring " Change Mouse Status "
TDDDD:  msb1pstring " Change 'Blink' Rate "
TDDF3:  msb1pstring " Edit & Save Macros  "
TDE09:  msb1pstring "; Press a key."

TDE18:  msb1pstring " = Unknown ProDOS Error"
TDE30:  msb1pstring "I/O Error"
TDE3A:  msb1pstring "No Device Connected"
TDE4E:  msb1pstring "Disk Write Protected"
TDE63:  msb1pstring "Duplicate Filename"
TDE76:  msb1pstring "No Disk in Drive"
TDE87:  msb1pstring "Bad Block"
TDE91:  msb1pstring "Bad File Type"
TDE9F:  msb1pstring "Invalid Pathname"
TDEB0:  msb1pstring "Directory not Found"
TDEC4:  msb1pstring "Volume not Found"
TDED5:  msb1pstring "File not Found"
TDEE4:  msb1pstring "Duplicate Filename"
TDEF7:  msb1pstring "Volume Full"
TDF03:  msb1pstring "Volume Directory Full"
TDF19:  msb1pstring "File Locked"

        .reloc

        Page3_Code := *

        .org $300

;;; All the following code is copied to $0300 (from $6C2E)
;;; This must be the macro editor
L0300:
        sta     L03E4
        jsr     L0364
        lda     #<TDB85
        ldx     #>TDB85
        jsr     DisplayStringInStatusLine
L6C3B:  jsr     L0375
L6C3E:  jsr     GetKeypress
        bit     SoftSwitch::RDBTN1
        bmi     L6C66
        ldx     ProDOS::SysPathBuf
        cpx     #$46
        bcs     L6C61
        inx
        sta     ProDOS::SysPathBuf,x
        stx     ProDOS::SysPathBuf
        bra     L6C3B
L6C56:  lda     ProDOS::SysPathBuf
        beq     L6C61
        dec     a
        sta     ProDOS::SysPathBuf
        bra     L6C3B
L6C61:  jsr     PlayTone
        bra     L6C3E
L6C66:  cmp     #ControlChar::Delete
        beq     L6C56
        cmp     #ControlChar::Esc
        beq     L6C7D
        cmp     #ControlChar::Return
        bne     L6C61
        ldy     ProDOS::SysPathBuf
L6C75:  lda     ProDOS::SysPathBuf,y
        sta     (Pointer2),y
        dey
        bpl     L6C75
L6C7D:  rts

        lda     #$01
L6C80:  sta     L03E4
        jsr     L0364
        jsr     L0375
        lda     L03E4
        inc     a
        cmp     #$0A
        bcc     L6C80
        rts

L0364:  dec     a
        tay
        jsr     LEDC8
        lda     (Pointer2)
        tay
L6C9A:  lda     (Pointer2),y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     L6C9A
        rts

L0375:  lda     L03E4
        asl     a
        inc     a
        tay
        ldx     #0
        jsr     SetCursorPosToXY
        lda     L03E4
        ora     #%10110000
        jsr     OutputCharAndAdvanceScreenPos
        lda     #HICHAR(':')
        jsr     OutputCharAndAdvanceScreenPos
        ldy     ProDOS::SysPathBuf
        beq     L6CFE
        sty     L03E3
        ldx     #$00
L6CC5:  inx
        lda     ProDOS::SysPathBuf,x
        bmi     L6CE5
        phy
        phx
        pha
        lda     ZeroPage::CV
        inc     a
        jsr     ComputeTextOutputPos
        lda     #$01
        jsr     OutputCharAndAdvanceScreenPos
        lda     ZeroPage::CV
        dec     a
        jsr     ComputeTextOutputPos
        dec     Columns80::OURCH
        pla
        plx
        ply
L6CE5:  ora     #%10000000
        cmp     #HICHAR(' ')
        bcs     L6CF3
        pha
        jsr     LEFF3
        pla
        clc
        adc     #$40
L6CF3:  jsr     OutputCharAndAdvanceScreenPos
        jsr     LEFF6
        cpx     ProDOS::SysPathBuf
        bcc     L6CC5
L6CFE:  jsr     ClearToEndOfLine
        lda     ZeroPage::CV
        inc     a
        jsr     ComputeTextOutputPos
        jsr     ClearToEndOfLine
        lda     ZeroPage::CV
        dec     a
        jsr     ComputeTextOutputPos
        rts

L03E3:  .byte $00
L03E4:  .byte $00

        .reloc
