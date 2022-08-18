
.scope ProDOS

MLI             := $BF00        ; MLI entry point

SysLoadAddress  := $2000
SysPathBuf      := $0280

;;; MLI call numbers
CCREATE         := $C0 ; CREATE
CDESTROY        := $C1 ; DESTROY
CRENAME         := $C2 ; RENAME
CSETFILEINFO    := $C3 ; SET_FILE_INFO
CGETFILEINFO    := $C4 ; GET_FILE_INFO
CONLINE         := $C5 ; ON_LINE
CSETPREFIX      := $C6 ; SET_PREFIX
CGETPREFIX      := $C7 ; GET_PREFIX
COPEN           := $C8 ; OPEN
CNEWLINE        := $C9 ; NEWLINE
CREAD           := $CA ; READ
CWRITE          := $CB ; WRITE
CCLOSE          := $CC ; CLOSE
CFLUSH          := $CD ; FLUSH
CSETMARK        := $CE ; SET_MARK
CGETMARK        := $CF ; GET_MARK
CSETEOF         := $D0 ; SET_EOF
CGETEOF         := $D1 ; GET_EOF
CSETBUF         := $D2 ; SET_BUF
CGETBUF         := $D3 ; GET_BUF
CGETTIME        := $82 ; GET_TIME
CALLOCINT       := $40 ; ALLOC_INTERRUPT
CDEALLOCINT     := $41 ; DEALLOC_INTERRUPT
CQUIT           := $65 ; QUIT
CRDBLOCK        := $80 ; READ_BLOCK
CWRBLOCK        := $81 ; WRITE_BLOCK

.struct CreateParams
        param_count    .byte
        pathname       .addr
        access         .byte
        file_type      .byte
        aux_type       .word
        storage_type   .byte
        create_date    .word
        create_time    .word
.endstruct

.struct DestroyParams
        param_count    .byte
        pathname       .addr
.endstruct

.struct RenameParams
        param_count    .byte
        pathname       .addr
        new_pathname   .addr
.endstruct

.struct SetFileInfoParams
        param_count    .byte
        pathname       .addr
        access         .byte
        file_type      .byte
        aux_type       .word
        null_field     .byte 3
        mod_date       .word
        mod_time       .word
.endstruct

.struct GetFileInfoParams
        param_count    .byte
        pathname       .addr
        access         .byte
        file_type      .byte
        aux_type       .word
        storage_type   .byte
        blocks_used    .word
        mod_date       .word
        mod_time       .word
.endstruct

.struct OnLineParams
        param_count    .byte
        unit_num       .byte
        data_buffer    .addr
.endstruct

.struct SetPrefixParams
        param_count   .byte
        pathname       .addr
.endstruct

.struct GetPrefixParams
        param_count    .byte
        data_buffer    .addr
.endstruct

.struct OpenParams
        param_count    .byte
        pathname       .addr
        io_buffer      .addr
        ref_num        .byte
.endstruct

.struct NewLineParams
        param_count    .byte
        ref_num        .byte
        enable_mask    .byte
        newline_char   .byte
.endstruct

.struct ReadParams
        param_count    .byte
        ref_num        .byte
        data_buffer    .addr
        request_count  .word
        transfer_count .word
.endstruct

.struct WriteParams
        param_count    .byte
        ref_num        .byte
        data_buffer    .addr
        request_count  .word
        transfer_count .word
.endstruct

.struct CloseParams
        param_count    .byte
        ref_num        .byte
.endstruct

.struct FlushParams
        param_count    .byte
        ref_num        .byte
.endstruct

.struct GetMarkParams
        param_count    .byte
        ref_num        .byte
        position       .byte 3
.endstruct

.struct SetMarkParams
        param_count    .byte
        ref_num        .byte
        position       .byte 3
.endstruct

.struct GetEOFParams
        param_count    .byte
        ref_num        .byte
        eof            .byte 3
.endstruct

.struct SetEOFParams
        param_count    .byte
        ref_num        .byte
        eof            .byte 3
.endstruct

.struct GetBufParams
        param_count    .byte
        ref_num        .byte
        io_buffer      .addr
.endstruct

.struct SetBufParams
        param_count    .byte
        ref_num        .byte
        io_buffer      .addr
.endstruct

.struct AllocInterruptParams
        param_count    .byte
        interrupt_num  .byte
        interrupt_handler .addr
.endstruct

.struct DeallocInterruptParams
        param_count    .byte
        interrupt_num  .byte
.endstruct

.struct QuitParams
        param_count    .byte
        quit_type      .byte
        pathname       .addr
        reserved_byte  .byte
        reserved_word  .word
.endstruct

.struct ReadBlockParams
        param_count    .byte
        unit_num       .byte
        data_buffer    .addr
        block_num      .word
.endstruct

.struct WriteBlockParams
        param_count    .byte
        unit_num       .byte
        data_buffer    .addr
        block_num      .word
.endstruct

;;; ProDOS global page locations
DEVADR0         := $BF10 ; Device driver address table
DEVNUM          := $BF30 ; Last used device number
DEVCNT          := $BF31 ; Number of online devices minus 1
DEVLST          := $BF32 ; Device list
MEMTABL         := $BF58 ; Memory allocation bitmap
GLBUFF          := $BF70 ; File buffer address table
DATELO          := $BF90 ; Low byte of date
DATEHI          := $BF91 ; High byte of date
TIMELO          := $BF92 ; Low byte of time
TIMEHI          := $BF93 ; High byte of time
LEVEL           := $BF94 ; Current file level
BUBIT           := $BF95 ; Backup-needed bit disable
MACHID          := $BF98 ; Machine ID
SLTBYT          := $BF99 ; Peripheral ROM presence mask
PFIXPTR         := $BF9A ; If not 0, a prefix is active
MLIACTV         := $BF9B ; If not 0, a MLI call is in progress
IVERSION        := $BFFD ; Version of current SYS program
KVERSION        := $BFFF ; Version of ProDOS kernel

;;; MLI error codes
EOK             := $00
EBADCALL        := $01 ; Bad call number
EBADPARAMCT     := $04 ; Bad param count
EINTBLFULL      := $25 ; Interrupt table full
EIO             := $27 ; I/O error
ENODEVCONN      := $28 ; No device connected
EWRITEPROT      := $2B ; Disk write-protected
EDISKSW         := $2E ; Disk switched
EBADPATH        := $40 ; Invalid pathname
EMAXFILES       := $42 ; Maximum number of files open
EBADREFNUM      := $43 ; Invalid reference number
EDIRNOTF        := $44 ; Directory not found
EVOLNOTF        := $45 ; Volume not found
EFILENOTF       := $46 ; File not found
EDUPFNAME       := $47 ; Duplicate file name
EVOLFULL        := $48 ; Volume full
EDIRFULL        := $49 ; Directory full
EBADFILEFMT     := $4A ; Incompatible file format
EBADSTYPE       := $4B ; Unsupported storage type
EEOF            := $4C ; End of file
EBADPOS         := $4D ; File position out of range
EFLOCKED        := $4E ; File locked
EFOPEN          := $50 ; File already open
EDIRDAMAG       := $51 ; Directory structure damaged
EBADPARAM       := $53 ; Invalid parameter
EVOLBLKFULL     := $55 ; Volume control block full
EBADBUF         := $56 ; Bad buffer address
EDUPVOL         := $57 ; Duplicate volume
EFILEDAMAG      := $5A ; File structure damaged

.endscope
