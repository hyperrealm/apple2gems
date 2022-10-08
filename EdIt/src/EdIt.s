;;;                   Ed-It! - A Text File Editor

;;; This is a disassembly of Ed-It!, a text file editor for the Apple II
;;; written by Bill Tudor. Ed-It! runs on ProDOS and requires a 65C02
;;; processor, MouseText, and at least 128K of RAM. It is compatible with
;;; the Enhanced IIe, IIc, IIc Plus, and IIGS.
;;;
;;; This is version 3.04 of Ed-It!, which is the latest version that I
;;; have been able to find. It was released in August 1993. Given that
;;; release date, just three months before the discontinuation of the
;;; Apple II line, it is highly likely that this is the final version.
;;;
;;; Version 2.90 was released on SoftDisk issue #94 in 1989.
;;;
;;; Version 3.00 was distributed as part of "Talk Is Cheap", a dialup
;;; communications package for the Apple II. This version added macro
;;; support, a "set line length" menu option, and clipboard copy/paste
;;; functionality.
;;;
;;; Versions 3.01 through 3.04 were bugfix releases and were shipped
;;; with successive releases of "Talk Is Cheap".

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

;;; Macros.

;;; Macro to remap MouseText character to control char range ($00-$1F)
.define MT_REMAP(c) c - $40

;;; Zero Page Locations.

Pointer              := $06 ; used for most text editing operations
MacroPtr             := $08
CurrentLinePtr       := $0A
NextLinePtr          := $0C ; used for insert/delete and word-wrap
ParamTablePtr        := $1A
MouseSlot            := $E1
MenuNumber           := $E2
MenuItemNumber       := $E3
MenuItemSelectedFlag := $E4
Pointer2             := $E5 ; used for clipboard and menu drawing
Pointer3             := $E7 ; used for search, drawing menus, and input
MenuDrawingIndex     := $E9
DialogHeight         := $EA
DialogWidth          := $EB
ScreenYCoord         := $EC
ScreenXCoord         := $ED
StringPtr            := $EE ; used for string output
ReadLineCounter      := $F0
;;; also used: $E0 (written, but never read)

DataBuffer         := $B800 ; 1K buffer used for ON_LINE, clipboard, etc.
DataBufferLength   :=  $400
BlockBuffer        := $1000 ; 512-byte buffer for reading a disk block
BackingStoreBuffer := $0800 ; Buffer in aux-mem to store text behind menus

;;; Constants.

TopMenuLine                :=  2
MaxMenuLine                :=  8
TopTextLine                :=  3
BottomTextLine             := 21
StatusLine                 := 23
LastColumn                 := 79
ColumnCount                := 80
NumMacros                  :=  9
SearchTextMaxLength        := 20
VisibleLineCount           := BottomTextLine-TopTextLine+1
MaxLineCount               := $0458
MaxMacroLength             := 70
NumLinesOnPrintedPage      := 54
StartingMousePos           := 128
PrinterInitStringMaxLength := 20

LastClipboardPointer := DataBuffer+DataBufferLength-ColumnCount

.linecont +
MacroTableOffsetInExecutable := \
        (MainEditor_Code_End - (NumMacros * (MaxMacroLength + 1)) \
         - ProDOS::SysLoadAddress)
.linecont -

;;; Bitmasks.

;;; Mask for converting lowercase char to uppercase.
ToUpperCaseANDMask := %11011111
;;; Mask for converting digit char to digit value.
CharToDigitANDMask := %00001111
;;; Mask for converting digit value to (high ascii) digit char.
DigitToCharORMask := %10110000
;;; Mask for converting uppercase char to control char.
UppercaseToControlCharANDMask := %00011111
;;; Mask to turn on MSB.
MSBOnORMask   := %10000000
;;; Mask to turn off MSB.
MSBOffANDMask := %01111111

;;; Entry point. (Initialization code.)

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
@Loop:  lda     TextRequiresHardware,y
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
;;; Copy $400 bytes of resident code to main RAM at $BC00.
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
;;; Copy $100 bytes of resident code to main RAM at $0300
L2133:  lda     Page3_Code_Start,y
        sta     $0300,y
        dey
        bne     L2133
;;; Copy the bulk of the editor's resident code to the auxiliary RAM
;;; language card.
        sei
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        lda     #<MemoryMap::LCRAM
        sta     ZeroPage::A4L
        lda     #>MemoryMap::LCRAM
        sta     ZeroPage::A4H
        ldy     #<MainEditor_Code_Start
        lda     #>MainEditor_Code_Start
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
;;; Copy text data to $D000-$DFFF bank 2 of the auxiliary RAM language
;;; card.
L217C:  sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB2
        lda     SoftSwitch::WRLCRAMB2
        lda     #<MemoryMap::LCRAM
        sta     ZeroPage::A4L
        lda     #>MemoryMap::LCRAM
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
        lda     #OpCode::LDX_Imm
        sta     LoadKeyModReg
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
L21E7:  ldx     #$1E
L21E9:  lda     ProDOS::DEVADR0+1,x
        cmp     #$FF ; /RAM driver has address $FFxx
        beq     L21F7
        dex
        dex
        bne     L21E9
L21F4:  jmp     AfterRAMDiskDisconnected ; no /RAM disk found
L21F7:  sta     RAMDiskDriverAddress+1
        lda     ProDOS::DEVADR0,x
        sta     RAMDiskDriverAddress
        txa
        tay
        asl     a
        asl     a
        asl     a
        sta     ReadBlockUnitNum ; save /RAM disk unit number
        ldx     ProDOS::DEVCNT
        inx
L220C:  lda     ProDOS::DEVCNT,x
        lda     ProDOS::DEVCNT,x ; useless duplicate instruction
        and     #%11110000 ; slot/drive
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
        cmp     #$80 ; /RAM has 128 blocks
        bge     L21F4
        ldy     #$25
        lda     BlockBuffer,y   ; file_count == 0?
        ora     BlockBuffer+1,y
        beq     DisconnectRAMDisk ; yes - /RAM is empty
        ldy     #0
L2257:  lda     TextRemoveRamDiskPrompt,y
        beq     L2262
        jsr     Monitor::COUT
        iny
        bne     L2257
L2262:  lda     BlockBuffer+4
        and     #%00001111      ; volume name length
        tax
        ldy     #0
L226A:  lda     BlockBuffer+5,y ; output volume name
        ora     #MSBOnORMask
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
        and     #MSBOffANDMask
        cmp     #'/'
        beq     SaveCallingProgramInfo ; branch if absolute path
L22DB:  lda     ProDOS::SysPathBuf
        beq     L2333 ; branch if no path
        cmp     #ProDOS::MaxPathnameLength+1
        bge     L2333 ; branch if path too long
        tay
L22E5:  lda     ProDOS::SysPathBuf,y ; copy our path
        sta     ExecutableFilePathnameBuffer,y ; to executable file path
        dey
        bpl     L22E5
        lda     ExecutableFilePathnameBuffer+1
        and     #MSBOffANDMask
        cmp     #'/'
        beq     L234A ; branch if absolute path
        jsr     ProDOS::MLI ; get prefix
        .byte   ProDOS::CGETPREFIX
        .addr   GetSetPrefixParams
        beq     L2302
        jmp     DiskErrorDuringInit
L2302:  lda     PrefixBuffer
        beq     L2333 ; branch if empty prefix
        tay
        pha
L2309:  lda     PrefixBuffer,y ; copy prefix to executable file path
        sta     ExecutableFilePathnameBuffer,y
        dey
        bne     L2309
        ply
        ldx     ProDOS::SysPathBuf
        stx     GetFileInfoModDate ; store our pathname length
        ldx     #1
L231B:  iny
        cpy     #ProDOS::MaxPathnameLength+1
        bge     L2333
        lda     ProDOS::SysPathBuf,x ; append our path to executable path
        sta     ExecutableFilePathnameBuffer,y
        inx
        cpx     GetFileInfoModDate
        blt     L231B
        beq     L231B
        sty     ExecutableFilePathnameBuffer ; update pathname length
        bra     L234A
L2333:  stz     ExecutableFilePathnameBuffer ; can't determine exe path
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::WRLCRAMB1
        lda     SoftSwitch::WRLCRAMB1
        lda     #3
        sta     MenuLengths+2 ; remove the "Edit Macros" menu item
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
L234A:  jmp     AfterConfigFileRead
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
        and     #MSBOffANDMask           ; to get directory part
        cmp     #'/'
        beq     L2385
        dey
        bne     L2376
        jmp     L22DB              ; no slash found
L2385:  sty     GetFileInfoModDate ; save length up to slash
        ldy     #1
L238A:  lda     CallingProgramPath,y ; copy that path
        sta     ProDOS::SysPathBuf,y ; to SysPathBuf
        sta     ExecutableFilePathnameBuffer,y ; and to executable file
        cpy     GetFileInfoModDate
        beq     L239B
        iny
        bra     L238A
L239B:  ldx     #0
L239D:  iny
        lda     ConfigFilename,x ; append config filename to SysPathBuf
        beq     L23A9
        sta     ProDOS::SysPathBuf,y
        inx
        bra     L239D
L23A9:  dey
        sty     ProDOS::SysPathBuf
        ldy     GetFileInfoModDate
        ldx     #0
L23B2:  iny
        lda     EditorFilename,x ; append Macros filename to path
        beq     L23BE
        sta     ExecutableFilePathnameBuffer,y
        inx
        bra     L23B2
L23BE:  dey
        sty     ExecutableFilePathnameBuffer
        jsr     ProDOS::MLI ; open the config file
        .byte   ProDOS::COPEN
        .addr   OpenParams
        bne     AfterConfigFileRead ; branch if didn't exist
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
        beq     AfterConfigFileRead ; if yes, ignore file contents
        sta     SoftSwitch::SETALTZP
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        lda     GetFileInfoModDate ; check 2nd byte again - printer slot #
        beq     AfterPrinterConfigRead ; 0 - invalid
        cmp     #8
        bge     AfterPrinterConfigRead ; >= 8 - invalid
        sta     PrinterSlot ; save printer slot #
        ldy     #PrinterInitStringMaxLength
L2411:  lda     MemoryMap::INBUF+$8A,y ; read printer init string
        sta     PrinterInitStringRawBytes,y ; from last 20 bytes of file
        dey
        bpl     L2411
        ldy     #1
        ldx     #1
L241E:  lda     MemoryMap::INBUF+$8A,y ; create human readable version of
        cmp     #' '                   ; printer init string by encoding
        bge     L2430                  ; control chars as '^' + printable
        pha                            ; character
        lda     #HICHAR('^')
        sta     PrinterInitString,x
        inx
        pla
        clc
        adc     #$40 ; convert control char to uppercase high ascii letter
L2430:  ora     #MSBOnORMask
        sta     PrinterInitString,x
        cpy     MemoryMap::INBUF+$8A
        beq     L2440
        iny
        inx
        cpx     #PrinterInitStringMaxLength
        blt     L241E
L2440:  stx     PrinterInitString ; update init string length
AfterPrinterConfigRead:
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
AfterConfigFileRead:
        jsr     ProDOS::MLI ; get the prefix
        .byte   ProDOS::CGETPREFIX
        .addr   GetSetPrefixParams
        bne     DiskErrorDuringInit
        lda     PrefixBuffer
        bne     L24AF ; branch if prefix not empty
        lda     DocumentPath+1
        and     #MSBOffANDMask
        cmp     #'/'
        beq     L24AF ; branch if document path is absolute
;;; Document path is relative, and there's no prefix. Assume it's
;;; relative to the volume directory of the last accessed volume.
        lda     ProDOS::DEVNUM ; Get volume name of current volume
        sta     OnLineUnitNum
        jsr     ProDOS::MLI
        .byte   ProDOS::CONLINE
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
L24A1:  lda     TextDiskErrorOccurred,y
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
L24D9:  sta     SoftSwitch::KBDSTRB
        jsr     ProDOS::MLI
        .byte   ProDOS::CALLOCINT
        .addr   AllocInterruptParams
        lda     InterruptNum
        sta     EditorDeallocIntParams+1
;;; Set reset vector
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
        sta     InitMouseEntry+1
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
        sta     InitMouseEntry

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
        bne     SetInitialDocumentPath
        jmp     InitializeEditor
SetInitialDocumentPath:
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
InitializeEditor:
        jsr     SetCurrentLinePointerToFirstLine
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
;;; LinePointerCount. The first pointer's value is LinePointer and each
;;; subsequent pointer is 80 + the previous pointer.
GenerateLinePointerTable:
        ldy     #0
        lda     LinePointer
        sta     (Pointer),y ; *Pointer = LinePointer
        iny
        lda     LinePointer+1
        sta     (Pointer),y
        lda     Pointer
        clc
        adc     #2 ; Pointer += 2
        sta     Pointer
        bcc     L25E2
        inc     Pointer+1
L25E2:  lda     LinePointer
        clc
        adc     #ColumnCount ; LinePointer += 80
        sta     LinePointer
        bcc     L25F0
        inc     LinePointer+1
L25F0:  dec     LinePointerCount ; LinePointerCount -= 1
        lda     LinePointerCount
        cmp     #$FF
        bne     L25FD
        dec     LinePointerCount+1
L25FD:  lda     LinePointerCount+1 ; loop until LinePointerCount == 0
        ora     LinePointerCount
        bne     GenerateLinePointerTable
        rts

TitleScreenText:
        .byte   HICHAR(ControlChar::Return)
        .byte   HICHAR(ControlChar::Return)
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
        .byte    HICHAR(ControlChar::MouseTextOff)
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 34
        highascii "by Bill Tudor"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 28
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 32
        highascii "Copyright 1988-93"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 31
        highascii "ALL RIGHTS RESERVED"
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 32
        highascii "July 1993  v3.04" ; typo - should be Aug?
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR('_'), 80
        .byte   $00

TextRequiresHardware:
        highascii "ED-IT! REQUIRES AN APPLE //C\r"
        highascii "ENHANCED //E, OR APPLE IIGS\r"
        highascii "WITH AT LEAST 128K RAM AND\r"
        highasciiz "AN 80-COLUMN CARD."

TextDiskErrorOccurred:
        highascii "DISK-RELATED ERROR OCCURRED!"
        .byte   HICHAR(ControlChar::Bell)
        .byte   $00

TextRemoveRamDiskPrompt:
        highascii "\r\rAuxillary 64K RamDisk found!\r"
        highasciiz "OK to remove files on /"
        .byte   HICHAR(ControlChar::Return)

TextLoadingConfigFile:
        highasciiz "Loading EDIT.CONFIG.." ; not referenced

MouseSignatureByteOffsets:
        .byte   $05,$07,$0B,$0C,$FB,$11
MouseSignatureByteValues:
        .byte   $38,$18,$01,$20,$D6,$00

LinePointerCount:
        .word   $0000
LinePointer:
        .addr   $0000

ConfigFilename:
        .asciiz "TIC.CONFIG"
EditorFilename:
        .asciiz "TIC.EDITOR"

        repeatbyte $00, 64 ; unused 64-byte buffer

AllocInterruptParams:
        .byte   $02
InterruptNum:
        .byte   $00
        .addr   InterruptHandler

GetSetPrefixParams:
        .byte   $01
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

MainEditor_Code_Start := *

        .org MemoryMap::LCRAM

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
        jmp     LoadFileMenuItem

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
        jsr     DisplayCurrentDocumentLine
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
ListDirectoryMenuItem:
        ldx     #0 ; Directory
LD0B6:  lda     #1 ; Menu number 1
        bra     DispatchToMenuItemHandler

;;; Handlers for menu items in "File" menu
DisplayAboutBox:
        ldx     #0 ; About
        bra     LD0DB
PrintDocument:
        ldx     #3 ; Print
        bra     LD0DB
QuitEditor:
        ldx     #5 ; Quit
        bra     LD0DB
LoadFileMenuItem:
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
        and     #MSBOffANDMask
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
        beq     LD165
        jsr     MoveToNextDocumentLine
LD165:  jmp     MainEditorInputLoop

PageUp:
        jsr     IsOnFirstDocumentLine
        beq     LD165
        lda     CurrentCursorYPos
        cmp     #TopTextLine
        beq     LD186
        sec
        sbc     #TopTextLine
        tay
LD178:  jsr     SetCurrentLinePointerToPreviousLine
        dey
        bne     LD178
        lda     #TopTextLine
        sta     CurrentCursorYPos
        jmp     MainEditorInputLoop
;;;  back one screenful
LD186:  ldy     #VisibleLineCount
LD188:  jsr     SetCurrentLinePointerToPreviousLine
        dey
        bne     LD188
        lda     CurrentLineNumber+1
        cmp     #$FF
        beq     LD19A
        ora     CurrentLineNumber
        bne     LD19D
LD19A:  jsr     SetCurrentLinePointerToFirstLine
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
        jsr     SetCurrentLinePointerToNextLine
        iny
        cpy     ScratchVal4
        bne     LD1BA
LD1C8:  tya
        clc
        adc     CurrentCursorYPos
        sta     CurrentCursorYPos
        jmp     MainEditorInputLoop
LD1D3:  ldy     #VisibleLineCount
LD1D5:  jsr     SetCurrentLinePointerToNextLine
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
        and     #MSBOffANDMask
        cmp     DocumentLineLength
        bne     @Skip
        dec     a
@Skip:  sta     CurrentCursorXPos
        jmp     MainEditorInputLoop

MoveToBeginningOfDocument:
        jsr     SetCurrentLinePointerToFirstLine
        stz     CurrentCursorXPos
        lda     #TopTextLine
        sta     CurrentCursorYPos
        jmp     MainEditorRedrawDocument

MoveToEndOfDocument:
        jsr     IsOnLastDocumentLine
        beq     @Done
@Loop:  jsr     SetCurrentLinePointerToNextLine
        jsr     IsOnLastDocumentLine
        bne     @Loop
        jsr     DisplayAllVisibleDocumentLines
@Done:  jmp     MoveToEndOfLine

