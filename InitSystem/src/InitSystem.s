;;; ===================================================================
;;; INIT.SYSTEM
;;;
;;; Loads and executes all "inits" (file type P8C, aux_type $4000) in
;;; the INITS subdirectory of the volume directory. Then finds and runs
;;; the next .SYSTEM program in the volume directory. Inits are loaded
;;; and executed at $2000. Inits may be up to $2000 bytes in size; any
;;; init larger than this size will be skipped.
;;;
;;; The program relocates itself to $1000, and reserves all memory up
;;; to $1FFF for itself. It uses several bytes of zero page storage but
;;; saves these before calling an init and restores them afterwards.
;;; ====================================================================

.MACPACK generic
.FEATURE string_escapes

.include "ProDOS.s"
.include "Monitor.s"
.include "ZeroPage.s"
.include "FileTypes.s"
.include "Macros.s"

;;; Constants

SystemSuffixLen    :=   $07 ; length of ".SYSTEM"
InitFileType       := FileType::P8C ; Prodos 8 Code Module
InitAuxType        := $4000 ; aux_type for inits
DirBufferSize      :=  $200 ; directory buffer size
Version            :=    $1 ; our version number
MaxInitPages       :=   $20 ; max size of an init, in pages
RelocOrg           := $1000 ; our relocation target

EFILE2BIG          :=   $88 ; "file too big" error

;;; Zero page locations

BufferPtr          :=   $06 ; general use buffer pointer
SavedError         :=   $08 ; save location for MLI error
TempVal            :=   $09 ; temporary value storage

ZPStart            :=   $06 ; start of Zero Page range used
ZPLen              :=   $04 ; length of Zero Page range used

;;; Internal storage

VolNameLen         := $1590 ; volume name length
InitPathLen        := $1591 ; init path length
DirEntryLen        := $1592 ; directory entry length
EntriesInDir       := $1593 ; directory entry count (2 bytes)
EntriesPerBlock    := $1595 ; dir entries per block
EntriesLeftInBlock := $1596 ; entries left in this block
FileLength         := $1597 ; storage for file length (2 bytes)
FileType           := $1599 ; storage for filetype
ZPStorageBuf       := $159A ; storage for zero page locs

NextSysFileName    := $15A0 ; next SYS filename to run (16 bytes)
OurFilename        := $15B0 ; our filename (16 bytes)
PathBuf            := $15C0 ; path buffer (64 bytes)
DirBuffer          := $1600 ; directory block buffer (512 bytes)
IOBuffer1          := $1800 ; 1K file buffer #1
IOBuffer2          := $1C00 ; 1K file buffer #2

        .setcpu "65c02"
        .org ProDOS::SysLoadAddress

        cld

;;; ----------------------------------------
;;; Relocate code to RelocOrg
;;;
;;; Code length = ProgramEnd-ProgramStart
;;; ----------------------------------------

        lda   #<RelocStart
        sta   ZeroPage::A1L
        sta   ZeroPage::A2L
        lda   #>RelocStart
        sta   ZeroPage::A1H
        sta   ZeroPage::A2H

        clc
        lda   ZeroPage::A2L
        adc   #<(ProgramEnd-ProgramStart)
        sta   ZeroPage::A2L
        lda   ZeroPage::A2H
        adc   #>(ProgramEnd-ProgramStart)
        sta   ZeroPage::A2H

        lda   #<RelocOrg
        sta   ZeroPage::A4L
        lda   #>RelocOrg
        sta   ZeroPage::A4H

        ldy   #0
        jsr   Monitor::MOVE

        jmp   RelocOrg

;;; ----------------------------------------
;;; Beginning of code to be relocated
;;; ----------------------------------------

RelocStart := *
        .org  RelocOrg

ProgramStart:
        lda   #Version ; store our version #
        sta   ProDOS::IVERSION

;;; ----------------------------------------
;;; Save our name in OurFilename
;;; ----------------------------------------

SaveName:
        ldy   ProDOS::SysPathBuf
@Loop:  dey
        beq   @Cont
        lda   ProDOS::SysPathBuf+1,Y
        cmp   #'/'
        bne   @Loop
        iny
@Cont:  ldx   #0
@Loop2: lda   ProDOS::SysPathBuf+1,Y
        sta   OurFilename+1,X
        inx
        iny
        cpy   ProDOS::SysPathBuf
        bne   @Loop2
        stx   OurFilename

