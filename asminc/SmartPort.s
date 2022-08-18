
;;; SmartPort firmware

.scope SmartPortCall

Status      := $00 ; Get device status
ReadBlock   := $01 ; Read block of data
WriteBlock  := $02 ; Write block of data
Format      := $03 ; Format media
Control     := $04 ; Perform device control function
Init        := $05 ; Initialize device
Open        := $06 ; Open device
Close       := $07 ; Close device
Read        := $08 ; Read data from device
Write       := $09 ; Write data to device

.endscope

.scope SmartPortStatusCode

DeviceStatus       := $00 ;
DeviceControlBlock := $01 ;
NewlineStatus      := $02 ;
DeviceInfoBlock    := $03 ;

.endscope

.scope SmartPortControlCode

SoftReset          := $00 ;
SetNewlineStatus   := $02 ; not implemented
ServiceInterrupt   := $03 ;
EjectMedia         := $04 ;

.endscope

.scope SmartPortDeviceType

RAMDisk            := $00 ; RAM disk
DiskDrive3_5       := $01 ; 3.5" disk drive
ProFileHardDisk    := $02 ; ProFile hard disk
GenericSCSIDevice  := $03 ; Generic SCSI device
ROMDisk            := $04 ; ROM disk
SCSICDROMDrive     := $05 ; SCSI CD-ROM rdrive
SCSITapeDrive      := $06 ; SCSI tape drive
SCSIHardDisk       := $07 ; SCSI hard disk
SCSIPrinter        := $09 ; SCSI printer
DiskDrive5_25      := $0A ; 5.25" disk drive
Printer            := $0D ; Printer
Clock              := $0E ; Clock
Modem              := $0F ; Modem

.endscope

.scope SmartPortError

OK          := $00 ; Success
BADCMD      := $01 ; Command number is not valid
BADPCNT     := $04 ; Paramter count is not valid
BUSERR      := $06 ; IWM communication error
BADUNIT     := $11 ; Bad unit number
NOINT       := $1F ; Interrupt devices are not supported
BADCTL      := $21 ; Control or status code is not supported by device
BADCTLPARM  := $22 ; Invalid parameter(s) in control list
IOERROR     := $27 ; I/O error
NODRIVE     := $28 ; Device is not connected
NOWRITE     := $2B ; Device is write-protected
BADBLOCK    := $2D ; Bock number is not valid
DISKSW      := $2E ; Disk switched
OFFLINE     := $2F ; Device offline
DEVSPEC     := $30 ; Device-specific errors
NONFATAL    := $50 ; Non-fatal device-specific errors

; Non-fatal versions of $2x errors

NF_BADCTL     := $61 ;
NF_BADCTLPARM := $62 ;
NF_IOERROR    := $67 ;
NF_NODRIVE    := $68 ;
NF_NOWRITE    := $6B ;
NF_BADBLOCK   := $6D ;
NF_DISKSW     := $6E ;
NF_OFFLINE    := $6F ;

.endscope