ToggleShowCR:
        lda     ShowCRFlag
        eor     #MSBOnORMask
        sta     ShowCRFlag
        jmp     MainEditorRedrawDocument

ClearToEndOfCurrentLine:
        jsr     IsCursorAtEndOfLine
        bcc     LD2C6 ; nothing to do
        stz     DocumentUnchangedFlag
        jsr     GetLengthOfCurrentLine
        and     #MSBOnORMask ; preserve CR bit
        ora     CurrentCursorXPos
        jsr     SetLengthOfCurrentLine ; truncate line
        jsr     IsOnFirstDocumentLine
        beq     LD2C0 ; yes - word wrap rest of line
        jsr     SetCurrentLinePointerToPreviousLine
        jsr     GetLengthOfCurrentLine
        bmi     LD2BD ; branch if has CR
        and     #MSBOffANDMask
        clc
        adc     CurrentCursorXPos ; will the remaining text fit
        cmp     LastEditableColumn ; on the previous line?
        bge     LD2BD ; branch if no
        sta     CurrentCursorXPos
        jsr     WordWrapUpToNextCR ; word wrap rest of line
        jsr     SetCurrentLinePointerToNextLine
        jsr     MoveToPreviousDocumentLine
        jmp     MainEditorRedrawDocument
LD2BD:  jsr     SetCurrentLinePointerToNextLine ; word wrap rest of line
LD2C0:  jsr     WordWrapUpToNextCR
        jsr     MainEditorRedrawDocument
LD2C6:  jmp     MainEditorInputLoop

CarriageReturn:
        jsr     CheckIfMemoryFull
        beq     LD2C6 ; can't insert a new line
        stz     DocumentUnchangedFlag
        jsr     InsertNewLine
        jsr     IsCursorAtEndOfLine
        bcc     LD2E1 ; branch if yes
        beq     LD2E1 ; branch if empty line
        ldy     CurrentCursorXPos
        jsr     SplitLineAtCursor
LD2E1:  stz     CurrentCursorXPos
        jsr     GetLengthOfCurrentLine
        ora     #MSBOnORMask ; set CR flag
        jsr     SetLengthOfCurrentLine
        jsr     MoveToNextDocumentLine
        jsr     GetLengthOfCurrentLine
        bne     LD2F9 ; branch if next line isn't empty
        ora     #MSBOnORMask ; set CR flag
        jsr     SetLengthOfCurrentLine
LD2F9:  jsr     WordWrapUpToNextCR
        jmp     MainEditorRedrawDocument

;;; Process ordinary, non-command keypresses.
ProcessOrdinaryInputChar:
        stz     DocumentUnchangedFlag
        and     #MSBOffANDMask
        pha
        jsr     IsCursorAtEndOfLine
        beq     LD374
        bcc     LD371 ; past end of line
        lda     CurrentCursorChar
        cmp     InsertCursorChar
        bne     OverwriteCharacter
        jmp     InsertCharacter
OverwriteCharacter: ; overwrite mode
        ldy     CurrentCursorXPos
        iny
        pla
        jsr     SetCharAtYInCurrentLine
        sty     CurrentCursorXPos
LD322:  cmp     #' '
        bne     LD36E
;;; see if the word just completed would fit on the previous line
        jsr     GetSpaceLeftOnPreviousLine
        cmp     CurrentCursorXPos
        blt     LD36E ; no...won't fit
        ldy     CurrentCursorXPos       ; copy text up to cursor
LD331:  jsr     GetCharAtYInCurrentLine ; in current line
        sta     MemoryMap::INBUF,y      ; into INBUF
        dey
        bne     LD331
        ldx     CurrentCursorXPos ; set length of text copied
        stx     MemoryMap::INBUF
        stz     CurrentCursorXPos ; set cursor position to 0
LD343:  ldy     #1
        jsr     RemoveCharAtYOnCurrentLine ; remove text copied
        dex                                ; from current lien
        bne     LD343
        jsr     SetCurrentLinePointerToPreviousLine
        jsr     GetLengthOfCurrentLine
        tay
        ldx     #0
LD354:  iny
        inx
        lda     MemoryMap::INBUF,x ; append the copied text
        jsr     SetCharAtYInCurrentLine ; to the previous line
        dec     MemoryMap::INBUF
        bne     LD354
        tya
        jsr     SetLengthOfCurrentLine ; update length of previous line
        jsr     SetCurrentLinePointerToNextLine
        jsr     WordWrapUpToNextCR ; re-wrap up to carriage return
        jmp     MainEditorRedrawDocument
LD36E:  jmp     MainEditorRedrawCurrentLine
LD371:  jsr     PadLineWithSpacesUpToCursor
LD374:  ldy     CurrentCursorXPos
        cpy     LastEditableColumn
        bge     LD386
        jsr     GetLengthOfCurrentLine ;;; increment line length by 1
        inc     a
        jsr     SetLengthOfCurrentLine
        jmp     OverwriteCharacter
LD386:  jsr     CheckIfMemoryFull
        bne     LD38E
        jmp     LD435
LD38E:  jsr     InsertNewLine
        ldy     LastEditableColumn
LD394:  jsr     GetCharAtYInCurrentLine ; search backward for a space
        cmp     #' '
        beq     LD3A5
        dey
        bne     LD394
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        bra     LD3B0
LD3A5:  sty     CurrentCursorXPos ; split line at the space
        jsr     SplitLineAtCursor
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
LD3B0:  jsr     SetLengthOfCurrentLine
        jsr     MoveToNextDocumentLine
        jsr     GetLengthOfCurrentLine ; increment length of next line
        inc     a
        jsr     SetLengthOfCurrentLine
        and     #MSBOffANDMask
        tay
        pla
        jsr     SetCharAtYInCurrentLine ; append the char to the next line
        sty     CurrentCursorXPos
        jsr     WordWrapUpToNextCR ; word wrap up to next carriage return
        jmp     MainEditorRedrawDocument
InsertCharacter: ; Insert mode
        jsr     GetLengthOfCurrentLine
        sta     ScratchVal4 ; save line length in temp val
        and     #MSBOffANDMask
        cmp     LastEditableColumn
        bge     LD401 ; branch if current line already full
        inc     a
        tay
        bit     ScratchVal4 ; increment line length in temp val
        bpl     LD3E3       ; branch if no CR at end of line
        ora     #MSBOnORMask
LD3E3:  jsr     SetLengthOfCurrentLine
LD3E6:  dey
        jsr     GetCharAtYInCurrentLine ; shift characters on line to
        iny                             ; the right
        jsr     SetCharAtYInCurrentLine
        dey
        cpy     CurrentCursorXPos
        beq     LD3F6
        bge     LD3E6
LD3F6:  pla                     ; set the char in the newly opened
        iny                     ; character position
        jsr     SetCharAtYInCurrentLine
        inc     CurrentCursorXPos
        jmp     LD322
;;; char won't fit on current line
LD401:  jsr     CheckIfMemoryFull
        beq     LD435
        jsr     MoveWordToNextLine ; move last word on line to next line
        jsr     MoveToNextDocumentLine ; and re-word wrap up to CR
        jsr     WordWrapUpToNextCR
        jsr     DisplayAllVisibleDocumentLines
        jsr     MoveToPreviousDocumentLine ; then try inserting the char
        jsr     IsCursorAtEndOfLine        ; again
        bcs     InsertCharacter
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        sta     ScratchVal4
        lda     CurrentCursorXPos ; move cursor backward to where the
        sec                       ; char is to be inserted
        sbc     ScratchVal4
        sta     CurrentCursorXPos
        jsr     MoveToNextDocumentLine
        jmp     InsertCharacter

        jsr     PlayTone ; unreachable instruction

LD435:  pla     ; should this label have been on previous instruction?
        jmp     MainEditorInputLoop

DeleteChar:
        stz     DocumentUnchangedFlag
        lda     CurrentCursorXPos
        beq     LD4B1
LD441:  jsr     IsCursorAtEndOfLine
        bcs     LD465
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        sta     CurrentCursorXPos
        beq     LD477
        jsr     GetLengthOfCurrentLine
        bpl     LD465
        and     #MSBOffANDMask
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
        and     #MSBOffANDMask
        sta     ScratchVal4
        ldy     #0
LD480:  iny
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
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
        and     #MSBOffANDMask
        bne     LD4DE           ; anything to delete on this line?
        jsr     IsOnLastDocumentLine
        beq     LD4C6
        jsr     ShiftLinePointersUpForDelete
LD4C6:  jsr     DecrementDocumentLineCount
        pla
        bpl     LD4DE
        jsr     MoveToPreviousDocumentLine
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        sta     CurrentCursorXPos
        ora     #MSBOnORMask
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
        ora     DocumentLineCount ; bug? should be DocumentLineCount+1 ?
        bne     LD515
        jsr     SetDocumentLineCountToCurrentLine
LD502:  jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        sta     CurrentCursorXPos
        jmp     MainEditorRedrawDocument

;;; Two Unreachable instructions:
        lda     #$80
        jsr     SetLengthOfCurrentLine

LD512:  jmp     MainEditorRedrawDocument
LD515:  lda     CurrentLineNumber+1
        cmp     DocumentLineCount+1
        blt     LD512 ; done
        lda     DocumentLineCount
        cmp     CurrentLineNumber
        bge     LD512 ; done
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
LD562:  stz     DocumentUnchangedFlag
        jmp     MainEditorRedrawDocument
LD568:  jsr     ShiftLinePointersUpForDelete
        jsr     DecrementDocumentLineCount
        bra     LD562

BlockDelete:
        lda     CurrentCursorXPos ; save current cursor position
        pha
        lda     CurrentCursorYPos
        pha
        jsr     PerformBlockSelection ; select block
        bcc     LD588 ; branch if block selection cancelled
        pla     ; restore cursor position
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        jmp     MainEditor ; return to editing
LD588:  lda     CurrentLinePtr ; compare ending line pointer
        cmp     SavedCurrentLinePtr2 ; to starting selection line pointer
        bne     LD5AF
        lda     CurrentLinePtr+1
        cmp     SavedCurrentLinePtr2+1
        bne     LD5AF
;;; Starting and ending line number of selection are the same, so
;;; just delete the current line.
        jsr     DisplayDefaultStatusText
        jsr     DisplayHelpKeyCombo
        pla     ; restore original cursor position
        sta     CurrentCursorYPos
        tay
        pla
        sta     CurrentCursorXPos
        tax
        jsr     SetCursorPosToXY
        jsr     DisplayLineAndColLabels
        jmp     ClearCurrentLine ; clear current line, and done
;;; Deleting multiple lines.
LD5AF:  stz     DocumentUnchangedFlag
        lda     #<TextPleaseWait
        ldx     #>TextPleaseWait
        jsr     DisplayStringInStatusLine
        lda     CurrentLineNumber+1
        cmp     SavedCurrentLineNumber2+1
        blt     LD5E3 ; branch for backward selection
        beq     LD5DB
LD5C3:  lda     CurrentLineNumber
;;; Save the number of lines to be deleted in ScratchVal4 (low) and
;;; ScratchVal6 (high).
        sec
        sbc     SavedCurrentLineNumber2 ; SV(4,6) = ending - starting
        sta     ScratchVal4
        lda     CurrentLineNumber+1
        sbc     SavedCurrentLineNumber2+1
        sta     ScratchVal6
        jsr     RestoreCurrentLineState2
        bra     DeleteLinesLoop
LD5DB:  lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber2
        bge     LD5C3
LD5E3:  lda     SavedCurrentLineNumber2 ; SV(4,6) = starting - ending
        sec
        sbc     CurrentLineNumber
        sta     ScratchVal4
        lda     SavedCurrentLineNumber2+1
        sbc     CurrentLineNumber+1
        sta     ScratchVal6
DeleteLinesLoop:
        jsr     ShiftLinePointersUpForDelete ; delete line
        jsr     DecrementDocumentLineCount   ; decrement line count
        dec     ScratchVal4 ; decrement count of lines left to delete
        lda     ScratchVal4
        cmp     #$FF
        bne     DeleteLinesLoop
        dec     ScratchVal6
        lda     ScratchVal6
        cmp     #$FF
        bne     DeleteLinesLoop
        pla     ; restore original cursor position
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        lda     DocumentLineCount+1
        cmp     CurrentLineNumber+1
        bge     LD62A ; branch if didn't delete to end of doc
LD620:  jsr     IsOnFirstDocumentLine
        beq     LD632 ; branch if deleted to start of doc
        jsr     SetCurrentLinePointerToPreviousLine
        bra     LD632
LD62A:  lda     DocumentLineCount ; check if entire doc was deleted
        cmp     CurrentLineNumber
        blt     LD620
LD632:  lda     DocumentLineCount
        ora     DocumentLineCount ; bug? should be DocumentLineCount+1?
        bne     LD645
        jsr     SetCurrentLinePointerToFirstLine ; clear the document
        jsr     SetDocumentLineCountToCurrentLine
        lda     #0
        jsr     SetLengthOfCurrentLine
;;; Check if deletion resulted in the cursor being past the current line;
;;; if so, move it to the current line.
LD645:  lda     CurrentLineNumber+1
        bne     LD667
        lda     CurrentLineNumber
        cmp     #BottomTextLine-1
        bge     LD667
        lda     CurrentCursorYPos
        sec
        sbc     #TopTextLine-1
        cmp     CurrentLineNumber
        blt     LD667 ; if cursor y pos <= current line, OK
        beq     LD667
        lda     CurrentLineNumber ; else move cursor to current line
        clc
        adc     #TopTextLine-1
        sta     CurrentCursorYPos
LD667:  jmp     MainEditor

;;; Copy text to/from clipboard. Clipboard is stored in DataBuffer ($B800)
;;; which is 1K in size. The first byte of the buffer is the number of
;;; lines stored in the clipboard; the next two bytes are $FF, $FF if the
;;; clipboard is not empty.
CopyToOrFromClipboard:
        lda     #<TextCopyToOrFromClipboardPrompt
        ldx     #>TextCopyToOrFromClipboardPrompt
        jsr     DisplayStringInStatusLineWithEscToGoBack
LD671:  jsr     GetKeypress
        and     #ToUpperCaseANDMask
        cmp     #HICHAR(ControlChar::Esc)
        beq     LD6A4
        cmp     #HICHAR('T')
        beq     CopyToClipboard
        cmp     #HICHAR('F')
        beq     CopyFromClipboard
        jsr     PlayTone
        bra     LD671
CopyFromClipboard:
        lda     DataBuffer
        beq     ClipboardEmpty
        lda     DataBuffer+1
        cmp     #$FF
        bne     ClipboardEmpty
        lda     DataBuffer+2
        cmp     #$FF
        beq     ClipboardNotEmpty
ClipboardEmpty:
        lda     #<TextClipboardIsEmpty
        ldx     #>TextClipboardIsEmpty
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     BeepAndWaitForReturnOrEscKey
LD6A4:  jmp     MainEditor
ClipboardNotEmpty:
        jsr     DisplayPleaseWaitForClipboard
        jsr     SaveCurrentLineState
        lda     DataBuffer
        sta     ClipboardLineCounter ; save line count
CopyLineFromClipboard:
        jsr     CheckIfMemoryFull
        beq     LD6DB ; memory full; can't copy
        jsr     InsertNewLine
        jsr     SetCurrentLinePointerToNextLine
        lda     (Pointer2)
        and     #MSBOffANDMask
        tay
LD6C3:  lda     (Pointer2),y
        jsr     SetCharAtYInCurrentLine
        dey
        bpl     LD6C3
        and     #MSBOffANDMask
        sec
        adc     Pointer2 ; increment Pointer2 by the length of
        sta     Pointer2 ; the line just copied
        bcc     LD6D6
        inc     Pointer2+1
LD6D6:  dec     ClipboardLineCounter ; Decrement # of lines left to copy
        bne     CopyLineFromClipboard
LD6DB:  jsr     RestoreCurrentLineState
        jmp     MainEditor
CopyToClipboard:
        lda     CurrentCursorXPos ; save current cursor position
        pha
        lda     CurrentCursorYPos
        pha
        jsr     PerformBlockSelection ; select text to copy
        bcc     LD6F9 ; branch if selection accepted
FinishClipboardCopy:
        pla     ; restore cursor position
        sta     CurrentCursorYPos
        pla
        sta     CurrentCursorXPos
        jmp     MainEditor ; return to editing
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
;;; handle backward selection
LD716:  ldy     #3
LD718:  lda     SavedCurrentLinePtr2,y
        sta     SavedCurrentLinePtr,y
        dey
        bpl     LD718
LD721:  stz     DataBuffer ; init line count in clipboard
        lda     #$FF ; mark clipboard as not empty
        sta     DataBuffer+1
        sta     DataBuffer+2
CopyLineToClipboard:
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        tay
LD732:  jsr     GetCharAtYInCurrentLine
        sta     (Pointer2),y
        dey
        bpl     LD732
        and     #MSBOffANDMask
        sec
        adc     Pointer2 ; advance Pointer 5 by length
        sta     Pointer2 ; of line just copied
        bcc     LD745
LD743:  inc     Pointer2+1
LD745:  inc     DataBuffer ; increment line count in clipboard
        lda     Pointer2+1 ; check if clipboard full
        cmp     #>LastClipboardPointer
        blt     LD754
        lda     Pointer2
        cmp     #<LastClipboardPointer
        bge     ClipboardFull
LD754:  lda     CurrentLineNumber+1 ; check if more left to copy
        cmp     SavedCurrentLineNumber+1
        blt     LD766
        bne     LD76B
        lda     CurrentLineNumber
        cmp     SavedCurrentLineNumber
        bge     LD76B
LD766:  jsr     SetCurrentLinePointerToNextLine
        bra     CopyLineToClipboard
LD76B:  jsr     RestoreCurrentLineState2
        jmp     FinishClipboardCopy
ClipboardFull:
        lda     #<TextClipboardIsFull
        ldx     #>TextClipboardIsFull
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     BeepAndWaitForReturnOrEscKey
        bra     LD76B
