.MACPACK generic
.FEATURE string_escapes

.setcpu "65C02"

.include "Columns80.s"
.include "ControlChars.s"
.include "FileTypes.s"
.include "Macros.s"
.include "MemoryMap.s"
.include "Monitor.s"
.include "Mouse.s"
.include "MouseText.s"
.include "OpCodes.s"
.include "ProDOS.s"
.include "SmartPort.s"
.include "SoftSwitches.s"
.include "Vectors.s"
.include "ZeroPage.s"

;;; Macro to remap MouseText character to control char range ($00-$1F)
.define MT_REMAP(c) c-$40

;;; Zero Page Usage

Pointer              := $06
MacroPtr             := $08
CurLinePtr           := $0A
Pointer4             := $0C
ParamTablePtr        := $1A
MouseSlot            := $E1
MenuNumber           := $E2
MenuItemNumber       := $E3
MenuItemSelectedFlag := $E4
Pointer5             := $E5     ; used for clipboard and menu drawing
Pointer6             := $E7
MenuDrawingIndex     := $E9
DialogHeight         := $EA
DialogWidth          := $EB
ScreenYCoord         := $EC
ScreenXCoord         := $ED
StringPtr            := $EE

;;; also used: $E0 (written, but never read)

DataBuffer         := $B800        ; 1K I/O buffer up to $BC00
BlockBuffer:       := $1000        ; 512-byte buffer for reading a disk block
BackingStoreBuffer := $0800        ; Buffer in aux-mem to store text behind menus

TopMenuLine    :=  2
TopTextLine    :=  3
BottomTextLine := 21
StatusLine     := 23
LastColumn     := 79

VisibleLineCount      := BottomTextLine-TopTextLine+1
MaxLineCount          := $0458
LastLinePointer       := $BBB0
MaxMacroLength        := 70
NumLinesOnPrintedPage := 54
StartingMousePos      := 128

;;; mask for converting lowercase char to uppercase
ToUpperCaseANDMask := %11011111
;;; mask for converting digit char to digit value
CharToDigitANDMask := %00011111
;;; mask for converting digit value to (high ascii) digit char
DigitToCharORMask := %10110000
;;; mask for converting uppercase char to control char
UppercaseToControlCharANDMask := %00011111

        jmp     SysStart

        .byte   ProDOS::InterpreterID
        .byte   ProDOS::InterpreterID
        .byte   ProDOS::MaxPathnameLength+1
DocumentPath:
        .byte   $00 ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

;;; The address to jump to in the calling program
;;; when it is loaded at exit time.
CallingProgramReturnAddr:
        .addr   $0000

;;; The path of the SYS program to launch when this
;;; program exits.
CallingProgramPath:
        .byte   $00 ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

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
        lda     ProDOS::MACHID
        bpl     UnsupportedSystem
        and     #%00110000
        cmp     #$30
        bne     UnsupportedSystem
        lda     Monitor::SUBID1
        cmp     #$EA
        bne     SupportedSystem
UnsupportedSystem:
        ldy     #0
@Loop:  lda     RequiresText,y
        beq     WaitForKeypressAndQuit
        jsr     Monitor::COUT
        iny
        bne     @Loop
WaitForKeypressAndQuit:
        sta     SoftSwitch::KBDSTRB ; Wait for keypress
@Loop:  lda     SoftSwitch::KBD
        bpl     @Loop
        sta     SoftSwitch::KBDSTRB
        cli
QuitToProDOS:
        jsr     ProDOS::MLI
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
        jsr     Monitor::HOME
        lda     CallingProgramPath
        bne     RelocateCode
        lda     #<TitleScreenText
        sta     Pointer
        lda     #>TitleScreenText
        sta     Pointer+1
        ldy     #0
L20FA:  lda     (Pointer),y
        beq     L2108
        jsr     Monitor::COUT
        iny
        bne     L20FA
        inc     Pointer+1
        bra     L20FA
L2108:  ldy     #$14 ; Delay loop
L210A:  phy
        lda     #$FF
        jsr     Monitor::WAIT
        ply
        dey
        bne     L210A
;;; Relocate code at $5A2D-$5D09 to $BC00 (3a2d-3d09 in file,
;;; bytes 14893 - 15625, 733 bytes)
RelocateCode:
        lda     #<$BC00
        sta     ZeroPage::A4L
        lda     #>$BC00
        sta     ZeroPage::A4H
        ldy     #<BC00_Code_Start
        lda     #>BC00_Code_Start
        sty     ZeroPage::A1L
        sta     ZeroPage::A1H
        ldy     #<BC00_Code_End
        lda     #>BC00_Code_End
        sty     ZeroPage::A2L
        sta     ZeroPage::A2H
        ldy     #0
        jsr     Monitor::MOVE
        ldy     #0
L2133:  lda     Page3_Code_Start,y ; Copy 256 bytes from $6C2E to $0300
        sta     $0300,y
        dey
        bne     L2133
;;; Turn on AUX LC RAM bank 1, and copy code at $2ABC-$5A2C to it @ $D000.
;;; (abc - 3a2c in file, bytes 2748-14892, 12145 bytes)
        sei
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        lda     #<$D000
        sta     ZeroPage::A4L
        lda     #>$D000
        sta     ZeroPage::A4H
        ldy     #<MainEditorCode
        lda     #>MainEditorCode
        sty     ZeroPage::A1L
        sta     ZeroPage::A1H
        ldy     #<MainEditor_Code_End
        lda     #>MainEditor_Code_End
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
        lda     #<$D000
        sta     ZeroPage::A4L
        lda     #>$D000
        sta     ZeroPage::A4H
        lda     #<D000_Bank2_Data_Start
        sta     ZeroPage::A1L
        lda     #>D000_Bank2_Data_Start
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
        stz     NumericKeypadBitMask
        lda     #MT_REMAP(MouseText::OverUnderScore)
        sta     TitleBarChar
        lda     #3
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
L21E9:  lda     ProDOS::DEVADR0+1,x
        cmp     #$FF
        beq     L21F7
        dex
        dex
        bne     L21E9
L21F4:  jmp     AfterRAMDiskDisconnected
L21F7:  sta     RAMDiskDriverAddress+1
        lda     ProDOS::DEVADR0,x
        sta     RAMDiskDriverAddress
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
        and     #%11110000      ; slot/drive
        cmp     ReadBlockUnitNum
        beq     L2234
        dex
        bne     L220C
        stx     RAMDiskDriverAddress+1 ; store a 0
        stx     RAMDiskDriverAddress   ; store a 0
        stx     ReadBlockUnitNum
        lda     ProDOS::DEVADR0
        sta     ProDOS::DEVADR0,y
        lda     ProDOS::DEVADR0+1
        sta     ProDOS::DEVADR0+1,y
        jmp     AfterRAMDiskDisconnected
;;; Read volume directory block
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
        bge     L21F4
        ldy     #$25
        lda     BlockBuffer,y   ; file_count == 0?
        ora     BlockBuffer+1,y
        beq     DisconnectRAMDisk ; yes - /RAM is empty
        ldy     #0
L2257:  lda     RemoveRamDiskPrompt,y
        beq     L2262
        jsr     Monitor::COUT
        iny
        bne     L2257
L2262:  lda     BlockBuffer+4
        and     #%00001111      ; volume name length
        tax
        ldy     #0
L226A:  lda     BlockBuffer+5,y ; output volume name
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
        and     #ToUpperCaseANDMask
        cmp     #HICHAR('Y')
        beq     DisconnectRAMDisk
        cmp     #HICHAR('N')
        bne     L227B
        jmp     QuitToProDOS
DisconnectRAMDisk:
        lda     ReadBlockUnitNum
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     ProDOS::DEVADR0
        sta     ProDOS::DEVADR0,x
        lda     ProDOS::DEVADR0+1
        sta     ProDOS::DEVADR0+1,x
        ldx     ProDOS::DEVCNT
        inx
L22A7:  lda     ProDOS::DEVCNT,x
        and     #%11110000
        cmp     ReadBlockUnitNum
        beq     L22B6
        dex
        bne     L22A7
        bra     AfterRAMDiskDisconnected
L22B6:  lda     ProDOS::DEVCNT,x
        sta     RAMDiskUnitNum
L22BC:  lda     ProDOS::DEVLST,x
        sta     ProDOS::DEVCNT,x
        inx
        cpx     ProDOS::DEVCNT
        blt     L22BC
        beq     L22BC
        dec     ProDOS::DEVCNT

AfterRAMDiskDisconnected:
        lda     CallingProgramPath
        beq     L22DB ; branch if no path
        lda     CallingProgramPath+1
        and     #%01111111
        cmp     #'/'
        beq     SaveCallingProgramInfo ; branch if absolute path
L22DB:  lda     ProDOS::SysPathBuf
        beq     L2333 ; branch if no path
        cmp     #ProDOS::MaxPathnameLen+1
        bge     L2333 ; branch if path too long
        tay
L22E5:  lda     ProDOS::SysPathBuf,y ; copy our path
        sta     MacrosFilePathnameBuffer,y ; to macros file path
        dey
        bpl     L22E5
        lda     MacrosFilePathnameBuffer+1
        and     #%01111111
        cmp     #'/'
        beq     L234A ; branch if absolute path
        jsr     ProDOS::MLI ; get prefix
        byte    ProDOS::CGETPREFIX
        .addr   GetSetPrefixParams
        beq     L2302
        jmp     DiskErrorDuringInit
L2302:  lda     PrefixBuffer
        beq     L2333 ; branch if empty prefix
        tay
        pha
L2309:  lda     PrefixBuffer,y ; copy prefix to macros file path
        sta     MacrosFilePathnameBuffer,y
        dey
        bne     L2309
        ply
        ldx     ProDOS::SysPathBuf
        stx     GetFileInfoModDate ; store our pathname length
        ldx     #1
L231B:  iny
        cpy     #ProDOS::MaxPathnameLength+1
        bge     L2333
        lda     ProDOS::SysPathBuf,x ; append our path to macros file path
        sta     MacrosFilePathnameBuffer,y
        inx
        cpx     GetFileInfoModDate
        blt     L231B
        beq     L231B
        sty     MacrosFilePathnameBuffer ; update pathname length
        bra     L234A
L2333:  stz     MacrosFilePathnameBuffer ; there's no macros file
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        lda     #3
        sta     MenuLengths+2 ; remove the "Edit Macros" menu item
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
L234A:  jmp     AfterConfigFilesRead
SaveCallingProgramInfo:
;;; Save calling program path and entry point address.
;;; Get the directory portion of that path; if there is
;;; one, use that as the directory to load config files
;;; from; otherwise, branch backward to use the
;;; directory that this SYS program is in, if possible.
        lda     CallingProgramPath
        tay
L2351:  lda     CallingProgramPath,y
        sta     SavedPathToCallingProgram,y
        dey
        bpl     L2351
        lda     CallingProgramReturnAddr
        sta     JumpToCallingProgram+1
        lda     CallingProgramReturnAddr+1
        ora     CallingProgramReturnAddr
        bne     L236C
        lda     #>ProDOS::SysLoadAddress
        bra     L236F
L236C:  lda     CallingProgramReturnAddr+1
L236F:  sta     JumpToCallingProgram+2
        lda     CallingProgramPath
        tay
L2376:  lda     CallingProgramPath,y ; search backward for slash
        and     #%01111111           ; to get directory part
        cmp     #'/'
        beq     L2385
        dey
        bne     L2376
        jmp     L22DB              ; no slash found
L2385:  sty     GetFileInfoModDate ; save length up to slash
        ldy     #1
L238A:  lda     CallingProgramPath,y ; copy that path
        sta     ProDOS::SysPathBuf,y ; to SysPathBuf
        sta     MacrosFilePathnameBuffer,y ; and to macros file path
        cpy     GetFileInfoModDate
        beq     L239B
        iny
        bra     L238A
L239B:  ldx     #0
L239D:  iny
        lda     TicConfigFilename,x ; append config filename to SysPathBuf
        beq     L23A9
        sta     ProDOS::SysPathBuf,y
        inx
        bra     L239D
L23A9:  dey
        sty     ProDOS::SysPathBuf
        ldy     GetFileInfoModDate
        ldx     #0
L23B2:  iny
        lda     TicEditorFilename,x ; append Macros filename to macros file path
        beq     L23BE
        sta     MacrosFilePathnameBuffer,y
        inx
        bra     L23B2
L23BE:  dey
        sty     MacrosFilePathnameBuffer
        jsr     ProDOS::MLI ; open the config file
        .byte   ProDOS::COPEN
        .addr   OpenParams
        bne     AfterConfigFilesRead ; branch if didn't exist
        lda     OpenRefNum
        sta     ReadRefNum
        sta     CloseRefNum
        stz     GetFileInfoModDate
        jsr     ProDOS::MLI ; read the config file
        .byte   ProDOS::CREAD
        .addr   ReadParams ; 2 bytes requested first
        bne     CloseConfigFile
        lda     MemoryMap::INBUF+1 ; save second byte read
        sta     GetFileInfoModDate
        lda     #$DD ; Read 221 more bytes
        sta     ReadReqCount
        jsr     ProDOS::MLI
        .byte   ProDOS::CREAD
        .addr   ReadParams
CloseConfigFile:
        jsr     ProDOS::MLI ; close the config file
        .byte   ProDOS::CCLOSE
        .addr   CloseParams
        lda     GetFileInfoModDate ; was 2nd byte from file 0?
        beq     AfterConfigFilesRead ; if yes, ignore file contents
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        lda     GetFileInfoModDate ; check 2nd byte again - printer slot #
        beq     AfterPrinterConfigRead ; 0 - invalid
        cmp     #8
        bge     AfterPrinterConfigRead ; >= 8 - invalid
        sta     PrinterSlot ; save printer slot #
        ldy     #20
L2411:  lda     MemoryMap::INBUF+$C9,y ; read printer init string
        sta     PrinterInitStringRawBytes,y ; from last 20 bytes of file
        dey
        bpl     L2411
        ldy     #1
        ldx     #1
L241E:  lda     MemoryMap::INBUF+$C9,y ; create human readable version of
        cmp     #' '                   ; printer init string by encoding
        bge     L2430                  ; control characters as ^ + printable
        pha                            ; character
        lda     #HICHAR('^')
        sta     PrinterInitString,x
        inx
        pla
        clc
        adc     #$40 ; convert control char to uppercase high ascii letter
L2430:  ora     #%10000000
        sta     PrinterInitString,x
        cpy     MemoryMap::INBUF+$C9
        beq     L2440
        iny
        inx
        cpx     #20
        blt     L241E
L2440:  stx     PrinterInitString ; update init string length
AfterPrinterConfigRead:
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
AfterConfigFilesRead:
        jsr     ProDOS::MLI ; get the prefix
        .byte   ProDOS::CGETPREFIX
        .addr   GetSetPrefixParams
        bne     DiskErrorDuringInit
        lda     PrefixBuffer
        bne     L24AF ; branch if prefix not empty
        lda     DocumentPath+1
        and     #%01111111
        cmp     #'/'
        beq     L24AF ; branch if document path is absolute
;;; Document path is relative, and there's no prefix. Assume it's
;;; relative to the volume directory of the last accessed volume.
        lda     ProDOS::DEVNUM ; Get volume name of current volume
        sta     OnLineUnitNum
        jsr     ProDOS::MLI
        .byte   ProDOS::ON_LINE
        .addr   OnLineParams
        bne     DiskErrorDuringInit
        lda     OnLineBuffer
        and     #%00001111
        beq     DiskErrorDuringInit
        sta     PrefixBuffer ; Copy it to PrefixBuffer,
        inc     PrefixBuffer ; prepending and appending a slash
        ldy     #1           ; as needed
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
L2494:  jsr     ProDOS::MLI ; Set the prefix to this volume
        .byte   ProDOS::CSETPREFIX
        .addr   GetSetPrefixParams
        beq     L24AF
DiskErrorDuringInit:
        jsr     Monitor::HOME
        ldy     #0
L24A1:  lda     DiskErrorOccurredText,y
        beq     L24AC
        jsr     Monitor::COUT
        iny
        bne     L24A1
L24AC:  jmp     WaitForKeypressAndQuit
L24AF:  lda     ProDOS::MACHID
        lsr     a
        bcs     L24B6 ; Branch if clock/calendar card present
        iny
L24B6:  sty     $E0 ; meant to be clock/calendar flag? never read
;;; Search for mouse slot
        lda     #8
        sta     MouseSlot
L24BC:  dec     MouseSlot
        lda     MouseSlot
        beq     L24D9
        ora     #%11000000
        sta     Pointer+1
        lda     #0
        sta     Pointer
        ldx     #5
L24CC:  ldy     MouseSignatureByteOffsets,x
        lda     (Pointer),y
        cmp     MouseSignatureByteValues,x
        bne     L24BC
        dex
        bpl     L24CC
;;; Set reset vector
L24D9:  sta     SoftSwitch::KBDSTRB
        lda     #<ResetHandler
        sta     Vector::SOFTEV
        lda     #>ResetHandler
        sta     Vector::SOFTEV+1
        jsr     Monitor::SETPWRC
;;; Copy zero page from main to aux mem.
        ldy     #0
L24EB:  sty     SoftSwitch::SETSTDZP
        lda     $00,y
        sty     SoftSwitch::SETALTZP
        sta     $00,y
        dey
        bne     L24EB
;;; Set up mouse firmware entry points
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        lda     MouseSlot
        beq     GenerateLinePointerTables
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

LinePointerTable           := $0800

LineCountForMainMem        := $0213 ; (531 lines)
LineCountForAuxMem         := $0245 ; (581 lines)
FirstLinePointerForMainMem := $1200
FirstLinePointerForAuxMem  := $0A31

GenerateLinePointerTables:
        lda     #<LinePointerTable
        sta     Pointer
        lda     #>LinePointerTable
        sta     Pointer+1
        lda     #<LineCountForMainMem
        sta     LinePointerCount
        lda     #>LineCountForMainMem
        sta     LinePointerCount+1
        lda     #<FirstLinePointerForMainMem
        sta     LinePointer
        lda     #>FirstLinePointerForMainMem
        sta     LinePointer+1
        jsr     GenerateLinePointerTable
        lda     #<LineCountForAuxMem
        sta     LinePointerCount
        lda     #>LineCountForAuxMem
        sta     LinePointerCount+1
        lda     #<FirstLinePointerForAuxMem
        sta     LinePointer
        lda     #>FirstLinePointerForAuxMem
        sta     LinePointer+1
        jsr     GenerateLinePointerTable
        lda     DocumentPath
        bne     LoadInitialDocument
        jmp     StartWithEmptyDocument
LoadInitialDocument:
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        lda     #<DocumentPath
        sta     GetFileInfoPathname
        lda     #>DocumentPath
        sta     GetFileInfoPathname+1
        jsr     ProDOS::MLI ; get document info
        .byte   ProDOS::CGETFILEINFO
        .addr   GetFileInfoParams
        bne     NoInitialDocument
        lda     GetFileInfoFileType
        cmp     #FileType::DIR
        beq     NoInitialDocument ; can't open a directory
        lda     DocumentPath
        sta     ProDOS::SysPathBuf
        tay
L2596:  lda     DocumentPath,y
        sta     ProDOS::SysPathBuf,y
        dey
        bne     L2596
        lda     #$FF
        sta     PathnameLength ; set to nonzero to force load dialog
NoInitialDocument:
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
StartWithEmptyDocument:
        jsr     LoadFirstLinePointer
        jsr     MoveCursorToHomePos
        jsr     SetDocumentLineCountToCurrentLine ; empty document
        lda     #$80 ; empty line with CR
        sta     FirstLinePointerForMainMem
        ldy     DocumentPath ; copy DocumentPath
@Loop:  lda     DocumentPath,y
        sta     PathnameBuffer,y
        dey
        bpl     @Loop
        jmp     MainEditorStart

;;; This creates a pointer table, starting at (Pointer), of length
;;; LinePointerCount. The first pointer's value is LinePointer and
;;; each subsequent pointer is 80 + the previous pointer.
GenerateLinePointerTable:
        ldy     #0
        lda     LinePointer
        sta     (Pointer),y     ; *Pointer = LinePointer
        iny
        lda     LinePointer+1
        sta     (Pointer),y
        lda     Pointer
        clc
        adc     #2            ; Pointer += 2
        sta     Pointer
        bcc     L25E2
        inc     Pointer+1
L25E2:  lda     LinePointer
        clc
        adc     #80            ; LinePointer += 80
        sta     LinePointer
        bcc     L25F0
        inc     LinePointer+1
L25F0:  dec     LinePointerCount    ; LinePointerCount -= 1
        lda     LinePointerCount
        cmp     #$FF
        bne     L25FD
        dec     LinePointerCount+1
L25FD:  lda     LinePointerCount+1  ; loop until LinePointerCount == 0
        ora     LinePointerCount
        bne     GenerateLinePointerTable
        rts

TitleScreenText:
        highascii "\r\r"
        repeatbyte HICHAR('_'), 80
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 24
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('[')
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(ControlChar::MouseTextOff)
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 25
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('[')
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(ControlChar::MouseTextOff)
        highascii "  Ed-It! - A Text File Editor"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 24
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('[')
        .byte   HICHAR(ControlChar::NormalVideo)
        .bye    HICHAR(ControlChar::MouseTextOff)
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 34
        highascii "by Bill Tudor"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 28
        repeatbyte HICHAR('_'), 25
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 27
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('Z')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        highascii " Northeast Micro Systems "
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('_')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 27
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('Z')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        highascii "   1220 Gerling Street   "
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('_')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 27
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('Z')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        highascii "  Schenectady, NY 12308  "
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('_')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 27
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('Z')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        highascii "   Tel. (518) 370-3976   "
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        .byte   HICHAR('_')
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 28
        .byte   ControlChar::InverseVideo
        .byte   ControlChar::MouseTextOn
        repeatbyte HICHAR('L'), 25
        .byte   ControlChar::NormalVideo
        .byte   ControlChar::MouseTextOff
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 32
        highascii "Copyright 1988-89"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 31
        highascii "ALL RIGHTS RESERVED"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 33
        highascii "Sept. 89  v3.00"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR('_'), 80
        .byte   $00

RequiresText:
        highascii "ED-IT! REQUIRES AN APPLE //C\r"
        highascii "ENHANCED //E, OR APPLE IIGS\r"
        highascii "WITH AT LEAST 128K RAM AND\r"
        highasciiz "AN 80-COLUMN CARD."

DiskErrorOccurredText:
        highascii "DISK-RELATED ERROR OCCURRED!"
        .byte   HICHAR(ControlChar::Bell)
        .byte   $00

RemoveRamDiskPrompt:
        highascii "\r\rAuxillary 64K RamDisk found!\r"
        highasciiz "OK to remove files on /\r"

        highasciiz "Loading EDIT.CONFIG.."

MouseSignatureByteOffsets:
        .byte   $05,$07,$0B,$0C,$FB,$11
MouseSignatureByteValues:
        .byte   $38,$18,$01,$20,$D6,$00

LinePointerCount:
        .word   $0000
LinePointer:
        .addr   $0000

TicConfigFilename:
        .asciiz "TIC.CONFIG"
TicEditorFilename:
        .asciiz "TIC.EDITOR"

;;; 64-byte buffer (unused?)
L2A4D:
        repeatbyte $00, 64

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
GetFileInfoPathname:
        .addr   $0000
        .byte   $00             ; access
GetFileInfoFileType:
        .byte   $00

        .word   $0000           ; aux_type
        .byte   $00             ; storage_type
        .word   $0000           ; blocks_used
GetFileInfoModDate:
        .word   $0000           ; mod_date
        .word   $0000           ; mod_time
        .word   $0000           ; create_date
        .word   $0000           ; create_time

        .reloc

;;; This code gets relocated to $D000 (bank 1) to $FF70 in LCRAM

MainEditorCodeStart := *

        .org $D000

MainEditorStart:
        jsr     ClearTextWindow
        jsr     DrawMenuBarAndMenuTitles
LD006:  jsr     OutputStatusBarLine
        lda     #TopTextLine
        sta     ZeroPage::WNDTOP
        lda     #BottomTextLine+1
        sta     ZeroPage::WNDBTM
        jsr     ClearTextWindow
        bit     PathnameLength
        beq     MainEditor
        jmp     LoadFile