;;; ---------------------------------------
;;; Get the current prefix into PathBuf,
;;; chop off at volume name, and store its
;;; length in VolNameLen.
;;; ----------------------------------------

GetPrefix:
        jsr   ProDOS::MLI
        .byte ProDOS::CGETPREFIX
        .addr GetPrefixParams
        bcc   @OK
        jmp   FatalError
@OK:    ldy   #0
@Loop:  iny   ; skip first slash
        cpy   PathBuf
        beq   @Done
        lda   PathBuf+1,Y
        cmp   #'/'
        bne   @Loop
@Done:  sty   PathBuf ; truncate to vol name
        sty   VolNameLen ; save name length

;;; ----------------------------------------
;;; Append inits directory name
;;; ----------------------------------------

AppendInitsDir:
        ldx   #0
@Loop:  lda   InitsDir,X
        beq   @Done
        sta   PathBuf+1,Y
        inx
        iny
        bra   @Loop
@Done:  sty   PathBuf ; update path length
        sty   InitPathLen ; save length of inits path

;;; ----------------------------------------
;;; Set the prefix to the inits directory
;;; ----------------------------------------

        jsr   ProDOS::MLI
        .byte ProDOS::CSETPREFIX
        .addr SetPrefixParams
        bcs   NextSysProgram ; error? skip inits

;;; ----------------------------------------
;;; Set top of text window to line 16
;;; ----------------------------------------

        lda   #$10
        sta   ZeroPage::WNDTOP
        jsr   Monitor::HOME

;;; ----------------------------------------
;;; Process the inits directory
;;; ----------------------------------------

        ldx   #<ProcessInitFile
        ldy   #>ProcessInitFile
        lda   #InitFileType
        jsr   ReadDir

;;; ----------------------------------------
;;; Reset top of text window
;;; ----------------------------------------

        stz   ZeroPage::WNDTOP

;;; ----------------------------------------
;;; Change PathBuf and prefix back to the root path.
;;; ----------------------------------------

        lda   VolNameLen
        sta   PathBuf

        jsr   ProDOS::MLI
        .byte ProDOS::CSETPREFIX
        .addr SetPrefixParams
        bcc   NextSysProgram
        jmp   FatalError

;;; ----------------------------------------
;;; Process the volume directory to find
;;; the next .SYSTEM file to run.
;;; ----------------------------------------

NextSysProgram:
        stz   NextSysFileName
        ldx   #<ProcessSysFile
        ldy   #>ProcessSysFile
        lda   #FileType::SYS
        jsr   ReadDir

        bcc   @OK
        jmp   FatalError ; error reading directory

@OK:    lda   NextSysFileName
        bne   FullSysPath ; first byte not 0?
        lda   #ProDOS::EFILENOTF ; file not found
        jmp   FatalError ; no next .SYSTEM file found

;;; ----------------------------------------
;;; Append NextSysFileName to PathBuf to get full
;;; path to .SYSTEM file to launch.
;;; ----------------------------------------

FullSysPath:
        ldy   PathBuf
        lda   #'/'
        sta   PathBuf+1,Y
        iny
        ldx   #0
@Loop:  lda   NextSysFileName+1,X
        sta   PathBuf+1,Y
        inx
        iny
        cpx   NextSysFileName
        bne   @Loop
        sty   PathBuf ; update path length

;;; ----------------------------------------
;;; Open the .SYSTEM file.
;;; ----------------------------------------

OpenSysFile:
        jsr   ProDOS::MLI
        .byte ProDOS::COPEN
        .addr OpenFileParams
        bcc   @OK
        jmp   FatalError

@OK:    lda   FileRefNum1
        sta   FileRefNum2
        sta   FileRefNum3

;;; ----------------------------------------
;;; Read the .SYSTEM file.
;;; ----------------------------------------

        lda   FileLength ; set bytes requested
        sta   FileRequestCount
        lda   FileLength+1
        sta   FileRequestCount+1

        jsr   ProDOS::MLI
        .byte ProDOS::CREAD
        .addr ReadFileParams
        sta   SavedError

;;; ----------------------------------------
;;; Close the .SYSTEM file.
;;; ----------------------------------------

        jsr   ProDOS::MLI
        .byte ProDOS::CCLOSE
        .addr CloseFileParams