ClipboardLineCounter:
        .byte   $00

;;; Display "please wait" and load Pointer2 with beginning of clipboard
;;; data.
DisplayPleaseWaitForClipboard:
        lda     #<TextPleaseWait
        ldx     #>TextPleaseWait
        jsr     DisplayStringInStatusLine
        lda     #<DataBuffer+3
        sta     Pointer2
        lda     #>DataBuffer
        sta     Pointer2+1
        rts

EditTabStops:
        lda     CurrentCursorXPos
        sta     ScratchVal1
        lda     #24
        sta     ZeroPage::WNDBTM
        lda     #<TextTabStopEditingInstructions
        ldx     #>TextTabStopEditingInstructions
        jsr     DisplayStringInStatusLine
;;; draw ruler with tab stops
LD79F:  ldy     #22
        ldx     #0
        jsr     SetCursorPosToXY
        ldy     #ColumnCount
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
;;; Move to next tab
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

DisplayHelpScreen:
        jsr     ClearTextWindow
        jsr     DisplayHelpText
        jsr     WaitForSpaceToContinueInStatusLine
        jsr     ClearTextWindow
        jmp     MainEditor

SearchForString:
        jsr     SaveCursorPosInDocument
        lda     #<TextSearchForPrompt
        ldx     #>TextSearchForPrompt
        jsr     DisplayStringInStatusLineWithEscToGoBack
        ldy     SearchText ; copy current search text
LD88D:  lda     SearchText,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LD88D
        lda     #SearchTextMaxLength
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
        lda     #<TextSearching
        ldx     #>TextSearching
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
        and     #MSBOffANDMask
        clc
        sbc     CurrentCursorXPos
        bmi     ContinueSearchOnNextLine
        beq     ContinueSearchOnNextLine
        tax
        ldy     CurrentCursorXPos
        bra     LD906
LD8EF:  jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        beq     ContinueSearchOnNextLine
        tax
        ldy     #1
LD8F9:  jsr     GetCharAtYInCurrentLine ; compare text
        ora     #MSBOnORMask              ; at Y
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
        sta     Pointer3+1
        jsr     GetCharAtYInCurrentLine
        ora     #MSBOnORMask
        jsr     CharToUppercase
        cmp     Pointer3+1
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
LD93E:  lda     #<TextSearchTextNotFoundPrompt
        ldx     #>TextSearchTextNotFoundPrompt
        jsr     DisplayStringInStatusLine
        jsr     BeepAndWaitForReturnOrEscKey
LD948:  jsr     RestoreCursorPosInDocument
        jmp     MainEditor

;;; Routines to save and restore cursor position during search.

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

;;; Does not scroll if on bottom line.
MoveToNextVisibleLine:
        lda     CurrentCursorYPos
        cmp     #BottomTextLine
        beq     @Out
        inc     CurrentCursorYPos
@Out:   jsr     SetCurrentLinePointerToNextLine
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
;;; Set mouse tracking speed to slow.
        lda     #StartingMousePos+23
        sta     MousePosMax
        lda     #StartingMousePos-23
        sta     MousePosMin
LD99B:  lda     #<TextMenuNavigationInstructions
        ldx     #>TextMenuNavigationInstructions
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

;;; Removes a menu after a menu selection triggered the display of a
;;; dialog box (in which case the menu is still on-screen)
CleanUpAfterMenuSelection:
        jsr     RestoreScreenAreaUnderMenus
        jsr     DrawMenuBarAndMenuTitles
        lda     #HICHAR(ControlChar::Esc)
        sta     CursorMovementControlChars+4
;;; Set mouse tracking speed to fast.
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

DisplayVolumesDialog:
        jsr     DrawDialogBox
        .byte   17 ; height
        .byte   35 ; width
        .byte   4  ; y-coord
        .byte   36 ; x-coord
        .byte   46 ; x-coord of title
        .addr   TextVolumesDialogTitle
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
        ora     #DigitToCharORMask
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
        ora     #MSBOnORMask
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
        jsr     DisplayPrintDialog
        jsr     RestoreCurrentLineState2
        jmp     CleanUpAfterMenuSelection

DisplayQuitDialog:
        jsr     DrawDialogBox
        .byte   7  ; height
        .byte   36 ; width
        .byte   5  ; y-coord
        .byte   32 ; x-coord
        .byte   48 ; x-coord of title
        .addr   TextQuitDialogTitle
        ldy     #7
        ldx     #38
        jsr     SetCursorPosToXY
        lda     #<TextQuitWithSave
        ldx     #>TextQuitWithSave
        jsr     DisplayMSB1String
        ldy     #8
        ldx     #38
        jsr     SetCursorPosToXY
        lda     #<TextQuitWithoutSave
        ldx     #>TextQuitWithoutSave
        jsr     DisplayMSB1String
        ldx     #50
        ldy     #9
        jsr     DrawAbortButton
        jsr     DisplayHitEscToEditDocInStatusLine
LDB0D:  jsr     PlayTone
        ldx     #1
        jsr     GetSpecificKeypress
        bcs     LDB4E
        ora     #MSBOnORMask
        and     #ToUpperCaseANDMask
        cmp     #HICHAR('E')
        beq     LDB4B
        cmp     #HICHAR('Q')
        bne     LDB0D
        lda     DocumentLineCount+1
        bne     LDB36
        lda     DocumentLineCount
        cmp     #1
        bne     LDB36
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        beq     LDB4B
LDB36:  lda     DocumentUnchangedFlag
        bne     LDB4B
        lda     PathnameBuffer
        beq     LDB46
        sta     CurrentDocumentPathnameLength
        sta     PathnameLength
LDB46:  jsr     DisplaySaveAsDialog
        bcs     LDB4E
LDB4B:  jmp     ShutdownRoutine
LDB4E:  jmp     CleanUpAfterMenuSelection

DisplayAboutDialog:
        jsr     DrawDialogBox
        .byte   10 ; height
        .byte   60 ; width
        .byte   6  ; x-coord
        .byte   10 ; y-coord
        .byte   36 ; x-coord of title
        .addr   TextAboutDialogTitle
        ldy     #8
        ldx     #23
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #9
        ldx     #24
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #9
        ldx     #27
        jsr     SetCursorPosToXY
        lda     #<TextAboutDialogLine1
        ldx     #>TextAboutDialogLine1
        jsr     DisplayMSB1String
        ldy     #10
        ldx     #23
        jsr     SetCursorPosToXY
        jsr     OutputDiamond
        ldy     #11
        ldx     #34
        jsr     SetCursorPosToXY
        lda     #<TextAboutDialogLine2
        ldx     #>TextAboutDialogLine2
        jsr     DisplayMSB1String
        lda     #29
        sta     Columns80::OURCH
        lda     #<TextAboutDialogLine3
        ldx     #>TextAboutDialogLine3
        jsr     DisplayMSB1String
        lda     #16
        sta     Columns80::OURCH
        lda     #<TextAboutDialogLine4
        ldx     #>TextAboutDialogLine4
        jsr     DisplayMSB1String
        jsr     WaitForSpaceToContinueInStatusLine
        jmp     CleanUpAfterMenuSelection

SaveFileAs:
        jsr     DisplaySaveAsDialog
        jmp     CleanUpAfterMenuSelection

ListDirectory:
        jsr     DisplayListDirectoryDialog
        jmp     CleanUpAfterMenuSelection

DisplaySetPrefixDialog:
        lda     #<TextSetPrefixDialogTitle
        ldx     #>TextSetPrefixDialogTitle
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
        lda     #<TextSlotAndDriveKeyCombo
        ldx     #>TextSlotAndDriveKeyCombo
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
        lda     #<TextSlotPrompt
        ldx     #>TextSlotPrompt
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
        lda     #<TextDrivePrompt
        ldx     #>TextDrivePrompt
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
        ora     #MSBOnORMask ; set drive 2
        sta     EditorOnLineUnitNum
        pla
LDC96:  jsr     OutputCharAndAdvanceScreenPos
        lda     #<ProDOS::SysPathBuf+1
        sta     EditorOnLineDataBuffer
        lda     #>ProDOS::SysPathBuf
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
        jmp     DisplaySetPrefixDialog
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
        jmp     DisplaySetPrefixDialog
;;; copy prefix back to prefix buffer
LDCFB:  ldy     ProDOS::SysPathBuf-1
LDCFE:  lda     ProDOS::SysPathBuf-1,y
        sta     PrefixBuffer,y
        dey
        bpl     LDCFE
        ldy     PrefixBuffer
;;; append trailing slash if needed
        lda     PrefixBuffer,y
        and     #MSBOffANDMask
        cmp     #'/'
        beq     LDD1C
        iny
        lda     #'/'
        sta     PrefixBuffer,y
        sty     PrefixBuffer
LDD1C:  jmp     CleanUpAfterMenuSelection

LoadFile:
        jsr     DisplayOpenFileDialog
        jmp     CleanUpAfterMenuSelection

DisplayChangeMouseStatusDialog:
        jsr     DrawDialogBox
        .byte   7  ; height
        .byte   40 ; width
        .byte   9  ; y-coord
        .byte   20 ; x-coord
        .byte   30 ; x-coord of title
        .addr   TextSetMouseStatusDialogTitle
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
        lda     #<TextTurnMouseOffPrompt
        ldx     #>TextTurnMouseOffPrompt
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
        lda     #<TextTurnMouseOnPrompt
        ldx     #>TextTurnMouseOnPrompt
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     WaitForReturnOrEscKey
        bcs     LDD5E
        lda     SavedMouseSlot
        sta     MouseSlot
        jmp     CleanUpAfterMenuSelection
LDD7D:  lda     #<TextNoMouseInSystem
        ldx     #>TextNoMouseInSystem
        jsr     DisplayMSB1String
        jsr     DisplayHitEscToEditDocInStatusLine
        jsr     GetKeypress
        jmp     CleanUpAfterMenuSelection

ChangeBlinkRate:
        lda     #<TextEnterBlinkRatePrompt
        ldx     #>TextEnterBlinkRatePrompt
        ldy     CursorBlinkRate
        jsr     InputSingleDigitDefaultInY
        bcs     LDD9F
        bne     LDD9C
        inc     a
LDD9C:  sta     CursorBlinkRate
LDD9F:  jmp     CleanUpAfterMenuSelection

DisplayClearMemoryDialog:
        jsr     DrawDialogBox
        .byte   7  ; height
        .byte   40 ; width
        .byte   6  ; y-coord
        .byte   25 ; x-coord
        .byte   39 ; x-coord of title
        .addr   TextClearMemoryDialogTitle
        ldy     #8
        ldx     #32
        jsr     SetCursorPosToXY
        lda     #<TextEraseMemoryPrompt
        ldx     #>TextEraseMemoryPrompt
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
        jsr     SetCurrentLinePointerToFirstLine
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
        and     #MSBOffANDMask
        beq     LDE0F
LDE00:  lda     #<TextMustClearMemoryPrompt
        ldx     #>TextMustClearMemoryPrompt
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     PlayTone
        jsr     WaitForSpaceKeypress
        bra     LDE88
LDE0F:  jsr     MoveCursorToHomePos
LDE12:  lda     #<TextEnterLineLengthPrompt
        ldx     #>TextEnterLineLengthPrompt
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
;;; Handle invalid input.
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
        and     #CharToDigitANDMask ; convert char to numeric value 0-9
        sta     LineLengthHighDigit
        lda     ProDOS::SysPathBuf+2
        cmp     #HICHAR('0') ; check for valid low digit
        blt     LDE39
        cmp     #HICHAR(':')
        bge     LDE39
        and     #CharToDigitANDMask ; convert char to numeric value 0-9
        sta     LineLengthLowDigit
        ldy     LineLengthHighDigit
        beq     LDE79
LDE73:  clc     ; add (10 * high digit) to low digit
        adc     #10
        dey
        bne     LDE73
LDE79:  cmp     #39 ; minimum width is 39
        blt     LDE39
        cmp     #ColumnCount ; maximum width is 79
        bge     LDE39
        sta     DocumentLineLength
        dec     a
        sta     LastEditableColumn
LDE88:  jmp     CleanUpAfterMenuSelection
LineLengthLowDigit:
        .byte   $00
LineLengthHighDigit:
        .byte   $00

DisplayEditMacrosScreen:
        jsr     DrawMenuBar
        ldy     #1
        ldx     #5
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        lda     #<TextEditMacrosMenuItemTitle
        ldx     #>TextEditMacrosMenuItemTitle
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
LDEA4:  jsr     ClearTextWindow
        jsr     DisplayAllMacros
        lda     #<TextMacroEditingInstructions2
        ldx     #>TextMacroEditingInstructions2
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
LDED1:  and     #CharToDigitANDMask
        jsr     EditMacro
        bra     LDEA4

;;; Macros are saved inside the editor executable.
SaveMacrosToFile:
        ldy     ExecutableFilePathnameBuffer
LDEDB:  lda     ExecutableFilePathnameBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LDEDB
LDEE4:  lda     #<TextSaving
        ldx     #>TextSaving
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     GetFileInfo
        beq     LDEFF
        lda     #<TextInsertProgramDiskPrompt
        ldx     #>TextInsertProgramDiskPrompt
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
        jsr     CopyCurrentMacroText
        lda     #ProDOS::CWRITE
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        bne     LDF1B
        lda     MacroNumberBeingEdited
        inc     a
        cmp     #NumMacros+1
        blt     LDF32
        jsr     CloseFile
        rts

;;; Used to enter printer slot # and printer left margin. Default value
;;; is passed in A.
InputSingleDigit:
        sta     InputSingleDigitDefaultValue
        bra     LDF5A
;;; Same as above, but default value is passed in Y.
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
        sta     Pointer3+1
LDFBB:  lda     Pointer3+1
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
        lda     (Pointer2),y
        tax
        dey
        lda     (Pointer2),y
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        jsr     OutputLeftVerticalBar
        jsr     MoveTextOutputPosToStartOfNextLine
        inc     MenuDrawingIndex
        lda     MenuDrawingIndex
        ldy     MenuNumber
        cmp     MenuLengths,y
        blt     LDFBB
        lda     Pointer3+1
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
        sta     Pointer2
        iny
        lda     MenuItemListAddresses,y
        sta     Pointer2+1
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
LE05F:  lda     #<TextFileMenuTitle
        ldx     #>TextFileMenuTitle
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        lda     MenuXPositions+1
        sta     Columns80::OURCH
        dec     MenuDrawingIndex
        beq     LE076
        jsr     SetMaskForInverseText
LE076:  lda     #<TextUtilitiesMenuTitle
        ldx     #>TextUtilitiesMenuTitle
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        lda     MenuXPositions+2
        sta     Columns80::OURCH
        dec     MenuDrawingIndex
        beq     LE08D
        jsr     SetMaskForInverseText
LE08D:  lda     #<TextOptionsMenuTitle
        ldx     #>TextOptionsMenuTitle
        jsr     DisplayMSB1String
        jsr     SetMaskForNormalText
        rts

DisplayListDirectoryDialog:
        jsr     DrawDialogBox
        .byte   14 ; height
        .byte   69 ; width
        .byte   6  ; y-coord
        .byte   4  ; x-coord
        .byte   32 ; x-coord of title
        .addr   TextListDirectoryDialogTitle
        ldy     #8
        ldx     #6
        jsr     SetCursorPosToXY
        lda     #<TextMouseTextFolder
        ldx     #>TextMouseTextFolder
        jsr     DisplayMSB1String
        ldx     #1
        ldy     PrefixBuffer
LE0B5:  lda     PrefixBuffer,x
        ora     #MSBOnORMask
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
        lda     #<TextFileListColumnHeaders
        ldx     #>TextFileListColumnHeaders
        jsr     DisplayMSB1String
        lda     #<TextFileListColumnHeaders2
        ldx     #>TextFileListColumnHeaders2
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
        lda     #<TextBlocksTotalLabel
        ldx     #>TextBlocksTotalLabel
        jsr     DisplayMSB1String
        ldy     #13
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TextBlocksUsedLabel
        ldx     #>TextBlocksUsedLabel
        jsr     DisplayMSB1String
        ldy     #14
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TextBlocksFreeLabel
        ldx     #>TextBlocksFreeLabel
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
        lda     #<TextUseSpaceToContinuePrompt
        ldx     #>TextUseSpaceToContinuePrompt
        jsr     DisplayMSB1String
        ldy     #18
        ldx     #57
        jsr     SetCursorPosToXY
        jsr     OutputLeftVerticalBar
        lda     #<TextUseSpaceToContinuePrompt2
        ldx     #>TextUseSpaceToContinuePrompt2
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
        ora     #MSBOnORMask
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
        ldx     ProDOS::SysPathBuf+$1F
        lda     ProDOS::SysPathBuf+$20
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
LE27C:  lda     #<TextDirectoryCompletePrompt
        ldx     #>TextDirectoryCompletePrompt
        jsr     DisplayStringInStatusLine
        jsr     GetKeypress
LE286:  jsr     CloseFile
        rts

DisplayOpenFileDialog:
;;; First check if current document is empty.
        lda     PathnameLength
        bne     LE2A7
        lda     DocumentLineCount+1
        bne     LE2A2
        lda     DocumentLineCount
        cmp     #1
        bne     LE2A2
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
LE2A0:  beq     LE2A7
LE2A2:  lda     DocumentUnchangedFlag
        beq     LE2AA ; branch if document has unsaved changes
LE2A7:  jmp     LE30C ; skip offering to save current document
LE2AA:  jsr     DrawDialogBox
        .byte   12 ; height
        .byte   56 ; width
        .byte   9  ; y-coord
        .byte   11 ; x-coord
        .byte   35 ; x-coord of title
        .addr   TextOpenFileDialogTitle
        ldy     #12
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TextFileWillBeLostWarning
        ldx     #>TextFileWillBeLostWarning
        jsr     DisplayMSB1String
        ldy     #14
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TextSaveCurrentFilePrompt
        ldx     #>TextSaveCurrentFilePrompt
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
        and     #ToUpperCaseANDMask
        cmp     #HICHAR('S')
        bne     LE2E6
        lda     PathnameBuffer ; already have a filename?
        beq     LE303 ; branch if no
        sta     CurrentDocumentPathnameLength
        sta     PathnameLength