MainEditor:
        jsr     DisplayDefaultStatusText
        jsr     DisplayHelpKeyCombo
        jsr     DisplayLineAndColLabels
MainEditorRedrawDocument:
        jsr     DisplayAllVisibleDocumentLines
        bra     MainEditorInputLoop
MainEditorRedrawCurrentLine:
        ldy     CurrentCursorYPos
        ldx     CurrentCursorXPos
        jsr     SetCursorPosToXY
        jsr     DrawCurrentDocumentLine
MainEditorInputLoop:
        jsr     DisplayCurrentLineAndCol
        ldy     CurrentCursorYPos
        ldx     CurrentCursorXPos
        jsr     SetCursorPosToXY
        jsr     GetKeypress
        bmi     LD063 ; branch if not OpenApple command
        cmp     #ControlChar::Esc
        beq     LD067
LD04B:  ldy     OpenAppleKeyComboTable
LD04E:  cmp     OpenAppleKeyComboTable,y
        beq     LD05C
        dey
        bne     LD04E
        jsr     PlayTone
        jmp     MainEditorInputLoop
LD05C:  dey
        tya
        asl     a
        tax
        jmp     (OpenAppleKeyComboJumpTable,x)
LD063:  cmp     #HICHAR(ControlChar::Esc)
        bne     LD06C
LD067:  jsr     StartMenuNavigation
        bra     MainEditor
LD06C:  pha
        txa
NumericKeypadBitMask := *+1
        and     #%00010000 ; test numeric keypad bit
        beq     LD085      ; branch if not keypad key
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
LD086:  cmp     #HICHAR(ControlChar::Delete)
        bne     LD08D
        jmp     DeleteChar
LD08D:  cmp     #HICHAR(' ')
        blt     HandleControlChars
        jmp     ProcessOrdinaryInputChar
HandleControlChars:
        ldy     EditingControlKeyTable
LD097:  cmp     EditingControlKeyTable,y
        beq     LD0A5
        dey
        bne     LD097
        jsr     PlayTone
        jmp     MainEditorInputLoop
LD0A5:  dey
        tya
        asl     a
        tax
        jmp     (EditingControlKeyJumpTable,x)

;;; Handlers for menu items in "Utilities" menu
SetNewPrefix:
        ldx     #1 ; New Prefix
        bra     LD0B6
ListVolumes:
        ldx     #2 ; Volumes
        bra     LD0B6
ListDirectory:
        ldx     #0 ; Directory
LD0B6:  lda     #1 ; Menu number 1
        bra     DispatchToMenuItemHandler

;;; Handlers for menu items in "File" menu
ShowAboutBox:
        ldx     #0 ; About
        bra     LD0DB
PrintDocument:
        ldx     #3 ; Print
        bra     LD0DB
QuitEditor:
        ldx     #5 ; Quit
        bra     LD0DB
LoadFile:
        ldx     #1 ; Load File
        bra     LD0DB
SaveFile:
        ldx     #2 ; Save/Save As
        lda     PathnameBuffer
        beq     LD0DB
        sta     PathnameLength
        sta     CurrentDocumentPathnameLength
        bra     LD0DB
ClearMemory:
        ldx     #4 ; Clear Memory
LD0DB:  lda     #0 ; Menu number 0

;;; Dispatch to menu item handler; menu # in A, menu item # in X.
DispatchToMenuItemHandler:
        jsr     StartMenuNavigationAtMenuItem
        jmp     MainEditor

ForwardTab:
        ldy     CurrentCursorXPos
@Loop:  cpy     LastEditableColumn
        beq     @Done
        iny
        lda     TabStops,y
        beq     @Loop
@Done:  sty     CurrentCursorXPos
        jmp     MainEditorInputLoop

BackwardTab:
        ldy     CurrentCursorXPos
@Loop:  cpy     #0
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
        beq     @MoveUp
        dec     CurrentCursorXPos
        jmp     MainEditorInputLoop
@MoveUp:
        jsr     IsOnFirstDocumentLine
        beq     LD157
        jsr     MoveToPreviousDocumentLine
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        sta     CurrentCursorXPos
        jmp     MainEditorRedrawDocument

MoveUpOneLine:
        jsr     IsOnFirstDocumentLine
        beq     @Done
        jsr     MoveToPreviousDocumentLine
@Done:  jmp     MainEditorInputLoop

MoveRightOneChar:
        lda     CurrentCursorXPos
        cmp     LastEditableColumn
        beq     @MoveDown
        inc     CurrentCursorXPos
        jmp     MainEditorInputLoop
@MoveDown:
        jsr     IsOnLastDocumentLine
        bne     LD15A
LD157:  jmp     MainEditorInputLoop
LD15A:  stz     CurrentCursorXPos
;;; falls through

MoveDownOneLine:
        jsr     IsOnLastDocumentLine
        beq     @Done
        jsr     MoveToNextDocumentLine
@Done:  jmp     MainEditorInputLoop

PageUp:
        jsr     IsOnFirstDocumentLine
        beq     LD165
        lda     CurrentCursorYPos
        cmp     #TopTextLine
        beq     LD186
        sec
        sbc     #TopTextLine
        tay
LD178:  jsr     DecrementCurrentLineNumber
        dey
        bne     LD178
        lda     #TopTextLine
        sta     CurrentCursorYPos
        jmp     MainEditorInputLoop
;;;  back one screenful
LD186:  ldy     #VisibleLineCount
LD188:  jsr     DecrementCurrentLineNumber
        dey
        bne     LD188
        lda     CurrentLineNumber+1
        cmp     #$FF
        beq     LD19A
        ora     CurrentLineNumber
        bne     LD19D
LD19A:  jsr     LoadFirstLinePointer
LD19D:  lda     #TopTextLine
        sta     CurrentCursorYPos
        jsr     MainEditorRedrawDocument ; should be a jmp

PageDown:
        jsr     IsOnLastDocumentLine
        beq     LD165
        lda     #BottomTextLine
        cmp     CurrentCursorYPos
        beq     LD1D3
        sec
        sbc     CurrentCursorYPos
        sta     ScratchVal4
        ldy     #0
LD1BA:  jsr     IsOnLastDocumentLine
        beq     LD1C8
        jsr     LoadNextLinePointer
        iny
        cpy     ScratchVal4
        bne     LD1BA
LD1C8:  tya
        clc
        adc     CurrentCursorYPos
        sta     CurrentCursorYPos
        jmp     MainEditorInputLoop
LD1D3:  ldy     #VisibleLineCount
LD1D5:  jsr     LoadNextLinePointer
        jsr     IsOnLastDocumentLine
        beq     LD1E0
        dey
        bne     LD1D5
LD1E0:  jmp     MainEditorRedrawDocument

MoveLeftOneWord:
        lda     CurrentCursorXPos
        bne     LD1F2
        jsr     IsOnFirstDocumentLine
        beq     LD20F
        jsr     MoveToPreviousDocumentLine
        bra     MoveToEndOfLine
LD1F2:  jsr     IsCursorAtEndOfLine
        bcc     MoveToEndOfLine
        ldy     CurrentCursorXPos
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        bne     LD204
        jsr     SkipSpacesBackward
LD204:  jsr     SkipNonSpacesBackward
        cpy     #0
        beq     LD20C
        dey
LD20C:  sty     CurrentCursorXPos
LD20F:  jmp     MainEditorInputLoop

MoveRightOneWord:
        lda     CurrentCursorXPos
        cmp     #77
        bge     LD236
        ldy     CurrentCursorXPos
        iny
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     LD227
        jsr     SkipNonSpacesForward
LD227:  jsr     SkipSpacesForward
        dey
        sty     CurrentCursorXPos
        jsr     IsCursorAtEndOfLine
        bcc     LD236
        jmp     MainEditorInputLoop
LD236:  jsr     IsOnLastDocumentLine
        beq     MoveToEndOfLine
        jsr     MoveToNextDocumentLine

MoveToBeginningOfLine:
        lda     #0
        sta     CurrentCursorXPos
        jmp     MainEditorInputLoop

MoveToEndOfLine:
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        cmp     DocumentLineLength
        bne     LD251
        dec     a
LD251:  sta     CurrentCursorXPos
        jmp     MainEditorInputLoop

MoveToBeginningOfDocument:
        jsr     LoadFirstLinePointer
        stz     CurrentCursorXPos
        lda     #TopTextLine
        sta     CurrentCursorYPos
        jmp     MainEditorRedrawDocument

MoveToEndOfDocument:
        jsr     IsOnLastDocumentLine
        beq     LD275
@Loop:  jsr     LoadNextLinePointer
        jsr     IsOnLastDocumentLine
        bne     @Loop
        jsr     DisplayAllVisibleDocumentLines
LD275:  jmp     MoveToEndOfLine

ToggleShowCR:
        lda     ShowCRFlag
        eor     #%10000000
        sta     ShowCRFlag
        jmp     MainEditorRedrawDocument

ClearToEndOfCurrentLine:
        jsr     IsCursorAtEndOfLine
        bcc     LD2C6 ; nothing to do
        stz     DocumentChangedFlag
        jsr     GetLengthOfCurrentLine
        and     #%10000000 ; preserve CR bit
        ora     CurrentCursorXPos
        jsr     SetLengthOfCurrentLine ; truncate line
        jsr     IsOnFirstDocumentLine
        beq     LD2C0 ; yes - word wrap rest of line
        jsr     LoadPreviousLinePointer
        jsr     GetLengthOfCurrentLine
        bmi     LD2BD ; branch if has CR
        and     #%01111111
        clc
        adc     CurrentCursorXPos ; will the remaining text fit
        cmp     LastEditableColumn ; on the previous line?
        bge     LD2BD ; branch if no
        sta     CurrentCursorXPos
        jsr     WordWrapUpToNextCR ; word wrap rest of line
        jsr     LoadNextLinePointer
        jsr     MoveToPreviousDocumentLine
        jmp     MainEditorRedrawDocument
LD2BD:  jsr     LoadNextLinePointer ; word wrap rest of line
LD2C0:  jsr     WordWrapUpToNextCR
        jsr     MainEditorRedrawDocument
LD2C6:  jmp     MainEditorInputLoop

CarriageReturn:
        jsr     CheckIfMemoryFull
        beq     LD2C6 ; can't insert a new line
        stz     DocumentChangedFlag
        jsr     InsertNewLine
        jsr     IsCursorAtEndOfLine
        bcc     LD2E1 ; branch if yes
        beq     LD2E1 ; branch if empty line
        ldy     CurrentCursorXPos
        jsr     SplitLineAtCursor
LD2E1:  stz     CurrentCursorXPos
        jsr     GetLengthOfCurrentLine
        ora     #%10000000 ; set CR flag
        jsr     SetLengthOfCurrentLine
        jsr     MoveToNextDocumentLine
        jsr     GetLengthOfCurrentLine
        bne     LD2F9 ; branch if next line isn't empty
        ora     #%10000000 ; set CR flag
        jsr     SetLengthOfCurrentLine
LD2F9:  jsr     WordWrapUpToNextCR
        jmp     MainEditorRedrawDocument

;;; Process ordinary, non-command keypresses.
ProcessOrdinaryInputChar:
        stz     DocumentChangedFlag
        and     #%01111111
        pha
        jsr     IsCursorAtEndOfLine
        beq     LD374
        bcc     LD371
        lda     CurrentCursorChar
        cmp     InsertCursorChar
        bne     LD317
        jmp     LD3CD
;;; Overwrite mode
LD317:  ldy     CurrentCursorXPos
        iny
        pla
        jsr     SetCharAtYInCurrentLine
        sty     CurrentCursorXPos
LD322:  cmp     #' '
        bne     LD36E
;;; see if the word just completed would fit on the previous line?
        jsr     GetSpaceLeftOnPreviousLine
        cmp     CurrentCursorXPos
        blt     LD36E ; no...won't fit
;;;  copy text up to cursor in current line into INBUF
        ldy     CurrentCursorXPos
LD331:  jsr     GetCharAtYInCurrentLine
        sta     MemoryMap::INBUF,y
        dey
        bne     LD331
        ldx     CurrentCursorXPos
        stx     MemoryMap::INBUF
;;;  set length of current line to 0
        stz     CurrentCursorXPos
LD343:  ldy     #1
        jsr     RemoveCharAtYOnCurrentLine
        dex
        bne     LD343
        jsr     LoadPreviousLinePointer
        jsr     GetLengthOfCurrentLine
        tay
        ldx     #0
LD354:  iny
        inx
        lda     MemoryMap::INBUF,x
        jsr     SetCharAtYInCurrentLine
        dec     MemoryMap::INBUF
        bne     LD354
        tya
        jsr     SetLengthOfCurrentLine
        jsr     LoadNextLinePointer
        jsr     WordWrapUpToNextCR
        jmp     MainEditorRedrawDocument
LD36E:  jmp     MainEditorRedrawCurrentLine
LD371:  jsr     PadLineWithSpacesUpToCursor
LD374:  ldy     CurrentCursorXPos
        cpy     LastEditableColumn
        bge     LD386
;;; increment line length by 1
        jsr     GetLengthOfCurrentLine
        inc     a
        jsr     SetLengthOfCurrentLine
        jmp     LD317
LD386:  jsr     CheckIfMemoryFull
        bne     LD38E
        jmp     LD435
LD38E:  jsr     InsertNewLine
        ldy     LastEditableColumn
LD394:  jsr     GetCharAtYInCurrentLine
        cmp     #$20
        beq     LD3A5
        dey
        bne     LD394
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        bra     LD3B0
LD3A5:  sty     CurrentCursorXPos
        jsr     SplitLineAtCursor
        jsr     GetLengthOfCurrentLine
        and     #%01111111
LD3B0:  jsr     SetLengthofCurrentLine
        jsr     MoveToNextDocumentLine
        jsr     GetLengthOfCurrentLine
        inc     a
        jsr     SetLengthOfCurrentLine
        and     #%01111111
        tay
        pla
        jsr     SetCharAtYInCurrentLine
        sty     CurrentCursorXPos
        jsr     WordWrapUpToNextCR
        jmp     MainEditorRedrawDocument
;;; Insert mode
LD3CD:  jsr     GetLengthOfCurrentLine
        sta     ScratchVal4
        and     #%01111111
        cmp     LastEditableColumn
        bge     LD401
        inc     a
        tay
        bit     ScratchVal4
        bpl     LD3E3
        ora     #%10000000
LD3E3:  jsr     SetLengthOfCurrentLine
LD3E6:  dey
        jsr     GetCharAtYInCurrentLine
        iny
        jsr     SetCharAtYInCurrentLine
        dey
        cpy     CurrentCursorXPos
        beq     LD3F6
        bge     LD3E6
LD3F6:  pla
        iny
        jsr     SetCharAtYInCurrentLine
        inc     CurrentCursorXPos
        jmp     LD322
;;; char won't fit on current line
LD401:  jsr     CheckIfMemoryFull
        beq     LD435
        jsr     MoveWordToNextLine
        jsr     MoveToNextDocumentLine
        jsr     WordWrapUpToNextCR
        jsr     DisplayAllVisibleDocumentLines
        jsr     MoveToPreviousDocumentLine
        jsr     IsCursorAtEndOfLine
        bcs     LD3CD
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        sta     ScratchVal4
        lda     CurrentCursorXPos
        sec
        sbc     ScratchVal4
        sta     CurrentCursorXPos
        jsr     MoveToNextDocumentLine
        jmp     LD3CD
        jsr     PlayTone        ;unreachable instruction
LD435:  pla
        jmp     MainEditorInputLoop

DeleteChar:
        stz     DocumentChangedFlag
        lda     CurrentCursorXPos
        beq     LD4B1
LD441:  jsr     IsCursorAtEndOfLine
        bcs     LD465
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        sta     CurrentCursorXPos
        beq     LD477
        jsr     GetLengthOfCurrentLine
        bpl     LD465
        and     #%01111111
        jsr     SetLengthOfCurrentLine
LD45A:  jsr     WordWrapUpToNextCR
        beq     LD462
        jmp     MainEditorRedrawDocument
LD462:  jmp     MainEditorRedrawCurrentLine
LD465:  dec     CurrentCursorXPos
        ldy     CurrentCursorXPos
        iny
        cpy     DocumentLineLength
        bge     LD474
        jsr     RemoveCharAtYOnCurrentLine
LD474:  jsr     GetLengthOfCurrentLine
LD477:  beq     LD4EC
        and     #%01111111
        sta     ScratchVal4
        ldy     #0
LD480:  iny
        jsr     GetCharAtYInCurrentLine
        cmp     #$20
        beq     LD48E
        iny
        cpy     ScratchVal4
        blt     LD480
LD48E:  sty     ScratchVal4
        jsr     GetSpaceLeftOnPreviousLine
        cmp     ScratchVal4
        blt     LD45A
        beq     LD45A
        sta     ScratchVal6
        lda     DocumentLineLength
        sec
        sbc     ScratchVal6
        clc
        adc     CurrentCursorXPos
        sta     CurrentCursorXPos
        jsr     MoveToPreviousDocumentLine
        bra     LD45A
LD4B1:  jsr     IsOnFirstDocumentLine
        beq     LD532
        jsr     GetLengthOfCurrentLine
        pha
        and     #%01111111
        bne     LD4DE           ; anything to delete on this line?
        jsr     IsOnLastDocumentLine
        beq     LD4C6
        jsr     ShiftLinePointersUpForDelete
LD4C6:  jsr     DecrementDocumentLineCount
        pla
        bpl     LD4DE
        jsr     MoveToPreviousDocumentLine
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        sta     CurrentCursorXPos
        ora     #%10000000
        jsr     SetLengthOfCurrentLine
        bra     LD512           ; done
LD4DE:  jsr     MoveToPreviousDocumentLine
        jsr     GetLengthOfCurrentLine
        sta     CurrentCursorXPos
        beq     LD4EC
        jmp     LD441
LD4EC:  jsr     IsOnLastDocumentLine
        beq     LD4F4
        jsr     ShiftLinePointersUpForDelete
LD4F4:  jsr     DecrementDocumentLineCount
        lda     DocumentLineCount
        ora     DocumentLineCount+1
        bne     LD515
        jsr     SetDocumentLineCountToCurrentLine
LD502:  jsr     GetLengthOfCurrentLine
        and     #%01111111
        sta     CurrentCursorXPos
        jmp     MainEditorRedrawDocument

;;; no label?
        lda     #$80
        jsr     SetLengthOfCurrentLine
LD512:  jmp     MainEditorRedrawDocument

LD515:  lda     CurrentLineNumber+1
        cmp     DocumentLineCount+1
        blt     LD512           ; done
        lda     DocumentLineCount
        cmp     CurrentLineNumber
        bge     LD512           ; done
        jsr     MoveToPreviousDocumentLine
        bra     LD502

DeleteForwardChar:
        lda     CurrentCursorXPos
        cmp     LastEditableColumn
        blt     LD538
LD532:  jsr     PlayTone
LD535:  jmp     MainEditorInputLoop
LD538:  jsr     IsCursorAtEndOfLine
        bcc     LD535
        beq     LD545
LD53F:  inc     CurrentCursorXPos
        jmp     DeleteChar
LD545:  jsr     GetLengthOfCurrentLine
        bmi     LD53F
        bra     LD535

ClearCurrentLine:
        jsr     IsOnLastDocumentLine
        bne     LD568
        jsr     IsOnFirstDocumentLine
        bne     LD55C
        stz     CurrentCursorXPos
        jmp     ClearToEndOfCurrentLine
LD55C:  jsr     DecrementDocumentLineCount
        jsr     MoveToPreviousDocumentLine
LD562:  stz     DocumentChangedFlag
        jmp     MainEditorRedrawDocument
LD568:  jsr     ShiftLinePointersUpForDelete
        jsr     DecrementDocumentLineCount
        bra     LD562

BlockDelete:
        lda     CurrentCursorXPos
        pha
        lda     CurrentCursorYPos
        pha
        jsr     PerformBlockSelection
        bcc     LD588
        pla
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        jmp     MainEditor
LD588:  lda     CurLinePtr
        cmp     SavedCurLinePtr2
        bne     LD5AF
        lda     CurLinePtr+1
        cmp     SavedCurLinePtr2+1
        bne     LD5AF
        jsr     DisplayDefaultStatusText
        jsr     DisplayHelpKeyCombo
        pla
        sta     CurrentCursorYPos
        tay
        pla
        sta     CurrentCursorXPos
        tax
        jsr     SetCursorPosToXY
        jsr     DisplayLineAndColLabels
        jmp     ClearCurrentLine
LD5AF:  stz     DocumentChangedFlag
        lda     #<TD964 ; "Please Wait.."
        ldx     #>TD964
        jsr     DisplayStringInStatusLine
        lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber2+1
        blt     LD5E3
        beq     LD5DB
LD5C3:  lda     CurrentLineNumber
        sec
        sbc     SavedCurrentLineNumber2
        sta     ScratchVal4
        lda     CurrentLineNumber+1
        sbc     SavedCurrentLineNumber2+1
        sta     ScratchVal6
        jsr     RestoreCurrentLineState2
        bra     LD5F6
LD5DB:  lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber2
        bge     LD5C3
LD5E3:  lda     SavedCurrentLineNumber2
        sec
        sbc     CurrentLineNumber
        sta     ScratchVal4
        lda     SavedCurrentLineNumber2+1
        sbc     CurrentLineNumber+1
        sta     ScratchVal6
LD5F6:  jsr     ShiftLinePointersUpForDelete
        jsr     DecrementDocumentLineCount
        dec     ScratchVal4
        lda     ScratchVal4
        cmp     #$FF
        bne     LD5F6
        dec     ScratchVal6
        lda     ScratchVal6
        cmp     #$FF
        bne     LD5F6
        pla
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        lda     DocumentLineCount+1
        cmp     CurrentLineNumber+1
        bge     LD62A
LD620:  jsr     IsOnFirstDocumentLine
        beq     LD632
        jsr     LoadPreviousLinePointer
        bra     LD632
LD62A:  lda     DocumentLineCount
        cmp     CurrentLineNumber
        blt     LD620
LD632:  lda     DocumentLineCount
        ora     DocumentLineCount+1
        bne     LD645
        jsr     LoadFirstLinePointer
        jsr     SetDocumentLineCountToCurrentLine
        lda     #0
        jsr     SetLengthOfCurrentLine
LD645:  lda     CurrentLineNumber+1
        bne     LD667
        lda     CurrentLineNumber
        cmp     #20
        bge     LD667
        lda     CurrentCursorYPos
        sec
        sbc     #2
        cmp     CurrentLineNumber
        blt     LD667
        beq     LD667
        lda     CurrentLineNumber
        clc
        adc     #2
        sta     CurrentCursorYPos
LD667:  jmp     MainEditor

;;;  Copy text to/from clipboard
CopyToOrFromClipboard:
        lda     #<TD5D0 ; "Copy to or from..."
        ldx     #>TD5D0
        jsr     DisplayStringInStatusLineWithEscToGoBack
LD671:  jsr     GetKeypress
        and     #ToUpperCaseANDMask
        cmp     #HICHAR(ControlChar::Esc)
        beq     LD6A4
        cmp     #HICHAR('T')
        beq     LD6E1
        cmp     #HICHAR('F')
        beq     LD687
        jsr     PlayTone
        bra     LD671
LD687:  lda     DataBuffer
        beq     LD69A
        lda     DataBuffer+1
        cmp     #$FF
        bne     LD69A
        lda     DataBuffer+2
        cmp     #$FF
        beq     LD6A7
LD69A:  lda     #<TD5F8 ; "Clipboard is empty"
        ldx     #>TD5F8
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     BeepAndWaitForReturnOrEscKey
LD6A4:  jmp     MainEditor
LD6A7:  jsr     DisplayPleaseWaitForClipboard
        jsr     SaveCurrentLineState
        lda     DataBuffer
        sta     LD77D
LD6B3:  jsr     CheckIfMemoryFull
        beq     LD6DB
        jsr     InsertNewLine
        jsr     LoadNextLinePointer
        lda     (Pointer5)
        and     #%01111111
        tay
