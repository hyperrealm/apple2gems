;;; 6502 and 65C02 opcodes

.scope OpCode

BRK_Imp       := $00
ORA_IndZPIdxX := $01
TSB_ZP        := $04 ; 65C02
ORA_ZP        := $05
ASL_ZP        := $06
PHP_Imp       := $08
ORA_Imm       := $09
ASL_A         := $0A
TSB_Abs       := $0C ; 65C02
ORA_Abs       := $0D
ASL_Abs       := $0E

BPL_Rel       := $10
ORA_IndZPIdxY := $11
ORA_IndZP     := $12 ; 65C02
TRB_ZP        := $14 ; 65C02
ORA_ZPIdxX    := $15
ASL_ZPIdxX    := $16
CLC_Imp       := $18
ORA_AbsIdxY   := $19
INC_A         := $1A ; 65C02
TRB_Abs       := $1C ; 65C02
ORA_AbsIdxX   := $1D
ASL_AbsIdxX   := $1E

JSR_Abs       := $20
AND_IndZPIdxX := $21
BIT_ZP        := $24
AND_ZP        := $25
ROL_ZP        := $26
PLP_Imp       := $28
AND_Imm       := $29
ROL_A         := $2A
BIT_Abs       := $2C
AND_Abs       := $2D
ROL_Abs       := $2E

BMI_Rel       := $30
AND_IndZPIdxY := $31
AND_IndZP     := $32 ; 65C02
BIT_ZPIdxX    := $34 ; 65C02
AND_ZPIdxX    := $35
ROL_ZPIdxX    := $36
SEC_Imp       := $38
AND_AbsIdxY   := $39
DEC_A         := $3A ; 65C02
BIT_AbsIdxX   := $3C ; 65C02
AND_AbsIdxX   := $3D
ROL_AbsIdxX   := $3E

RTI_Imp       := $40
EOR_IndZPIdxX := $41
EOR_ZP        := $45
LSR_ZP        := $46
PHA_Imp       := $48
EOR_Imm       := $49
LSR_A         := $4A
JMP_Abs       := $4C
EOR_Abs       := $4D
LSR_Abs       := $4E

BVC_Rel       := $50
EOR_IndZPIdxY := $51
EOR_IndZP     := $52 ; 65C02
EOR_ZPIdxX    := $55
LSR_ZPIdxX    := $56
CLI_Imp       := $58
EOR_AbsIdxY   := $59
PHY_Imp       := $5A ; 65C02
EOR_AbsIdxX   := $5D
LSR_AbsIdxX   := $5E

RTS_Imp       := $60
ADC_IndZPIdxX := $61
STZ_ZP        := $64 ; 65C02
ADC_ZP        := $65
ROR_ZP        := $66
PLA_Imp       := $68
ADC_Imm       := $69
ROR_A         := $6A
JMP_Ind       := $6C
ADC_Abs       := $6D
ROR_Abs       := $6E

BVS_Rel       := $70
ADC_IndZPIdxY := $71
ADC_IndZP     := $72 ; 65C02
STZ_ZPIdxX    := $74 ; 65C02
ADC_ZPIdxX    := $75
ROR_ZPIdxX    := $76
SEI_Imp       := $78
ADC_AbsIdxY   := $79
PLY_Imp       := $7A ; 65C02
JMP_IndIdxX   := $7C ; 65C02
ADC_AbsIdxX   := $7D
ROR_AbsIdxX   := $7E

BRA_Rel       := $80 ; 65C02
STA_IndZPIdxX := $81
STY_ZP        := $84
STA_ZP        := $85
STX_ZP        := $86
DEY_Imp       := $88
BIT_Imm       := $89 ; 65C02
TXA_Imp       := $8A
STY_Abs       := $8C
STA_Abs       := $8D
STX_Abs       := $8E

BCC_Rel       := $90
STA_IndZPIdxY := $91
STA_IndZP     := $92 ; 65C02
STY_ZPIdxX    := $94
STA_ZPIdxX    := $95
STZ_ZPIdxY    := $96 ; 65C02
TYA_Imp       := $98
STA_AbsIdxY   := $99
TXS_Imp       := $9A
STZ_Abs       := $9C ; 65C02
STA_AbsIdxX   := $9D
STZ_AbsIdxX   := $9E ; 65C02

LDY_Imm       := $A0
LDA_IndZPIdxX := $A1
LDX_Imm       := $A2
LDY_ZP        := $A4
LDA_ZP        := $A5
LDX_ZP        := $A6
TAY_Imp       := $A8
LDA_Imm       := $A9
TAX_Imp       := $AA
LDY_Abs       := $AC
LDA_Abs       := $AD
LDX_Abs       := $AE

BCS_Rel       := $B0
LDA_IndZPIdxY := $B1
LDA_IndZP     := $B2 ; 65C02
LDY_ZPIdxX    := $B4
LDA_ZPIdxX    := $B5
LDX_ZPIdxY    := $B6
CLV_Imp       := $B8
LDA_AbsIdxY   := $B9
TSX_Imp       := $BA
LDY_AbsIdxX   := $BC
LDA_AbsIdxX   := $BD
LDX_AbsIdxY   := $BE

CPY_Imm       := $C0
CMP_IndZPIdxX := $C1
CPY_ZP        := $C4
CMP_ZP        := $C5
DEC_ZP        := $C6
INY_Imp       := $C8
CMP_Imm       := $C9
DEX_Imp       := $CA
WAI_Imp       := $CB
CPY_Abs       := $CC
CMP_Abs       := $CD
DEC_Abs       := $CE

BNE_Rel       := $D0
CMP_IndZPIdxY := $D1
CMP_IndZP     := $D2 ; 65C02
CMP_ZPIdxX    := $D5
DEC_ZPIdxX    := $D6
CLD_Imp       := $D8
CMP_AbsIdxY   := $D9
PHX_Imp       := $DA ; 65C02
STP_Imp       := $DB
CMP_AbsIdxX   := $DD
DEC_AbsIdxX   := $DE

CPX_Imm       := $E0
SBC_IndZPIdxX := $E1
CPX_ZP        := $E4
SBC_ZP        := $E5
INC_ZP        := $E6
INX_Imp       := $E8
SBC_Imm       := $E9
NOP_Imp       := $EA
CPX_Abs       := $EC
SBC_Abs       := $ED
INC_Abs       := $EE

BEQ_Rel       := $F0
SBC_IndZPIdxY := $F1
SBC_IndZP     := $F2 ; 65C02
SBC_ZPIdxX    := $F5
INC_ZPIdxX    := $F6
SED_Imp       := $F8
SBC_AbsIdxY   := $F9
PLX_Imp       := $FA ; 65C02
SBC_AbsIdxX   := $FD
INC_AbsIdxX   := $FE

.endscope