LE303:  jsr     DisplaySaveAsDialog
        bcc     LE309 ; if save successful, continue to load
LE308:  rts
LE309:  stz     PathnameLength
LE30C:  lda     #<TextOpenFileDialogTitle
        ldx     #>TextOpenFileDialogTitle
        jsr     DisplayPathInputBox
        lda     #'L'
        sta     CursorMovementControlChars+4
        lda     PathnameLength
        bne     LE32E
        ldy     #17
        ldx     #25
        jsr     SetCursorPosToXY
        lda     #<TextListFilesKeyCombo
        ldx     #>TextListFilesKeyCombo
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
        jsr     DisplayDirectoryListingDialog
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
        lda     #<TextLoading
        ldx     #>TextLoading
        jsr     DisplayLoadingOrSavingMessage
        jsr     ClearStatusLine
        stz     EditorReadWriteRequestCount+1
        lda     #16 ; going to read file 16 bytes at a time
        sta     EditorReadWriteRequestCount
        lda     #<MemoryMap::INBUF
        sta     EditorReadWriteBufferAddr
        lda     #>MemoryMap::INBUF
        sta     EditorReadWriteBufferAddr+1
        jsr     SetCurrentLinePointerToFirstLine ; start first line
        jsr     SetDocumentLineCountToCurrentLine
        stz     ReadLineCounter
        stz     EditorReadWriteTransferCount
ReadNextLineFromFile:
        lda     #0
        jsr     SetLengthOfCurrentLine
ProcessNextCharFromFile:
        lda     EditorReadWriteTransferCount
        bne     LE3AE
        lda     #ProDOS::CREAD
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        beq     LE3AC
        jmp     LE43D  ; handle error
LE3AC:  stz     ReadLineCounter
LE3AE:  dec     EditorReadWriteTransferCount
        ldx     ReadLineCounter
        inc     ReadLineCounter
        lda     MemoryMap::INBUF,x
        and     #MSBOffANDMask
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
        jsr     LoadNextLinePointer
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
        jsr     SetLengthOfCurrentLine ; truncate line at end of last word
        ldx     #1
LE3FC:  iny     ; move word into next line
        cpy     DocumentLineLength
        beq     LE411
        jsr     GetCharAtYInCurrentLine
        phy
        phx
        ply
        jsr     SetCharAtYInNextLine
        phy
        plx
        ply
        inx
        bra     LE3FC
;;; Start next line.
LE411:  txa
        tay
        jsr     SetLengthOfNextLine
        ldx     ReadLineCounter
        dex
        lda     MemoryMap::INBUF,x
        and     #MSBOffANDMask
        jsr     SetCharAtYInNextLine
        jsr     SetCurrentLinePointerToNextLine
        jsr     IncrementDocumentLineCount
        jmp     ProcessNextCharFromFile
LE427:  jsr     GetLengthOfCurrentLine
        ora     #MSBOnORMask ; add CR marker
        jsr     SetLengthOfCurrentLine
        jsr     CheckIfMemoryFull
        beq     DoneReadingFile
        jsr     SetCurrentLinePointerToNextLine
        jsr     IncrementDocumentLineCount
        jmp     ReadNextLineFromFile
LE43D:  cmp     #ProDOS::EEOF
        bne     ErrorLoadingFile
;;; Done loading file (or memory full).
DoneReadingFile:
        sta     DocumentUnchangedFlag
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
LE463:  jsr     SetCurrentLinePointerToFirstLine
        lda     EditorCreateFileType
        cmp     #FileType::TXT
        beq     LE470
        stz     PathnameBuffer ; non-TXT files can't be overwritten
LE470:  rts
ErrorLoadingFile:
        jsr     SetCurrentLinePointerToFirstLine
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
        ldy     PrefixBuffer ; copy current prefix to SysPathBuf
LE48E:  lda     PrefixBuffer,y
        ora     #MSBOnORMask
        sta     ProDOS::SysPathBuf-1,y
        dey
        bne     LE48E
        ldy     PrefixBuffer
        dey
        sty     ProDOS::SysPathBuf
        lda     #<TextEnterPrefixAbove
        ldx     #>TextEnterPrefixAbove
        jsr     DisplayStringInStatusLine
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TextPrefixLabel
        ldx     #>TextPrefixLabel
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #11
        lda     #63
        jsr     EditPath ; input new prefix
        bcs     LE4F7
        ldy     ProDOS::SysPathBuf
        iny
        sty     ProDOS::SysPathBuf-1
        lda     #HICHAR('/') ; prepend a slash
        sta     ProDOS::SysPathBuf
        lda     #ProDOS::CSETPREFIX
        ldy     #>EditorSetPrefixParams
        ldx     #<EditorSetPrefixParams
        jsr     MakeMLICall ; set the new prefix
        beq     LE4DA
        jmp     DisplayErrorAndReturnWithCarrySet
LE4DA:  ldy     ProDOS::SysPathBuf-1 ; copy it back to PrefixBuffer
LE4DD:  lda     ProDOS::SysPathBuf-1,y
        sta     PrefixBuffer,y
        dey
        bpl     LE4DD
        lda     #HICHAR('/') ; append a slash
        ldx     PrefixBuffer
        cmp     PrefixBuffer,x
        beq     LE4F7
        inx
        sta     PrefixBuffer,x
        stx     PrefixBuffer
LE4F7:  rts

DisplaySaveAsDialog:
        lda     #<TextSaveAsDialogTitle
        ldx     #>TextSaveAsDialogTitle
        jsr     DisplayPathInputBox
        ldy     #17
        ldx     #23
        jsr     SetCursorPosToXY
        lda     #<TextSaveCarriageReturnsKeyCombo
        ldx     #>TextSaveCarriageReturnsKeyCombo
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
        bra     DisplaySaveAsDialog
LE53F:  sec     ; dialog cancelled
        rts
LE541:  ldy     #$FF
        .byte   OpCode::BIT_Abs
LE544:  ldy     #0
        sty     SaveCRAtEndOfEachLineFlag
        lda     #<TextSaving
        ldx     #>TextSaving
        jsr     DisplayLoadingOrSavingMessage
        jsr     ClearStatusLine
        jsr     GetFileInfo
        beq     LE55F
        cmp     #ProDOS::EFILENOTF ; file doesn't exist
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
        lda     #<TextReplaceOldFilePrompt
        ldx     #>TextReplaceOldFilePrompt
        jsr     DisplayMSB1String
        jsr     PlayTone
        jsr     GetConfirmationKeypress
        bcs     LE53F
        jsr     ClearStatusLine
LE588:  jsr     DeleteFile ; delete old version of file
        beq     LE590
        jmp     DisplayErrorAndReturnWithCarrySet
LE590:  ldy     ProDOS::SysPathBuf
LE593:  lda     ProDOS::SysPathBuf,y
        sta     PathnameBuffer,y
        dey
        bpl     LE593
        lda     #ProDOS::CCREATE ; create new version of file
        ldy     #>EditorCreateParams
        ldx     #<EditorCreateParams
        jsr     MakeMLICall
        bne     DisplayErrorAndReturnWithCarrySet
        jsr     OpenFile ; open the file
        bne     LE60D
        jsr     SaveCurrentLineState2
        jsr     SetCurrentLinePointerToFirstLine
        stz     EditorReadWriteRequestCount+1
LE5B5:  jsr     CopyCurrentLineToSysPathBuf
        lda     #<ProDOS::SysPathBuf+1
        sta     EditorReadWriteBufferAddr
        lda     #>ProDOS::SysPathBuf
        sta     EditorReadWriteBufferAddr+1
        lda     ProDOS::SysPathBuf
        and     #MSBOffANDMask
LE5C7:  sta     EditorReadWriteRequestCount
        beq     LE5D7 ; branch if empty line
        lda     #ProDOS::CWRITE ; write current line to file
        ldx     #<EditorReadWriteParams
        ldy     #>EditorReadWriteParams
        jsr     MakeMLICall
        bne     LE60D
LE5D7:  lda     #>SingleReturnCharBuffer ; write blank line to file
        cmp     EditorReadWriteBufferAddr+1
        beq     LE5F6
        lda     SaveCRAtEndOfEachLineFlag
        bne     LE5E8
        lda     ProDOS::SysPathBuf
        bpl     LE5F6
LE5E8:  lda     #<SingleReturnCharBuffer ; write a single CR char to file
        sta     EditorReadWriteBufferAddr
        lda     #>SingleReturnCharBuffer
        sta     EditorReadWriteBufferAddr+1
        lda     #1
        bra     LE5C7
LE5F6:  jsr     IsOnLastDocumentLine
        beq     LE600
        jsr     SetCurrentLinePointerToNextLine
        bra     LE5B5 ; branch to write the next line
LE600:  jsr     CloseFile ; close file
        jsr     RestoreCurrentLineState2
        lda     #1
        sta     DocumentUnchangedFlag
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
        lda     #ProDOS::CDESTROY
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

;;; Path editor (for load, save as, set prefix), drawn at X,Y, width A.
;;; Returns in A the keypress that ended the input, and Carry set if it
;;; wasn't the Return key.
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
;;; Delete char left.
LE6BA:  lda     ProDOS::SysPathBuf
        beq     LE69B
        dec     a
        sta     ProDOS::SysPathBuf
        jmp     LE653
;;; Clear input.
LE6C6:  stz     ProDOS::SysPathBuf
        jmp     LE653

LE6CC:  stz     PathnameLength
        lda     #HICHAR(ControlChar::Return)
;;; Accept input.
LE6D1:  tay
        lda     ProDOS::SysPathBuf
        beq     LE69B
        tya
        clc
        rts
;;; Cancel input (other command entered).
LE6DA:  sec
        rts

PathEditingOpenAppleKeyCombos:
;;;  Key commands available in path editing dialog.
        .byte   'N' ; OA-N
        .byte   'n' ; OA-n
        .byte   'L' ; OA-L
        .byte   'l' ; OA-l
        .byte   'S' ; OA-S
        .byte   's' ; OA-s
        .byte   ControlChar::Return ; OA-Return
        .byte   HICHAR(ControlChar::Esc)

;;; Blanks out lines 17-20, from column 16 to 66, then displays string at
;;; AX, on line 18. Only used for "Loading..." and "Saving..." messages.
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
        lda     #<TextPathLabel
        ldx     #>TextPathLabel
        jsr     DisplayMSB1String
        ldy     #15
        ldx     #3
        jsr     SetCursorPosToXY
        lda     #<TextPrefixLabel
        ldx     #>TextPrefixLabel
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
        lda     #<TextNewPrefixKeyCombo
        ldx     #>TextNewPrefixKeyCombo
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
@Loop:  cmp     MLIErrorTable,y
        beq     @Found
        dey
        bne     @Loop
        jsr     Monitor::PRBYTE ; bug; Would crash - ROM not paged in
        ldy     #0
@Found: tya
        asl     a
        tay
        lda     MLIErrorMessageTable+1,y
        tax
        lda     MLIErrorMessageTable,y
        jsr     DisplayMSB1String
        lda     #<TextPressAKeyPromptSuffix
        ldx     #>TextPressAKeyPromptSuffix
        jsr     DisplayMSB1String
        jsr     PlayTone
        sta     SoftSwitch::KBDSTRB
        jsr     GetKeypress
        rts

;;; Document line buffers are used to store the formatted directory
;;; entries. Directory entries are displayed in a scrollable list that
;;; occupies 8 screen rows from row 13 to 20.
DisplayDirectoryListingDialog:
        lda     #HICHAR(ControlChar::Return)
        sta     CursorMovementControlChars+4
        lda     #$FF
        sta     DocumentUnchangedFlag
        jsr     DrawDialogBox
        .byte   12 ; height
        .byte   44 ; width
        .byte   9  ; y-coord
        .byte   17 ; x-coord
        .byte   34 ; x-coord of title
        .addr   TextDirectoryListingDialogTitle
        ldy     #10
        ldx     #19
        jsr     SetCursorPosToXY
        lda     #<TextFileListColumnHeaders
        ldx     #>TextFileListColumnHeaders
        jsr     DisplayMSB1String
        ldy     #11
        ldx     #18
        jsr     SetCursorPosToXY
        ldy     #44
        jsr     OutputHorizontalLineX
        lda     #<TextFileSelectionInstructions
        ldx     #>TextFileSelectionInstructions
        jsr     DisplayStringInStatusLine
        ldy     PrefixBuffer ; copy PrefixBuffer to SysPathBuf
LE81F:  lda     PrefixBuffer,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LE81F
        jsr     OpenDirectoryAndReadHeader
        bcs     LE88B ; branch on error
        jsr     SetCurrentLinePointerToFirstLine
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
        bcs     LE886 ; branch on error
        jsr     FormatDirectoryEntryToString
        lda     MemoryMap::INBUF ; copy formatted entry to doc line
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
LE86F:  jsr     SetCurrentLinePointerToNextLine
        bra     LE842
;;; Clean up & return.
LE874:  jsr     SetCurrentLinePointerToFirstLine
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
        lda     #<TextNoFilesPrompt
        ldx     #>TextNoFilesPrompt
        jsr     DisplayStringInStatusLine
        jsr     PlayTone
        jsr     GetKeypress
;;; Dismiss the dialog.
LE8A8:  bra     LE874
LE8AA:  lda     #12  ; highlight top entry
        sta     DirectoryListHighlightedRow
        jsr     SetCurrentLinePointerToFirstLine
RedrawDirectoryListingScrollArea:
        jsr     SaveCurrentLineState2
        ldy     #12
LE8B7:  ldx     #19
        jsr     SetCursorPosToXY
        lda     ZeroPage::CV
        cmp     DirectoryListHighlightedRow
        bne     LE8C6
        jsr     SetMaskForInverseText
LE8C6:  ldx     CurrentLinePtr+1
        lda     CurrentLinePtr
        lsr     a ; check low bit of pointer
        php       ; to determine memory bank
        rol     a ; containing that line
        plp
        bcc     LE8D3
        sta     SoftSwitch::RDCARDRAM
LE8D3:  jsr     DisplayString
        sta     SoftSwitch::RDMAINRAM
        jsr     SetMaskForNormalText
        jsr     IsOnLastDocumentLine
        beq     LE8EE
        jsr     SetCurrentLinePointerToNextLine
        ldy     ZeroPage::CV
        iny
        cpy     #BottomTextLine
        blt     LE8B7
        jsr     SetCurrentLinePointerToPreviousLine
LE8EE:  ldy     #StatusLine
        ldx     #32
        jsr     SetCursorPosToXY
DirectoryListingGetKeypress:
        jsr     GetKeypress
        cmp     #HICHAR(ControlChar::UpArrow)
        beq     LE93B
        cmp     #HICHAR(ControlChar::Return)
        beq     LE966
        cmp     #HICHAR(ControlChar::Esc)
        beq     LE8A8
        cmp     #HICHAR(ControlChar::DownArrow)
        bne     DirectoryListingGetKeypress
;;; Move highlight to next directory entry.
        lda     DocumentLineCount+1
        bne     LE91C
        lda     DocumentLineCount
        cmp     #9
        bge     LE91C ; branch if there are more entries past bottom
        clc
        adc     #10
        cmp     DirectoryListHighlightedRow ; already on last entry
        blt     DirectoryListingGetKeypress
LE91C:  lda     DirectoryListHighlightedRow
        cmp     #20
        blt     LE931 ; branch if not on bottom visible entry
        jsr     IsOnLastDocumentLine
        beq     DirectoryListingGetKeypress
        jsr     RestoreCurrentLineState2
        jsr     SetCurrentLinePointerToNextLine ; scroll up one line
        jmp     RedrawDirectoryListingScrollArea
LE931:  inc     a
        sta     DirectoryListHighlightedRow
        jsr     RestoreCurrentLineState2
        jmp     RedrawDirectoryListingScrollArea
;;; Move highlight to previous directory entry.
LE93B:  jsr     SaveCurrentLineState
        jsr     RestoreCurrentLineState2
        jsr     IsOnFirstDocumentLine
        bne     LE952
        lda     DirectoryListHighlightedRow
        cmp     #12 ; aleady on top visible entry?
        bne     LE95F
        jsr     RestoreCurrentLineState
        bra     DirectoryListingGetKeypress
LE952:  lda     DirectoryListHighlightedRow
        cmp     #13
        bge     LE95F ; branch if not on top visible entry
        jsr     SetCurrentLinePointerToPreviousLine
        jmp     RedrawDirectoryListingScrollArea
LE95F:  dec     a ; scroll down one line
        sta     DirectoryListHighlightedRow
        jmp     RedrawDirectoryListingScrollArea
;;; Accept selected file.
LE966:  jsr     RestoreCurrentLineState2
        lda     DirectoryListHighlightedRow
        sec     ; compute index of selected entry
        sbc     #12
        clc
        adc     CurrentLineNumber
        sta     CurrentLineNumber
        bcc     LE97B
        inc     CurrentLineNumber+1
LE97B:  jsr     LoadCurrentLinePointerIntoAX
        sta     CurrentLinePtr
        stx     CurrentLinePtr+1
        ldy     #0
        ldx     #0
LE986:  inx
        iny
        jsr     GetCharAtYInCurrentLine ; copy filename of selected entry
        sta     ProDOS::SysPathBuf,x    ; to SysPathBuf
        cmp     #HICHAR(' ')
        bne     LE986
        dex
        stx     ProDOS::SysPathBuf
        stx     PathnameLength
        jmp     LE874
DirectoryListHighlightedRow:
        .byte   $00
DirectoryEntriesLeftToList:
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
        lda     #43
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