LD6C3:  lda     (Pointer5),y
        jsr     SetCharAtYInCurrentLine
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
LD6DB:  jsr     RestoreCurrentLineState
        jmp     MainEditor
LD6E1:  lda     CurrentCursorXPos
        pha
        lda     CurrentCursorYPos
        pha
        jsr     PerformBlockSelection
        bcc     LD6F9
LD6EE:  pla
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        jmp     MainEditor
LD6F9:  jsr     DisplayPleaseWaitForClipboard
        lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber2+1
        blt     LD716
        bne     LD70E
        lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber2
        blt     LD716
LD70E:  jsr     SaveCurrentLineState
        jsr     RestoreCurrentLineState2
        bra     LD721
LD716:  ldy     #3
LD718:  lda     SavedCurLinePtr2,y
        sta     SavedCurLinePtr,y
        dey
        bpl     LD718
LD721:  stz     DataBuffer
        lda     #$FF
        sta     DataBuffer+1
        sta     DataBuffer+2
LD72C:  jsr     GetLengthOfCurrentLine
        and     #%01111111
        tay
LD732:  jsr     GetCharAtYInCurrentLine
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
        cmp     #>LastLinePointer
        blt     LD754
        lda     Pointer5
        cmp     #<LastLinePointer
        bge     LD771
LD754:  lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber+1
        blt     LD766
        bne     LD76B
        lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber
        bge     LD76B
LD766:  jsr     LoadNextLinePointer
        bra     LD72C
LD76B:  jsr     RestoreCurrentLineState2
        jmp     LD6EE
LD771:  lda     #<TD60C ; "Clipboard is full"
        ldx     #>TD60C
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     BeepAndWaitForReturnOrEscKey
        bra     LD76B
LD77D:  .byte   $00

;;; display "please wait" and load Pointer5 with beginning
;;; of clipboard data
DisplayPleaseWaitForClipboard:
        lda     #<TD964 ; "Please wait.."
        ldx     #>TD964
        jsr     DisplayStringInStatusLine
        lda     #<DataBuffer+3
        sta     Pointer5
        lda     #>DataBuffer
        sta     Pointer5+1
        rts

EditTabStops:
        lda     CurrentCursorXPos
        sta     ScratchVal1
        lda     #24
        sta     ZeroPage::WNDBTM
        lda     #<TD6A2 ; Tab stop editing instructions
        ldx     #>TD6A2
        jsr     DisplayStringInStatusLine
;;; draw ruler with tab stops
LD79F:  ldy     #22
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     #80
        jsr     OutputDashedLine
        ldy     #22
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     #0
LD7B4:  lda     TabStops,y
        beq     LD7BF
        sty     Columns80::OURCH
        jsr     OutputDiamond
LD7BF:  iny
        cpy     DocumentLineLength
        blt     LD7B4
LD7C5:  ldy     #StatusLine
        ldx     #75
        jsr     SetCursorPosToXY
        lda     ScratchVal1
        inc     a
        ldx     #0
        ldy     #2
        jsr     DisplayAXInDecimal
        ldy     #22
        ldx     ScratchVal1
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
;;; Set tab stop
LD80E:  ldy     ScratchVal1
        lda     TabStops,y
        beq     LD81C
        inc     a
LD817:  sta     TabStops,y
        bra     LD79F
LD81C:  dec     a
        bne     LD817
;;; Move left
LD81F:  lda     ScratchVal1
        beq     LD829
        dec     ScratchVal1
        bra     LD7C5
LD829:  lda     LastEditableColumn
        sta     ScratchVal1
        bra     LD7C5
;;; Move right
LD831:  lda     ScratchVal1
        cmp     LastEditableColumn
        bne     LD83E
        stz     ScratchVal1
        bra     LD7C5
LD83E:  inc     ScratchVal1
        bne     LD7C5
;;; Done editing
LD843:  jmp     LD006
;;; Clear all tab stops
LD846:  ldx     LastEditableColumn
LD849:  stz     TabStops,x
        dex
        bpl     LD849
        bra     LD862
;;; Move text tab
LD851:  ldx     ScratchVal1
LD854:  cpx     LastEditableColumn
        beq     LD85F
        inx
        lda     TabStops,x
        beq     LD854
LD85F:  stx     ScratchVal1
LD862:  jmp     LD79F
;;; Move to previous tab
LD865:  ldx     ScratchVal1
LD868:  cpx     #0
        beq     LD85F
        dex
        lda     TabStops,x
        beq     LD868
        bne     LD85F ; branch always taken

ShowHelpScreen:
        jsr     ClearTextWindow
        jsr     DisplayHelpText
        jsr     WaitForSpaceToContinueInStatusLine
        jmp     MainEditor

SearchForString:
        jsr     SaveCursorPosInDocument
        lda     #<TD59E ; "Search for:"
        ldx     #>TD59E
        jsr     DisplayStringInStatusLineWithEscToGoBack
        ldy     SearchText ; copy current search text
LD88D:  lda     SearchText,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LD88D
        lda     #20
        jsr     InputSingleLine
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
        lda     #<TD5AA ; "Searching..."
        ldx     #>TD5AA
        jsr     DisplayStringInStatusLine
        jsr     RestoreCursorPosOnScreen
        ldx     CurrentCursorXPos
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        inc     CurrentCursorXPos
        lda     CurrentCursorXPos
        cmp     DocumentLineLength
        bge     ContinueSearchOnNextLine
        jsr     IsCursorAtEndOfLine
        bcc     ContinueSearchOnNextLine
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        clc
        sbc     CurrentCursorXPos
        bmi     ContinueSearchOnNextLine
        beq     ContinueSearchOnNextLine
        tax
        ldy     CurrentCursorXPos
        bra     LD906
LD8EF:  jsr     GetLengthOfCurrentLine
        and     #%01111111
        beq     ContinueSearchOnNextLine
        tax
        ldy     #1
LD8F9:  jsr     GetCharAtYInCurrentLine ; compare text
        ora     #%10000000              ; at Y
        jsr     CharToUppercase
        cmp     SearchText+1
        beq     LD914
LD906:  iny
        dex
        bne     LD8F9
ContinueSearchOnNextLine:
        jsr     IsOnLastDocumentLine
        beq     LD93E
        jsr     MoveToNextVisibleLine
        bra     LD8EF
LD914:  phx
        phy
        ldx     #2
;;; Compare rest of search string.
LD918:  iny
        lda     SearchText,x
        beq     LD933
        sta     Pointer6+1
        jsr     GetCharAtYInCurrentLine
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
;;; Set new cursor position at start of found string.
        dey
        sty     CurrentCursorXPos
        jsr     SaveCursorPosInDocument
        bra     LD948
;;; Didn't find the string.
LD93E:  lda     #<TD5B8 ; "Not found"
        ldx     #>TD5B8
        jsr     DisplayStringInStatusLine
        jsr     BeepAndWaitForReturnOrEscKey
LD948:  jsr     RestoreCursorPosInDocument
        jmp     MainEditor

;;; Routines to save and restore cursor position during
;;; search.

SaveCursorPosInDocument:
        jsr     SaveCurrentLineState2
        lda     CurrentCursorXPos
        sta     ScratchVal4
        lda     CurrentCursorYPos
        sta     ScratchVal6
        rts

RestoreCursorPosInDocument:
        jsr     RestoreCurrentLineState2
RestoreCursorPosOnScreen:
        lda     ScratchVal4
        sta     CurrentCursorXPos
        lda     ScratchVal6
        sta     CurrentCursorYPos
        rts

;;; does not scroll if on bottom line
MoveToNextVisibleLine:
        lda     CurrentCursorYPos
        cmp     #BottomTextLine
        beq     @Out
        inc     CurrentCursorYPos
@Out:   jsr     LoadNextLinePointer
        rts

StartMenuNavigationAtMenuItem:
        sta     MenuNumber ; menu #
        stx     MenuItemNumber ; menu item #
        lda     #$FF
        sta     MenuItemSelectedFlag
        bra     LD98C

StartMenuNavigation:
        stz     MenuItemSelectedFlag
        stz     MenuNumber
        stz     MenuItemNumber
LD98C:  lda     #HICHAR(ControlChar::Return)
        sta     CursorMovementControlChars+4
;;; set mouse tracking speed to slow
        lda     #StartingMousePos+23
        sta     MousePosMax
        lda     #StartingMousePos-23
        sta     MousePosMin
LD99B:  lda     #<TD65C ; "Use arrows/mouse to select an option..."
        ldx     #>TD65C
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     SaveScreenAreaUnderMenus
LD9A5:  jsr     LoadMenuItemListPointer
        lda     MenuNumber
        jsr     DrawMenuTitles
LD9AD:  jsr     DrawMenu
        lda     MenuItemSelectedFlag
        bne     SelectMenuItem
LD9B4:  ldy     #StatusLine
        ldx     #54
        jsr     SetCursorPosToXY
        ldx     #6
        jsr     GetSpecificKeypress
        bcs     CleanUpAfterMenuSelection
        txa
        asl     a
        tax
        jmp     (MenuNavigationKeypressHandlerTable,x)

MenuNavigationKeypressHandlerTable:
        .addr   InvalidMenuKey         ; any other key
        .addr   SelectMenuItem         ; Return
        .addr   InvalidMenuKey         ; Space
        .addr   MoveToPreviousMenu     ; Left arrow
        .addr   MoveToNextMenu         ; Right arrow
        .addr   MoveToPreviousMenuItem ; Up Arrow
        .addr   MoveToNextMenuItem     ; Down Arrow

;;; Removes a menu after a menu selection triggered the display of
;;; a dialog box (in which case the menu is still on-screen)
CleanUpAfterMenuSelection: ; $D9D6
        jsr     RestoreScreenAreaUnderMenus
        jsr     DrawMenuBarAndMenuTitles
        lda     #HICHAR(ControlChar::Esc)
        sta     CursorMovementControlChars+4
;;; Set mouse tracking speed to fast
        lda     #StartingMousePos+3
        sta     MousePosMax
        lda     #StartingMousePos-3
        sta     MousePosMin
        rts

InvalidMenuKey:
        jsr     PlayTone
        bra     LD9B4

MoveToPreviousMenuItem:
        lda     MenuItemNumber
        dec     a
        bpl     LD9FC
        ldy     MenuNumber
        lda     MenuLengths,y
        dec     a
LD9FC:  sta     MenuItemNumber
        bra     LD9AD

MoveToNextMenuItem:
        lda     MenuItemNumber
        inc     a
        ldy     MenuNumber
        cmp     MenuLengths,y
        blt     LD9FC
        lda     #0
        bra     LD9FC

MoveToPreviousMenu:
        lda     MenuNumber
        dec     a
        bpl     MoveToMenuA
        lda     MenuCount
        dec     a
MoveToMenuA:
        sta     MenuNumber
        jsr     RestoreScreenAreaUnderMenus
        stz     MenuItemNumber
        bra     LD9A5

MoveToNextMenu:
        lda     MenuNumber
        inc     a
        cmp     MenuCount
        blt     MoveToMenuA
        lda     #0
        bra     MoveToMenuA

SelectMenuItem:
        jsr     DrawCheckNextToSelectedMenuItem
        lda     MenuNumber
        asl     a
        asl     a
        asl     a
        asl     a
        sta     MenuNumber
        lda     MenuItemNumber
        asl     a
        clc
        adc     MenuNumber
        tax
        jmp     (MenuItemJumpTable,x)

ShowVolumesDialog:
;;;  Draw Volumes Online dialog
        jsr     DrawDialogBox
        .byte   17 ; height
        .byte   35 ; width
        .byte   4  ; y-coord
        .byte   36 ; x-coord
        .byte   46 ; x-coord of title
        .addr   TDCCC ; "Volumes Online"
        lda     #ProDOS::CONLINE
        ldx     #<EditorOnLineParams
        ldy     #>EditorOnLineParams
        jsr     MakeMLICall
        bcc     LDA61
        jsr     DisplayProDOSErrorAndWaitForKeypress
        bra     LDA5E
LDA5B:  jsr     WaitForSpaceToContinueInStatusLine
LDA5E:  jmp     CleanUpAfterMenuSelection
LDA61:  lda     #0
        sta     ScratchVal1
        ldy     #6
LDA68:  ldx     #41
        jsr     SetCursorPosToXY
        ldy     ScratchVal1
        lda     DataBuffer,y
        beq     LDA5B
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        and     #%00000111
        pha
        lda     #HICHAR('S')
        jsr     OutputCharAndAdvanceScreenPos
        pla
        ora     #%10110000
        jsr     OutputCharAndAdvanceScreenPos
        lda     #HICHAR(',')
        jsr     OutputCharAndAdvanceScreenPos
        lda     #HICHAR('D')
        jsr     OutputCharAndAdvanceScreenPos
        ldx     #HICHAR('1')
        ldy     ScratchVal1
        lda     DataBuffer,y
        bpl     LDA9C
        inx     ; increment drive char to '2'
LDA9C:  txa
        jsr     OutputCharAndAdvanceScreenPos
        ldy     #4
        jsr     OutputSpaces
        ldy     ScratchVal1
        lda     DataBuffer,y
        and     #%00001111 ; get volume name length
        beq     LDAC3
        pha
        lda     #HICHAR('/')
        jsr     OutputCharAndAdvanceScreenPos
        pla
        tax
LDAB7:  iny
        lda     DataBuffer,y ; output volume name
        ora     #%10000000
        jsr     OutputCharAndAdvanceScreenPos
        dex
        bne     LDAB7
LDAC3:  lda     ScratchVal1
        clc
        adc     #$10
        sta     ScratchVal1
        ldy     ZeroPage::CV
        iny
        bra     LDA68 ; continue with next entry

PrintFile:
        jsr     SaveCurrentLineState2
        jsr     ShowPrintDialog
        jsr     RestoreCurrentLineState2
        jmp     CleanUpAfterMenuSelection

ShowQuitDialog:
        jsr     DrawDialogBox
        .byte   7  ; height
        .byte   36 ; width
        .byte   5  ; y-coord
        .byte   32 ; x-coord
        .byte   48 ; x-coord of title
        .addr   TD741 ; "Quit"
        ldy     #7
        ldx     #38
        jsr     SetCursorPosToXY
        lda     #<TD748 ; Q - Quit...
        ldx     #>TD748
        jsr     DisplayMSB1String
        ldy     #8
        ldx     #38
        jsr     SetCursorPosToXY
        lda     #<TD761 ; E - Exit ...
        ldx     #>TD761
        jsr     DisplayMSB1String
        ldx     #50
        ldy     #9
        jsr     DrawAbortButton
        jsr     DisplayHitEscToEditDocInStatusLine
LDB0D:  jsr     PlayTone
        ldx     #1
        jsr     GetSpecificKeypress
        bcs     LDB4E
        ora     #%10000000 ; set MSB
        and     #ToUpperCaseANDMask
        cmp     #HICHAR('E')
        beq     @Exit
        cmp     #HICHAR('Q')
        bne     LDB0D
        lda     DocumentLineCount+1
        bne     LDB36
        lda     DocumentLineCount
        cmp     #1
        bne     LDB36
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        beq     @Exit
LDB36:  lda     DocumentChangedFlag
        bne     @Exit
        lda     PathnameBuffer
        beq     LDB46
        sta     CurrentDocumentPathnameLength
        sta     PathnameLength
LDB46:  jsr     ShowSaveAsDialog
        bcs     LDB4E
@Exit:  jmp     ShutdownRoutine
LDB4E:  jmp     CleanUpAfterMenuSelection

ShowAboutBox:
        jsr     DrawDialogBox
        .byte   14 ; height
        .byte   60 ; width
        .byte   6  ; x-coord
        .byte   10 ; y-coord
        .byte   36 ; x-coord of title
        .addr   TD99A ; "Ed-It!"
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
        lda     #<TD9A3 ; about box text
        ldx     #>TD9A3
        jsr     DisplayMSB1String
        ldy     #10
        ldx     #23
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #11
        ldx     #34
        jsr     SetCursorPosToXY
        lda     #<TD9C1 ; about box text
        ldx     #>TD9C1
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TD9D1 ; about box text
        ldx     #>TD9D1
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TDA36 ; about box text
        ldx     #>TDA36
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TDA4D ; about box text
        ldx     #>TDA4D
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TD9EA ; about box text
        ldx     #>TD9EA
        jsr     DisplayMSB1String
        lda     #16
        sta     Columns80::OURCH
        lda     #<TDA02 ; about box text
        ldx     #>TDA02
        jsr     DisplayMSB1String
        jsr     WaitForSpaceToContinueInStatusLine
        jmp     CleanUpAfterMenuSelection

SaveFileAs:
        jsr     ShowSaveAsDialog
        jmp     CleanUpAfterMenuSelection

ListDirectory:
        jsr     ShowListDirectoryDialog
        jmp     CleanUpAfterMenuSelection

ShowSetPrefixDialog:
        lda     #<TD773 ; "New Prefix"
        ldx     #>TD773
        jsr     DisplayPathInputBox
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        ldy     #73
        jsr     OutputSpaces
        jsr     DisplayHitEscToEditDocInStatusLine
        ldy     PrefixBuffer
LDBFC:  lda     PrefixBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDBFC
LDC05:  ldy     #16
        ldx     #28
        jsr     SetCursorPosToXY
        lda     #<TD780 ; "Press OA-S for Slot/Drive"
        ldx     #>TD780
        jsr     DisplayMSB1String
LDC13:  ldy     #12
        ldx     #11
        lda     #64
        jsr     EditPath
        bcc     LDC29
        cmp     #'s'
        beq     LDC33
        cmp     #'S'
        beq     LDC33
        jmp     LDD1C
LDC29:  lda     ProDOS::SysPathBuf
        cmp     #2
        blt     LDC13
        jmp     LDCDB
;;; Slot/Drive entry
LDC33:  stz     EditorOnLineUnitNum
        ldy     #16
        ldx     #25
        jsr     SetCursorPosToXY
        ldy     #$32
        jsr     OutputSpaces
        ldx     #31
        stx     Columns80::OURCH
        lda     #<TD799 ; "Slot?"
        ldx     #>TD799
        jsr     DisplayMSB1String
        bra     LDC53
LDC50:  jsr     PlayTone
LDC53:  jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDC05
        cmp     #HICHAR('1')
        blt     LDC50
        cmp     #HICHAR('8')
        bge     LDC50
        jsr     OutputCharAndAdvanceScreenPos
        asl     a ; shift in the slot #
        asl     a
        asl     a
        asl     a
        sta     EditorOnLineUnitNum
        lda     #44
        sta     Columns80::OURCH
        lda     #<TD79F ; "Drive?"
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
        ora     #%10000000 ; set drive 2
        sta     EditorOnLineUnitNum
        pla
LDC96:  jsr     OutputCharAndAdvanceScreenPos
        lda     #<ProDOS::SysPathBuf+1
        sta     EditorOnLineDataBuffer
        lda     #>ProDOS::SysPathBuf+1
        sta     EditorOnLineDataBuffer+1
        lda     #ProDOS::CONLINE
        ldx     #<EditorOnLineParams
        ldy     #>EditorOnLineParams
        jsr     MakeMLICall
        pha
        php
;;; restore param table to previous values
        stz     EditorOnLineUnitNum
        lda     #<DataBuffer
        sta     EditorOnLineDataBuffer
        lda     #>DataBuffer
        sta     EditorOnLineDataBuffer+1
        plp
        pla
        bcs     LDCC7 ; branch if error
        lda     ProDOS::SysPathBuf+1 ; will be 0 on error
        bne     LDCCD
        lda     ProDOS::SysPathBuf+2 ; get error number
LDCC7:  jsr     DisplayProDOSErrorAndWaitForKeypress
        jmp     ShowSetPrefixDialog
LDCCD:  and     #%00001111 ; get volume name length
        inc     a
        sta     ProDOS::SysPathBuf
        lda     #'/'
        sta     ProDOS::SysPathBuf+1 ; add leading slash
        jmp     LDC05
LDCDB:  ldx     #0
        ldy     ProDOS::SysPathBuf ; shift name left 1 char
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
        jsr     DisplayProDOSErrorAndWaitForKeypress
        jmp     ShowSetPrefixDialog
;;; copy prefix back to prefix buffer
LDCFB:  ldy     ProDOS::SysPathBuf-1
LDCFE:  lda     ProDOS::SysPathBuf-1,y
        sta     PrefixBuffer,y
        dey
        bpl     LDCFE
        ldy     PrefixBuffer
;;; append trailing slash if needed
        lda     PrefixBuffer,y
        and     #%01111111
        cmp     #'/'
        beq     LDD1C
        iny
        lda     #'/'
        sta     PrefixBuffer,y
        sty     PrefixBuffer
LDD1C:  jmp     CleanUpAfterMenuSelection

LoadFile:
        jsr     ShowOpenFileDialog
        jmp     CleanUpAfterMenuSelection

ShowChangeMouseStatusDialog:
        jsr     DrawDialogBox
        .byte   9  ; height
        .byte   40 ; width
        .byte   9  ; y-coord
        .byte   20 ; x-coord
        .byte   30 ; x-coord of title
        .addr   TDDC7 ; "Change Mouse Status"
        ldy     #13
        ldx     #23
        jsr     DrawAbortButton
        ldy     #13
        ldx     #43
        jsr     DrawAcceptButton
        ldy     #11
        ldx     #30
        jsr     SetCursorPosToXY
        lda     MouseSlot
        beq     LDD61
        lda     #<TD8BB ; "Turn OFF mouse?"
        ldx     #>TD8BB
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     WaitForReturnOrEscKey
        bcs     LDD5E
        lda     MouseSlot
        sta     SavedMouseSlot
        stz     MouseSlot
LDD5E:  jmp     CleanUpAfterMenuSelection
LDD61:  lda     SavedMouseSlot
        beq     LDD7D
        lda     #<TD8CB ; "Turn ON Mouse?"
        ldx     #>TD8CB
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     WaitForReturnOrEscKey
        bcs     LDD5E
        lda     SavedMouseSlot
        sta     MouseSlot
        jmp     CleanUpAfterMenuSelection
LDD7D:  lda     #<TD8A7 ; "No mouse in system!"
        ldx     #>TD8A7
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     GetKeypress
        jmp     CleanUpAfterMenuSelection

ChangeBlinkRate:
        lda     #<TD8DA ; "Enter new rate..."
        ldx     #>TD8DA
        ldy     CursorBlinkRate
        jsr     InputSingleDigitDefaultInY
        bcs     LDD9F
        bne     LDD9C
        inc     a
LDD9C:  sta     CursorBlinkRate
LDD9F:  jmp     CleanUpAfterMenuSelection

ShowClearMemoryDialog:
        jsr     DrawDialogBox
        .byte   7  ; height
        .byte   40 ; width
        .byte   6  ; y-coord
        .byte   25 ; x-coord
        .byte   39 ; x-coord of title
        .addr   TD974 ; "Clear Memory"
        ldy     #8
        ldx     #32
        jsr     SetCursorPosToXY
        lda     #<TD983 ; "Erase memory contents?"
        ldx     #>TD983
        jsr     DisplayMSB1String
        ldy     #10
        ldx     #28
        jsr     DrawAbortButton
        ldy     #10
        ldx     #48
        jsr     DrawAcceptButton
        jsr     DisplayHitEscToEditDocInStatusLine
LDDCB:  jsr     PlayTone
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDDEA
        cmp     #HICHAR(ControlChar::Return)
        bne     LDDCB
        jsr     LoadFirstLinePointer
        jsr     SetDocumentLineCountToCurrentLine
        jsr     MoveCursorToHomePos
        lda     #$80
        jsr     SetLengthOfCurrentLine
        stz     PathnameBuffer
LDDEA:  jmp     CleanUpAfterMenuSelection

SetLineLengthPrompt:
        lda     DocumentLineCount+1
        bne     LDE00
        lda     DocumentLineCount
        cmp     #1
        bne     LDE00
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        beq     LDE0F
LDE00:  lda     #<TD90F ; "You MUST clear file in memory..."
        ldx     #>TD90F
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     PlayTone
        jsr     WaitForSpaceKeypress
        bra     LDE88