;;; ----------------------------------------
;;; Execute the .SYSTEM file, if no error.
;;; ----------------------------------------

        lda   SavedError
        bne   FatalError

        nop
        nop
        nop

        jsr   Monitor::HOME ; clear the screen
        jmp   ProDOS::SysLoadAddress

;;; ----------------------------------------
;;; Fatal error. Print error message, wait
;;; for keypress, and quit to ProDOS.
;;; ----------------------------------------

FatalError:
        pha   ; save error
        stz   ZeroPage::WNDTOP
        jsr   Monitor::HOME
        ldy   #0
@Loop:  lda   FatalErrorText,Y
        beq   @Done
        jsr   Monitor::COUT
        iny
        bra   @Loop
@Done:  pla   ; restore error
        jsr   Monitor::PRBYTE
        lda   #HICHAR(' ')
        jsr   Monitor::COUT
        jsr   Monitor::RDKEY

        jsr   ProDOS::MLI
        .byte ProDOS::CQUIT
        .addr QuitParams
        rts

;;; ========================================
;;; Process an INIT directory entry. Load
;;; and execute each of the files.
;;; ========================================

ProcessInitFile:

;;; ----------------------------------------
;;; Check the aux_type
;;; ----------------------------------------

        ldy   #$1F
        lda   (BufferPtr),Y
        cmp   #<InitAuxType
        bne   @BadType
        iny
        lda   (BufferPtr),Y
        cmp   #>InitAuxType
        beq   @CheckSize

@BadType:
        clc
        rts

;;; ----------------------------------------
;;; Check file size
;;; ----------------------------------------

@CheckSize:
        ldy   #$17 ; eof field offset (last byte)
        lda   (BufferPtr),Y ; high byte
        beq   @CopyLen
        jmp   InitFileTooBig ; file too big

@CopyLen:
        dey
        lda   (BufferPtr),Y ; middle byte
        sta   FileLength+1
        sta   FileRequestCount+1
        dey
        lda   (BufferPtr),Y ; low byte
        sta   FileLength
        sta   FileRequestCount

        lda   FileLength+1 ; check high byte
        cmp   #MaxInitPages
        blt   MakeInitPath
        beq   @CheckLowByte
        bra   InitFileTooBig ; file too big
@CheckLowByte:
        lda   FileLength ; check low byte
        beq   MakeInitPath
        bra   InitFileTooBig ; file too big

;;; ---------------------------------------
;;; Append the init name to the init path
;;; ----------------------------------------

MakeInitPath:
        ldy   #0
        lda   (BufferPtr),Y
        and   #$0F ; filename length
        sta   TempVal

        ldx   InitPathLen
        lda   #'/'
        sta   PathBuf+1,X
@LOOP:  inx
        iny
        lda   (BufferPtr),Y
        sta   PathBuf+1,X
        ora   #$80
        jsr   Monitor::COUT
        cpy   TempVal
        bne   @LOOP
        inx
        stx   PathBuf
        jsr   Monitor::CROUT

;;; ----------------------------------------
;;; Open the INIT file
;;; ----------------------------------------

OpenInit:
        jsr   ProDOS::MLI
        .byte ProDOS::COPEN
        .addr OpenFileParams
        bcs   InitFailed

        lda   FileRefNum1
        sta   FileRefNum2
        sta   FileRefNum3

;;; ----------------------------------------
;;; Read the INIT file.
;;; ----------------------------------------

ReadInit:
        jsr   ProDOS::MLI
        .byte ProDOS::CREAD
        .addr ReadFileParams
        sta   SavedError

;;; ----------------------------------------
;;; Close the INIT file
;;; ----------------------------------------

CloseInit:
        jsr   ProDOS::MLI
        .byte ProDOS::CCLOSE
        .addr CloseFileParams

;;; ---------------------------------------
;;; Skip this init if there was a MLI error
;;; ----------------------------------------

        lda   SavedError
        bne   InitFailed

;;; ----------------------------------------
;;; Protect $1000-$1FFF in memory bitmap
;;; ----------------------------------------

        lda   #$FF
        sta   ProDOS::MEMTABL+2
        sta   ProDOS::MEMTABL+3

;;; ----------------------------------------
;;; Execute the init
;;; ----------------------------------------

        jsr   SaveZP ; save zero page locs
        jsr   ProDOS::SysLoadAddress ; call the init
        jsr   RestoreZP ; restore zero page locs