;;; 13 directory entries per block * 39 bytes per entry is 507 bytes;
;;; 5 bytes of padding to complete a 512 byte block.
SkipPaddingBytesInDirectoryBlock:
        lda     #5
        bra     LE9DB
ReadNextDirectoryEntryInBlock:
        lda     #39
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
;;; Output filename.
LEA0C:  lda     ProDOS::SysPathBuf,y
        ora     #MSBOnORMask
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
;;; Output known file type (3-char type).
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
;;; Output unknown filetype (hex value).
LEA3A:  lda     #HICHAR('$')
        sta     MemoryMap::INBUF+$12
        lda     ProDOS::SysPathBuf+$10
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #DigitToCharORMask
        cmp     #HICHAR(':')
        blt     LEA4F
        clc
        adc     #7
LEA4F:  sta     MemoryMap::INBUF+$13
        lda     ProDOS::SysPathBuf+$10
        and     #%00001111
        ora     #DigitToCharORMask
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
;;; Output aux type.
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
;;; Output modified date.
        lda     ProDOS::SysPathBuf+$21
        ldx     ProDOS::SysPathBuf+$22
        jsr     FormatDateInAX
;;; Output modified time.
        lda     ProDOS::SysPathBuf+$23
        ldx     ProDOS::SysPathBuf+$24
        jsr     FormatTimeInAX
        ldy     #$10
LEAA5:  lda     DateTimeFormatString,y
        sta     MemoryMap::INBUF+$1A,y
        dey
        bne     LEAA5
;;; Store final length of output.
        lda     #42
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

;;; Wait for a special key (from SpecialKeyTable, any key in first X
;;; entries), or Esc. Return with carry clear if that key was pressed,
;;; carry set if Esc was pressed. Returns 0 if none of the special keys
;;; were pressed, otherwise returns 1+ the offset in SpecialKeyTable of
;;; the key that was pressed.
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
        pha     ; save registers
        phy
        phx
        cmp     #$20 ; MouseText?
        bge     LEB14 ; branch if no
        clc
        adc     #$40 ; remap MouseText
LEAFD:  jsr     WriteCharToScreen
        lda     Columns80::OURCH
        inc     a
        cmp     #ColumnCount ; last column?
        blt     LEB0D
LEB08:  jsr     MoveTextOutputPosToStartOfNextLine
        lda     #0
LEB0D:  sta     Columns80::OURCH
LEB10:  plx     ; restore registers
        ply
        pla
        rts
LEB14:  cmp     #HICHAR(' ')
        bge     LEB1C
        cmp     #HICHAR(ControlChar::Null)
        bge     LEB2E
LEB1C:  and     CharANDMask
        bmi     LEAFD
        cmp     #$40 ; check if MouseText char
        blt     LEAFD ; ($40 - $5F)
        cmp     #$60
        bge     LEAFD
        sec
        sbc     #$40 ; subtract $40 if MouseText
        bra     LEAFD
LEB2E:  cmp     #HICHAR(ControlChar::Return)
        beq     LEB08
        cmp     #HICHAR(ControlChar::InverseVideo)
        beq     LEB3C
        cmp     #HICHAR(ControlChar::NormalVideo)
        beq     LEB3F
        bra     LEB10
LEB3C:  lda     #MSBOffANDMask ; turn on inverse video
        .byte   OpCode::BIT_Abs
LEB3F:  lda     #%11111111 ; turn on normal video
        sta     CharANDMask
LEB44:  bra     LEB10

ComputeTextOutputPosForCurrentCursorPos:
        lda     ZeroPage::CV
        bra     ComputeTextOutputPos
MoveTextOutputPosToStartOfNextLine:
        stz     Columns80::OURCH
        lda     ZeroPage::CV
        inc     a
;;; for row in A
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

;;; Table of text row base addresses.
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

;;; Clears to end of line, without changing the cursor position.
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

        bra     LEC10 ; unreachable instruction

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
        lda     #HICHAR('-')
        .byte   OpCode::BIT_Abs
OutputOverscoreLine:
        lda     #MT_REMAP(MouseText::Overscore)
        .byte   OpCode::BIT_Abs
OutputUnderscoreLine:
        lda     #HICHAR('_')
        .byte   OpCode::BIT_Abs
OutputSpaces:
        lda     #HICHAR(' ')
OutputRowOfChars:
        jsr     OutputCharAndAdvanceScreenPos
        dey
        bne     OutputRowOfChars
        rts

;;; Returns character entered in A. It will have the MSB set unless
;;; Open-Apple was down, in which case the MSB will be clear.
GetKeypress:
        lda     MacroRemainingLength
        beq     ReadKeyboardAndMouse
;;; Replay next keypress from macro
        lda     (MacroPtr)
        pha
        inc     MacroPtr
        bne     @Skip
        inc     MacroPtr+1
@Skip:  dec     MacroRemainingLength
        ldx     #0 ; no KeyModReg when replaying macro
        pla
        rts
;;; Keyboard & mouse input, and blinking cursor. Returns KeyModReg in X.
ReadKeyboardAndMouse:
        jsr     ComputeTextOutputPosForCurrentCursorPos
        jsr     ReadCharFromScreen
        sta     CharUnderCursor
        lda     CurrentCursorChar
        sta     DisplayedCharAtCursor
        lda     MouseSlot
        beq     ToggleCharAtCursor ; branch if no mouse
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
;;; Mouse position is always recentered, then compared to the
;;; MousePos(Min,Max) values to track the mouse movement. Mouse movements
;;; are mapped to arrow key keypresses for later processing.
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
;;; Toggle displayed character between cursor character and what's under
;;; the cursor.
ToggleCharAtCursor:
        jsr     DisplayCurrentDateAndTimeInMenuBar
        jsr     ReadCharFromScreen
        pha
        lda     DisplayedCharAtCursor
        jsr     WriteCharToScreen
        pla
        sta     DisplayedCharAtCursor
        lda     CursorBlinkRate
        sta     CursorBlinkCounter
LECE6:  lda     #$28
        sta     CursorBlinkCounter+1
LECEB:  ldy     #0
LECED:  lda     SoftSwitch::KBD
        bmi     HandleKeyPress ; branch if key pressed
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
        bpl     LED23 ; branch if mouse button up
LED09:  cli
        jsr     LoadXYForMouseCall
        sei
        jsr     CallReadMouse
        ldx     MouseSlot
        ldy     #4
        lda     Mouse::MOUSTAT,x
        bmi     LED09 ; loop while mouse button down
        lda     #$80
        jsr     CallWaitMonitorRoutine
        ldy     #4 ; mouse button released; maps to control char
        bra     LED5B
LED23:  dey
        lda     Mouse::MOUXL,x
        cmp     MousePosMin
        blt     LED5B ; movement left maps to left arrow
        dey
        cmp     MousePosMax
        bge     LED5B ; movement right maps to right arrow
        dey
        lda     Mouse::MOUYL,x
        cmp     MousePosMin
        blt     LED5B ; movement up maps to up arrow
        dey
        cmp     MousePosMax
        bge     LED5B ; movement down maps to down arrow
        cli
        bra     LED4E
LED44:  ldy     #$4B            ; 75
LED46:  lda     SoftSwitch::KBD ; check for keypress
        bmi     HandleKeyPress
        dey
        bne     LED46
LED4E:  dec     CursorBlinkCounter+1 ; decrement blink counter
        bne     LECEB
        dec     CursorBlinkCounter
        bne     LECE6
        jmp     ToggleCharAtCursor
LED5B:  cli
        lda     CursorMovementControlChars,y
HandleKeyPress:
        bit     SoftSwitch::RDBTN0 ; Open-Apple
        bmi     LED71              ; branch if down
        bit     SoftSwitch::RDBTN1 ; Solid-Apple
        bpl     LED73              ; branch if up
        cmp     #HICHAR('1')       ; keypress between 1 and 9?
        blt     LED71
        cmp     #HICHAR(':')
        blt     HandleMacroFunctionKey
LED71:  and     #MSBOffANDMask ; clear MSB
LED73:  pha
        lda     CharUnderCursor ; hide cursor
        jsr     WriteCharToScreen
LoadKeyModReg:
        ldx     SoftSwitch::KEYMODREG
        txa
        and     #%00010000 ; check if numeric keypad key pressed
        beq     LED8E
        ldy     #8
        pla
LED85:  cmp     MacroFunctionKeys,y
        beq     TriggerMacroNumberY
        dey
        bpl     LED85
        pha
LED8E:  stz     SoftSwitch::KBDSTRB
        pla     ; restore key typed into A
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
        and     #CharToDigitANDMask
        dec     a
        tay
TriggerMacroNumberY:
        jsr     LoadMacroPointer
        lda     (MacroPtr)
        sta     MacroRemainingLength
        beq     @Done ; zero-length macro
        inc     MacroPtr
        bne     @Skip
        inc     MacroPtr+1
@Skip:  lda     CharUnderCursor
        jsr     WriteCharToScreen
        stz     SoftSwitch::KBDSTRB
        jmp     GetKeypress
@Done:  stz     SoftSwitch::KBDSTRB
        lda     CharUnderCursor
        jsr     WriteCharToScreen
        jmp     GetKeypress

;;; Load pointer to macro #Y into MacroPtr.
LoadMacroPointer:
        lda     #<MacroTable
        sta     MacroPtr
        lda     #>MacroTable
        sta     MacroPtr+1
        cpy     #0
        beq     @Out
@Loop:  lda     MacroPtr
        clc
        adc     #MaxMacroLength+1 ; length of macro table entry
        sta     MacroPtr
        bcc     @Skip
        inc     MacroPtr+1
@Skip:  dey
        bne     @Loop
@Out:   rts

;;; Loads $Cs and $s0 values for the mouse slot into X and Y,
;;; respectively.
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
        bcc     @Out ; branch if no clock/cal card
        lda     ZeroPage::CV
        pha
        lda     Columns80::OURCH
        pha
        ldx     #60
        ldy     #1
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        lda     #<DateTimeFormatString
        ldx     #>DateTimeFormatString
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
        bne     @Skip
        ldx     #HICHAR(' ')
@Skip:  stx     DateTimeFormatString+2
        sta     DateTimeFormatString+3
        lda     DateLoByte
        and     #%11100000
        lsr     DateHiByte
        ror     a
        lsr     a
        lsr     a
        tay
        ldx     #0
@Loop:  lda     MonthNames-3,y
        sta     DateTimeFormatString+5,x
        iny
        inx
        cpx     #4
        blt     @Loop
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
        ora     #DigitToCharORMask
        rts

DisplayCurrentDocumentLine:
        stz     Columns80::OURCH
        ldx     CurrentLinePtr+1
        lda     CurrentLinePtr
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
        bpl     @Out
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
@Loop:  cpy     #TopTextLine
        beq     @GotTopLine
        jsr     SetCurrentLinePointerToPreviousLine
        dey
        bra     @Loop
@GotTopLine:
        ldx     #0
        jsr     SetCursorPosToXY
@Loop2: jsr     DisplayCurrentDocumentLine
        lda     ZeroPage::CV
        cmp     #BottomTextLine
        beq     @Done
        jsr     IsOnLastDocumentLine
        beq     @ClearRemaining
        jsr     MoveTextOutputPosToStartOfNextLine
        jsr     SetCurrentLinePointerToNextLine
        bra     @Loop2
@ClearRemaining:
        jsr     ClearTextWindowFromCursor
@Done:  jsr     RestoreCurrentLineState2
        rts

DisplayDefaultStatusText:
        Lda     #<TextDefaultStatusText
        ldx     #>TextDefaultStatusText
        jmp     DisplayStringInStatusLine

DisplayHelpKeyCombo:
        ldx     #67
        ldy     #StatusLine
        jsr     SetCursorPosToXY
        lda     #<TextHelpKeyCombo
        ldx     #>TextHelpKeyCombo
        jsr     DisplayMSB1String
        rts

DisplayLineAndColLabels:
        ldy     #StatusLine
        ldx     #44
        jsr     SetCursorPosToXY
        lda     #<TextLineAndColumnLabels
        ldx     #>TextLineAndColumnLabels
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
        lda     #<TextHelpText
        sta     Pointer
        lda     #>TextHelpText
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

;;; Routine that displays one of the strings in LCRAM bank 2. Pointer to
;;; the string is in A (lo), X (hi). Displays an MSB-off (low ASCII)
;;; string.
DisplayString:
        sta     StringPtr
        stx     StringPtr+1
        lda     #MSBOnORMask
        sta     CharORMask
        ldy     #0
        lda     (StringPtr),y
        and     #MSBOffANDMask
        bra     LEFD0

;;; Same above, but displays an MSB-on (high ASCII) string.
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
        ldy     #ColumnCount
        jsr     OutputHorizontalLine
        rts

SetMaskForInverseText:
        lda     #MSBOffANDMask
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
        lda     #<TextAbortButton
        ldx     #>TextAbortButton
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
        lda     #<TextAcceptButton
        ldx     #>TextAcceptButton
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

;;; Draws a dialog box with the given position, dimensions, and title.
;;; This is like a ProDOS MLI call; it reads 7 bytes from memory after
;;; the JSR.
;;;
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
;;; ParamTablePtr now points to 1 byte before the start of the param
;;; table. Copy first 4 bytes of param table to $EA - $ED.
        ldy     #4
@Loop:  lda     (ParamTablePtr),y
        sta     DialogHeight-1,y
        dey
        bne     @Loop
        jsr     DrawDialogBoxFrame
        jsr     SetMaskForInverseText
        ldy     #5
        lda     (ParamTablePtr),y
        tax
        ldy     ScreenYCoord
        jsr     SetCursorPosToXY
;;; Draw the title string.
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
        bcc     @Skip
        inc     ParamTablePtr+1
@Skip:  lda     ParamTablePtr+1
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
        lda     #<TextEscToGoBack
        ldx     #>TextEscToGoBack
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
        lda     #<TextPressEscToEditDocumentPrompt
        ldx     #>TextPressEscToEditDocumentPrompt
        jmp     DisplayStringInStatusLine

WaitForSpaceToContinueInStatusLine:
        lda     #<TextPressSpaceToContinuePrompt
        ldx     #>TextPressSpaceToContinuePrompt
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

;;; Restore the text screen (rows 2-9, under the menus) from the backing
;;; store buffer.
RestoreScreenAreaUnderMenus:
        lda     #<BackingStoreBuffer
        sta     Pointer3
        lda     #>BackingStoreBuffer
        sta     Pointer3+1
        lda     #TopMenuLine
@LineLoop:
        jsr     ComputeTextOutputPos
        lda     #LastColumn
        sta     Columns80::OURCH
@CharLoop:
        ldy     Columns80::OURCH
        sta     SoftSwitch::RDCARDRAM
        lda     (Pointer3),y
        sta     SoftSwitch::RDMAINRAM
        jsr     WriteCharToScreen
        dec     Columns80::OURCH
        bpl     @CharLoop
        lda     Pointer3
        clc
        adc     #ColumnCount
        sta     Pointer3
        bcc     @Skip
        inc     Pointer3+1
@Skip:  lda     ZeroPage::CV
        cmp     #MaxMenuLine+1
        bge     @Out
        inc     a
        bra     @LineLoop
@Out:   rts

;;; Store text rows 2-9 (which are obscured by menus) to the backing
;;; store buffer.
SaveScreenAreaUnderMenus:
        lda     #<BackingStoreBuffer
        sta     Pointer3
        lda     #>BackingStoreBuffer
        sta     Pointer3+1
        lda     #TopMenuLine
@LineLoop:
        jsr     ComputeTextOutputPos
        lda     #LastColumn
        sta     Columns80::OURCH
@CharLoop:
        jsr     ReadCharFromScreen
        ldy     Columns80::OURCH
        sta     SoftSwitch::WRCARDRAM
        sta     (Pointer3),y
        sta     SoftSwitch::WRMAINRAM
        dec     Columns80::OURCH
        bpl     @CharLoop
        lda     Pointer3
        clc
        adc     #ColumnCount
        sta     Pointer3
        bcc     @Skip
        inc     Pointer3+1
@Skip:  lda     ZeroPage::CV
        cmp     #MaxMenuLine+1
        bge     @Out
        inc     a
        bra     @LineLoop
@Out:   rts

;;; Standard ProDOS tone.
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
        lda     #<TextHighlightBlockInstructions
        ldx     #>TextHighlightBlockInstructions
        jsr     DisplayStringInStatusLineWithEscToGoBack
        jsr     SwapCursorMovementControlChars
        jsr     DisplayLineAndColLabels
        jsr     DisplayCurrentDocumentLineInInverse
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
;;; Finish block selection.
        jsr     SwapCursorMovementControlChars
        clc
        rts
;;; Invalid character entered during block selection.
LF200:  jsr     PlayTone
        bra     LF1DD
;;; Block select forward one page.
LF205:  lda     #VisibleLineCount
        bra     LF20B
;;; Block select forward one line.
LF209:  lda     #1
LF20B:  sta     ScratchVal1
LF20E:  jsr     IsOnLastDocumentLine
        beq     LF1D5 ; get next keypress
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
        jsr     DisplayCurrentDocumentLine
LF232:  ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     MoveToNextDocumentLine
        jsr     DisplayCurrentDocumentLineInInverse
        dec     ScratchVal1
        bne     LF20E
        jmp     LF1D5 ; get next keypress
;;; Block select backward one page.
LF248:  lda     #VisibleLineCount
        bra     LF24E
;;; Block select backward one line.
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
        jsr     DisplayCurrentDocumentLine
LF27A:  ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     MoveToPreviousDocumentLine
        jsr     DisplayCurrentDocumentLineInInverse
        dec     ScratchVal1
        bne     LF251
        jmp     LF1D5 ; get next keypress
CancelBlockSelection:
        jsr     RestoreCurrentLineState2
        jsr     SwapCursorMovementControlChars
        sec
        rts

;;; Swaps these two lists of control characters.
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

;;; Remapped Control chars during block selection.
BlockSelectionCursorControlChars:
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::Return)