LDE0F:  jsr     MoveCursorToHomePos
LDE12:  lda     #<TD8F0 ; "Enter new line length"
        ldx     #>TD8F0
        jsr     DisplayStringInStatusLineWithEscToGoBack
        lda     DocumentLineLength ; default input is current length
        ldx     #0
        ldy     #2
        jsr     FormatAXInDecimal
        ldy     StringFormattingBuffer
LDE26:  lda     StringFormattingBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDE26
        lda     #3
        jsr     InputSingleLine
        bcc     LDE41
        jmp     LDE88 ; input cancelled
;;; Handle invalid input
LDE39:  jsr     PlayTone
        stz     Columns80::OURCH
        bra     LDE12
LDE41:  stz     LineLengthLowDigit
        stz     LineLengthHighDigit
        lda     ProDOS::SysPathBuf
        cmp     #2
        blt     LDE39 ; line length must be 2 digits
        lda     ProDOS::SysPathBuf+1
        cmp     #HICHAR('3')
        blt     LDE39 ; high digit must be in range 3-7
        cmp     #HICHAR('8')
        bge     LDE39
        and     #%00001111 ; convert char to numeric value 0-9
        sta     LineLengthHighDigit
        lda     ProDOS::SysPathBuf+2
        cmp     #HICHAR('0') ; check for valid low digit
        blt     LDE39
        cmp     #HICHAR(':')
        bge     LDE39
        and     #%00001111 ; convert char to numeric value 0-9
        sta     LineLengthLowDigit
        ldy     LineLengthHighDigit
        beq     LDE79
LDE73:  clc     ; add (10 * high digit) to low digit
        adc     #10
        dey
        bne     LDE73
LDE79:  cmp     #39 ; minimum width is 39
        blt     LDE39
        cmp     #80 ; maximum width is 79
        bge     LDE39
        sta     DocumentLineLength
        dec     a
        sta     LastEditableColumn
LDE88:  jmp     CleanUpAfterMenuSelection
LineLengthLowDigit:
        .byte   $00
LineLengthHighDigit:
        .byte   $00

ShowEditMacrosScreen:
        jsr     DrawMenuBar
        ldy     #1
        ldx     #5
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        lda     #<TDDF3 ; "Edit & Save Macros"
        ldx     #>TDDF3
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
LDEA4:  jsr     ClearTextWindow
        jsr     DisplayAllMacros
        lda     #<TDB5F ; "Enter # to edit..."
        ldx     #>TDB5F
        jsr     DisplayStringInStatusLineWithEscToGoBack
LDEB1:  jsr     GetKeypress
        cmp     #HICHAR('1')
        blt     LDEBC
        cmp     #HICHAR(':')
        blt     LDED1
LDEBC:  and     #ToUpperCaseANDMask
        cmp     #HICHAR(ControlChar::Esc)
        beq     LDECE
        cmp     #HICHAR('S')
        beq     LDECB
        jsr     PlayTone
        bra     LDEB1
LDECB:  jsr     SaveMacrosToFile
LDECE:  jmp     CleanUpAfterMenuSelection
LDED1:  and     #%00001111 ; to digit
        jsr     EditMacro
        bra     LDEA4

SaveMacrosToFile:
        ldy     MacrosFilePathnameBuffer
LDEDB:  lda     MacrosFilePathnameBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDEDB
LDEE4:  lda     #<TDBE6 ; "Saving..."
        ldx     #>TDBE6
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     GetFileInfo
        beq     LDEFF
        lda     #<TDBC5 ; "Insert PROGRAM disk..."
        ldx     #>TDBC5
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        bne     LDEE4
        rts
LDEFF:  lda     EditorGetFileInfoFileType
        cmp     #FileType::SYS
        beq     LDF0B
        lda     #ProDOS::EBADSTYPE
LDF08:  jmp     DisplayProDOSErrorAndWaitForKeypress
LDF0B:  jsr     OpenFile
        bne     LDF08
        lda     #ProDOS::CSETMARK
        ldx     #<EditorSetMarkParams
        ldy     #>EditorSetMarkParams
        jsr     MakeMLICall
        beq     LDF1E
LDF1B:  jmp     CloseFileAndDisplayError
LDF1E:  lda     #<ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        stz     EditorReadWriteRequestCount+1
        lda     #MaxMacroLength+1 ; length of macro entry
        sta     EditorReadWriteRequestCount
        lda     #1
LDF32:  sta     MacroNumberBeingEdited
        jsr     DisplayCurrentMacroText
        lda     #ProDOS::CWRITE
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        bne     LDF1B
        lda     MacroNumberBeingEdited
        inc     a
        cmp     #10 ; there are 9 macros
        blt     LDF32
        jsr     CloseFile
        rts

;;; Used to enter printer slot # and printer left margin.
;;; Default value passed in A.
InputSingleDigit:
        sta     InputSingleDigitDefaultValue
        bra     LDF5A
;;; Same as above, but default value passed in Y.
InputSingleDigitDefaultInY:
        sty     InputSingleDigitDefaultValue
        jsr     DisplayStringInStatusLineWithEscToGoBack
LDF5A:  lda     Columns80::OURCH
        sta     InputSingleDigitCursorXPos
LDF60:  lda     InputSingleDigitCursorXPos
        sta     Columns80::OURCH
        lda     InputSingleDigitDefaultValue
        ora     #DigitToCharORMask
        sta     ProDOS::SysPathBuf+1
        lda     #1
        sta     ProDOS::SysPathBuf
        lda     #2
        jsr     InputSingleLine
        bcs     LDF93
        lda     ProDOS::SysPathBuf
        beq     LDF8A
        lda     ProDOS::SysPathBuf+1
        cmp     #HICHAR('0')
        blt     LDF8A
        cmp     #HICHAR(':')
        blt     LDF8F
LDF8A:  jsr     PlayTone ; handle invalid input
        bra     LDF60
LDF8F:  and     #CharToDigitANDMask
        clc
        rts
LDF93:  sec
        rts
InputSingleDigitCursorXPos:
        .byte   $00
InputSingleDigitDefaultValue:
        .byte   $00

DrawCheckNextToSelectedMenuItem:
        ldy     MenuNumber
        lda     MenuXPositions,y
        tax
        lda     #TopMenuLine
        clc
        adc     MenuItemNumber
        tay
        jsr     SetCursorPosToXY
        lda     #MT_REMAP(MouseText::InverseCheckmark)
        jsr     OutputCharAndAdvanceScreenPos
        rts

DrawMenu:
        lda     #TopMenuLine
        jsr     ComputeTextOutputPos
        stz     MenuDrawingIndex
        ldy     MenuNumber
        lda     MenuXPositions,y
        dec     a
        sta     Pointer6+1
LDFBB:  lda     Pointer6+1
        sta     Columns80::OURCH
        jsr     OutputRightVerticalBar
        lda     MenuDrawingIndex
        cmp     MenuItemNumber
        bne     LDFCC
        jsr     SetMaskForInverseText
LDFCC:  lda     MenuDrawingIndex
        asl     a
        tay
        iny
        lda     (Pointer5),y
        tax
        dey
        lda     (Pointer5),y
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        jsr     OutputLeftVerticalBar
        jsr     MoveTextOutputPosToStartOfNextLine
        inc     MenuDrawingIndex
        lda     MenuDrawingIndex
        ldy     MenuNumber
        cmp     MenuLengths,y
        blt     LDFBB
        lda     Pointer6+1
        inc     a
        sta     Columns80::OURCH
        ldy     MenuNumber
        lda     MenuWidths,y
        tay
        jsr     OutputOverscoreLine
        rts

LoadMenuItemListPointer:
        lda     MenuNumber
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
        lda     #MT_REMAP(MouseText::RightVerticalBar)
        jsr     OutputCharAndAdvanceScreenPos
        ldy     #39
@Loop:  lda     #MT_REMAP(MouseText::Checkerboard2)
        jsr     OutputCharAndAdvanceScreenPos
        lda     #MT_REMAP(MouseText::Checkerboard1)
        jsr     OutputCharAndAdvanceScreenPos
        dey
        bne     @Loop
        lda     #MT_REMAP(MouseText::LeftVerticalBar)
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
DrawMenuTitles:
        sta     MenuDrawingIndex
        inc     MenuDrawingIndex
        ldy     #1
        ldx     MenuXPositions
        jsr     SetCursorPosToXY
        dec     MenuDrawingIndex
        beq     LE05F
        jsr     SetMaskForInverseText
LE05F:  lda     #<TDCDD ; "File"
        ldx     #>TDCDD
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        lda     MenuXPositions+1
        sta     Columns80::OURCH
        dec     MenuDrawingIndex
        beq     LE076
        jsr     SetMaskForInverseText
LE076:  lda     #<TDCE4 ; "Utilities"
        ldx     #>TDCE4
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        lda     MenuXPositions+2
        sta     Columns80::OURCH
        dec     MenuDrawingIndex
        beq     LE08D
        jsr     SetMaskForInverseText
LE08D:  lda     #<TDCF0 ; "Options"
        ldx     #>TDCF0
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        rts

ShowListDirectoryDialog:
        jsr     DrawDialogBox
        .byte   14 ; height
        .byte   69 ; width
        .byte   6  ; y-coord
        .byte   4  ; x-coord
        .byte   32 ; x-coord of title
        .addr   TDC19 ; "Directory"
        ldy     #8
        ldx     #6
        jsr     SetCursorPosToXY
        lda     #<TDC25 ; MouseText folder
        ldx     #>TDC25
        jsr     DisplayMSB1String
        ldx     #1
        ldy     PrefixBuffer
LE0B5:  lda     PrefixBuffer,x
        ora     #%10000000
        jsr     OutputCharAndAdvanceScreenPos
        inx
        dey
        bne     LE0B5
        ldy     #9
        ldx     #5
        jsr     SetCursorPosToXY
        ldy     #69
        jsr     OutputHorizontalLineX
        ldy     #10
        ldx     #6
        jsr     SetCursorPosToXY
        lda     #<TDC29 ; File list column headers
        ldx     #>TDC29
        jsr     DisplayMSB1String
        lda     #<TDC54 ; More file list column headers
        ldx     #>TDC54
        jsr     DisplayMSB1String
        ldy     #11
        ldx     #5
        jsr     SetCursorPosToXY
        ldy     #52
        jsr     OutputHorizontalLineX
        jsr     OutputLeftVerticalBar
        ldy     #3
        jsr     OutputSpaces
        ldy     #6
        jsr     OutputHorizontalLineX
        ldy     #12
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC69 ; "Total:"
        ldx     #>TDC69
        jsr     DisplayMSB1String
        ldy     #13
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC71 ; "Used:"
        ldx     #>TDC71
        jsr     DisplayMSB1String
        ldy     #14
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC79 ; "Free:"
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
        lda     #<TDC81 ; "Use <SPACE> to"
        ldx     #>TDC81
        jsr     DisplayMSB1String
        ldy     #18
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TDC90 ; "continue"
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
        sta     ScratchVal4
        ldy     #2
LE182:  lda     ProDOS::SysPathBuf,y
        ora     #%10000000
        cmp     #HICHAR('/')
        beq     LE191
        iny
        cpy     ProDOS::SysPathBuf
        blt     LE182
LE191:  sty     ProDOS::SysPathBuf
        jsr     GetFileInfo
        beq     LE19C
LE199:  jmp     DisplayErrorAndReturnWithCarrySet
LE19C:  lda     ScratchVal4
        sta     ProDOS::SysPathBuf
        ldx     #65
        ldy     #12
        jsr     SetCursorPosToXY
        lda     EditorGetFileInfoAuxType
        ldx     EditorGetFileInfoAuxType+1
        ldy     #5
        jsr     DisplayAXInDecimal
        ldx     #65
        ldy     #13
        jsr     SetCursorPosToXY
        lda     EditorGetFileInfoBlocksUsed
        ldx     EditorGetFileInfoBlocksUsed+1
        ldy     #5
        jsr     DisplayAXInDecimal
        ldx     #65
        ldy     #14
        jsr     SetCursorPosToXY
LE1CD:  lda     EditorGetFileInfoAuxType
        sec
        sbc     EditorGetFileInfoBlocksUsed
        pha
        lda     EditorGetFileInfoAuxType+1
        sbc     EditorGetFileInfoBlocksUsed+1
        tax
        pla
        ldy     #5
        jsr     DisplayAXInDecimal
        jsr     OpenDirectoryAndReadHeader
        bcs     LE199
LE1E7:  lda     #8
        sta     ScratchVal3
        ldy     #12
        ldx     #6
        jsr     SetCursorPosToXY
LE1F3:  lda     FileCountInDirectory
        ora     FileCountInDirectory+1
        beq     LE26A
        jsr     ReadNextDirectoryEntry
        bcs     LE199
        dec     FileCountInDirectory
        lda     FileCountInDirectory
        cmp     #$FF
        bne     LE20D
        dec     FileCountInDirectory+1
LE20D:  ldy     #50
        jsr     OutputSpaces
        lda     #6
        sta     Columns80::OURCH
        jsr     FormatDirectoryEntryToString
        lda     #<MemoryMap::INBUF
        ldx     #>MemoryMap::INBUF
        jsr     DisplayMSB1String
        lda     #50
        sta     Columns80::OURCH
        lda     #HICHAR('$')
        jsr     OutputCharAndAdvanceScreenPos
        ldx     ProDOS::SysPathbuf+$1F
        lda     ProDOS::SysPathbuf+$20
        jsr     DisplayAXInHexadecimal
        jsr     MoveTextOutputPosToStartOfNextLine
        lda     #6
        sta     Columns80::OURCH
        dec     ScratchVal3
        beq     LE244
        jmp     LE1F3
LE244:  lda     FileCountInDirectory
        ora     FileCountInDirectory+1
        beq     LE27C
        ldy     #StatusLine
        ldx     #25
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
LE26A:  ldy     #50
        jsr     OutputSpaces
        jsr     MoveTextOutputPosToStartOfNextLine
        lda     #6
        sta     Columns80::OURCH
        dec     ScratchVal3
        bne     LE26A
LE27C:  lda     #<TDC9C ; "Directory complete..."
        ldx     #>TDC9C
        jsr     DisplayStringInStatusLine
        jsr     GetKeypress
LE286:  jsr     CloseFile
        rts

ShowOpenFileDialog:
;;; First check if current document is empty
        lda     PathnameLength
        bne     LE2A7
        lda     DocumentLineCount+1
        bne     LE2A2
        lda     DocumentLineCount
        cmp     #1
        bne     LE2A2
        jsr     GetLengthOfCurrentLine
        and     #%01111111
LE2A0:  beq     LE2A7
LE2A2:  lda     DocumentChangedFlag
        beq     LE2AA ; branch if document has unsaved changes
LE2A7:  jmp     LE30C ; skip offering to save current document
LE2AA:  jsr     DrawDialogBox
        .byte   12 ; height
        .byte   56 ; width
        .byte   9  ; y-coord
        .byte   11 ; x-coord
        .byte   35 ; x-coord of title
        .addr   TDA88 ; "Load File"
        ldy     #12
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TD7F5 ; "WARNING: File in memory will be lost..."
        ldx     #>TD7F5
        jsr     DisplayMSB1String
        ldy     #14
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TD81B ; "Press 'S' to save file in memory"
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
        sta     CursorMovementControlChars+4
LE2E6:  jsr     PlayTone
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     LE308
        cmp     #HICHAR(ControlChar::Return)
        beq     LE30C
        cmp     #HICHAR('S')
        bne     LE2E6
        lda     PathnameBuffer ; already have a filename?
        beq     LE303 ; branch if no
        sta     CurrentDocumentPathnameLength
        sta     PathnameLength
LE303:  jsr     ShowSaveAsDialog
        bcc     LE309 ; if save successful, continue to load
LE308:  rts
LE309:  stz     PathnameLength
LE30C:  lda     #<TDA88 ; "Load File"
        ldx     #>TDA88
        jsr     DisplayPathInputBox
        lda     #'L'
        sta     CursorMovementControlChars+4
        lda     PathnameLength
        bne     LE32E
        ldy     #17
        ldx     #25
        jsr     SetCursorPosToXY
        lda     #<TD7D4 ; "OA-L or click mouse to List Files"
        ldx     #>TD7D4
        jsr     DisplayMSB1String
        stz     ProDOS::SysPathBuf
LE32E:  ldy     #12
        ldx     #11
        lda     #64
        jsr     EditPath
        bcc     LE34E
        and     #ToUpperCaseANDMask
        cmp     #'N'
        beq     LE348
        cmp     #'L'
        bne     LE34D
        jsr     ShowDirectoryListingDialog
        bra     LE30C
LE348:  jsr     EnterNewPrefix
        bra     LE30C
LE34D:  rts
LE34E:  jsr     GetFileInfo ; of file being loaded
        beq     LE358
LE353:  jsr     DisplayProDOSErrorAndWaitForKeypress
        bra     LE30C
LE358:  lda     EditorGetFileInfoFileType
        cmp     #FileType::DIR ; can't open directories
        bne     LE363
        lda     #ProDOS::EBADSTYPE
        bra     LE353
LE363:  sta     EditorCreateFileType
        ldy     ProDOS::SysPathBuf
LE369:  lda     ProDOS::SysPathBuf,y
        sta     PathnameBuffer,y
        dey
        bpl     LE369
        jsr     OpenFile
        bne     LE353
        lda     #<TDBFF ; "Loading..."
        ldx     #>TDBFF
        jsr     DisplayLoadingOrSavingMessage
        jsr     ClearStatusLine
        stz     EditorReadWriteRequestCount+1
        lda     #1 ; going to read file one byte at a time
        sta     EditorReadWriteRequestCount
        lda     #<ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        jsr     LoadFirstLinePointer ; start first line
        jsr     SetDocumentLineCountToCurrentLine
ReadNextLineFromFile:
        lda     #0
        jsr     SetLengthOfCurrentLine
ProcessNextCharFromFile:
        lda     #ProDOS::CREAD
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        beq     LE3AC
        jmp     LE43D  ; handle error
LE3AC:  lda     ProDOS::SysPathBuf
        and     #%01111111
        cmp     #ControlChar::Return
        beq     LE427 ; need to end current "line" and start a new one
        cmp     #' '
        blt     ProcessNextCharFromFile ; skip over control characters
        tax
        jsr     GetLengthOfCurrentLine
        inc     a
        cmp     DocumentLineLength
        beq     LE3CD ; branch if won't fit on this line
        jsr     SetLengthOfCurrentLine
        tay
        txa
        jsr     SetCharAtYInCurrentLine ; add char to current line
        bra     ProcessNextCharFromFile
LE3CD:  jsr     CheckIfMemoryFull ; try to start a new line
        beq     DoneReadingFile ; branch if memory full
        phx
        jsr     LoadCurrentLinePointerIntoPointer4 ; save copy of pointer to current line
        plx
        ldy     DocumentLineLength
        cpx     #' '
        bne     LE3DF
        dey
LE3DF:  dey     ; search backward for space char
        beq     LE3E9
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        bne     LE3DF
LE3E9:  cpy     #0 ; at beginning of line?
        beq     LE3F2 ; branch if yes
        cpy     LastEditableColumn ; at max length?
        bne     LE3F6
LE3F2:  ldx     #1 ; can't word-wrap, so add char on next line
        bra     LE411
LE3F6:  tya
        jsr     SetLengthOfCurrentLine ; truncate current line at end of last word
        ldx     #1
;;; Word wrap logic--I don't quite understand this.
LE3FC:  iny
        cpy     DocumentLineLength
        beq     LE411
        jsr     GetCharAtYInCurrentLine
        phy
        phx
        ply
        jsr     SetCharAtYInLineAtPointer4
        phy
        plx
        ply
        inx
        bra     LE3FC
;;; start next line
LE411:  txa
        tay
        jsr     SetLengthOfLineAtPointer4
        lda     ProDOS::SysPathBuf
        and     #%01111111
        jsr     SetCharAtYInLineAtPointer4
        jsr     LoadNextLinePointer
        jsr     IncrementDocumentLineCount
        jmp     ProcessNextCharFromFile
LE427:  jsr     GetLengthOfCurrentLine
        ora     #%10000000 ; add CR marker
        jsr     SetLengthOfCurrentLine
        jsr     CheckIfMemoryFull
        beq     DoneReadingFile
        jsr     LoadNextLinePointer
        jsr     IncrementDocumentLineCount
        jmp     ReadNextLineFromFile
LE43D:  cmp     #ProDOS::EEOF
        bne     ErrorLoadingFile
;;; done loading file (or memory full)
DoneReadingFile:
        sta     DocumentChangedFlag
        jsr     CloseFile
        jsr     MoveCursorToHomePos
        jsr     SetDocumentLineCountToCurrentLine
        jsr     GetLengthOfCurrentLine
        cmp     #0
        bne     LE463
        lda     DocumentLineCount+1
        bne     LE460
        lda     DocumentLineCount
        cmp     #1
        beq     LE463
LE460:  jsr     DecrementDocumentLineCount
LE463:  jsr     LoadFirstLinePointer
        lda     EditorCreateFileType
        cmp     #FileType::TXT
        beq     LE470
        stz     PathnameBuffer ; non-TXT files can't be overwritten
LE470:  rts
ErrorLoadingFile:
        jsr     LoadFirstLinePointer
        lda     #0
        jsr     SetLengthOfCurrentLine
        jsr     SetDocumentLineCountToCurrentLine
        jsr     MoveCursorToHomePos
        bra     CloseFileAndDisplayError
        lda     #ProDOS::EBADSTYPE ; unreachable instruction

CloseFileAndDisplayError:
        pha
        jsr     CloseFile
        pla
        jmp     DisplayErrorAndReturnWithCarrySet

EnterNewPrefix:
        ldy     PrefixBuffer
LE48E:  lda     PrefixBuffer,y
        ora     #%10000000
        sta     ProDOS::SysPathBuf-1,y
        dey
        bne     LE48E
        ldy     PrefixBuffer
        dey
        sty     ProDOS::SysPathBuf
        lda     #<TDAAA ; "Enter new prefix above..."
        ldx     #>TDAAA
        jsr     DisplayStringInStatusLine
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TD7B8 ; "Prefix:/"
        ldx     #>TD7B8
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #11
        lda     #63
        jsr     EditPath
        bcs     LE4F7
        ldy     ProDOS::SysPathBuf
LE4C3:  iny
        sty     ProDOS::SysPathBuf-1
        lda     #HICHAR('/')
        sta     ProDOS::SysPathBuf
        lda     #ProDOS::CSETPREFIX
        ldy     #>EditorSetPrefixParams
        ldx     #<EditorSetPrefixParams
        jsr     MakeMLICall
        beq     LE4DA
        jmp     DisplayErrorAndReturnWithCarrySet
LE4DA:  ldy     ProDOS::SysPathBuf-1
LE4DD:  lda     ProDOS::SysPathBuf-1,y
        sta     PrefixBuffer,y
        dey
        bpl     LE4DD
        lda     #HICHAR('/')
        ldx     PrefixBuffer
        cmp     PrefixBuffer,x
        beq     LE4F7
        inx
        sta     PrefixBuffer,x
        stx     PrefixBuffer
LE4F7:  rts

ShowSaveAsDialog:
        lda     #<TD7A6 ; "Save File"
        ldx     #>TD7A6
        jsr     DisplayPathInputBox
        ldy     #17
        ldx     #23
        jsr     SetCursorPosToXY
        lda     #<TD883 ; "Use OA-Ret to save with Ret on each line"
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
LE525:  ldy     #12
        ldx     #11
        lda     #64
        jsr     EditPath
        bcc     LE544
        and     #ToUpperCaseANDMask
        cmp     #ControlChar::Return
        beq     LE541
        cmp     #'N'
        bne     LE53F
        jsr     EnterNewPrefix
        bra     ShowSaveAsDialog
LE53F:  sec
        rts
LE541:  ldy     #$FF
        .byte   OpCode::BIT_Abs
LE544:  ldy     #0
        sty     SaveCRAtEndOfEachLineFlag
        lda     #<TDBE6 ; "Saving..."
        ldx     #>TDBE6
        jsr     DisplayLoadingOrSavingMessage
        jsr     ClearStatusLine
        jsr     GetFileInfo
        beq     LE55F
        cmp     #$46
        beq     LE590
        jmp     DisplayErrorAndReturnWithCarrySet