;;; ----------------------------------------
;;; Unprotect $1000-$1FFF in memory bitmap
;;; ----------------------------------------

        stz   ProDOS::MEMTABL+2
        stz   ProDOS::MEMTABL+3

InitDone:
        clc
        rts

;;; ----------------------------------------
;;; Handle errors
;;; ----------------------------------------

InitFileTooBig:
        lda   #EFILE2BIG
InitFailed:
        pha
        ldy   #0
@Loop:  lda   ErrorText,Y
        beq   @Done
        jsr   Monitor::COUT
        iny
        bra   @Loop
@Done:  pla
        jsr   Monitor::PRBYTE
        jsr   Monitor::CROUT

        cld
        rts

;;; ========================================
;;; Save zero page locations.
;;; ========================================

SaveZP:
        ldx   #0
@Loop:  lda   ZPStart,X
        sta   ZPStorageBuf,X
        inx
        cpx   #ZPLen
        bne   @Loop
        rts

;;; ========================================
;;; Restore zero page locations.
;;; ========================================

RestoreZP:
        ldx   #0
@Loop:  lda   ZPStorageBuf,X
        sta   ZPStart,X
        inx
        cpx   #ZPLen
        bne   @Loop
        rts

;;; ========================================
;;; Process a volume directory entry to
;;; find the first .SYSTEM file (other than
;;; us) and execute it.
;;; ========================================

ProcessSysFile:
        ldy   #0
        lda   (BufferPtr),Y
        and   #$0F ; get filename length
        sta   TempVal

        sec
        sbc   #SystemSuffixLen
        beq   GetNextFileEntry ; filename too short
        bmi   GetNextFileEntry ; filename too short

;;; Now A contains the length of the filename before '.SYSTEM'

        ldx   #$FF
        tay
@Cmp:   iny
        inx
        cpx   #SystemSuffixLen
        beq   CheckNotUs
        lda   (BufferPtr),Y
        cmp   SystemSuffix,X
        bne   GetNextFileEntry ; not a '.SYSTEM' file
        bra   @Cmp

;;; ----------------------------------------
;;; Make sure this is not us
;;; ----------------------------------------

CheckNotUs:
        lda   TempVal
        cmp   OurFilename
        bne   FoundSysFile

        ldx   #0
        ldy   #1
@Loop:  lda   (BufferPtr),Y
        cmp   OurFilename+1,X
        bne   FoundSysFile
        iny
        inx
        cpx   TempVal
        bne   @Loop

GetNextFileEntry:
        clc
        rts

;;; ----------------------------------------
;;; Found a .SYSTEM file that isn't us. Save the filename and file
;;; length.
;;; ----------------------------------------

FoundSysFile:
        ldx   #0
        ldy   #1
@Loop:  lda   (BufferPtr),Y
        sta   NextSysFileName+1,X
        iny
        inx
        cpx   TempVal
        bne   @Loop
        stx   NextSysFileName
        ldy   #$15
        lda   (BufferPtr),Y
        sta   FileLength
        iny
        lda   (BufferPtr),Y
        sta   FileLength+1

        sec
        rts

;;; ======================================================================
;;; Subroutine to read directory in PathBuf. Filetype to be filtered
;;; on is passed in Accumulator, and address of a callback routine in
;;; X (low) and Y (high).  For each entry, the callback is called with
;;; BufferPtr pointing to the beginning of the directory entry. On error,
;;; returns with Carry set and MLI error in Accumulator. If the
;;; callback returns with Carry set, the rest of the directory entries
;;; are skipped.
;;; ======================================================================

.proc ReadDir
        sta   FileType ; Save filetype
        stx   Callback+1 ; and callback address
        sty   Callback+2

;;; ----------------------------------------
;;; Open the directory
;;; ----------------------------------------

OpenDir:
        jsr   ProDOS::MLI
        .byte ProDOS::COPEN
        .addr OpenDirParams
        bcc   @OK
        rts   ; Return with error

@OK:    lda   DirRefNum1
        sta   DirRefNum2
        sta   DirRefNum3

        stz   DirEntryLen ; don't know entry length yet

;;; ----------------------------------------
;;; Read block of directory
;;; ----------------------------------------