DisplayCurrentDocumentLineInInverse:
        ldx     #0
        ldy     CurrentCursorYPos
        jsr     SetCursorPosToXY
        jsr     SetMaskForInverseText
        jsr     DisplayCurrentDocumentLine
        jsr     SetMaskForNormalText
        rts

DisplayPrintDialog:
        jsr     DrawDialogBox
        .byte   10 ; height
        .byte   42 ; width
        .byte   5  ; y-coord
        .byte   18 ; x-coord
        .byte   34 ; x-coord of title
        .addr   TextPrintDialogTitle
        ldx     #38
        ldy     #12
        jsr     DrawAbortButton
        jsr     DisplayHitEscToEditDocInStatusLine
LF2D7:  ldy     #7
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TextPrinterSlotPrompt
        ldx     #>TextPrinterSlotPrompt
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
        lda     #<TextPrinterInitStringPrompt
        ldx     #>TextPrinterInitStringPrompt
        jsr     DisplayMSB1String
        ldy     PrinterInitString
LF30E:  lda     PrinterInitString,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LF30E
        lda     #PrinterInitStringMaxLength
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
        and     #MSBOffANDMask
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
        lda     #<TextEnterLeftMarginPrompt
        ldx     #>TextEnterLeftMarginPrompt
        jsr     DisplayMSB1String
        lda     PrinterLeftMargin
        jsr     InputSingleDigit
        bcs     LF31E ; cancelled, so return
        sta     PrinterLeftMargin
        ldy     #10
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TextPrintFromWherePrompt
        ldx     #>TextPrintFromWherePrompt
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
        jsr     SetCurrentLinePointerToFirstLine
        pla
;;; print from cursor
LF397:  jsr     OutputCharAndAdvanceScreenPos
        ldy     #11
        ldx     #20
        jsr     SetCursorPosToXY
        lda     #<TextPrinting
        ldx     #>TextPrinting
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
        lda     #<TextPrinterNotFound
        ldx     #>TextPrinterNotFound
        jsr     DisplayMSB1String
        jmp     BeepAndWaitForReturnOrEscKey
LF3EF:  jsr     DeterminePrinterOutputRoutineAddress
        lda     #$FF
        sta     PrinterLineFeedFlag
        jmp     LF417
FoundPrinter:
        ldy     #$0D; get PInit entry point
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
        jsr     SetCurrentLinePointerToNextLine
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
        beq     @AfterMargin      ; left margin spaces
@MarginLoop:
        lda     #' '
        phy
        jsr     SendCharacterToPrinter
        ply
        dey
        bne     @MarginLoop
@AfterMargin:
        jsr     CopyCurrentLineToSysPathBuf
        lda     #<ProDOS::SysPathBuf
        ldx     #>ProDOS::SysPathBuf
SendLineAtAXToPrinter:
        sta     Pointer
        stx     Pointer+1
        lda     (Pointer)
        and     #MSBOffANDMask
        sta     ScratchVal1 ; length of line to print
        beq     @EndOfLine
        lda     #1
        sta     ScratchVal6
@CharLoop:
        ldy     ScratchVal6 ; offset of char in line
        lda     (Pointer),y
        jsr     SendCharacterToPrinter
        inc     ScratchVal6
        dec     ScratchVal1
        bne     @CharLoop
@EndOfLine:
        lda     #ControlChar::Return
        jsr     SendCharacterToPrinter
        lda     PrinterLineFeedFlag
        bne     @Out
        lda     #ControlChar::ControlJ ; line feed
        jsr     SendCharacterToPrinter
@Out:   rts

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
        lda     #ColumnCount
        sta     ZeroPage::WNDWDTH
        rts

;;; A single-line input routine. Maximum length+1 passed in A. Returns
;;; with Carry set if input was cancelled with Esc.
InputSingleLine:
        sta     Pointer3+1
        lda     Columns80::OURCH
        sta     MenuDrawingIndex
@RedisplayInput:
        lda     MenuDrawingIndex
        sta     Columns80::OURCH
        ldy     Pointer3+1
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
        cpy     Pointer3+1
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
        blt     @Skip
        adc     #6
@Skip:  jmp     OutputCharAndAdvanceScreenPos

;;; Display AX in decimal, with width of Y.
DisplayAXInDecimal:
        jsr     FormatAXInDecimal
        lda     #<StringFormattingBuffer
        ldx     #>StringFormattingBuffer
        jsr     DisplayMSB1String
        rts

;;; Format AX as decimal, with width in Y.
FormatAXInDecimal:
        sta     ScratchVal4
        stx     ScratchVal5
        sty     StringFormattingBuffer
LF570:  jsr     ConvertNextDecimalDigit
        lda     ScratchVal6
        ora     #DigitToCharORMask
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
        ldx     #16 ; 16 bits to process
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
        lda     CurrentLinePtr
        sta     SavedCurrentLinePtr2
        lda     CurrentLinePtr+1
        sta     SavedCurrentLinePtr2+1
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
        lda     SavedCurrentLinePtr2+1
        sta     CurrentLinePtr+1
        lda     SavedCurrentLinePtr2
        sta     CurrentLinePtr
        rts

SaveCurrentLineState:
        lda     CurrentLinePtr
        sta     SavedCurrentLinePtr
        lda     CurrentLinePtr+1
        sta     SavedCurrentLinePtr+1
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
        lda     SavedCurrentLinePtr+1
        sta     CurrentLinePtr+1
        lda     SavedCurrentLinePtr
        sta     CurrentLinePtr
        rts

;;; Returns with Zero flag set if on last line of document.
IsOnLastDocumentLine:
        lda     CurrentLineNumber
        cmp     DocumentLineCount
        bne     @Out
        lda     CurrentLineNumber+1
        cmp     DocumentLineCount+1
@Out:   rts

;;; Returns the current line length in A, and Carry clear if cursor is at
;;; (or past) end of line.
IsCursorAtEndOfLine:
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        cmp     CurrentCursorXPos
        rts

;;; Returns with Zero flag set if memory is full.
CheckIfMemoryFull:
        lda     DocumentLineCount
        cmp     #<MaxLineCount
        bne     @Out
        lda     DocumentLineCount+1
        cmp     #>MaxLineCount
        bne     @Out
        lda     #<TextMemoryFull
        ldx     #>TextMemoryFull
        jsr     DisplayStringInStatusLine
        jsr     BeepAndWaitForReturnOrEscKey
        jsr     DisplayDefaultStatusText
        jsr     DisplayHelpKeyCombo
        jsr     DisplayLineAndColLabels
        lda     #0
        sta     PathnameBuffer
@Out:   rts

IsOnFirstDocumentLine:
        lda     CurrentLineNumber
        cmp     #1
        bne     @Out
        lda     CurrentLineNumber+1
@Out:   rts

SetCurrentLinePointerToPreviousLine:
        jsr     DecrementCurrentLineNumber
        jsr     LoadCurrentLinePointerIntoAX
        sta     CurrentLinePtr
        stx     CurrentLinePtr+1
        rts

DecrementCurrentLineNumber:
        dec     CurrentLineNumber
        lda     CurrentLineNumber
        cmp     #$FF
        bne     @Out
        dec     CurrentLineNumber+1
@Out:   rts

LoadCurrentLinePointerIntoAX:
;;; Decrements by 1 to get pointer offset; this is because line numbers
;;; start at 1.
        lda     CurrentLineNumber
        ldx     CurrentLineNumber+1
LoadLineAXPointerIntoAX_1:
        dec     a
        cmp     #$FF
        bne     LoadLineAXPointerIntoAX
        dex
;;; Multiplies AX by 2 to get offset into line pointer table, then loads
;;; that pointer into AX.
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

SetCurrentLinePointerToNextLine:
        jsr     IncrementCurrentLineNumber
        jsr     LoadCurrentLinePointerIntoAX
        sta     CurrentLinePtr
        stx     CurrentLinePtr+1
        rts

IncrementCurrentLineNumber:
        inc     CurrentLineNumber
        bne     @Out
        inc     CurrentLineNumber+1
@Out:   rts

;;; This routine is never referenced.
        ldx     CurrentLineNumber+1
        lda     CurrentLineNumber
        clc
        adc     #2
        bcc     LF6C9
        inx
LF6C9:  jsr     LoadLineAXPointerIntoAX_1
        sta     NextLinePtr
        stx     NextLinePtr+1
        rts

;;; Moves the cursor to the previous line, and scrolls down if necessary.
MoveToPreviousDocumentLine:
        lda     CurrentCursorYPos
        cmp     #TopTextLine
        beq     @DoScroll
        dec     CurrentCursorYPos
        jsr     SetCurrentLinePointerToPreviousLine
        rts
@DoScroll:
        jsr     ScrollDownOneLine
        jsr     SetCurrentLinePointerToPreviousLine
        jsr     DisplayCurrentDocumentLine
        rts

;;; Moves the cursor to the next line, and scrolls up if necessary.
MoveToNextDocumentLine:
        lda     CurrentCursorYPos
        cmp     #BottomTextLine
        beq     @DoScroll
        inc     CurrentCursorYPos
        jsr     SetCurrentLinePointerToNextLine
        rts
@DoScroll:
        jsr     ScrollUpOneLine
        jsr     SetCurrentLinePointerToNextLine
        jsr     DisplayCurrentDocumentLine
        rts

;;; Moves left past all spaces in current line, starting at position Y.
;;; Updates Y.
SkipSpacesBackward:
        cpy     #2
        blt     @Out
        dey
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     SkipSpacesBackward
@Out:   rts

;;; Moves right past all spaces in current line, starting at position Y.
;;; Updates Y.
SkipSpacesForward:
        cpy     LastEditableColumn
        beq     @Out
        iny
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     SkipSpacesForward
@Out:   rts

;;; Moves left past all non-spaces in current line, starting at position
;;; Y. Updates Y.
SkipNonSpacesBackward:
        cpy     #2
        blt     @Out
        dey
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        bne     SkipNonSpacesBackward
        iny
@Out:   rts

;;; Moves right past all non-spaces in current line, starting at position
;;;  Y. Updates Y.
SkipNonSpacesForward:
        cpy     LastEditableColumn
        beq     @Out
        iny
        jsr     GetCharAtYInCurrentLine
        cmp     #' '
        bne     SkipNonSpacesForward
@Out:   rts

;;; Sets the current line to 1 and loads it into CurrentLinePtr.
SetCurrentLinePointerToFirstLine:
        stz     CurrentLineNumber+1
        lda     #1
        sta     CurrentLineNumber
        ldx     CurrentLineNumber+1
        jsr     LoadLineAXPointerIntoAX_1
        sta     CurrentLinePtr
        stx     CurrentLinePtr+1
        rts

;;; Pads line with spaces if line length is less than current cursor
;;; x-position. Updates line length, preserving CR flag.
PadLineWithSpacesUpToCursor:
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask ; clear MSB
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
        ora     #MSBOnORMask ; set MSB
        bra     LF769
LF768:  tya
LF769:  jsr     SetLengthOfCurrentLine
        rts

;;; If on the last line of the doc, sets its length to 0. Otherwise
;;; inserts a new line. The newly inserted line will be at NextLinePtr.
InsertNewLine:
        jsr     LoadNextLinePointer
        jsr     IsOnLastDocumentLine
        beq     LF778
        jsr     ShiftLinePointersDownForInsert
LF778:  lda     #0
        jsr     SetLengthOfNextLine

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

;;; Splits a line at the cursor. Y should also be set to the current
;;; cursor position within the line prior to calling.
SplitLineAtCursor:
        jsr     GetLengthOfCurrentLine
        bpl     LF7B1 ; branch if no CR at end of line
        lda     #$80
        jsr     SetLengthOfNextLine ; empty line with CR
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
LF7B1:  sta     ScratchVal4 ; saved line length
        sec
        sbc     CurrentCursorXPos ; decrement it by length before cursor
        sta     ScratchVal4
        beq     LF7E8 ; if 0, current line will be an empty line with CR
        tya            ; new length of current line is length before cursor
        ora     #MSBOnORMask ; add CR
        jsr     SetLengthOfCurrentLine
        ldx     #1
LF7C5:  iny     ; then copy text after cursor to other line
        jsr     GetCharAtYInCurrentLine
        phy
        phx
        ply
        jsr     SetCharAtYInNextLine
        phy
        plx
        ply
        inx
        dec     ScratchVal4
        bne     LF7C5
        dex
        jsr     GetLengthOfNextLine
        bpl     LF7E3
        txa
        ora     #MSBOnORMask ; add back CR
        bra     LF7E4
LF7E3:  txa
LF7E4:  jsr     SetLengthOfNextLine
LF7E7:  rts
LF7E8:  jsr     GetLengthOfCurrentLine
        bmi     LF7E7
        lda     #0
        bra     LF7E4

;;; Line number is 1-based; since this doesn't subtract 1 from the line
;;; number before accessing the line pointer table, it's actually loading
;;; the pointer to the line following the current line.
LoadNextLinePointer:
        ldx     CurrentLineNumber+1
        lda     CurrentLineNumber
        jsr     LoadLineAXPointerIntoAX
        sta     NextLinePtr
        stx     NextLinePtr+1
        rts

;;; The newly inserted line will be at NextLinePtr.
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
@Loop:  jsr     SetCurrentLinePointerToPreviousLine
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
        jsr     SetCurrentLinePointerToPreviousLine
        jsr     LoadNextLinePointer
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
        lda     SavedCurrentLinePtr+1
        sta     (Pointer),y
        dey
        lda     SavedCurrentLinePtr
        sta     (Pointer),y
        jsr     RestoreCurrentLineState
        jsr     LoadCurrentLinePointerIntoAX
        sta     CurrentLinePtr
        stx     CurrentLinePtr+1
        jsr     LoadNextLinePointer
@Out:   rts

;;; Word-wraps (reflows) the text up to the next CR (the end of the text
;;; line).
WordWrapUpToNextCR:
        jsr     SaveCurrentLineState2
        stz     WordWrapScratchVal4 ; Val4 = 0
LF88E:  jsr     IsOnLastDocumentLine
        bne     LF896
LF893:  jmp     WordWrapDone
LF896:  jsr     GetLengthOfCurrentLine
        bmi     LF893 ; branch if line ends with CR
        cmp     DocumentLineLength
        bge     LF893 ; branch if line full
        jsr     LoadNextLinePointer
        jsr     GetLengthOfCurrentLine
        sta     WordWrapScratchVal1 ; Val1 = length of current line
        jsr     GetLengthOfNextLine
        bpl     LF8B2 ; branch if no CR
        and     #MSBOffANDMask
        beq     LF893 ; branch if line empty
LF8B2:  sta     WordWrapScratchVal2 ; Val2 = length of next line
        lda     DocumentLineLength  ; calculate space left on
        sec                         ; current line
        sbc     WordWrapScratchVal1
        cmp     #2
        blt     LF893 ; branch if only 1 char of space left
        tay     ; Y = space left
        cmp     WordWrapScratchVal2 ; enough space for text on next line?
        blt     LF8DD               ; branch if no
        ldy     WordWrapScratchVal2 ; Y = length of next line
        jsr     GetLengthOfNextLine ; if next line has a CR,
        and     #MSBOnORMask                ; add a CR to the current line
        sta     ScratchVal2
        jsr     GetLengthOfCurrentLine
        ora     ScratchVal2
        jsr     SetLengthOfCurrentLine
        jmp     LF8E9 ; branch to the move logic
LF8DD:  jsr     GetCharAtYInNextLine ; search backward in next line
        cmp     #' ' ; for a space, so that only whole words are moved
        beq     LF8E9 ; branch if found
        dey
        bne     LF8DD
        beq     WordWrapDone
LF8E9:  sty     WordWrapScratchVal4 ; Val4 = number of chars to move
        sty     WordWrapScratchVal3 ; Val3 = number of chars to move
LF8EF:  jsr     GetCharAtYInNextLine ; copy text up to Y in next line
        sta     ProDOS::SysPathBuf,y       ; to SysPathBuf
        dey
        bne     LF8EF
        lda     WordWrapScratchVal1 ; update length of current line
        tay                         ; by number of chars moved
        clc
        adc     WordWrapScratchVal3
        sta     ScratchVal4
        jsr     GetLengthOfCurrentLine ; and preserve CR flag
        and     #MSBOnORMask
        ora     ScratchVal4
        jsr     SetLengthOfCurrentLine
        lda     WordWrapScratchVal3
        sta     ScratchVal4
        ldx     #1
LF916:  iny
        lda     ProDOS::SysPathBuf,x ; copy text from SysPathBuf to end
        jsr     SetCharAtYInCurrentLine ; of current line
        inx
        dec     ScratchVal4
        bne     LF916
        jsr     IsOnLastDocumentLine ; if this is the last line in the
        beq     WordWrapDone         ; document, then all done
        jsr     SetCurrentLinePointerToNextLine ; remove moved text
LF92B:  ldy     #1                   ; from the front of the next line
        jsr     RemoveCharAtYOnCurrentLine
        lda     ScratchVal4
        beq     LF93A
        dec     WordWrapScratchVal3
        bne     LF92B
LF93A:  jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        beq     LF944 ; branch if the line is now empty
        jmp     LF88E ; continue word-wrap on next line
LF944:  jsr     ShiftLinePointersUpForDelete ; delete the empty line
        jsr     SetCurrentLinePointerToPreviousLine
        jsr     DecrementDocumentLineCount
WordWrapDone:
        jsr     RestoreCurrentLineState2
        lda     WordWrapScratchVal4
        rts

;;; Returns the amount of space left on the previous line, if there is a
;;; previous line AND that line doesn't end with a CR; otherwise returns
;;; 0.
GetSpaceLeftOnPreviousLine:
        jsr     IsOnFirstDocumentLine
        beq     @IsFirst
        jsr     SetCurrentLinePointerToPreviousLine
        jsr     GetLengthOfCurrentLine
        bmi     @HasCR ; branch if ends in CR
        sta     ScratchVal2
        lda     DocumentLineLength
        sec
        sbc     ScratchVal2
        pha
        jsr     SetCurrentLinePointerToNextLine
        pla
        rts