LE55F:  lda     EditorGetFileInfoFileType
        sta     EditorCreateFileType
        lda     CurrentDocumentPathnameLength
        beq     LE56F
        stz     CurrentDocumentPathnameLength
        bra     LE588
LE56F:  ldy     #StatusLine
        ldx     #0
        jsr     SetCursorPosToXY
        lda     #<TDA65 ; "Replace old version of file?"
        ldx     #>TDA65
        jsr     DisplayMSB1String
        jsr     PlayTone
        jsr     GetConfirmationKeypress
        bcs     LE53F
        jsr     ClearStatusLine
LE588:  jsr     DeleteFile
        beq     LE590
        jmp     DisplayErrorAndReturnWithCarrySet
LE590:  ldy     ProDOS::SysPathBuf
LE593:  lda     ProDOS::SysPathBuf,y
        sta     PathnameBuffer,y
        dey
        bpl     LE593
        lda     #ProDOS::CCREATE
        ldy     #>EditorCreateParams
        ldx     #<EditorCreateParams
        jsr     MakeMLICall
        bne     DisplayErrorAndReturnWithCarrySet
        jsr     OpenFile
        bne     LE60D
        jsr     SaveCurrentLineState2
        jsr     LoadFirstLinePointer
        stz     EditorReadWriteRequestCount+1
LE5B5:  jsr     CopyCurrentLineToSysPathBuf
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
LE5D7:  lda     #>SingleReturnCharBuffer
        cmp     EditorReadWriteBufferAddr+1
        beq     LE5F6
        lda     SaveCRAtEndOfEachLineFlag
        bne     LE5E8
        lda     ProDOS::SysPathBuf
        bpl     LE5F6
LE5E8:  lda     #<SingleReturnCharBuffer            ; write a single CR char to file
        sta     EditorReadWriteBufferAddr
        lda     #>SingleReturnCharBuffer
        sta     EditorReadWriteBufferAddr+1
        lda     #1
        bra     LE5C7
LE5F6:  jsr     IsOnLastDocumentLine
        beq     LE600
        jsr     LoadNextLinePointer
        bra     LE5B5
LE600:  jsr     CloseFile
        jsr     RestoreCurrentLineState2
        lda     #1
        sta     DocumentChangedFlag
        clc
        rts
LE60D:  pha
        jsr     CloseFile
        jsr     DeleteFile
        pla
DisplayErrorAndReturnWithCarrySet:
        jsr     DisplayProDOSErrorAndWaitForKeypress
        sec
        rts

GetFileInfo:
        lda     #ProDOS::CGETFILEINFO
        ldx     #<EditorGetFileInfoParams
        ldy     #>EditorGetFileInfoParams
        jsr     MakeMLICall
        rts

OpenFile:
        lda     #ProDOS::COPEN
        ldx     #<EditorOpenParams
        ldy     #>EditorOpenParams
        jsr     MakeMLICall
        pha
        lda     EditorOpenRefNum
        sta     EditorReadWriteRefNum
        sta     EditorSetMarkRefNum
        pla
        rts

DeleteFile:
        lda     #PrODOS::CDESTROY
        ldx     #<EditorDestroyParams
        ldy     #>EditorDestroyParams
        jsr     MakeMLICall
        rts

CloseFile:
        lda     #ProDOS::CCLOSE
        ldx     #<EditorCloseParams
        ldy     #>EditorCloseParams
        jsr     MakeMLICall
        rts

;;; path editor (for load, save as, set prefix)
;;; drawn at X,Y, width A. Returns in A the keypress
;;; that ended the input, and Carry set if it wasn't
;;; the Return key.
EditPath:
        stx     ScreenXCoord
        sty     ScreenYCoord
        sta     DialogWidth
LE653:  ldx     ScreenXCoord
        ldy     ScreenYCoord
        jsr     SetCursorPosToXY ; display current path
        lda     #<ProDOS::SysPathBuf
        ldx     #>ProDOS::SysPathBuf
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
        ldx     #7
LE67F:  cmp     PathEditingOpenAppleKeyCombos,x
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
        bge     LE6A9
LE69B:  jsr     PlayTone
        bra     LE67A
        cmp     #HICHAR('/')
        beq     LE6A9
        ldy     ProDOS::SysPathBuf
        beq     LE69B
LE6A9:  ldy     ProDOS::SysPathBuf
        cpy     DialogWidth     ; path full?
        beq     LE69B
        iny
        sta     ProDOS::SysPathBuf,y ; append char
        sty     ProDOS::SysPathBuf
        jmp     LE653
;;; delete char left
LE6BA:  lda     ProDOS::SysPathBuf
        beq     LE69B
        dec     a
        sta     ProDOS::SysPathBuf
        jmp     LE653
;;; clear input
LE6C6:  stz     ProDOS::SysPathBuf
        jmp     LE653

LE6CC:  stz     PathnameLength
        lda     #HICHAR(ControlChar::Return)
;;; accept input
LE6D1:  tay
        lda     ProDOS::SysPathBuf
        beq     LE69B
        tya
        clc
        rts
;;; cancel input (other command entered)
LE6DA:  sec
        rts

PathEditingOpenAppleKeyCombos:
;;;  Key commands available in path editing dialog.
        .byte   'N'             ; OA-N
        .byte   'n'             ; OA-n
        .byte   'L'             ; OA-L
        .byte   'l'             ; OA-l
        .byte   'S'             ; OA-S
        .byte   's'             ; OA-s
        .byte   ControlChar::Return ; OA-Return
        .byte   HICHAR(ControlChar::Esc)

;;; blanks out lines 17-20, from column 16 to 66, then
;;; displays string at AX, on line 18. Only used for
;;;  "Loading..." and "Saving..." messages.
DisplayLoadingOrSavingMessage:
        pha
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

DisplayPathInputBox:
        pha
        phx
        lda     #76
        sta     DialogWidth
        lda     #12
        sta     DialogHeight
        ldx     #1
        ldy     #9
        jsr     DrawDialogBoxFrameAtXY_1
        lda     #66
        sta     DialogWidth
        lda     #3
        sta     DialogHeight
        ldx     #9
        ldy     #11
        jsr     DrawDialogBoxFrameAtXY
        ldy     #11
        ldx     #10
        jsr     SetCursorPosToXY
        ldy     #66
        jsr     OutputOverscoreLine
        ldy     #9
        ldx     #35
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        plx
        pla
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        ldy     #12
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TD7B2 ; "Path:"
        ldx     #>TD7B2
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TD7B8 ; "Prefix:/"
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
        lda     #<TD7C1 ; "OA-N for New Prefix"
        ldx     #>TD7C1
        jsr     DisplayMSB1String
        rts

DisplayProDOSErrorAndWaitForKeypress:
        sta     MLIError
        jsr     ClearStatusLine
        ldy     #StatusLine
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     MLIErrorTable
        lda     MLIError
LE7BC:  cmp     MLIErrorTable,y
        beq     LE7C9
        dey
        bne     LE7BC
        jsr     Monitor::PRBYTE ; Would crash - ROM not paged in
        ldy     #0
LE7C9:  tya
        asl     a
        tay
        lda     MLIErrorMessageTable+1,y
        tax
        lda     MLIErrorMessageTable,y
        jsr     DisplayMSB1String
        lda     #<TDE09 ; "Press a key"
        ldx     #>TDE09
        jsr     DisplayMSB1String
        jsr     PlayTone
        sta     SoftSwitch::KBDSTRB
        jsr     GetKeypress
        rts

ShowDirectoryListingDialog:
        lda     #HICHAR(ControlChar::Return)
        sta     CursorMovementControlChars+4
        lda     #$FF
        sta     DocumentChangedFlag
        jsr     DrawDialogBox
        .byte   12 ; height
        .byte   44 ; width
        .byte   9  ; y-coord
        .byte   17 ; x-coord
        .byte   34 ; x-coord of title
        .addr   TD83D ; "Select File"
        ldy     #10
        ldx     #19
        jsr     SetCursorPosToXY
        lda     #<TDC29 ; File list column headers
        ldx     #>TDC29
        jsr     DisplayMSB1String
        ldy     #11
        ldx     #18
        jsr     SetCursorPosToXY
        ldy     #44
        jsr     OutputHorizontalLineX
        lda     #<TD84B ; "Use up/down to select..."
        ldx     #>TD84B
        jsr     DisplayStringInStatusLine
        ldy     PrefixBuffer
LE81F:  lda     PrefixBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LE81F
        jsr     OpenDirectoryAndReadHeader
        bcs     LE88B
        jsr     LoadFirstLinePointer
        lda     FileCountInDirectory
        sta     DirectoryEntriesLeftToList
        sta     DocumentLineCount
        lda     FileCountInDirectory+1
        sta     DirectoryEntriesLeftToList+1
        sta     DocumentLineCount+1
LE842:  lda     DirectoryEntriesLeftToList+1
        ora     DirectoryEntriesLeftToList
        beq     LE890
        jsr     ReadNextDirectoryEntry
        bcs     LE886
        jsr     FormatDirectoryEntryToString
        lda     MemoryMap::INBUF
        tay
        jsr     SetLengthOfCurrentLine
LE859:  lda     MemoryMap::INBUF,y
        jsr     SetCharAtYInCurrentLine
        dey
        bne     LE859
        dec     DirectoryEntriesLeftToList
        lda     DirectoryEntriesLeftToList
        cmp     #$FF
        bne     LE86F
        dec     DirectoryEntriesLeftToList+1
LE86F:  jsr     LoadNextLinePointer
        bra     LE842
LE874:  jsr     LoadFirstLinePointer
        jsr     SetDocumentLineCountToCurrentLine
        lda     #$80
        jsr     SetLengthOfCurrentLine
        jsr     SaveCurrentLineState2
        jsr     MoveCursorToHomePos
        rts
LE886:  pha
        jsr     CloseFile
        pla
LE88B:  jsr     DisplayProDOSErrorAndWaitForKeypress
        bra     LE874
LE890:  jsr     CloseFile
        lda     DocumentLineCount
        ora     DocumentLineCount+1
        bne     LE8AA
        lda     #<TD86C ; "NO files; press a key."
        ldx     #>TD86C
        jsr     DisplayStringInStatusLine
        jsr     PlayTone
        jsr     GetKeypress
LE8A8:  bra     LE874
LE8AA:  lda     #$0C
        sta     LE99C
        jsr     LoadFirstLinePointer
LE8B2:  jsr     SaveCurrentLineState2
        ldy     #12
LE8B7:  ldx     #19
        jsr     SetCursorPosToXY
        lda     ZeroPage::CV
        cmp     LE99C
        bne     LE8C6
        jsr     SetMaskForInverseText
LE8C6:  ldx     CurLinePtr+1
        lda     CurLinePtr
        lsr     a
        php
        rol     a
        plp
        bcc     LE8D3
        sta     SoftSwitch::RDCARDRAM
LE8D3:  jsr     DisplayString
        sta     SoftSwitch::RDMAINRAM
        jsr     SetMaskForNormalText
        jsr     IsOnLastDocumentLine
        beq     LE8EE
        jsr     LoadNextLinePointer
        ldy     ZeroPage::CV
        iny
        cpy     #BottomTextLine
        blt     LE8B7
        jsr     LoadPreviousLinePointer
LE8EE:  ldy     #StatusLine
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
        lda     DocumentLineCount+1
        bne     LE91C
        lda     DocumentLineCount
        cmp     #9
        bge     LE91C
        clc
        adc     #$0A
        cmp     LE99C
        blt     LE8F5
LE91C:  lda     LE99C
        cmp     #$14
        blt     LE931
        jsr     IsOnLastDocumentLine
        beq     LE8F5
        jsr     RestoreCurrentLineState2
        jsr     LoadNextLinePointer
        jmp     LE8B2
LE931:  inc     a
        sta     LE99C
        jsr     RestoreCurrentLineState2
        jmp     LE8B2
LE93B:  jsr     SaveCurrentLineState
        jsr     RestoreCurrentLineState2
        jsr     IsOnFirstDocumentLine
        bne     LE952
        lda     LE99C
        cmp     #$0C
        bne     LE95F
        jsr     RestoreCurrentLineState
        bra     LE8F5
LE952:  lda     LE99C
        cmp     #$0D
        bge     LE95F
        jsr     LoadPreviousLinePointer
        jmp     LE8B2
LE95F:  dec     a
        sta     LE99C
        jmp     LE8B2
LE966:  jsr     RestoreCurrentLineState2
        lda     LE99C
        sec
        sbc     #$0C
        clc
        adc     CurrentLineNumber
        sta     CurrentLineNumber
        bcc     LE97B
        inc     CurrentLineNumber+1
LE97B:  jsr     LoadCurrentLinePointerIntoAX
        sta     CurLinePtr
        stx     CurLinePtr+1
        ldy     #0
        ldx     #0
LE986:  inx
        iny
        jsr     GetCharAtYInCurrentLine
        sta     ProDOS::SysPathBuf,x
        cmp     #HICHAR(' ')
        bne     LE986
        dex
        stx     ProDOS::SysPathBuf
        stx     PathnameLength
        jmp     LE874
LE99C:  .byte   $00             ; scratch byte
DirectoryEntriesLeftToList0:
        .word   $0000

OpenDirectoryAndReadHeader:
        jsr     OpenFile
        bne     OpenDirectoryFail
        lda     #<ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
;;; Directory entries are 39 bytes in length but there are two 2-byte
;;; pointers at the beginning of the block, hence the 43.
        lda     #$2B            ; 43
        sta     EditorReadWriteRequestCount
        stz     EditorReadWriteRequestCount+1
        jsr     ReadFromDirectoryBlock
        bne     CloseDirectoryAndFail
        lda     #13
        sta     DirectoryEntriesLeftInBlock
        lda     ProDOS::SysPathBuf+$25
        sta     FileCountInDirectory
        lda     ProDOS::SysPathBuf+$26
        sta     FileCountInDirectory+1
        clc
        rts
CloseDirectoryAndFail:
        pha
        jsr     CloseFile
        pla
OpenDirectoryFail:
        sec
        rts

;;; 13 directory entries per block * 39 bytes per entry
;;; is 507 bytes; 5 bytes of padding to complete a
;;; 512 byte block
SkipPaddingBytesInDirectoryBlock:
        lda     #5
        bra     LE9DB
ReadNextDirectoryEntryInBlock:
LE9D9:  lda     #39
LE9DB:  sta     EditorReadWriteRequestCount
ReadFromDirectoryBlock:
        lda     #ProDOS::CREAD
        ldy     #>EditorReadWriteParams
        ldx     #<EditorReadWriteParams
        jsr     MakeMLICall
        rts

ReadNextDirectoryEntry:
        dec     DirectoryEntriesLeftInBlock
        bne     LE9F7
        lda     #13
        sta     DirectoryEntriesLeftInBlock
        jsr     SkipPaddingBytesInDirectoryBlock
        bne     CloseDirectoryAndFail
LE9F7:  jsr     ReadNextDirectoryEntryInBlock
        bne     CloseDirectoryAndFail
        lda     ProDOS::SysPathBuf
        beq     ReadNextDirectoryEntry
        clc
        rts

FormatDirectoryEntryToString:
        lda     ProDOS::SysPathBuf
        and     #%00001111 ; filename length
        sta     MemoryMap::INBUF
        tay
;;; output filename
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
        lda     #HICHAR(' ')
LEA21:  sta     MemoryMap::INBUF+1,x
        dex
        dey
        bpl     LEA21
;;; output known file type (3-char type)
        ldy     #0
LEA2A:  lda     FileTypeTable,y
        beq     LEA3A
        cmp     ProDOS::SysPathBuf+$10
        beq     LEA65
        iny
        iny
        iny
        iny
        bra     LEA2A
;;; output unknown filetype (hex value)
LEA3A:  lda     #HICHAR('$')
        sta     MemoryMap::INBUF+$12
        lda     ProDOS::SysPathBuf+$10
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #%10110000
        cmp     #HICHAR(':')
        blt     LEA4F
        clc
        adc     #7
LEA4F:  sta     MemoryMap::INBUF+$13
        lda     ProDOS::SysPathBuf+$10
        and     #%00001111
        ora     #%10110000
        cmp     #HICHAR(':')
        blt     LEA60
        clc
        adc     #7
LEA60:  sta     MemoryMap::INBUF+$14
        bra     LEA73
LEA65:  ldx     #0
LEA67:  iny
        lda     FileTypeTable,y
        sta     MemoryMap::INBUF+$12,x
        inx
        cpx     #3
        blt     LEA67
LEA73:  lda     #HICHAR(' ')
;;; output aux type
        sta     MemoryMap::INBUF+$15
        sta     MemoryMap::INBUF+$16
        lda     ProDOS::SysPathBuf+$13
        ldx     ProDOS::SysPathBuf+$14
        ldy     #5
        jsr     FormatAXInDecimal
        ldy     #5
LEA88:  lda     StringFormattingBuffer,y
        sta     MemoryMap::INBUF+$15,y
        dey
        bne     LEA88
;;; output mod date
        lda     ProDOS::SysPathBuf+$21
        ldx     ProDOS::SysPathBuf+$22
        jsr     FormatDateInAX
;;; output mod time
        lda     ProDOS::SysPathBuf+$23
        ldx     ProDOS::SysPathBuf+$24
        jsr     FormatTimeInAX
        ldy     #$10
LEAA5:  lda     DateTimeFormatString,y
        sta     MemoryMap::INBUF+$1A,y
        dey
        bne     LEAA5
;;; store final length of output
        lda     #$2A ; 42
        sta     MemoryMap::INBUF
        rts

BeepAndWaitForReturnOrEscKey:
        jsr     PlayTone
WaitForReturnOrEscKey:
        ldx     #1
        jsr     GetSpecificKeypress
        bcs     @Out
        cpx     #0
        beq     BeepAndWaitForReturnOrEscKey
        clc
@Out:   rts

;;;  Wait for a special key (from SpecialKeyTable, any key in first X entries), or Esc.
;;;  Return with carry clear if that key was pressed, carry set
;;;  if Esc was pressed.
;;;  Returns 0 if none of the special keys were pressed, otherwise returns 1+ the offset
;;;  in SpecialKeyTable of the key that was pressed.

GetSpecificKeypress:
        phx
        jsr     GetKeypress
        plx
        cmp     #HICHAR(ControlChar::Esc)
        beq     @Out
@Loop:  cmp     SpecialKeyTable-1,x
        beq     @Match
        dex
        bne     @Loop
@Match: clc
@Out:   rts

SpecialKeyTable:
        .byte   HICHAR(ControlChar::Return)
        .byte   HICHAR(' ')
        .byte   HICHAR(ControlChar::LeftArrow)
        .byte   HICHAR(ControlChar::RightArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)

BeepAndGetConfirmationKeypress:
        jsr     PlayTone
GetConfirmationKeypress:
        ldx     #1
        jsr     GetSpecificKeypress
        bcs     @Out
        and     #ToUpperCaseANDMask
        cmp     #HICHAR('N')
        beq     @Out
        cmp     #HICHAR('Y')
        bne     BeepAndGetConfirmationKeypress
        clc
@Out:   rts

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
        blt     LEB0D
LEB08:  jsr     MoveTextOutputPosToStartOfNextLine
        lda     #0
LEB0D:  sta     Columns80::OURCH
LEB10:  plx                     ; restore registers
        ply
        pla
        rts
LEB14:  cmp     #HICHAR(' ')
        bge     LEB1C
        cmp     #HICHAR(ControlChar::Null)
        bge     LEB2E
LEB1C:  and     CharANDMask
        bmi     LEAFD
        cmp     #$40            ; check if MouseText char
        blt     LEAFD           ; ($40 - $5F)
        cmp     #$60
        bge     LEAFD
        sec
        sbc     #$40            ; subtract $40 if MouseText
        bra     LEAFD
LEB2E:  cmp     #HICHAR(ControlChar::Return)
        beq     LEB08
        cmp     #HICHAR(ControlChar::InverseVideo)
        beq     LEB3C
        cmp     #HICHAR(ControlChar::NormalVideo)
        beq     LEB3F
        bra     LEB10
LEB3C:  lda     #%01111111      ; turn on inverse video
        .byte   OpCode::BIT_Abs
LEB3F:  lda     #%11111111      ; turn on normal video
        sta     CharANDMask
LEB44:  bra     LEB10
LEB46:  lda     ZeroPage::CV
LEB48:  bra     ComputeTextOutputPos
MoveTextOutputPosToStartOfNextLine:
        stz     Columns80::OURCH
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
ClearTextWindowFromCursor:
        lda     Columns80::OURCH
        sta     ClearTextWindow_SavedCH
        lda     ZeroPage::CV
        sta     ClearTextWindow_SavedCV
@Loop:  jsr     ComputeTextOutputPos
        jsr     ClearToEndOfLine
        stz     Columns80::OURCH
        lda     ZeroPage::CV
        inc     a
        cmp     ZeroPage::WNDBTM
        blt     @Loop
        lda     ClearTextWindow_SavedCH
        sta     Columns80::OURCH
        lda     ClearTextWindow_SavedCV
        jmp     ComputeTextOutputPos
ClearTextWindow_SavedCV:
        .byte   $00 ; saved CV
ClearTextWindow_SavedCH:
        .byte   $00 ; saved OURCH

;;; clears to end of line, without moving cursor pos
ClearToEndOfLine:
        lda     #LastColumn
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

ScrollUpOneLine:
        lda     ZeroPage::CV
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
        bge     LEC10
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

ScrollDownOneLine:
        lda     ZeroPage::CV
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
        blt     LEC10
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
        lda     #MT_REMAP(MouseText::Diamond)
        .byte   OpCode::BIT_Abs
OutputReturnSymbol:
        lda     #MT_REMAP(MouseText::Return)
        .byte   OpCode::BIT_Abs
OutputLeftVerticalBar:
        lda     #MT_REMAP(MouseText::LeftVerticalBar)
        .byte   OpCode::BIT_Abs
OutputRightVerticalBar:
        lda     #MT_REMAP(MouseText::RightVerticalBar)
        jmp     OutputCharAndAdvanceScreenPos

;;; These routines output a given character Y times (in a row).
OutputHorizontalLine:
        lda     #MT_REMAP(MouseText::HorizLine)
        .byte   OpCode::BIT_Abs
OutputHorizontalLineX:
        lda     #MT_REMAP(MouseText::HorizLine)
        .byte   OpCode::BIT_Abs
OutputDashedLine:
        lda     #HICHAR('-')    ; dash
        .byte   OpCode::BIT_Abs
OutputOverscoreLine:
        lda     #MT_REMAP(MouseText::Overscore)
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

;;; Returns character entered in A. It will have the MSB
;;; set unless Open-Apple was down, in which case the MSB
;;; will be clear.
GetKeypress:
        lda     MacroRemainingLength
        beq     LEC90
        lda     (MacroPtr)
        pha
        inc     MacroPtr
        bne     LEC89
        inc     MacroPtr+1
LEC89:  dec     MacroRemainingLength
        ldx     #0
        pla
        rts
;;; Keyboard & mouse input, blinking cursor
;;; Returns KeyModReg in X
LEC90:  jsr     LEB46 ; TODO: define label
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
        lda     #1
        sei
        jsr     CallSetMouse
        cli
        ldx     MouseSlot
;;; Mouse pos is always recentered, then compared to the
;;; MousePos(Min,Max) values to track the mouse movement.
;;; Mouse movements are mapped to arrow key keypresses
;;; for later processing.
        lda     #StartingMousePos
        sta     Mouse::MOUXL,x
        sta     Mouse::MOUYL,x
        lda     #0
        sta     Mouse::MOUXH,x
        sta     Mouse::MOUYH,x
        jsr     LoadXYForMouseCall
        sei
        jsr     CallPosMouse
        cli
LECCF:  jsr     DisplayCurrentDateAndTimeInMenuBar
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
LECEB:  ldy     #0
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
        ldy     #4
        lda     Mouse::MOUSTAT,x
        bpl     LED23
LED09:  cli
        jsr     LoadXYForMouseCall
        sei
        jsr     CallReadMouse
        ldx     MouseSlot
        ldy     #4
        lda     Mouse::MOUSTAT,x
        bmi     LED09
        lda     #$80
        jsr     CallWaitMonitorRoutine
        ldy     #4
        bra     LED5B