ReadDirBlock:
        jsr   ProDOS::MLI
        .byte ProDOS::CREAD
        .addr ReadDirParams
        bcc @OK
        jmp CloseDir

;;; ----------------------------------------
;;; Initialize pointer buffer, skipping
;;; first 4 bytes which are link pointers
;;; ----------------------------------------

@OK:    lda   #<DirBuffer+4
        sta   BufferPtr
        lda   #>DirBuffer
        sta   BufferPtr+1

        lda   DirEntryLen
        bne   GotHeader ; alread read header

;;; ----------------------------------------
;;; Read the header entry and save the
;;; entry size, entries per block, entries
;;; left in this block, and total entry
;;; count.
;;; ----------------------------------------

        ldy   #$1F
        lda   (BufferPtr),Y
        sta   DirEntryLen
        iny
        lda   (BufferPtr),Y
        sta   EntriesPerBlock
        sta   EntriesLeftInBlock
        iny
        lda   (BufferPtr),Y
        sta   EntriesInDir
        iny
        lda   (BufferPtr),Y
        sta   EntriesInDir+1
        bra   NextDirEntry ; don't decrement counters

GotHeader:
        lda   EntriesPerBlock
        sta   EntriesLeftInBlock

;;; ----------------------------------------
;;; Read directory entry
;;; ----------------------------------------

ReadDirEntry:
        lda   EntriesLeftInBlock
        beq   ReadDirBlock ; no more entries in this block

        ldy   #0
        lda   (BufferPtr),Y
        beq   DoneWithEntry ; this is a deleted entry

        ldy   #$10 ; file_type field offset
        lda   (BufferPtr),Y

        cmp   FileType
        bne   DoneWithEntry ; skip if wrong filetype

        pha   ; save registers
        phx
        phy

Callback:
        jsr   $FFFF ; process the file entry

        ply   ; restore registers
        plx
        pla

        bcs   CloseDir ; Callback said "no more"

;;; ----------------------------------------
;;; Advance to next directory entry
;;; ----------------------------------------

DoneWithEntry:
        dec   EntriesLeftInBlock
        dec   EntriesInDir
        bpl   @Skip
        dec   EntriesInDir+1
@Skip:  lda   EntriesInDir ; if EntriesInDir = $0000, then
        ora   EntriesInDir+1 ; all entries have been processed
        beq   CloseDir

NextDirEntry:
        clc   ; increment BufferPtr by DirEntryLen
        lda   BufferPtr
        adc   DirEntryLen
        sta   BufferPtr
        bcc   @Skip2
        inc   BufferPtr+1
@Skip2: bra   ReadDirEntry ; process next entry

;;; ----------------------------------------
;;; No more entries. Close the directory.
;;; ----------------------------------------

CloseDir:
        jsr   ProDOS::MLI
        .byte ProDOS::CCLOSE
        .addr CloseDirParams

;;; ----------------------------------------
;;; Done reading directory.
;;; ----------------------------------------

        clc
        rts

.endproc

;;; ----------------------------------------
;;; Data area.
;;; ----------------------------------------

InitsDir:
        .asciiz "/INITS"
SystemSuffix:
        .byte ".SYSTEM"

FatalErrorText:
        highascii "Fatal "
ErrorText:
        highasciiz "Error - $"

GetPrefixParams:
SetPrefixParams:
        .byte $01
        .addr PathBuf

OpenDirParams:
        .byte $03
        .addr PathBuf
        .addr IOBuffer1
DirRefNum1:
        .byte $00

ReadDirParams:
        .byte $04
DirRefNum2:
        .byte $00
        .addr DirBuffer
DirRequestCount:
        .word DirBufferSize ; 512 bytes requested
DirTransferCount:
        .word $0000 ; bytes read

CloseDirParams:
        .byte $01
DirRefNum3:
        .byte $00

OpenFileParams:
        .byte $03
        .addr PathBuf
        .addr IOBuffer2
FileRefNum1:
        .byte $00

ReadFileParams:
        .byte $04
FileRefNum2:
        .byte $00
        .addr ProDOS::SysLoadAddress
FileRequestCount:
        .word $0000 ; bytes requested
FileTransferCount:
        .word $0000 ; bytes read

CloseFileParams:
        .byte $01
FileRefNum3:
        .byte $00

QuitParams:
        .byte $04
        .byte $00
        .word $0000
        .byte $00
        .word $0000

ProgramEnd := *