@HasCR: jsr     SetCurrentLinePointerToNextLine
@IsFirst:
        lda     #0
        rts

RemoveCharAtYOnCurrentLine:
        jsr     GetLengthOfCurrentLine
        and     #MSBOffANDMask
        sta     ScratchVal4
        beq     @Out
;;;  loop to shift characters from Y to end of line left by 1
@Loop:  cpy     ScratchVal4
        bge     @UpdateLength
        iny
        jsr     GetCharAtYInCurrentLine
        dey
        beq     @Skip
        jsr     SetCharAtYInCurrentLine
@Skip:  iny
        bra     @Loop
;;; decrement length of current line
@UpdateLength:
        dec     ScratchVal4
        jsr     GetLengthOfCurrentLine
        and     #MSBOnORMask
        ora     ScratchVal4
        jsr     SetLengthOfCurrentLine
@Out:   rts

;;; Moves current word to next line if it won't fit on current one.
MoveWordToNextLine:
        jsr     InsertNewLine
;;; Search backward for the beginning of the word.
        ldy     LastEditableColumn
        dey
LF9A9:  jsr     GetCharAtYInCurrentLine
        cmp     #' '
        beq     LF9B6
        dey
        bne     LF9A9
        ldy     LastEditableColumn ; didn't find a word break
LF9B6:  cpy     LastEditableColumn
        bne     LF9CA
        ldy     #1 ; put char on next line
        jsr     SetCharAtYInNextLine
        tya
        jsr     SetLengthOfNextLine
        jsr     GetLengthOfCurrentLine
        dec     a
        bra     LF9DB
LF9CA:  lda     CurrentCursorXPos ; truncate current line at cursor pos
        pha
        sty     CurrentCursorXPos
        jsr     SplitLineAtCursor
        pla
        sta     CurrentCursorXPos
        jsr     GetLengthOfCurrentLine
LF9DB:  and     #MSBOffANDMask
        jsr     SetLengthOfCurrentLine
        jsr     SetCurrentLinePointerToNextLine ; word-wrap after the break
        jsr     WordWrapUpToNextCR
        jsr     SetCurrentLinePointerToPreviousLine
        rts

;;; A = *CurrentLinePtr
GetLengthOfCurrentLine:
        sty     YRegisterStorage
        ldy     #0
        bra     LF9F4
;;; A = *(CurrentLinePtr + Y)
GetCharAtYInCurrentLine:
        sty     YRegisterStorage
LF9F4:  lda     CurrentLinePtr
        lsr     a
        bcc     LFA07
        sta     SoftSwitch::RDCARDRAM
        lda     (CurrentLinePtr),y
        sta     SoftSwitch::RDMAINRAM
LFA01:  pha
        ldy     YRegisterStorage
        pla
        rts
LFA07:  lda     (CurrentLinePtr),y
        bra     LFA01

;;; A = *NextLinePtr
GetLengthOfNextLine:
        sty     YRegisterStorage
        ldy     #0
        bra     LFA15
;;; A = *(NextLinePtr + Y)
GetCharAtYInNextLine:
        sty     YRegisterStorage
LFA15:  lda     NextLinePtr
        lsr     a
        bcc     LFA28
        sta     SoftSwitch::RDCARDRAM
        lda     (NextLinePtr),y
        sta     SoftSwitch::RDMAINRAM
LFA22:  pha
        ldy     YRegisterStorage
        pla
        rts
LFA28:  lda     (NextLinePtr),y
        bra     LFA22

;;; *CurrentLinePtr = A
SetLengthOfCurrentLine:
        sty     YRegisterStorage
        ldy     #0
        bra     LFA36
;;; *(CurrentLinePtr + Y) = A
SetCharAtYInCurrentLine:
        sty     YRegisterStorage
LFA36:  pha
        lda     CurrentLinePtr
        lsr     a
        bcc     LFA49
        sta     SoftSwitch::WRCARDRAM
        pla
        sta     (CurrentLinePtr),y
        sta     SoftSwitch::WRMAINRAM
        ldy     YRegisterStorage
        rts
LFA49:  pla
        sta     (CurrentLinePtr),y
        ldy     YRegisterStorage
        rts

;;; *(NextLinePtr) = A
SetLengthOfNextLine:
        sty     YRegisterStorage
        ldy     #0
        bra     LFA5A
;;; *(NextLinePtr + Y) = A
SetCharAtYInNextLine:
        sty     YRegisterStorage
LFA5A:  pha
        lda     NextLinePtr
        lsr     a
        bcc     LFA6D
        sta     SoftSwitch::WRCARDRAM
        pla
        sta     (NextLinePtr),y
        sta     SoftSwitch::WRMAINRAM
        ldy     YRegisterStorage
        rts
LFA6D:  pla
        sta     (NextLinePtr),y
        ldy     YRegisterStorage
        rts

CopyCurrentLineToSysPathBuf:
        jsr     GetLengthOfCurrentLine
        sta     ProDOS::SysPathBuf
        and     #MSBOffANDMask
        beq     @Out
        tay
@Loop:  jsr     GetCharAtYInCurrentLine
        sta     ProDOS::SysPathBuf,y
        dey
        bne     @Loop
@Out:   rts

;;; Extended Keyboard II functions keys, remapped to Apple key combos.
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
        .byte   ','
        .byte   ControlChar::UpArrow
        .byte   'F'
        .byte   '.'
        .byte   ControlChar::DownArrow

;;; Table of Open-Apple key commands and handlers.
OpenAppleKeyComboTable:
        .byte   46  ; number of key combos

        .byte   'A' ; About
        .byte   'Q' ; Quit
        .byte   'L' ; Load File
        .byte   'S' ; Save
        .byte   'M' ; Clear Memory
        .byte   'N' ; New Prefix
        .byte   'D' ; Directory

        .byte   'a'
        .byte   'q'
        .byte   'l'
        .byte   's'
        .byte   'm'
        .byte   'n'
        .byte   'd'

        .byte   'E' ; Toggle Insert/Edit
        .byte   'e'
        .byte   '<' ; Beginning of line
        .byte   ','
        .byte   '>' ; End of line
        .byte   '.'
        .byte   '1' ; Beginning of file
        .byte   '9' ; End of file

        .byte   ControlChar::Delete     ; Block delete
        .byte   ControlChar::UpArrow    ; Page up
        .byte   ControlChar::DownArrow  ; Page down
        .byte   ControlChar::LeftArrow  ; Previous word
        .byte   ControlChar::RightArrow ; Next word
        .byte   ControlChar::Tab        ; Reverse tab

        .byte   'F' ; Delete char right
        .byte   'f'
        .byte   'Z' ; Show/hide CRs
        .byte   'z'
        .byte   '/' ; Help
        .byte   '?'
        .byte   'Y' ; Clear to end of line
        .byte   'y'
        .byte   'T' ; Tab stops
        .byte   't'
        .byte   'X' ; Clear line
        .byte   'x'
        .byte   'P' ; Print
        .byte   'p'
        .byte   'V' ; Volumes
        .byte   'v'
        .byte   'C' ; Copy text
        .byte   'c'

OpenAppleKeyComboJumpTable:
        .addr   DisplayAboutBox           ; A
        .addr   QuitEditor                ; Q
        .addr   LoadFileMenuItem          ; L
        .addr   SaveFile                  ; S
        .addr   ClearMemory               ; M
        .addr   SetNewPrefix              ; N
        .addr   ListDirectoryMenuItem     ; D
        .addr   DisplayAboutBox           ; a
        .addr   QuitEditor                ; q
        .addr   LoadFileMenuItem          ; l
        .addr   SaveFile                  ; s
        .addr   ClearMemory               ; m
        .addr   SetNewPrefix              ; n
        .addr   ListDirectoryMenuItem     ; d
        .addr   ToggleInsertOverwrite     ; E
        .addr   ToggleInsertOverwrite     ; e
        .addr   MoveToBeginningOfLine     ; <
        .addr   MoveToBeginningOfLine     ; ,
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
        .addr   DisplayHelpScreen         ; /
        .addr   DisplayHelpScreen         ; ?
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

;;; Table of other key commands and handlers.
EditingControlKeyTable:
        .byte   8 ; count byte
        .byte   HICHAR(ControlChar::Tab)
        .byte   HICHAR(ControlChar::Return)
        .byte   HICHAR(ControlChar::UpArrow)
        .byte   HICHAR(ControlChar::DownArrow)
        .byte   HICHAR(ControlChar::LeftArrow)
        .byte   HICHAR(ControlChar::RightArrow)
        .byte   HICHAR(ControlChar::ControlX)
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
        .byte   6,3,4 ; number of items in each menu

MenuXPositions:
        .byte   3,13,28

MenuWidths:
        .byte   19,17,21

MenuCount:
        .byte   3

;;; Pointers into Menu Item strings table below (for each menu).
MenuItemListAddresses:
        .addr   FileMenuItemTitles
        .addr   UtilitiesMenuItemTitles
        .addr   OptionsMenuItemTitles

;;; Addresses of Menu Item strings.
MenuItemTitleTable:
FileMenuItemTitles:
        .addr   TextAboutMenuItemTitle
        .addr   TextOpenMenuItemTitle
        .addr   TextSaveAsMenuItemTitle
        .addr   TextPrintMenuItemTitle
        .addr   TextClearMemoryMenuItemTitle
        .addr   TextQuitMenuItemTitle
UtilitiesMenuItemTitles:
        .addr   TextDirectoryMenuItemTitle
        .addr   TextNewPrefixMenuItemTitle
        .addr   TextVolumesMenuItemTitle
OptionsMenuItemTitles:
        .addr   TextSetLineLengthMenuItemTitle
        .addr   TextSetMouseStatusMenuItemTitle
        .addr   TextSetBlinkRateMenuItemTitle
        .addr   TextEditMacrosMenuItemTitle

MenuItemJumpTable:
        .addr   DisplayAboutDialog
        .addr   LoadFile
        .addr   SaveFileAs
        .addr   PrintFile
        .addr   DisplayClearMemoryDialog
        .addr   DisplayQuitDialog
        .addr   $0000
        .addr   $0000

        .addr   ListDirectory
        .addr   DisplaySetPrefixDialog
        .addr   DisplayVolumesDialog
        .addr   $0000
        .addr   $0000
        .addr   $0000
        .addr   $0000
        .addr   $0000

        .addr   SetLineLengthPrompt
        .addr   DisplayChangeMouseStatusDialog
        .addr   ChangeBlinkRate
        .addr   DisplayEditMacrosScreen

MousePosMax:
        .byte   StartingMousePos+23
MousePosMin:
        .byte   StartingMousePos-23
SearchText:
        repeatbyte $00, SearchTextMaxLength
CursorBlinkCounter:
        .addr   $0000
CursorBlinkRate:
        .byte   5
; This value toggles between CurrentCursorChar and CharUnderCursor.
DisplayedCharAtCursor:
        .byte   $00
CurrentCursorChar:
        .byte   HICHAR('_')
CharUnderCursor:
        .byte   $00
InsertCursorChar:
        .byte   HICHAR('_')
OverwriteCursorChar:
        .byte   ' ' ; inverse space
CharANDMask:
        .byte   %11111111 ; character ANDing mask
CharORMask:
        .byte   %00000000 ; character ORing mask (ie., for MSB string)
SavedMouseSlot:
        .byte   $00
CurrentDocumentPathnameLength:
        .byte   $00
ScratchVal1:
        .byte   $00 ; scratch byte; used for various purposes
DocumentUnchangedFlag:
        .byte   $FF ; set to 0 if the document has changed since last save
ScratchVal2:
        .byte   $00 ; scratch byte; used for various purposes
MacroRemainingLength:
        .byte   $00 ; # of remaining bytes of macro to inject into input
PrinterSlot:
        .byte   1

PrinterInitStringRawBytes:
        repeatbyte $00, 20

PrinterInitString:
        msb1pstring "^I80N"
        repeatbyte $00, PrinterInitStringMaxLength-(*-PrinterInitString)

PrinterLineFeedFlag:
        .byte   $00 ; if nonzero, does not send line feeds

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

;;; General purpose buffer for formatting short strings (10 bytes).
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
        .byte   FileType::DVR
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
        .byte   FileType::S16
        highascii "P16"
        .byte   FileType::BAS
        highascii "Bas"
        .byte   FileType::VAR
        highascii "Var"
        .byte   FileType::REL
        highascii "Rel"
        .byte   FileType::SYS
        highascii "Sys"

        .byte   $00 ; unused

MacroTable:

;;; Macro 1
        .byte   68 ; length byte
        highascii "\r EdIt! - by Bill Tudor\r"
        highascii "   Copyright 1988-83\r" ; typo - should be 1988-93
        highascii "Northeast Micro Systems"
        .byte   $00,$00

;;; Macro 2
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 3
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 4
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 5
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 6
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 7
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 8
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

;;; Macro 9
        .byte   0 ; length byte
        repeatbyte $00, MaxMacroLength

        .reloc

MainEditor_Code_End := *
BC00_Code_Start := *

        .org    $BC00

ShutdownRoutine:
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        jsr     ProDOS::MLI
        .byte   ProDOS::CDEALLOCINT
        .addr   EditorDeallocIntParams
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
        bit     SoftSwitch::RDROMLCB2
        cli
;;; If there's a calling program, load & execute it.
LBC40:  lda     SavedPathToCallingProgram
        beq     ExitEditor
        tay
LBC46:  lda     SavedPathToCallingProgram,y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     LBC46
        jsr     ProDOS::MLI
        .byte   ProDOS::CGETFILEINFO
        .addr   EditorGetFileInfoParams
        bne     ExitEditor
        lda     EditorGetFileInfoFileType
        cmp     #FileType::SYS
        bne     ExitEditor
        sta     EditorReadWriteRequestCount
        sta     EditorReadWriteRequestCount+1
        jsr     ProDOS::MLI
        .byte   ProDOS::COPEN
        .addr   EditorOpenParams
        bne     ExitEditor
        sta     EditorReadWriteBufferAddr ; stores a 0
        lda     EditorOpenRefNum
        sta     EditorReadWriteRefNum
        lda     #>ProDOS::SysLoadAddress
        sta     EditorReadWriteBufferAddr+1
        jsr     ProDOS::MLI
        .byte   ProDOS::CREAD
        .addr   EditorReadWriteParams
        php
        jsr     ProDOS::MLI
        .byte   ProDOS::CCLOSE
        .addr   EditorCloseParams
        plp
        bcc     JumpToCallingProgram

;;; Clears the screen and exits to ProDOS.
ExitEditor:
        jsr     Monitor::HOME
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
        .byte   $00 ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

;;; Reset routine (hooked to reset vector).
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
InterruptHandler:
        cld
        clc
        rts

EditorDeallocIntParams:
        .byte   $01
        .byte   $00

;;; Makes a MLI call; call # in A, param list address in X (lo), Y (hi).
MakeMLICall:
        sta     MLICallNumber
        stx     MLICallParamTableAddr
        sty     MLICallParamTableAddr+1
        sta     SoftSwitch::SETSTDZP
        lda     SoftSwitch::RDROMLCB1
        jsr     ProDOS::MLI
MLICallNumber:
        .byte   $00
MLICallParamTableAddr:
        .addr   $0000
        sta     SoftSwitch::SETALTZP
        pha
        lda     SoftSwitch::RWLCRAMB1
        lda     SoftSwitch::RWLCRAMB1
        pla
        rts

EditorGetFileInfoParams:
        .byte   $0A ; param_count
        .addr   ProDOS::SysPathBuf ; pathname
        .byte   $00 ; access
EditorGetFileInfoFileType:
        .byte   $00 ; file_type
EditorGetFileInfoAuxType:
        .word   $0000 ; aux_type
        .byte   $00 ; storage_type
EditorGetFileInfoBlocksUsed:
        .word   $0000 ; blocks_used
        .word   $0000 ; mod_date
        .word   $0000 ; mod_time
        .word   $0000 ; create_date
        .word   $0000 ; create_time

EditorDestroyParams:
        .byte   $01   ; param_count
        .addr   ProDOS::SysPathBuf ; pathname

EditorCreateParams:
        .byte   $07 ; param_count
        .addr   PathnameBuffer ; pathname
        .byte   %11000011 ; access
EditorCreateFileType:
        .byte   FileType::TXT ; file_type
        .word   $0000 ; aux_type
        .byte   ProDOS::StorageType::Seedling ; storage_type
        .word   $0000 ; create_date
        .word   $0000 ; create_time

EditorOpenParams:
        .byte   $03 ; param_count
        .addr   ProDOS::SysPathBuf ; pathname
        .addr   DataBuffer ; io_buffer
EditorOpenRefNum:
        .byte   $00 ; ref_num

EditorCloseParams:
        .byte   $01 ; param_count
EditorCloseRefNum:
        .byte   $00 ; ref_num

EditorReadWriteParams:
        .byte   $04 ; param_count
EditorReadWriteRefNum:
        .byte   $00 ; ref_num
EditorReadWriteBufferAddr:
        .addr   $0000 ; data_buffer
EditorReadWriteRequestCount:
        .word   $0000 ; request_count
EditorReadWriteTransferCount:
        .word   $0000 ; transfer_count

;;; One-byte buffer containing only a carriage return. Used to write
;;; empty lines, or CR after each line, when saving file.
SingleReturnCharBuffer:
        .byte   ControlChar::Return

EditorSetPrefixParams:
        .byte   $01 ; param_count
        .addr   ProDOS::SysPathBuf-1 ; pathname

EditorOnLineParams:
        .byte   $02 ; param_count
EditorOnLineUnitNum:
        .byte   $00 ; unit_num
EditorOnLineDataBuffer:
        .addr   DataBuffer ; data_buffer

EditorSetMarkParams:
        .byte   $02 ; param_count
EditorSetMarkRefNum:
        .byte   $00 ; ref_num
        .word   MacroTableOffsetInExecutable
        .byte   $00 ; highest byte of offset