LED23:  dey
        lda     Mouse::MOUXL,x
        cmp     MousePosMin
        blt     LED5B           ; movement left maps to left arrow
        dey
        cmp     MousePosMax
        bge     LED5B           ; movement right maps to right arrow
        dey
        lda     Mouse::MOUYL,x
        cmp     MousePosMin
        blt     LED5B           ; movement up maps to up arrow
        dey
        cmp     MousePosMax
        bge     LED5B           ; movement down maps to down arrow
        cli
        bra     LED4E
LED44:  ldy     #$4B            ; 75
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
        lda     CursorMovementControlChars,y
LED5F:  bit     SoftSwitch::RDBTN0
        bmi     LED71
        bit     SoftSwitch::RDBTN1
        bpl     LED73
        cmp     #HICHAR('1')
        blt     LED71
        cmp     #HICHAR(':')
        bge     HandleMacroFunctionKey
LED71:  and     #%01111111      ; clear MSB
LED73:  pha
        lda     CharUnderCursor
        jsr     WriteCharToScreen
LoadKeyModReg:
        ldx     SoftSwitch::KEYMODREG
        txa
        and     #%00010000 ; check if numeric keypad key pressed
        beq     LED8E
        ldy     #8
        pla
LED85:  cmp     MacroFunctionKeys,y
        beq     LEDA0
        dey
        bpl     LED85
        pha
LED8E:  stz     SoftSwitch::KBDSTRB
        pla
        rts

;;; Function keys F1-F9 (on Extended Keyboard II) are used to invoke
;;; macros 1-9.
MacroFunctionKeys:
        .byte   ControlChar::F1
        .byte   ControlChar::F2
        .byte   ControlChar::F3
        .byte   ControlChar::F4
        .byte   ControlChar::F5
        .byte   ControlChar::F6
        .byte   ControlChar::F7
        .byte   ControlChar::F8
        .byte   ControlChar::F9

HandleMacroFunctionKey:
        and     #%00001111
        dec     a
        tay
LEDA0:  jsr     LoadMacroPointer
        lda     (MacroPtr)
        sta     MacroRemainingLength
        beq     LEDBC
        inc     MacroPtr
        bne     LEDB0
        inc     MacroPtr+1
LEDB0:  lda     CharUnderCursor
        jsr     WriteCharToScreen
        stz     SoftSwitch::KBDSTRB
        jmp     GetKeypress
LEDBC:  stz     SoftSwitch::KBDSTRB
        lda     CharUnderCursor
        jsr     WriteCharToScreen
        jmp     GetKeypress

;;; Load pointer to macro #Y into MacroPtr
LoadMacroPointer:
        lda     #<MacroTable
        sta     MacroPtr
        lda     #>MacroTable
        sta     MacroPtr+1
        cpy     #0
        beq     @Out
LEDD4:  lda     MacroPtr
        clc
        adc     #MaxMacroLength+1 ; length of macro table entry
        sta     MacroPtr
        bcc     LEDDF
        inc     MacroPtr+1
LEDDF:  dey
        bne     LEDD4
@Out:   rts

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
        bcs     @Odd
        ldy     SoftSwitch::TXTPAGE2
@Odd:   tay
        pla
        sta     (ZeroPage::BAS),y
        sta     SoftSwitch::TXTPAGE1
        rts

ReadCharFromScreen:
        lda     Columns80::OURCH
        lsr     a
        bcs     @Odd
        ldy     SoftSwitch::TXTPAGE2
@Odd:   tay
        lda     (ZeroPage::BAS),y
        sta     SoftSwitch::TXTPAGE1
        rts

DisplayCurrentDateAndTimeInMenuBar:
        lda     #ProDOS::CGETTIME
        ldx     #0
        ldy     #0
        jsr     MakeMLICall
        jsr     FormatCurrentDate
        jsr     FormatCurrentTime
        lda     ProDOS::MACHID
        lsr     a
        bcc     @Out           ; branch if no clock/cal card
        lda     ZeroPage::CV
        pha
        lda     Columns80::OURCH
        pha
        ldx     #60
        ldy     #1
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        lda     <DateTimeFormatString
        ldx     >DateTimeFormatString
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        plx
        ply
        jsr     SetCursorPosToXY
@Out:   rts

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
        ldx     #0
LEE7E:  lda     MonthNames-3,y
        sta     DateTimeFormatString+5,x
        iny
        inx
        cpx     #4
        blt     LEE7E
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
        .byte   $00
TimeHiByte:
        .byte   $00

ConvertToBase10:
        sec
        sbc     #10
        inx
        bcs     ConvertToBase10
        adc     #10
        ora     #%10110000
        rts

DrawCurrentDocumentLine:
        stz     Columns80::OURCH
        ldx     CurLinePtr+1
        lda     CurLinePtr
        lsr     a
        php
        rol     a
        plp
        bcc     @Even
        sta     SoftSwitch::RDCARDRAM
@Even:  jsr     DisplayString
        sta     SoftSwitch::RDMAINRAM
        jsr     ClearToEndOfLine
        bit     ShowCRFlag
        bpl     @Out
        jsr     GetLengthOfCurrentLine
        bpl     LEF0F
        jsr     OutputReturnSymbol
        lda     Columns80::OURCH
        bne     @Out
        lda     ZeroPage::CV
        dec     a
        jsr     ComputeTextOutputPos
        lda     #LastColumn
        sta     Columns80::OURCH
@Out:  rts

;;; Redraws the editing area (lines 3 - 21).
DisplayAllVisibleDocumentLines:
        jsr     SaveCurrentLineState2
        ldy     CurrentCursorYPos
LEF16:  cpy     #TopTextLine
        beq     LEF20
        jsr     LoadPreviousLinePointer
        dey
        bra     LEF16
LEF20:  ldx     #0
        jsr     SetCursorPosToXY
LEF25:  jsr     DrawCurrentDocumentLine
        lda     ZeroPage::CV
        cmp     #BottomTextLine
        beq     LEF3E
        jsr     IsOnLastDocumentLine
        beq     LEF3B
        jsr     MoveTextOutputPosToStartOfNextLine
        jsr     LoadNextLinePointer
        bra     LEF25
LEF3B:  jsr     ClearTextWindowFromCursor
LEF3E:  jsr     RestoreCurrentLineState2
        rts

DisplayDefaultStatusText:
        Lda     #<TD61F ; "Enter text or use OA-cmds..."
        ldx     #>TD61F
        jmp     DisplayStringInStatusLine

DisplayHelpKeyCombo:
        ldx     #67
        ldy     #StatusLine
        jsr     SetCursorPosToXY
        lda     #<TD591 ; "OA-? for Help"
        ldx     #>TD591
        jsr     DisplayMSB1String
        rts

DisplayLineAndColLabels:
        ldy     #StatusLine
        ldx     #44
        jsr     SetCursorPosToXY
        lda     #<TD649 ; Line / Col
        ldx     #>TD649
        jsr     DisplayMSB1String
        rts

DisplayCurrentLineAndCol:
        ldy     #StatusLine
        ldx     #49
        jsr     SetCursorPosToXY
        ldx     CurrentLineNumber+1
        lda     CurrentLineNumber
        ldy     #4
        jsr     DisplayAXInDecimal
        lda     #59
        sta     Columns80::OURCH
        ldx     #0
        lda     CurrentCursorXPos
        inc     a
        ldy     #3
        jsr     DisplayAXInDecimal
        rts

;;; Routine that displays the help text.
DisplayHelpText:
        lda     SoftSwitch::RWLCRAMB2
        lda     SoftSwitch::RWLCRAMB2
        lda     #<TD000
        sta     Pointer
        lda     #>TD000
        sta     Pointer+1
@Loop:  lda     (Pointer)
        beq     @Done
        jsr     OutputCharAndAdvanceScreenPos
        inc     Pointer
        bne     @Loop
        inc     Pointer+1
        bra     @Loop
@Done:  lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        rts

;;; Routine that displays one of the strings in LCRAM bank 2
;;; pointer is in A (lo), X (hi)
;;; displays an msb-off string
DisplayString:
        sta     StringPtr
        stx     StringPtr+1
        lda     #%10000000
        sta     CharORMask
        ldy     #0
        lda     (StringPtr),y
        and     #%01111111
        bra     LEFD0

;;;  displays an msb-on string
DisplayMSB1String:
        sta     StringPtr
        stx     StringPtr+1
        stz     CharORMask
        lda     SoftSwitch::RWLCRAMB2
        lda     SoftSwitch::RWLCRAMB2
        ldy     #0
LEFCE:  lda     (StringPtr),y
LEFD0:  beq     LEFDF
        tax
LEFD3:  iny
        lda     (StringPtr),y
        ora     CharORMask
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

SetMaskForInverseText:
        lda     #%01111111
        .byte   OpCode::BIT_Abs
SetMaskForNormalText:
        lda     #%11111111
        sta     CharANDMask
        rts

DrawAbortButton:
        jsr     DrawButtonFrame
        ldx     ScreenXCoord
        inx
        ldy     ScreenYCoord
        iny
        jsr     SetCursorPosToXY
        lda     #<TD6EE ; Abort - Esc
        ldx     #>TD6EE
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        rts

DrawAcceptButton:
        jsr     DrawButtonFrame
        ldx     ScreenXCoord
        inx
        ldy     ScreenYCoord
        iny
        jsr     SetCursorPosToXY
        lda     #<TD6FD ; Accept - Return
        ldx     #>TD6FD
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        rts

DrawButtonFrame:
        sty     ScreenYCoord
        stx     ScreenXCoord
        inx
        jsr     SetCursorPosToXY
        ldy     #14
        jsr     OutputUnderscoreLine
        ldy     ScreenYCoord
        iny
        ldx     ScreenXCoord
        jsr     SetCursorPosToXY
        jsr     OutputRightVerticalBar
        lda     Columns80::OURCH
        clc
        adc     #14
        sta     Columns80::OURCH
        jsr     OutputLeftVerticalBar
        ldy     ScreenYCoord
        ldx     ScreenXCoord
        iny
        iny
        inx
        jsr     SetCursorPosToXY
        ldy     #14
        jsr     OutputOverscoreLine
        rts

;;;  This is like a MLI call; it reads 7 bytes from memory after the JSR.
;;; byte    0: ($EA): height of box
;;; byte    1: ($EB): width of box
;;; byte    2: ($EC): y-coordinate of top-left corner of box
;;; byte    3: ($ED): x-coordinate of top-left corner of box
;;; byte    4: x-coordinate of title string
;;; bytes 5-6: pointer to title string

DrawDialogBox:
        pla
        sta     ParamTablePtr
        pla
        sta     ParamTablePtr+1
;;;  ParamTablePtr now points to 1 byte before the start of the param table
;;;  copy first 4 bytes of param table to $EA - $ED
        ldy     #4
LF066:  lda     (ParamTablePtr),y
        sta     DialogHeight-1,y
        dey
        bne     LF066
        jsr     DrawDialogBoxFrame
        jsr     SetMaskForInverseText
        ldy     #5
        lda     (ParamTablePtr),y
        tax
        ldy     ScreenYCoord
        jsr     SetCursorPosToXY
;;; Draw the title string
        ldy     #7
        lda     (ParamTablePtr),y
        tax
        dey
        lda     (ParamTablePtr),y
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
;;;  Calculate return address and push it on the stack.
        lda     ParamTablePtr
        clc
        adc     #7
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
        lda     #MT_REMAP(MouseText::TitleBar) ; IIGS only
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
        lda     #<TD693 ; "Esc to go back"
        ldx     #>TD693
        jsr     DisplayMSB1String
FinishDisplayStringInStatusLine:
        stz     Columns80::OURCH
        plx
        pla
        jmp     DisplayMSB1String

DisplayStringInStatusLine:
        pha
        phx
        jsr     ClearStatusLine
        bra     FinishDisplayStringInStatusLine

ClearStatusLine:
        ldy     #StatusLine
        ldx     #0
        jsr     SetCursorPosToXY
        jsr     ClearToEndOfLine
        rts

DisplayHitEscToEditDocInStatusLine:
        lda     #<TD70C ; "Hit ESC to edit document"
        ldx     #>TD70C
        jmp     DisplayStringInStatusLine

WaitForSpaceToContinueInStatusLine:
        lda     #<TD726 ; "Press <space> to continue"
        ldx     #>TD726
        jsr     DisplayStringInStatusLine
WaitForSpaceKeypress:
        ldx     #2
        jsr     GetSpecificKeypress
        cpx     #0
        beq     WaitForSpaceKeypress
        rts

CharToUppercase:
        cmp     #HICHAR('a')
        blt     @Out
        cmp     #HICHAR('{')
        bge     @Out
        and     #ToUpperCaseANDMask
@Out:   rts

;;; This appears to be restoring the text screen (rows 2-9,
;;; under the menus) from $800 in aux mem
RestoreScreenAreaUnderMenus:
        lda     #<BackingStoreBuffer
        sta     Pointer6
        lda     #>BackingStoreBuffer
        sta     Pointer6+1
        lda     #2
LF139:  jsr     ComputeTextOutputPos
        lda     #LastColumn
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
        cmp     #9
        bge     LF168
        inc     a
        bra     LF139
LF168:  rts

;;; This appears to be storing text rows 2-9 (which are obscured by
;;; menus) to $800 in aux mem
SaveScreenAreaUnderMenus:
        lda     #<BackingStoreBuffer
        sta     Pointer6
        lda     #>BackingStoreBuffer
        sta     Pointer6+1
        lda     #2
LF173:  jsr     ComputeTextOutputPos
        lda     #LastColumn
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
        adc     #80
        sta     Pointer6
        bcc     LF199
        inc     Pointer6+1
LF199:  lda     ZeroPage::CV
        cmp     #9
        bge     @Out
        inc     a
        bra     LF173
@Out:   rts

;;; Standard ProDOS tone
PlayTone:
        lda     #$20
        sta     PlayToneCounter
@Loop:  lda     #2
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

PerformBlockSelection:
        jsr     SaveCurrentLineState2
        stz     CurrentCursorXPos
        lda     #<TD93A ; "Use up/down to highlight block..."
        ldx     #>TD93A
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     SwapCursorMovementControlChars
        jsr     DisplayLineAndColLabels
        jsr     DrawCurrentDocumentLineInInverse
LF1D5:  jsr     DisplayCurrentLineAndCol
        lda     #41
LF1DA:  sta     Columns80::OURCH
LF1DD:  jsr     GetKeypress
        cmp     #ControlChar::UpArrow ; OA-Up
        beq     LF248
        cmp     #ControlChar::DownArrow ; OA-Down
        beq     LF205
        cmp     #HICHAR(ControlChar::DownArrow)
        beq     LF209
        cmp     #HICHAR(ControlChar::UpArrow)
        beq     LF24C
        cmp     #HICHAR(ControlChar::Esc)
        bne     LF1F7
        jmp     CancelBlockSelection
LF1F7:  cmp     #HICHAR(ControlChar::Return)
        bne     LF200
;;; Finish block selection
        jsr     SwapCursorMovementControlChars
        clc
        rts
;;; Invalid char entered during block selection
LF200:  jsr     PlayTone
        bra     LF1DD
;;; block select forward one page
LF205:  lda     #VisibleLineCount
        bra     LF20B
;;; block select forward one line
LF209:  lda     #1
LF20B:  sta     ScratchVal1
LF20E:  jsr     IsOnLastDocumentLine
        beq     LF1D5
        lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber2+1
        beq     LF21F
        bge     LF232
        blt     LF227
LF21F:  lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber2
        bge     LF232
LF227:  ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     DrawCurrentDocumentLine
LF232:  ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     MoveToNextDocumentLine
        jsr     DrawCurrentDocumentLineInInverse
        dec     ScratchVal1
        bne     LF20E
        jmp     LF1D5
;;; block select backward one page
LF248:  lda     #VisibleLineCount
        bra     LF24E
;;; block select backward one line
LF24C:  lda     #1
LF24E:  sta     ScratchVal1
LF251:  jsr     IsOnFirstDocumentLine
        bne     LF259
        jmp     LF1D5
LF259:  lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber2+1
        beq     LF265
        blt     LF27A
        bge     LF26F
LF265:  lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber2
        blt     LF27A
        beq     LF27A
LF26F:  ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     DrawCurrentDocumentLine
LF27A:  ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     MoveToPreviousDocumentLine
        jsr     DrawCurrentDocumentLineInInverse
        dec     ScratchVal1
        bne     LF251
        jmp     LF1D5

CancelBlockSelection:
        jsr     RestoreCurrentLineState2
        jsr     SwapCursorMovementControlChars
        sec
        rts

;;; swaps these two lists of control characters
SwapCursorMovementControlChars:
        ldy     #4
@Loop:  lda     CursorMovementControlChars,y
        pha
        lda     BlockSelectionCursorControlChars,y
        sta     CursorMovementControlChars,y
        pla
        sta     BlockSelectionCursorControlChars,y
        dey
        bpl     @Loop
        rts

;;; Remapped Control chars during block selection
BlockSelectionCursorControlChars:
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::Return)

DrawCurrentDocumentLineInInverse:
        ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        jsr     DrawCurrentDocumentLine
        jsr     SetMaskForNormalText
        rts

ShowPrintDialog:
        jsr     DrawDialogBox
        .byte   10 ; height
        .byte   42 ; width
        .byte   5  ; y-coord
        .byte   18 ; x-coord
        .byte   34 ; x-coord of title
        .addr   TDAD0 ; "Print File"
        ldx     #38
        ldy     #12
        jsr     DrawAbortButton
        jsr     DisplayHitEscToEditDocInStatusLine
LF2D7:  ldy     #7
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TDADD ; "Printer Slot?"
        ldx     #>TDADD
        jsr     DisplayMSB1String
        lda     PrinterSlot
        jsr     InputSingleDigit
        bcs     LF31E
        cmp     #8
        bge     LF2F5
        cmp     #0
        bne     LF2FA
LF2F5:  jsr     PlayTone
        bra     LF2D7
LF2FA:  sta     PrinterSlot
        ldy     #8
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TDAF1 ; "Printer init string:"
        ldx     #>TDAF1
        jsr     DisplayMSB1String
        ldy     PrinterInitString
LF30E:  lda     PrinterInitString,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LF30E
        lda     #20
        jsr     InputSingleLine
        bcc     LF31F
LF31E:  rts
LF31F:  ldy     ProDOS::SysPathBuf
LF322:  lda     ProDOS::SysPathBuf,y
        sta     PrinterInitString,y
        dey
        bpl     LF322
        ldx     #1
        ldy     #1
LF32F:  lda     ProDOS::SysPathBuf,x
        and     #%01111111
        cmp     #'^'
        bne     LF33E
        inx
        lda     ProDOS::SysPathBuf,x
        and     #UppercaseToControlCharANDMask
LF33E:  sta     PrinterInitStringRawBytes,y
        cpx     ProDOS::SysPathBuf
        bge     LF34A
        inx
        iny
        bra     LF32F
LF34A:  lda     ProDOS::SysPathBuf
        bne     LF351
        ldy     #0
LF351:  sty     PrinterInitStringRawBytes
        ldy     #9
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TDB46 ; "Enter left margin..."
        ldx     #>TDB46
        jsr     DisplayMSB1String
        lda     PrinterLeftMargin
        jsr     InputSingleDigit
        bcs     LF31E ; cancelled, so return
        sta     PrinterLeftMargin
        ldy     #10
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TDB06 ; "Print from start/cursor..."
        ldx     #>TDB06
        jsr     DisplayMSB1String
LF37B:  jsr     GetKeypress ; input routine
        jsr     CharToUppercase
        cmp     #HICHAR(ControlChar::Esc)
        beq     LF31E
        cmp     #HICHAR('C')
        beq     LF397
        cmp     #HICHAR('S')
        beq     LF392
        jsr     PlayTone
        bra     LF37B
;;; print from start
LF392:  pha
        jsr     LoadFirstLinePointer
        pla
;;; print from cursor
LF397:  jsr     OutputCharAndAdvanceScreenPos
        ldy     #11
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TDB27 ; "Printing..."
        ldx     #>TDB27
        jsr     DisplayMSB1String
        lda     PrinterSlot
        ora     #%11000000 ; $Cs
        sta     Pointer+1
        stz     Pointer
;;; Check for Serial firmware signature bytes
        ldy     #7
        lda     (Pointer),y
        cmp     #$18
        bne     LF3CF
        ldy     #5
        lda     (Pointer),y
        cmp     #$38
        bne     LF3CF
        ldy     #12
        lda     (Pointer),y
        and     #%11110000
        cmp     #$30 ; Serial/Parallel card?
        beq     FoundPrinter
        cmp     #$10 ; Printer?
        beq     FoundPrinter
LF3CF:  ldy     #1
        lda     (Pointer),y
        cmp     #$20
        bne     LF3EF
        ldy     #3
        lda     (Pointer),y
        bne     LF3EF
LF3DD:  ldy     #5
        lda     (Pointer),y
        cmp     #3
        bne     LF3EF
        lda     #<TDB33 ; "Printer not found"
        ldx     #>TDB33
        jsr     DisplayMSB1String
        jmp     BeepAndWaitForReturnOrEscKey
LF3EF:  jsr     DeterminePrinterOutputRoutineAddress
        lda     #$FF
        sta     PrinterLineFeedFlag
        jmp     LF417
FoundPrinter:
LF3FA:  ldy     #$0D; get PInit entry point
        lda     (Pointer),y
        sta     PrinterOutputRoutineAddress
        stz     PrinterLineFeedFlag
        lda     Pointer+1
        sta     PrinterOutputRoutineAddress+1
        lda     #' '
        jsr     SendCharacterToPrinter
        stz     Pointer
        ldy     #$0F ; get PWrite entry point
        lda     (Pointer),y
        sta     PrinterOutputRoutineAddress
LF417:  jsr     DisableCSW
        lda     PrinterInitStringRawBytes
        beq     LF437 ; skip if no init string
        lda     #<PrinterInitStringRawBytes
        ldx     #>PrinterInitStringRawBytes
        jsr     SendLineAtAXToPrinter
        lda     SoftSwitch::RD80VID ; reset text screen
        bmi     LF437
        jsr     ResetTextScreen
        jsr     ClearTextWindow
        jsr     DrawMenuBarAndMenuTitles ; and redraw UI
        jsr     OutputStatusBarLine
LF437:  lda     #NumLinesOnPrintedPage-1 ; lines left on page
        bra     LF442
;;; Start next printed page
LF43B:  lda     #ControlChar::ControlL ; form feed
        jsr     SendCharacterToPrinter
        lda     #NumLinesOnPrintedPage
LF442:  sta     ScratchVal4 ; counter for lines left on printed page
LF445:  jsr     SendLineToPrinter
        lda     SoftSwitch::KBD
        bpl     LF454
        sta     SoftSwitch::KBDSTRB
        cmp     #HICHAR(ControlChar::Esc)
        beq     LF463
LF454:  jsr     IsOnLastDocumentLine
        beq     LF463
        jsr     LoadNextLinePointer
        dec     ScratchVal4
        bne     LF445
        bra     LF43B
;;; finish or abort print
LF463:  lda     #ControlChar::ControlL ; form feed
        jsr     SendCharacterToPrinter
        jsr     RestoreCSW
        rts

SendLineToPrinter:
        ldy     PrinterLeftMargin ; loop to print
        beq     LF47B             ; left margin spaces
LF471:  lda     #' '
        phy
        jsr     SendCharacterToPrinter
        ply
        dey
        bne     LF471
LF47B:  jsr     CopyCurrentLineToSysPathBuf
        lda     #<ProDOS::SysPathBuf
        ldx     #>ProDOS::SysPathBuf
SendLineAtAXToPrinter:
        sta     Pointer
        stx     Pointer+1
        lda     (Pointer)
        and     #%01111111
        sta     ScratchVal1 ; length of line to print
        beq     LF4A4
        lda     #1
        sta     ScratchVal6
LF494:  ldy     ScratchVal6 ; offset of char in line
        lda     (Pointer),y
        jsr     SendCharacterToPrinter
        inc     ScratchVal6
        dec     ScratchVal1
        bne     LF494
