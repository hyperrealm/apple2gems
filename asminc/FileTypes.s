;;; ProDOS Filetypes

.scope FileType

UNK := $00 ; Unknown
BAD := $01 ; Bad blocks
TXT := $04 ; Text
BIN := $06 ; Binary
FOT := $08 ; Hi-res or Double hi-res graphics
DIR := $0F ; Directory
ADB := $19 ; AppleWorks Database
AWP := $1A ; AppleWorks Word Processing
ASP := $1B ; AppleWorks Spreadsheet
SC8 := $2A ; Apple II source code
OB8 := $2B ; Apple II object code
IC8 := $2C ; Apple II interpreted code
P8C := $2E ; ProDOS 8 code module
HLP := $58 ; Help file
CFG := $5A ; Configuration file
SRC := $B0 ; Apple IIGS source code
OBJ := $B1 ; Apple IIGS object code
LIB := $B2 ; Apple IIGS library
A16 := $B3 ; Apple IIGS application
RTL := $B4 ; Apple IIGS runtime library
EXE := $B5 ; Apple IIGS shell script
PIF := $B6 ; Apple IIGS permanent initialization file
TIF := $B7 ; Apple IIGS temporary initialization file
NDA := $B8 ; Apple IIGS new desk accessory
CDA := $B9 ; Apple IIGS classic desk accessory
TOL := $BA ; Apple IIGS tool
DVR := $BB ; Apple IIGS device driver
LDF := $BC ; Apple IIGS generic load file
FST := $BD ; Apple IIGS file system translator
DOC := $BF ; Apple IIGS document
PNT := $C0 ; Apple IIGS packed super hi-res graphics
PIC := $C1 ; Apple IIGS super hi-res graphics
SCR := $C6 ; Script
CDV := $C7 ; Apple IIGS control panel
FON := $C8 ; Apple IIGS font
FND := $C9 ; Apple IIGS finder data
ICN := $CA ; Apple IIGS icon file
MUS := $D5 ; Music
INS := $D6 ; Instrument
MDI := $D7 ; MIDI
SND := $D8 ; Apple IIGS audio
LBR := $E0 ; Archival library
ATK := $E2 ; AppleTalk data
R16 := $EE ; EDASM 816 relocatable code
CMD := $F0 ; ProDOS 8 command
OVL := $F1 ; ProDOS overlay file
LNK := $F8 ; EDASM linker file
S16 := $F9 ; ProDOS 16 or GS/OS system file
INT := $FA ; Integer BASIC program
IVR := $FB ; Integer BASIC variables
BAS := $FC ; Applesoft BASIC program
VAR := $FD ; Applesoft BASIC variables
REL := $FE ; EDASM relocatable code
SYS := $FF ; System program

UD1 := $F1 ; User-defined filetype #1
UD2 := $F2 ; User-defined filetype #2
UD3 := $F3 ; User-defined filetype #3
UD4 := $F4 ; User-defined filetype #4
UD5 := $F5 ; User-defined filetype #5
UD6 := $F6 ; User-defined filetype #6
UD7 := $F7 ; User-defined filetype #7
UD8 := $F8 ; User-defined filetype #8

.endscope