PathnameLength: ; copy of first byte of PathnameBuffer
        .byte   $00

PrefixBuffer:
        .byte   $00 ; length byte
OnLineBuffer:
        repeatbyte $00, ProDOS::MaxPathnameLength

PathnameBuffer:
        .byte   $00 ; length byte
        repeatbyte $00, ProDOS::MaxPathnameLength

;;; Path to the Macros file.
ExecutableFilePathnameBuffer:
        .byte   $00 ; length byte
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
        .byte   ProDOS::EVOLNOTF
        .byte   ProDOS::EFILENOTF
        .byte   ProDOS::EDUPFNAME ; duplicate entry!
        .byte   ProDOS::EVOLFULL
        .byte   ProDOS::EDIRFULL
        .byte   ProDOS::EFLOCKED

;;; Addresses of error messages

MLIErrorMessageTable:
        .addr   TextUnknownError
        .addr   TextIOError
        .addr   TextNoDeviceConnectedError
        .addr   TextWriteProtectedError
        .addr   TextDuplicateFilenameError
        .addr   TextNoDiskError
        .addr   TextBadBlockError
        .addr   TextBadFileTypeError
        .addr   TextInvalidPathnameError
        .addr   TextDirectoryNotFoundError
        .addr   TextVolumeNotFoundError
        .addr   TextFileNotFoundError
        .addr   TextDuplicateFilenameError2
        .addr   TextVolumeFullError
        .addr   TextVolumeDirectoryFullError
        .addr   TextFileLockedError

DirectoryEntriesLeftInBlock:
        .byte   $00

;;; Likely all scratch variables:

ScratchVal3:
        .byte   $00
ScratchVal4:
        .byte   $00  ; storage for Accumulator, also scratch byte
ScratchVal5:
        .byte   $00  ; storage for X register
ScratchVal6:
        .byte   $00
FileCountInDirectory: ; word
YRegisterStorage:
        .byte   $00 ; storage for Y register
        .byte   $00

CurrentCursorXPos:
        .byte   $00
CurrentCursorYPos:
        .byte   $00

        .byte   $00,$00 ; unused

DocumentLineCount:
        .word   $0000

        .byte   $00,$00 ; unused

CurrentLineNumber:
        .word   $0000

        .byte   $00,$00 ; unused

ShowCRFlag: ; whether carriage returns are shown (using mousetext)
        .byte   $00

SavedCurrentLinePtr2:
        .addr   $0000 ; stores ending line for block delete/copy
SavedCurrentLineNumber2:
        .word   $0000 ; another place to save CurrentLineNumber

SavedCurrentLinePtr:
        .addr   $0000
SavedCurrentLineNumber:
        .addr   $0000

;;; Scratch variables used in WordWrapUpToNextCR
WordWrapScratchVal1:
        .byte   $00
WordWrapScratchVal2:
        .byte   $00
WordWrapScratchVal3:
        .byte   $00

        .byte   $00 ; unused

;;; Scratch variable used in WordWrapUpToNextCR
WordWrapScratchVal4:
        .byte   $00

RAMDiskUnitNum:
        .byte   $00

CallSetMouse:
         jmp    $0000
CallInitMouse:
         sta    SoftSwitch::SETSTDZP
         pha
         lda    SoftSwitch::RDROMLCB1
        pla
InitMouseEntry := *+1
         jsr    $0000
         sta    SoftSwitch::SETALTZP
         pha
         lda    SoftSwitch::RWLCRAMB1
         lda    SoftSwitch::RWLCRAMB1
         pla
         rts
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

;;; Sends character in A to printer.
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
        jsr     $0000
        rts

        .reloc

;;; End of code that gets relocated to $BC00

        BC00_Code_End := *

;;; $1000 bytes starting here gets copied to $D000, LC RAM bank 2

        D000_Bank2_Data_Start := *

        .org MemoryMap::LCRAM

TextHelpText:
;;; Line 1
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        .repeat 78
        .byte   MT_REMAP(MouseText::Overscore)
        .endrepeat
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 2
        .byte   MT_REMAP(MouseText::RightVerticalBar)
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
;;; Line 3
        .byte   MT_REMAP(MouseText::RightVerticalBar)
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
;;; Line 4
        .byte   MT_REMAP(MouseText::RightVerticalBar)
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
;;; Line 5
        .byte   MT_REMAP(MouseText::RightVerticalBar)
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
;;; Line 6
        .byte   MT_REMAP(MouseText::RightVerticalBar)
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
;;; Line 7
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-<          - To begining of line    "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-M           - Clear memory       "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 8
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "->          - To end of line         "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-V           - Volumes online     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 9
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-1          - To start of document   "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-E           - Toggle insert/edit "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 10
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-9          - To end of document     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Z           - Show/hide CR's     "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 11
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Y          - Clear cursor to end    "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-T           - Set tab stops      "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 12
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  Tab          - Tab right              "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-X (clear)   - Clear current line "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 13
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Tab        - Tab left               "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Delete      - Begin block delete "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 14
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  Delete       - Delete character left  "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-D           - Directory of disk  "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 15
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-F          - Delete character right "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-N           - New ProDOS prefix  "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 16
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        highascii "  Cntrl-S      - Search for a string    "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "  "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-P           - Print file         "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
;;; Line 17
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        repeatbyte HICHAR('_'), 40
        .byte   MT_REMAP(MouseText::TextCursor)
        repeatbyte HICHAR('_'), 37
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        .byte   HICHAR(ControlChar::Return)
        repeatbyte HICHAR(' '), 17
        .byte   MT_REMAP(MouseText::Diamond)
        highascii " Copyright 1988-93  Northeast Micro Systems "
        .byte   MT_REMAP(MouseText::Diamond)
        .byte   $00

TextHelpKeyCombo:
        .byte   12
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-? for Help"

TextSearchForPrompt:
        msb1pstring "Search for:"
TextSearching:
        msb1pstring "Searching...."
TextSearchTextNotFoundPrompt:
        msb1pstring "Not Found; press RTN."
TextCopyToOrFromClipboardPrompt:
        msb1pstring "Copy Text [T]o or [F]rom the clipboard?"
TextClipboardIsEmpty:
        msb1pstring "Clipboard is empty."
TextClipboardIsFull:
        msb1pstring "Clipboard is full."

TextDefaultStatusText:
        .byte   41
        highascii "Enter text or use "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-cmds; Esc for menus. "

TextLineAndColumnLabels:
        msb1pstring "Line       Col.   "

TextMenuNavigationInstructions:
        .byte   54
        highascii "Use arrows or mouse to select an option; then press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TextEscToGoBack:
        msb1pstring "ESC to go back"

TextTabStopEditingInstructions:
        .byte   76
        highascii "Use "
        .byte   MT_REMAP(MouseText::LeftArrow)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::RightArrow)
        highascii ", TAB to move; [T]-set/remove tabs; [C]-clear all; "
        .byte   MT_REMAP(MouseText::Return)
        highascii "-accept.   Pos: "

TextAbortButton:
        .byte   14
        .byte   MT_REMAP(MouseText::Checkerboard2)
        .byte   MT_REMAP(MouseText::Checkerboard1)
        .byte   " Abort "
        highascii " Esc "

TextAcceptButton:
        .byte   14
        .byte   MT_REMAP(MouseText::Checkerboard2)
        .byte   MT_REMAP(MouseText::Checkerboard1)
        .byte   " Accept "
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::Return)
        .byte   MT_REMAP(MouseText::RightVerticalBar)
        .byte   MT_REMAP(MouseText::Checkerboard2)

TextPressEscToEditDocumentPrompt:
        msb1pstring "Hit ESC to edit document."

TextPressSpaceToContinuePrompt:
        msb1pstring "Press <space> to continue."

TextQuitDialogTitle:
        msb1pstring " Quit "

TextQuitWithSave:
        msb1pstring "Q - Quit; saving changes"
TextQuitWithoutSave:
        msb1pstring "E - Exit; no save"

TextSetPrefixDialogTitle:
        msb1pstring " New Prefix "

TextSlotAndDriveKeyCombo:
        .byte   24
        highascii "Press "
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-S for Slot/Drive"

TextSlotPrompt:
        msb1pstring "Slot?"
TextDrivePrompt:
        msb1pstring "Drive?"
TextSaveAsDialogTitle:
        msb1pstring " Save File "
TextPathLabel:
        msb1pstring "Path:"
TextPrefixLabel:
        msb1pstring "Prefix:/"

TextNewPrefixKeyCombo:
        .byte   18
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-N for New Prefix"

TextListFilesKeyCombo:
        .byte   32
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-L or click mouse to List Files"

TextFileWillBeLostWarning:
        msb1pstring "WARNING: File in memory will be lost."
TextSaveCurrentFilePrompt:
        msb1pstring "Press 'S' to save file in memory."
TextDirectoryListingDialogTitle:
        pstring  " Select File "

TextFileSelectionInstructions:
        .byte   32
        highascii "Use "
        .byte   MT_REMAP(MouseText::UpArrow)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::DownArrow)
        highascii " to select; then press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TextNoFilesPrompt:
        msb1pstring "No files; press a key."

TextSaveCarriageReturnsKeyCombo:
        .byte   35
        highascii "Use "
        .byte   MT_REMAP(MouseText::OpenApple)
        .byte   HICHAR('-')
        .byte   MT_REMAP(MouseText::Return)
        highascii " to save with "
        .byte   MT_REMAP(MouseText::Return)
        highascii " on each line"

TextNoMouseInSystem:
        msb1pstring "No mouse in system!"
TextTurnMouseOffPrompt:
        msb1pstring "Turn OFF mouse?"
TextTurnMouseOnPrompt:
        msb1pstring "Turn ON mouse?"
TextEnterBlinkRatePrompt:
        msb1pstring "Enter new rate (1-9):"
TextEnterLineLengthPrompt:
        msb1pstring "Enter new line length (39-79):"

TextMustClearMemoryPrompt:
        .byte   42
        highascii "You MUST clear file in memory ("
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-M) FIRST."

TextHighlightBlockInstructions:
        .byte   41
        highascii "Use "
        .byte   MT_REMAP(MouseText::UpArrow)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::DownArrow)
        highascii " to highlight block; then press"
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TextPleaseWait:
        .byte   15
        .byte   MT_REMAP(MouseText::Hourglass)
        highascii " Please Wait.."

TextClearMemoryDialogTitle:
        msb1pstring " Clear Memory "
TextEraseMemoryPrompt:
        msb1pstring "Erase memory contents?"
TextAboutDialogTitle:
        msb1pstring " Ed-It! "
TextAboutDialogLine1:
        msb1pstring "Ed-It! - A Text File Editor\r\r\r"
TextAboutDialogLine2:
        msb1pstring "by Bill Tudor\r\r"

;;; Unreferenced
        msb1pstring "                       \r"

TextAboutDialogLine3:
        msb1pstring "Version 3.04   Aug 1993\r\r"
TextAboutDialogLine4:
        msb1pstring "Copyright 1988-93               All Rights Reserved"

;;; Unreferenced
        msb1pstring "                     \r"
        msb1pstring "                      \r"

TextReplaceOldFilePrompt:
        msb1pstring "Replace old version of file (Y/N)?"
TextOpenFileDialogTitle:
        msb1pstring " Load File "

TextMemoryFull:
        .byte   21
        highascii "Memory Full; Press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TextEnterPrefixAbove:
        msb1pstring "Enter new prefix above; ESC to abort."
TextPrintDialogTitle:
        msb1pstring " Print File "
TextPrinterSlotPrompt:
        msb1pstring "Printer Slot (1-7)?"
TextPrinterInitStringPrompt:
        msb1pstring "Printer init string:"
TextPrintFromWherePrompt:
        msb1pstring "Print from Start or Cursor(S/C)?"
TextPrinting:
        msb1pstring "Printing..."
TextPrinterNotFound:
        msb1pstring "Printer NOT found!"
TextEnterLeftMarginPrompt:
        msb1pstring "Enter left margin (0-9):"
TextMacroEditingInstructions2:
        msb1pstring "Enter # to edit; [S] to save to disk."
TextMacroEditingInstructions:
        .byte   63
        highasciiz "Enter macro; "
        highasciiz "-DEL deletes left; "
        highasciiz "-Esc = abort; "
        highascii "-Rtn = accept."

TextInsertProgramDiskPrompt:
        .byte   32
        highascii "Insert PROGRAM disk and press "
        .byte   MT_REMAP(MouseText::Return)
        .byte   HICHAR('.')

TextSaving:
        .byte   24
        .byte   MT_REMAP(MouseText::Hourglass)
        highascii " Saving.. Please wait.."

TextLoading:
        .byte   25
        .byte   MT_REMAP(MouseText::Hourglass)
        highascii " Loading.. Please wait.."

TextListDirectoryDialogTitle:
        msb1pstring " Directory "

TextMouseTextFolder:
        .byte   3
        .byte   MT_REMAP(MouseText::Folder1)
        .byte   MT_REMAP(MouseText::Folder2)
        .byte   HICHAR(' ')

TextFileListColumnHeaders:
        msb1pstring "Filename        Type  Size  Date Modified "

TextFileListColumnHeaders2:
        .byte   20
        highascii " AuxType "
        .byte   MT_REMAP(MouseText::LeftVerticalBar)
        highascii "   Blocks:"

TextBlocksTotalLabel:
        msb1pstring " Total:"
TextBlocksUsedLabel:
        msb1pstring "  Used:"
TextBlocksFreeLabel:
        msb1pstring "  Free:"

TextUseSpaceToContinuePrompt:
        msb1pstring "Use <SPACE> to"
TextUseSpaceToContinuePrompt2:
        .byte   11
        highascii "continue"
        .byte   MT_REMAP(MouseText::Ellipsis)
        .byte   MT_REMAP(MouseText::Ellipsis)
        .byte   MT_REMAP(MouseText::Ellipsis)

TextDirectoryCompletePrompt:
        msb1pstring "Directory complete; Press any key to continue. "
TextVolumesDialogTitle:
        msb1pstring " Volumes Online "

TextFileMenuTitle:
        msb1pstring " File "
TextUtilitiesMenuTitle:
        msb1pstring " Utilities "
TextOptionsMenuTitle:
        msb1pstring " Options "

TextAboutMenuItemTitle:
        .byte   20
        highascii " About Ed-It! "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-A "

TextOpenMenuItemTitle:
        .byte   20
        highascii " Load File..  "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-L "

TextSaveAsMenuItemTitle:
        .byte   20
        highascii " Save as..    "
        .byte   HICHAR(ControlChar::NormalVideo)
        repeatbyte HICHAR(' '), 5

TextPrintMenuItemTitle:
        .byte   20
        highascii " Print..      "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-P "

TextClearMemoryMenuItemTitle:
        .byte   20
        highascii " Clear Memory "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-M "

TextQuitMenuItemTitle:
        .byte   20
        highascii " Quit         "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-Q "

TextDirectoryMenuItemTitle:
        .byte   18
        highascii " Directory  "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-D "

TextNewPrefixMenuItemTitle:
        .byte   18
        highascii " New Prefix "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-N "

TextVolumesMenuItemTitle:
        .byte   18
        highascii " Volumes    "
        .byte   HICHAR(ControlChar::NormalVideo)
        .byte   HICHAR(' ')
        .byte   MT_REMAP(MouseText::OpenApple)
        highascii "-V "

TextSetLineLengthMenuItemTitle:
        msb1pstring " Set Line Length     "
TextSetMouseStatusMenuItemTitle:
TextSetMouseStatusDialogTitle:
        msb1pstring " Change Mouse Status "
TextSetBlinkRateMenuItemTitle:
        msb1pstring " Change 'Blink' Rate "
TextEditMacrosMenuItemTitle:
        msb1pstring " Edit & Save Macros  "

TextPressAKeyPromptSuffix:
        msb1pstring "; Press a key."

TextUnknownError:
        msb1pstring " = Unknown ProDOS Error"
TextIOError:
        msb1pstring "I/O Error"
TextNoDeviceConnectedError:
        msb1pstring "No Device Connected"
TextWriteProtectedError:
        msb1pstring "Disk Write Protected"
TextDuplicateFilenameError:
        msb1pstring "Duplicate Filename"
TextNoDiskError:
        msb1pstring "No Disk in Drive"
TextBadBlockError:
        msb1pstring "Bad Block"
TextBadFileTypeError:
        msb1pstring "Bad File Type"
TextInvalidPathnameError:
        msb1pstring "Invalid Pathname"
TextDirectoryNotFoundError:
        msb1pstring "Directory not Found"
TextVolumeNotFoundError:
        msb1pstring "Volume not Found"
TextFileNotFoundError:
        msb1pstring "File not Found"
TextDuplicateFilenameError2:
        msb1pstring "Duplicate Filename"
TextVolumeFullError:
        msb1pstring "Volume Full"
TextVolumeDirectoryFullError:
        msb1pstring "Volume Directory Full"
TextFileLockedError:
        msb1pstring "File Locked"

        .reloc

        Page3_Code_Start := *

        .org $300

;;; All the following code is copied to $0300.

EditMacro:
        sta     MacroNumberBeingEdited
        jsr     CopyCurrentMacroText
        lda     #<TextMacroEditingInstructions
        ldx     #>TextMacroEditingInstructions
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
@Loop:  sta     MacroNumberBeingEdited
        jsr     CopyCurrentMacroText
        jsr     DisplayCurrentMacroText
        lda     MacroNumberBeingEdited
        inc     a
        cmp     #NumMacros+1
        blt     @Loop
        rts

CopyCurrentMacroText:
        dec     a
        tay
        jsr     LoadMacroPointer
        lda     (MacroPtr)
        tay
@Loop:  lda     (MacroPtr),y
        sta     ProDOS::SysPathBuf,y
        dey
        bpl     @Loop
        rts

DisplayCurrentMacroText:
        lda     MacroNumberBeingEdited
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
L03B7:  ora     #MSBOnORMask
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