LF4A4:  lda     #ControlChar::Return
        jsr     SendCharacterToPrinter
        lda     PrinterLineFeedFlag
        bne     LF4B3
        lda     #HICHAR(ControlChar::ControlJ) ; line feed
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

;;; A single-line input routine. Maximum length+1 passed in A.
;;; Returns with Carry set if input was cancelled with Esc.
InputSingleLine:
        sta     Pointer6+1
        lda     Columns80::OURCH
        sta     MenuDrawingIndex
@RedisplayInput:
        lda     MenuDrawingIndex
        sta     Columns80::OURCH
        ldy     Pointer6+1
        jsr     OutputSpaces
        lda     MenuDrawingIndex
        sta     Mouse::MOUXH+3
        lda     #<ProDOS::SysPathBuf
        ldx     #>ProDOS::SysPathBuf
        jsr     DisplayMSB1String
@InputChar:
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::Esc)
        beq     @Cancel
        cmp     #HICHAR(ControlChar::Return)
        beq     @Accept
        cmp     #HICHAR(ControlChar::Delete)
        beq     @DelChar
        cmp     #HICHAR(ControlChar::LeftArrow)
        beq     @DelChar
        cmp     #HICHAR(ControlChar::ControlX)
        beq     @DelAll
        cmp     #HICHAR(' ')
        bge     @ValidChar
@BadChar:
        jsr     PlayTone ; don't allow any other control chars
        bra     @InputChar
@ValidChar:
        ldy     ProDOS::SysPathBuf
        iny
        cpy     Pointer6+1
        bge     @BadChar
        sta     ProDOS::SysPathBuf,y
        sty     ProDOS::SysPathBuf
        bra     @RedisplayInput
@DelChar:
        lda     ProDOS::SysPathBuf
        beq     @BadChar
        dec     a
        sta     ProDOS::SysPathBuf
        jmp     @RedisplayInput
@DelAll:
        stz     ProDOS::SysPathBuf
        jmp     @RedisplayInput
@Accept:
        clc
        rts
@Cancel:
        sec
        rts

DisplayAXInHexadecimal:
        jsr     @ByteToHex
        txa
@ByteToHex:
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     @NibbleToHex
        pla
        and     #%00001111
@NibbleToHex:
        ora     #HICHAR('0')
        cmp     #HICHAR(':')
        blt     LF559
        adc     #6
LF559:  jmp     OutputCharAndAdvanceScreenPos

;;; Display AX in decimal, with width of Y
DisplayAXInDecimal:
        jsr     FormatAXInDecimal
        lda     #<StringFormattingBuffer
        ldx     #>StringFormattingBuffer
        jsr     DisplayMSB1String
        rts

;;; Format AX as decimal, with width in Y
FormatAXInDecimal:
        sta     ScratchVal4
        stx     ScratchVal5
        sty     StringFormattingBuffer
LF570:  jsr     ConvertNextDecimalDigit
        lda     ScratchVal6
        ora     #%10110000
        sta     StringFormattingBuffer,y
        dey
        lda     ScratchVal4
        ora     ScratchVal5
        bne     LF570
        lda     #HICHAR(' ')
        cpy     #0
        beq     LF590
LF58A:  sta     StringFormattingBuffer,y
        dey
        bne     LF58A
LF590:  rts

ConvertNextDecimalDigit:
        ldx     #$10
        lda     #0
        sta     ScratchVal6
LF598:  jsr     LF5B0
        rol     ScratchVal6
        sec
        lda     ScratchVal6
        sbc     #$0A
        bcc     LF5AC
        sta     ScratchVal6
        inc     ScratchVal4
LF5AC:  dex
        bne     LF598
        rts
;;; shift word left
LF5B0:  asl     ScratchVal4
        rol     ScratchVal5
        rts

MoveCursorToHomePos:
        lda     #TopTextLine
        sta     CurrentCursorYPos
        stz     CurrentCursorXPos
        rts

SaveCurrentLineState2:
        lda     CurLinePtr
        sta     SavedCurLinePtr2
        lda     CurLinePtr+1
        sta     SavedCurLinePtr2+1
        lda     CurrentLineNumber
        sta     SavedCurrentLineNumber2
        lda     CurrentLineNumber+1
        sta     SavedCurrentLineNumber2+1
        rts

RestoreCurrentLineState2:
        lda     SavedCurrentLineNumber2+1
        sta     CurrentLineNumber+1
        lda     SavedCurrentLineNumber2
        sta     CurrentLineNumber
        lda     SavedCurLinePtr2+1
        sta     CurLinePtr+1
        lda     SavedCurLinePtr2
        sta     CurLinePtr
        rts

SaveCurrentLineState:
        lda     CurLinePtr
        sta     SavedCurLinePtr
        lda     CurLinePtr+1
        sta     SavedCurLinePtr+1
        lda     CurrentLineNumber
        sta     SavedCurrentLineNumber
        lda     CurrentLineNumber+1
        sta     SavedCurrentLineNumber+1
        rts

RestoreCurrentLineState:
        lda     SavedCurrentLineNumber+1
        sta     CurrentLineNumber+1
        lda     SavedCurrentLineNumber
        sta     CurrentLineNumber
        lda     SavedCurLinePtr+1
        sta     CurLinePtr+1
        lda     SavedCurLinePtr
        sta     CurLinePtr
        rts

;;; Returns with Zero flag set if on last line of doc.
IsOnLastDocumentLine:
        lda     CurrentLineNumber
        cmp     DocumentLineCount
        bne     @Out
        lda     CurrentLineNumber+1
        cmp     DocumentLineCount+1
@Out:   rts

;;; Returns the current line length in A,
;;; and Carry clear if cursor is at (or past) end of line.
IsCursorAtEndOfLine:
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        cmp     CurrentCursorXPos
        rts

;;; Returns with Zero flag set if memory full
CheckIfMemoryFull:
        lda     DocumentLineCount
        cmp     #<MaxLineCount
        bne     @Out
        lda     DocumentLineCount+1
        cmp     #>MaxLineCount
        bne     @Out
        lda     #<TDA94 ; "Memory full..."
        ldx     #>TDA94
        jsr     DisplayStringInStatusLine
        jsr     BeepAndWaitForReturnOrEscKey
        jsr     DisplayDefaultStatusText
        jsr     DisplayHelpKeyCombo
        jsr     DisplayLineAndColLabels
        lda     #0
        sta     PathnameBuffer
@Out:   rts

IsOnFirstDocumentLine: ;; F65B
        lda     CurrentLineNumber
        cmp     #1
        bne     @Out
        lda     CurrentLineNumber+1
@Out:   rts

LoadPreviousLinePointer:        ;f666
        jsr     DecrementCurrentLineNumber
        jsr     LoadCurrentLinePointerIntoAX
        sta     CurLinePtr
        stx     CurLinePtr+1
        rts

DecrementCurrentLineNumber:;; f671
        dec     CurrentLineNumber
        lda     CurrentLineNumber
        cmp     #$FF
        bne     @Out
        dec     CurrentLineNumber+1
@Out:   rts

LoadCurrentLinePointerIntoAX:        ;; f67f
;;; decrements by 1 to get pointer offset;
;;; this is because line numbers start at 1
        lda     CurrentLineNumber
        ldx     CurrentLineNumber+1
LoadLineAXPointerIntoAX_1:
        dec     a
        cmp     #$FF
        bne     LoadLineAXPointerIntoAX
        dex
;;; multiplies AX by 2 to get offset into line pointer table, then
;;; loads that pointer into AX.
LoadLineAXPointerIntoAX:
        asl     a
        sta     Pointer
        txa
        rol     a
        sta     Pointer+1
        lda     Pointer
        clc
        adc     #<LinePointerTable
        sta     Pointer
        lda     Pointer+1
        adc     #>LinePointerTable
        sta     Pointer+1
        phy
        ldy     #1
        lda     (Pointer),y
        tax
        lda     (Pointer)
        ply
        rts

LoadNextLinePointer:
        jsr     IncrementCurrentLineNumber
        jsr     LoadCurrentLinePointerIntoAX
        sta     CurLinePtr
        stx     CurLinePtr+1
        rts

IncrementCurrentLineNumber:
        inc     CurrentLineNumber
        bne     @Out
        inc     CurrentLineNumber+1
@Out:   rts

;;; never referenced? $F6BD
        ldx     CurrentLineNumber+1
        lda     CurrentLineNumber
        clc
        adc     #2
        bcc     LF6C9
        inx
LF6C9:  jsr     LoadLineAXPointerIntoAX_1
        sta     Pointer4
        stx     Pointer4+1
        rts

MoveToPreviousDocumentLine:
;;; scrolls down if necessary
        lda     CurrentCursorYPos
        cmp     #TopTextLine
        beq     @DoScroll
        dec     CurrentCursorYPos
        jsr     LoadPreviousLinePointer
        rts
@DoScroll:
        jsr     ScrollDownOneLine
        jsr     LoadPreviousLinePointer
        jsr     DrawCurrentDocumentLine
        rts

;;; scrolls up if necessary
MoveToNextDocumentLine:
        lda     CurrentCursorYPos
        cmp     #BottomTextLine
        beq     @DoScroll
        inc     CurrentCursorYPos
        jsr     LoadNextLinePointer
        rts
@DoScroll:
        jsr     ScrollUpOneLine
        jsr     LoadNextLinePointer
        jsr     DrawCurrentDocumentLine
        rts

;;; Move left past all spaces in current line,
;;; starting at position Y. Updates Y.
SkipSpacesBackward:
        cpy     #2
        blt     @Out
        dey
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     SkipSpacesBackward
@Out:   rts

;;; Move right past all spaces in current line,
;;; starting at position Y. Updates Y.
SkipSpacesForward:
        cpy     LastEditableColumn
        beq     @Out
        iny
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     SkipSpacesForward
@Out:   rts

;;; Move left past all non-spaces in current line,
;;; starting at position Y. Updates Y.
SkipNonSpacesBackward:
        cpy     #2
        blt     @Out
        dey
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        bne     SkipNonSpacesBackward
        iny
@Out:   rts

;;; Move right past all non-spaces in current line,
;;; starting at position Y. Updates Y.
SkipNonSpacesForward:
        cpy     LastEditableColumn
        beq     @Out
        iny
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        bne     SkipNonSpacesForward
@Out:   rts

;;; set current line to 1 and load it into CurLinePtr.
LoadFirstLinePointer:
        stz     CurrentLineNumber+1
        lda     #1
        sta     CurrentLineNumber
        ldx     CurrentLineNumber+1
        jsr     LoadLineAXPointerIntoAX_1
        sta     CurLinePtr
        stx     CurLinePtr+1
        rts

;;; Pads line with spaces if line length is less than
;;; current cursor x-position. Updates line length,
;;; preserving MSB.
PadLineWithSpacesUpToCursor:
        jsr     GetLengthOfCurrentLine
        and     #%01111111 ; clear MSB
        tay
        lda     #' '
LF753:  cpy     CurrentCursorXPos
        beq     LF75E ; branch if cursor at end of line
        iny
        jsr     SetCharAtYInCurrentLine ; append space
        bra     LF753
LF75E:  jsr     GetLengthOfCurrentLine
        bpl     LF768 ; branch if MSB clear
        tya
        ora     #%10000000 ; set MSB
        bra     LF769
LF768:  tya
LF769:  jsr     SetLengthOfCurrentLine
        rts

;;; If on the last line of the doc, set its length to 0.
;;; Otherwise insert a new line. The newly inserted line
;;; will be at Pointer4.
InsertNewLine:
        jsr     LoadCurrentLinePointerIntoPointer4
        jsr     IsOnLastDocumentLine
        beq     LF778
        jsr     ShiftLinePointersDownForInsert
LF778:  lda     #0
        jsr     SetLengthOfLineAtPointer4

IncrementDocumentLineCount:
        inc     DocumentLineCount
        bne     @Out
        inc     DocumentLineCount+1
@Out:   rts

SetDocumentLineCountToCurrentLine:
        lda     CurrentLineNumber
        sta     DocumentLineCount
        lda     CurrentLineNumber+1
        sta     DocumentLineCount+1
        rts

DecrementDocumentLineCount:
        lda     DocumentLineCount
        dec     a
        sta     DocumentLineCount
        cmp     #$FF
        bne     @Out
        dec     DocumentLineCount+1
@Out:   rts

;;; Splits a line at the cursor. Y should also be set
;;; to the current cursor position within the line prior
;;; to calling.
SplitLineAtCursor:
        jsr     GetLengthOfCurrentLine
        bpl     LF7B1 ; branch if no CR at end of line
        lda     #$80
        jsr     SetLengthOfLineAtPointer4 ; empty line with CR
        jsr     GetLengthOfCurrentLine
        and     #%01111111
LF7B1:  sta     ScratchVal4 ; saved line length
        sec
        sbc     CurrentCursorXPos ; decrement it by length before cursor
        sta     ScratchVal4
        beq     LF7E8           ; if 0, current line will be an empty line with CR
        tya                     ; new length of current line is length before cursor
        ora     #%10000000 ; add CR
        jsr     SetLengthOfCurrentLine
        ldx     #1
LF7C5:  iny     ; then copy text after cursor to other line
        jsr     GetCharAtYInCurrentLine
        phy
        phx
        ply
        jsr     SetCharAtYInLineAtPointer4
        phy
        plx
        ply
        inx
        dec     ScratchVal4
        bne     LF7C5
        dex
        jsr     GetLengthOfLineAtPointer4
        bpl     LF7E3
        txa
        ora     #%10000000 ; add back CR
        bra     LF7E4
LF7E3:  txa
LF7E4:  jsr     SetLengthOfLineAtPointer4
LF7E7:  rts
LF7E8:  jsr     GetLengthOfCurrentLine
        bmi     LF7E7
        lda     #0
        bra     LF7E4

LoadCurrentLinePointerIntoPointer4:
        ldx     CurrentLineNumber+1
        lda     CurrentLineNumber
        jsr     LoadLineAXPointerIntoAX
        sta     Pointer4
        stx     Pointer4+1
        rts

;;; The newly inserted line will be at Pointer4.
ShiftLinePointersDownForInsert:
        jsr     SaveCurrentLineState2
        inc     SavedCurrentLineNumber2
        bne     @Skip
        inc     SavedCurrentLineNumber2+1
@Skip:  ldx     DocumentLineCount+1
        lda     DocumentLineCount
        sta     CurrentLineNumber
        stx     CurrentLineNumber+1
        jsr     LoadLineAXPointerIntoAX
        pha
        phx
        bra     @First
@Loop:  jsr     LoadPreviousLinePointer
@First: jsr     LoadCurrentLinePointerIntoAX
        ldy     #2
        sta     (Pointer),y
        iny
        txa
        sta     (Pointer),y
        lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber2
        bne     @Loop
        lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber2+1
        bne     @Loop
        ldy     #1
        pla
        sta     (Pointer),y
        pla
        sta     (Pointer)
        jsr     RestoreCurrentLineState2
        jsr     LoadPreviousLinePointer
        jsr     LoadCurrentLinePointerIntoPointer4
        rts

ShiftLinePointersUpForDelete:
        jsr     IsOnLastDocumentLine
        beq     @Out
        jsr     SaveCurrentLineState
@Loop:  jsr     LoadCurrentLinePointerIntoAX
        ldy     #3
        lda     (Pointer),y
        ldy     #1
        sta     (Pointer),y
        iny
        lda     (Pointer),y
        sta     (Pointer)
        jsr     IncrementCurrentLineNumber
        jsr     IsOnLastDocumentLine
        bne     @Loop
        ldy     #3
        lda     SavedCurLinePtr+1
        sta     (Pointer),y
        dey
        lda     SavedCurLinePtr
        sta     (Pointer),y
        jsr     RestoreCurrentLineState
        jsr     LoadCurrentLinePointerIntoAX
        sta     CurLinePtr
        stx     CurLinePtr+1
        jsr     LoadCurrentLinePointerIntoPointer4
@Out:   rts

;;; Word-wraps (reflows) the text up to the next CR
;;; (the end of the text line).
WordWrapUpToNextCR:
        jsr     SaveCurrentLineState2
        stz     ScratchVal11
LF88E:  jsr     IsOnLastDocumentLine
        bne     LF896
LF893:  jmp     LF94D
LF896:  jsr     GetLengthOfCurrentLine
        bmi     LF893
        cmp     DocumentLineLength
        bge     LF893
        jsr     LoadCurrentLinePointerIntoPointer4
        jsr     GetLengthOfCurrentLine
        sta     ScratchVal8
        jsr     GetLengthOfLineAtPointer4
        bpl     LF8B2
        and     #%01111111
        beq     LF893
LF8B2:  sta     ScratchVal9
        lda     DocumentLineLength
        sec
        sbc     ScratchVal8
        cmp     #2
        blt     LF893
        tay
        cmp     ScratchVal9
        blt     LF8DD
        ldy     ScratchVal9
        jsr     GetLengthOfLineAtPointer4
        and     #%10000000
        sta     ScratchVal2
        jsr     GetLengthOfCurrentLine
        ora     ScratchVal2
        jsr     SetLengthOfCurrentLine
        jmp     LF8E9
LF8DD:  jsr     GetCharAtYInLineAtPointer4
        cmp     #$20
        beq     LF8E9
        dey
        bne     LF8DD
        beq     LF94D
LF8E9:  sty     ScratchVal11
        sty     ScratchVal10
LF8EF:  jsr     GetCharAtYInLineAtPointer4
        sta     ProDOS::SysPathBuf,y
        dey
        bne     LF8EF
        lda     ScratchVal8
        tay
        clc
        adc     ScratchVal10
        sta     ScratchVal4
        jsr     GetLengthOfCurrentLine
        and     #%10000000
        ora     ScratchVal4
        jsr     SetLengthOfCurrentLine
        lda     ScratchVal10
        sta     ScratchVal4
        ldx     #1
LF916:  iny
        lda     ProDOS::SysPathBuf,x
        jsr     SetCharAtYInCurrentLine
        inx
        dec     ScratchVal4
        bne     LF916
        jsr     IsOnLastDocumentLine
        beq     LF94D
        jsr     LoadNextLinePointer
LF92B:  ldy     #1
        jsr     RemoveCharAtYOnCurrentLine
        lda     ScratchVal4
        beq     LF93A
        dec     ScratchVal10
        bne     LF92B
LF93A:  jsr     GetLengthOfCurrentLine
        and     #%01111111
        beq     LF944
        jmp     LF88E
LF944:  jsr     ShiftLinePointersUpForDelete
        jsr     LoadPreviousLinePointer
        jsr     DecrementDocumentLineCount
LF94D:  jsr     RestoreCurrentLineState2
        lda     ScratchVal11
        rts

;;; Returns the amount of space left on the previous line,
;;; if there is a previous line AND that line doesn't end
;;; with a CR; otherwise returns 0.
GetSpaceLeftOnPreviousLine:
        jsr     IsOnFirstDocumentLine
        beq     LF974
        jsr     LoadPreviousLinePointer
        jsr     GetLengthOfCurrentLine
        bmi     LF971 ; branch if ends in CR
        sta     ScratchVal2
        lda     DocumentLineLength
        sec
        sbc     ScratchVal2
        pha
        jsr     LoadNextLinePointer
        pla
        rts
LF971:  jsr     LoadNextLinePointer
LF974:  lda     #0
        rts

RemoveCharAtYOnCurrentLine:
        jsr     GetLengthOfCurrentLine
        and     #%01111111
        sta     ScratchVal4
        beq     LF9A1
;;;  loop to shift characters from Y to end of line left by 1
LF981:  cpy     ScratchVal4
        bge     LF993
        iny
        jsr     GetCharAtYInCurrentLine
        dey
        beq     LF990
        jsr     SetCharAtYInCurrentLine
LF990:  iny
        bra     LF981
;;; decrement length of current line
LF993:  dec     ScratchVal4
        jsr     GetLengthOfCurrentLine
        and     #%10000000
        ora     ScratchVal4
        jsr     SetLengthOfCurrentLine
LF9A1:  rts

;;; moves current word to next line if it won't fit on current one
MoveWordToNextLine:
        jsr     InsertNewLine
;;; search backward for the beginning of the word
        ldy     LastEditableColumn
        dey
LF9A9:  jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     LF9B6
        dey
        bne     LF9A9
        ldy     LastEditableColumn
LF9B6:  cpy     LastEditableColumn
        bne     LF9CA
        ldy     #1
        jsr     SetCharAtYInLineAtPointer4
        tya
        jsr     SetLengthOfLineAtPointer4
        jsr     GetLengthOfCurrentLine
        dec     a
        bra     LF9DB
LF9CA:  lda     CurrentCursorXPos
        pha
        sty     CurrentCursorXPos
        jsr     SplitLineAtCursor
        pla
        sta     CurrentCursorXPos
        jsr     GetLengthOfCurrentLine
LF9DB:  and     #%01111111
        jsr     SetLengthOfCurrentLine
        jsr     LoadNextLinePointer
        jsr     WordWrapUpToNextCR
        jsr     LoadPreviousLinePointer
        rts

GetLengthOfCurrentLine:
        sty     YRegisterStorage
        ldy     #0
        bra     LF9F4
GetCharAtYInCurrentLine:
        sty     YRegisterStorage
LF9F4:  lda     CurLinePtr
        lsr     a
        bcc     LFA07
        sta     SoftSwitch::RDCARDRAM
        lda     (CurLinePtr),y
        sta     SoftSwitch::RDMAINRAM
LFA01:  pha
        ldy     YRegisterStorage
        pla
        rts
LFA07:  lda     (CurLinePtr),y
        bra     LFA01

GetLengthOfLineAtPointer4:
;;; loads A from *Pointer4
        sty     YRegisterStorage
        ldy     #0
        bra     LFA15
;;; Loads a from *(Pointer4 + Y)
GetCharAtYInLineAtPointer4:
        sty     YRegisterStorage
LFA15:  lda     Pointer4
        lsr     a
        bcc     LFA28
        sta     SoftSwitch::RDCARDRAM
        lda     (Pointer4),y
        sta     SoftSwitch::RDMAINRAM
LFA22:  pha
        ldy     YRegisterStorage
        pla
        rts
LFA28:  lda     (Pointer4),y
        bra     LFA22

SetLengthOfCurrentLine:
        sty     YRegisterStorage
        ldy     #0
        bra     LFA36
SetCharAtYInCurrentLine:
        sty     YRegisterStorage
LFA36:  pha
        lda     CurLinePtr
        lsr     a
        bcc     LFA49
        sta     SoftSwitch::WRCARDRAM
        pla
        sta     (CurLinePtr),y
        sta     SoftSwitch::WRMAINRAM
        ldy     YRegisterStorage
        rts
LFA49:  pla
        sta     (CurLinePtr),y
        ldy     YRegisterStorage
        rts

SetLengthOfLineAtPointer4:
;;;  stores A at *(Pointer4)
        sty     YRegisterStorage
        ldy     #0
        bra     LFA5A
;;;  stores A at *(Pointer4 + Y)
SetCharAtYInLineAtPointer4:
        sty     YRegisterStorage
LFA5A:  pha
        lda     Pointer4
        lsr     a
        bcc     LFA6D
        sta     SoftSwitch::WRCARDRAM
        pla
        sta     (Pointer4),y
        sta     SoftSwitch::WRMAINRAM
        ldy     YRegisterStorage
        rts
LFA6D:  pla
        sta     (Pointer4),y
        ldy     YRegisterStorage
        rts

CopyCurrentLineToSysPathBuf:
        jsr     GetLengthOfCurrentLine
        sta     ProDOS::SysPathBuf
        and     #%01111111
        beq     @Out
        tay
@Loop:  jsr     GetCharAtYInCurrentLine
        sta     ProDOS::SysPathBuf,y
        dey
        bne     @Loop
@Out:   rts

;;; Extended Keyboard II functions keys, remapped to Apple key combos
FunctionKeys:
        .byte   6
        .byte   ControlChar::Help
        .byte   ControlChar::Home
        .byte   ControlChar::PageUp
        .byte   ControlChar::DeleteFwd
        .byte   ControlChar::End
        .byte   ControlChar::PageDown

FunctionKeysRemapped:
        .byte   '?'
        .byte   '1'
        .byte   ControlChar::UpArrow
        .byte   'F'
        .byte   '9'
        .byte   ControlChar::DownArrow

