
.define HICHAR(c) c | $80

.macro  highascii s
        .repeat .strlen(s), i
                .byte .strat(s,i) | $80
        .endrepeat
.endmacro

.macro  highasciiz s
        .repeat .strlen(s), i
                .byte .strat(s,i) | $80
        .endrepeat
        .byte $00
.endmacro


.macro pstring s
        .byte .strlen(s), s
.endmacro

.macro msb1pstring s
        .byte .strlen(s)
        .repeat .strlen(s), i
                .byte .strat(s,i) | $80
        .endrepeat
.endmacro

.macro repeatbyte c, l
        .repeat l
        .byte c
        .endrepeat
.endmacro
