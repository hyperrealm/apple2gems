
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