;;;  Table of Open-Apple key commands and handlers

OpenAppleKeyComboTable:
        .byte   46              ; number of key combos

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
        .addr   ShowAboutBox              ; A
        .addr   QuitEditor                ; Q
        .addr   LoadFile                  ; L
        .addr   SaveFile                  ; S
        .addr   ClearMemory               ; M
        .addr   SetNewPrefix              ; N
        .addr   ListDirectory             ; D
        .addr   ShowAboutBox              ; a
        .addr   QuitEditor                ; q
        .addr   LoadFile                  ; l
        .addr   SaveFile                  ; s
        .addr   ClearMemory               ; m
        .addr   SetNewPrefix              ; n
        .addr   ListDirectory             ; d
        .addr   ToggleInsertOverwrite     ; E
        .addr   ToggleInsertOverwrite     ; e
        .addr   MoveToBeginningOfLine:    ; <
        .addr   MoveToBeginningOfLine:    ; ,
        .addr   MoveToEndOfLine           ; >
        .addr   MoveToEndOfLine           ; .
        .addr   MoveToBeginningOfDocument ; 1
        .addr   MoveToEndOfDocument       ; 9
        .addr   BlockDelete               ; Delete
        .addr   PageUp                    ; UpArrow
        .addr   PageDown                  ; DownArrow
        .addr   MoveLeftOneWord           ; LeftArrow
        .addr   MoveRightOneWord          ; RightArrow
        .addr   BackwardTab               ; Tab
        .addr   DeleteForwardChar         ; F
        .addr   DeleteForwardChar         ; f
        .addr   ToggleShowCR              ; Z
        .addr   ToggleShowCR              ; z
        .addr   ShowHelpScreen            ; /
        .addr   ShowHelpScreen            ; ?
        .addr   ClearToEndOfCurrentLine   ; Y
        .addr   ClearToEndOfCurrentLine   ; y
        .addr   EditTabStops              ; T
        .addr   EditTabStops              ; t
        .addr   ClearCurrentLine          ; X
        .addr   ClearCurrentLine          ; x
        .addr   PrintDocument             ; P
        .addr   PrintDocument             ; p
        .addr   ListVolumes               ; V
        .addr   ListVolumes               ; v
        .addr   CopyToOrFromClipboard     ; C
        .addr   CopyToOrFromClipboard     ; c

;;; Table of other key commands and handlers
EditingControlKeyTable:
        .byte   8               ; count byte $FB21
        .byte   HICHAR(ControlChar::Tab)
        .byte   HICHAR(ControlChar::Return)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::LeftArrow)
        .byte   HICHAR(ControlChar::RightArrow)
        .byte   HICHAR(ContorlChar::ControlX)
        .byte   HICHAR(ControlChar::ControlS)

EditingControlKeyJumpTable:
        .addr   ForwardTab
        .addr   CarriageReturn
        .addr   MoveUpOneLine
        .addr   MoveDownOneLine
        .addr   MoveLeftOneChar
        .addr   MoveRightOneChar
        .addr   ClearCurrentLine
        .addr   SearchForString

MenuLengths:
        .byte   6,3,4    ; number of items in each menu

MenuXPositions:
        .byte   3,13,28         ; FB3D-FB3F

MenuWidths:
        .byte   19,17,21

MenuCount:
        .byte   3

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
        .addr   LoadFile
        .addr   SaveFileAs
        .addr   PrintFile
        .addr   ShowClearMemoryDialog
        .addr   ShowQuitDialog
        .addr   $0000
        .addr   $0000

        .addr   ListDirectory
        .addr   ShowSetPrefixDialog
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

MousePosMax:
        .byte   StartingMousePos+23
MousePosMin:
        .byte   StartingMousePos-23
SearchText:
        repeatbyte $00, 20
CursorBlinkCounter:
        .addr   $0000
CursorBlinkRate:
        .byte   $05

        .byte   $00             ; unused?

CurrentCursorChar:
        .byte   HICHAR('_')     ; current cursor
CharUnderCursor:
        .byte   $00             ; char under cursor?
InsertCursorChar:
        .byte   HICHAR('_')     ; insert cursor
OverwriteCursorChar:
        .byte   ' '             ; overwrite cursor (inverse space)
CharANDMask:
        .byte   %11111111       ; character ANDing mask
CharORMask:
        .byte   %00000000       ; character ORing mask (ie., for MSB string)
SavedMouseSlot:
        .byte   $00             ; saved mouse slot
CurrentDocumentPathnameLength:
        .byte   $00             ; copy of $BDA5 ? (prefix length byte)
ScratchVal1:
        .byte   $00             ; scratch byte; used for various purposes
DocumentChangedFlag:            ; set to 0 if the document has changed since last save
        .byte   $FF
ScratchVal2:
        .byte   $00             ; scratch byte; used for various purposes
MacroRemainingLength:
        .byte   $00             ; # of remaining bytes of macro to inject into input
PrinterSlot:
        .byte   1

PrinterInitStringRawBytes:
        repeatbyte $00, 20

;;; 20 chars max
PrinterInitString:              ; $FBC7
         msb1pstring "^I80N"
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00

PrinterLineFeedFlag:
        .byte   $00             ; if nonzero, does not send line feeds

PrinterLeftMargin:
        .byte   3

SaveCRAtEndOfEachLineFlag:
        .byte   $00

DocumentLineLength:
        .byte   79

LastEditableColumn:
        .byte   78

DateTimeFormatString:
        msb1pstring " DD-MMM-YY HH:MM "

MonthNames:
        highascii "-Jan-Feb-Mar-Apr-May-Jun-Jul-Aug-Sep-Oct-Nov-Dec-"

;;; General purpose buffer for formatting short strings (10 bytes)
StringFormattingBuffer:
        repeatbyte $00, 10

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
        highascii "Bad"
        .byte   FileType::TXT
        highascii "Txt"
        .byte   FileType::BIN
        highascii "Bin"
        .byte   FileType::DIR
        highascii "Dir"
        .byte   FileType::ADB
        highascii "Adb"
        .byte   FileType::AWP
        highascii "Awp"
        .byte   FileType::ASP
        highascii "Asp"
        .byte   FileType::SRC
        highascii "Src"
        .byte   FileType::OBJ
        highascii "Obj"
        .byte   FileType::LIB
        highascii "Lib"
        .byte   FileType::A16
        highascii "S16"
        .byte   FileType::RTL
        highascii "Rtl"
        .byte   FileType::EXE
        highascii "Exe"
        .byte   FileType::PIF
        highascii "Str"
        .byte   FileType::TIF
        highascii "Tsf"
        .byte   FileType::NDA
        highascii "Nda"
        .byte   FileType::CDA
        highascii "Cda"
        .byte   FileType::TOL
        highascii "Tol"
        .byte   FileType::DRV
        highascii "Drv"
        .byte   FileType::DOC
        highascii "Doc"
        .byte   FileType::PNT
        highascii "Pnt"
        .byte   FileType::PIC
        highascii "Pic"
        .byte   FileType::FON
        highascii "Fon"
        .byte   FileType::CMD
        highascii "Cmd"
        .byte   FileType::P16
        highascii "P16"
        .byte   FileType::BAS
        highascii "Bas"
        .byte   FileType::VAR
        highascii "Var"
        .byte   FileType::REL
        highascii "Rel"
        .byte   FileType::SYS
        highascii "Sys"

LFCF1:  .byte   $00             ; unused

MacroTable:

;;; Macro 1
        .byte   $44             ; length byte
        highascii "\r EdIt! - by Bill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii  "EM"

;;; Macro 2
        .byte   $0E             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii  "EM"

;;; Macro 3
        .byte   $00             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii "EM"

;;; Macro 4
        .byte   $00             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii "EM"

;;; Macro 5
        .byte $00               ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii "EM"

;;; Macro 6
        .byte   $00             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii "EM"

;;; Macro 7
        .byte   $00             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii "EM"

;;; Macro 8
        .byte   $00             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems\r"
        .ascii "EM"

;;; Macro 9
        .byte   $00             ; length byte
        highascii "This is a testill Tudor\r"
        highascii "   Copyright 1988-89\r"
        highascii "Northeast Micro Systems"
        .ascii "EM"

        .reloc

MainEditor_Code_End := *
BC00_Code_Start := * ; $5A2D

        .org    $BC00

ShutdownRoutine:
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
;;; Restore /RAM
        lda     RAMDiskUnitNum
        beq     LBC40
        sei
        ldx     ProDOS::DEVCNT
        sta     ProDOS::DEVLST+1,x
        inc     ProDOS::DEVCNT
        and     #%11110000
        sta     ProDOS::DiskDriverUnitNum
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     RAMDiskDriverAddress
        sta     ProDOS::DEVADR0,x
        lda     RAMDiskDriverAddress+1
        sta     ProDOS::DEVADR0+1,x
        lda     #SmartPortCall::Format
        sta     ProDOS::DiskDriverCommandNum
        stz     ProDOS::DiskDriverBufferPtr
        lda     #$20
        sta     ProDOS::DiskDriverBufferPtr+1
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
RAMDiskDriverAddress := * + 1
        jsr     $0000
LBC3D           := * + 1        ; this is odd...
        bit     SoftSwitch::RDROMLCB2
        cli
;;; If there's a calling program, load & execute it.
LBC40:  lda     SavedPathToCallingProgram
        beq     LBC8A
        tay
LBC46:  lda     SavedPathToCallingProgram,y
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
        bcc     JumpToCallingProgram

;;; Clear the screen and exit to ProDOS
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

JumpToCallingProgram:
        jmp     $0000

SavedPathToCallingProgram:
        .byte   $00             ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

;;; Reset routine (hooked to reset vector)
ResetHandler:
        jsr     ResetTextScreen
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        jmp     MainEditorStart

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
SingleReturnCharBuffer:
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
        .byte   $00             ; length byte
OnLineBuffer:
        repeatbyte $00, ProDOS::MaxPathnameLength

PathnameBuffer: ; ($BDE7)
        .byte   $00             ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

;;; Path to the Macros file.
MacrosFilePathnameBuffer:
        .byte   $00             ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

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

DirectoryEntriesLeftInBlock:
        .byte   $00

;;; Likely all scratch variables:

ScratchVal3:
        .byte   $00
ScratchVal4:
        .byte   $00             ; storage for Accumulator, also scratch byte
ScratchVal5:
        .byte   $00             ; storage for X register
ScratchVal6:
        .byte   $00
FileCountInDirectory:           ; word
YRegisterStorage:
        .byte   $00             ; storage for Y register
        .byte   $00

CurrentCursorXPos:
        .byte   $00
CurrentCursorYPos:
        .byte   $00

LBEA3:  .byte   $00,$00         ; not used

DocumentLineCount:
        .word   $0000

LBEA7:  .byte   $00             ; not used
LBEA8:  .byte   $00             ; not used

CurrentLineNumber:
        .word   $0000

LBEAB:  .byte   $00,$00         ; not used

ShowCRFlag: ; whether carriage returns are shown (using mousetext)
        .byte   $00

SavedCurLinePtr2:
        .addr   $0000           ; another place to save CurLinePtr
SavedCurrentLineNumber2:
        .word   $0000           ; another place to save CurrentLineNumber

SavedCurLinePtr:
        .addr   $0000

SavedCurrentLineNumber:
        .addr   $0000

;;; Probably more scratch variables:
ScratchVal8:
        .byte   $00
ScratchVal9:
        .byte   $00
ScratchVal10:
        .byte   $00

LBEB9:  .byte   $00             ; not used

ScratchVal11:
        .byte   $00
RAMDiskUnitNum:
        .byte   $00

CallSetMouse:
         jmp    $0000
CallInitMouse:
         jmp    $0000
CallReadMouse:
         jmp    $0000
CallPosMouse:
         jmp    $0000

CursorMovementControlChars:
        .byte   HICHAR(ControlChar::DownArrow)
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

        BC00_Code_End := * ; $5D09
        D000_Bank2_Data_Start := *

        .org $D000

;;; Top edge of Help box
TD000:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        .repeat 78
        .byte   MT_REMAP(MouseText::Overscore)
        .endrepeat
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD050:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::DownArrow)
        highascii " "
        .byte   MT_REMAP(MouseText::UpArrow)
        highascii " "
        .byte   MT_REMAP(MouseText::RightArrow)
        highascii " "
        .byte   MT_REMAP(MouseText::LeftArrow)
        highascii "      - Position cursor        "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-A           - About Ed-It!       "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD0A0:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "- "
        .byte   MT_REMAP(MouseText::UpArrow)
        highascii "         - Move up one page       "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-L           - Load File          "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD0F0:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "- "
        .byte   MT_REMAP(MouseText::RightArrow)
        highascii "         - Go right one word      "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-S           - Quick Save         "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD140:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "- "
        .byte   MT_REMAP(MouseText::LeftArrow)
        highascii "         - Go left one word       "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Q           - Quit Ed-It!        "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD190:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "- "
        .byte   MT_REMAP(MouseText::DownArrow)
        highascii "         - Move down one page     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-C           - Copy text          "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD1E0:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-<          - To begining of line    "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-M           - Clear memory       "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD230:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "->          - To end of line         "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-V           - Volumes online     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD280:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-1          - To start of document   "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-E           - Toggle insert/edit "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD2D0:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-9          - To end of document     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Z           - Show/hide CR's     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD320:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Y          - Clear cursor to end    "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-T           - Set tab stops      "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD370:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  Tab          - Tab right              "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-X (clear)   - Clear current line "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD3C0:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Tab        - Tab left               "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Delete      - Begin block delete "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD410:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  Delete       - Delete character left  "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-D           - Directory of disk  "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD460:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-F          - Delete character right "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-N           - New ProDOS prefix  "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

TD4B0:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  Cntrl-S      - Search for a string    "

        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-P           - Print file         "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

;;; bottom of Help box
TD500:  .byte   MT_REMAP(MouseText::RightVerticalBar)
        repeatbyte HICHAR('_'), 40
        .byte   MT_REMAP(MouseText::TextCursor)
        repeatbyte HICHAR('_'), 37
        .byte   MT_REMAP(MouseText::LeftVerticalBar)

        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 17
        .byte   MT_REMAP(MouseText::Diamond)
        highascii " Copyright 1988-89  Northeast Micro Systems "

        .byte   MT_REMAP(MouseText::Diamond)
        .byte   $00

TD591:  .byte   $0C
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-? for Help"

TD59E:  msb1pstring "Search for:"
TD5AA:  msb1pstring "Searching...."
TD5B8:  msb1pstring "Not Found; press a key."
TD5D0:  msb1pstring "Copy Text [T]o or [F]rom the clipboard?"
TD5F8:  msb1pstring "Clipboard is empty."
TD60C:  msb1pstring "Clipboard is full."

TD61F:  .byte   $29
        highascii "Enter text or use "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-cmds; Esc for menus. "

TD649:  msb1pstring "Line       Col.   "

TD65C:  .byte   $36
        highascii "Use arrows or mouse to select an option; then press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TD693:  msb1pstring "ESC to go back"

TD6A2:  .byte   $4C
        highascii "Use "
        .byte   MT_REMAP(MouseText::LeftArrow)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::RightArrow)
        highascii ", TAB to move; [T]-set/remove tabs; [C]-clear all; "
        .byte   MT_REMAP(MouseText::Return)
        highascii "-accept.   Pos: "

TD6EE:  .byte   $0E
        .byte   MT_REMAP(MouseText::Checkerboard2)
        .byte   MT_REMAP(MouseText::Checkerboard1)
        .ascii  " Abort "
        highascii " Esc "

TD6FD:  .byte   $0E
        .byte   MT_REMAP(MouseText::Checkerboard2)
        .byte   MT_REMAP(MouseText::Checkerboard1)
        .ascii  " Accept "
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::Return)
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        .byte   MT_REMAP(MouseText::Checkerboard2)

TD70C:  msb1pstring "Hit ESC to edit document."

TD726:  msb1pstring "Press <space> to continue."

TD741:  msb1pstring " Quit "

TD748:  msb1pstring "Q - Quit; saving changes"

TD761:  msb1pstring "E - Exit; no save"

TD773:  msb1pstring " New Prefix "

TD780:  .byte   $18
        highascii "Press "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-S for Slot/Drive"

TD799:  msb1pstring "Slot?"
TD79F:  msb1pstring "Drive?"
TD7A6:  msb1pstring " Save File "
TD7B2:  msb1pstring "Path:"
TD7B8:  msb1pstring "Prefix:/"

TD7C1:  .byte   $12
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-N for New Prefix"

TD7D4:  .byte   $20
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-L or click mouse to List Files"

TD7F5:  msb1pstring "WARNING: File in memory will be lost."
TD81B:  msb1pstring "Press 'S' to save file in memory."
TD83D:  msb1pstring  " Select File  "

TD84B:  .byte   $20
        highascii "Use "
        .byte   MT_REMAP(MouseText::UpArrow)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::DownArrow)
        highascii " to select; then press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TD86C:  msb1pstring "No files; press a key."

TD883:  .byte   $23
        highascii "Use "
        .byte   MT_REMAP(MouseText::OpenApple)
        .byte   HICHAR('-')
        .byte   MT_REMAP(MouseText::Return)
        highascii " to save with "
        .byte   MT_REMAP(MouseText::Return)
        highascii " on each line"

TD8A7:  msb1pstring "No mouse in system!"
TD8BB:  msb1pstring "Turn OFF mouse?"
TD8CB:  msb1pstring "Turn ON mouse?"
TD8DA:  msb1pstring "Enter new rate (1-9):"
TD8F0:  msb1pstring "Enter new line length (39-79):"

TD90F:  .byte   $2A
        highascii "You MUST clear file in memory ("
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-M) FIRST."

TD93A:  .byte   $29
        highascii "Use "
        .byte   MT_REMAP(MouseText::UpArrow)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::DownArrow)
        highascii " to highlight block; then press"
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TD964:  .byte   $0F
        .byte   MT_REMAP(MouseText::Hourglass)
        highascii " Please Wait.."

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
        highascii "Memory Full; Press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

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

        highasciiz "Enter macro; "
        highasciiz "-DEL deletes left; "
        highasciiz "-Esc = abort; "
        highascii "-Rtn = accept."

TDBC5:  .byte   $20
        highascii "Insert PROGRAM disk and press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TDBE6:  .byte   $18
        .byte   MT_REMAP(MouseText::Hourglass)
        highascii " Saving.. Please wait.."

TDBFF:  .byte   $19
        .byte   MT_REMAP(MouseText::Hourglass)
        highascii " Loading.. Please wait.."

TDC19:  msb1pstring " Directory "

TDC25:  .byte   $03
        .byte   MT_REMAP(MouseText::Folder1)
        .byte   MT_REMAP(MouseText::Folder2)
        .byte   HICHAR(' ')

TDC29:  msb1pstring "Filename        Type  Size  Date Modified "

TDC54:  .byte   $14
        highascii " AuxType "
        .byte   MT_REMAP(MoueText::LeftVerticalBar)
        highascii "   Blocks:"

TDC69:  msb1pstring " Total:"
TDC71:  msb1pstring "  Used:"
TDC79:  msb1pstring "  Free:"
TDC81:  msb1pstring "Use <SPACE> to"

TDC90:  .byte   $0B
        highascii "continue"
        .byte   MT_REMAP(MouseText::Ellipsis)
        .byte   MT_REMAP(MouseText::Ellipsis)
        .byte   MT_REMAP(MouseText::Ellipsis)

TDC9C:  msb1pstring "Directory complete; Press any key to continue. "
TDCCC:  msb1pstring " Volumes Online "
TDCDD:  msb1pstring " File "
TDCE4:  msb1pstring " Utilities "
TDCF0:  msb1pstring " Options "

TDCFA:  .byte   $14
        highascii " About Ed-It! "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-A "

TDD0F:  .byte   $14
        highascii " Load File..  "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-L "

TDD24:  .byte   $14
        highascii " Save as..    "
        .byte   HICHAR(ControlChar::NormalVideo)
        repeatbyte HICHAR(' '), 5

TDD39:  .byte   $14
        highascii " Print..      "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-P "

TDD4E:  .byte   $14
        highascii " Clear Memory "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-M "

TDD63:  .byte   $14
        highascii " Quit         "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Q "

TDD78:  .byte   $12
        highascii " Directory  "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-D "

TDD8B:  .byte   $12
        highascii " New Prefix "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-N "

TDD9E:  .byte   $12
        highascii " Volumes    "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-V "

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

        Page3_Code_Start := *

        .org $300

;;; All the following code is copied to $0300 (from $6C2E)

EditMacro:
        sta     MacroNumberBeingEdited
        jsr     DisplayCurrentMacroText
        lda     #<TDB85 ; Macro editing instructions
        ldx     #>TDB85
        jsr     DisplayStringInStatusLine
L030F:  jsr     DisplayCurrentMacroText
L0312:  jsr     GetKeypress
        bit     SoftSwitch::RDBTN1 ; test Solid Apple key
        bmi     L0338              ; branch if it's down
        ldx     ProDOS::SysPathBuf
        cpx     #MaxMacroLength
        bge     L0333
        inx
        sta     ProDOS::SysPathBuf,x
        stx     ProDOS::SysPathBuf
        bra     L030F
;;; Delete character
L032A:  lda     ProDOS::SysPathBuf
        beq     L0333
        dec     a
        sta     ProDOS::SysPathBuf
        bra     L030F
L0333:  jsr     PlayTone ; invalid editing key
        bra     L0312
L0338:  cmp     #ControlChar::Delete
        beq     L032A
        cmp     #ControlChar::Esc
        beq     DoneEditingMacro
        cmp     #ControlChar::Return
        bne     L0333
        ldy     ProDOS::SysPathBuf
L0347:  lda     ProDOS::SysPathBuf,y
        sta     (MacroPtr),y
        dey
        bpl     L0347
DoneEditingMacro:
        rts

DisplayAllMacros:
        lda     #1
L0352:  sta     MacroNumberBeingEdited
        jsr     CopyCurrentMacroText
        jsr     DisplayCurrentMacroText
        lda     MacroNumberBeingEdited
        inc     a
        cmp     #$0A
        blt     L0352
        rts

CopyCurrentMacroText:
        dec     a
        tay
        jsr     LoadMacroPointer
        lda     (MacroPtr)
        tay
L036C:  lda     (MacroPtr),y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     L036C
        rts

DisplayCurrentMacroText:
L0375:  lda     MacroNumberBeingEdited
        asl     a
        inc     a
        tay
        ldx     #0
        jsr     SetCursorPosToXY
        lda     MacroNumberBeingEdited
        ora     #HICHAR('0') ; convert to digit character
        jsr     OutputCharAndAdvanceScreenPos
        lda     #HICHAR(':')
        jsr     OutputCharAndAdvanceScreenPos
        ldy     ProDOS::SysPathBuf
        beq     L03D0
        sty     L03E3
        ldx     #0
L0397:  inx
        lda     ProDOS::SysPathBuf,x
        bmi     L03B7
        phy
        phx
        pha
        lda     ZeroPage::CV
        inc     a
        jsr     ComputeTextOutputPos
        lda     #MT_REMAP(MouseText::OpenApple)
        jsr     OutputCharAndAdvanceScreenPos
        lda     ZeroPage::CV
        dec     a
        jsr     ComputeTextOutputPos
        dec     Columns80::OURCH
        pla
        plx
        ply
L03B7:  ora     #%10000000
        cmp     #HICHAR(' ')
        bge     L03C5
        pha     ; display control chars in inverse
        jsr     SetMaskForInverseText
        pla
        clc
        adc     #$40 ; remap control char to uppercase char
L03C5:  jsr     OutputCharAndAdvanceScreenPos
        jsr     SetMaskForNormalText
        cpx     ProDOS::SysPathBuf
        blt     L0397
L03D0:  jsr     ClearToEndOfLine
        lda     ZeroPage::CV
        inc     a
        jsr     ComputeTextOutputPos
        jsr     ClearToEndOfLine
        lda     ZeroPage::CV
        dec     a
        jsr     ComputeTextOutputPos
        rts

L03E3:  .byte $00 ; written but never read
MacroNumberBeingEdited:
        .byte $00

        .reloc
