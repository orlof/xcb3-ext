DECLARE FUNCTION RndQByte AS BYTE() SHARED STATIC
DECLARE FUNCTION RndByte AS BYTE(min AS BYTE, max AS BYTE) SHARED STATIC
DECLARE FUNCTION RndQWord AS WORD() SHARED STATIC
DECLARE FUNCTION RndWord AS WORD(min AS WORD, max AS WORD) SHARED STATIC
DECLARE FUNCTION RndQInt AS INT() SHARED STATIC
DECLARE FUNCTION RndInt AS INT(min AS INT, max AS INT) SHARED STATIC
DECLARE FUNCTION RndQLong AS LONG() SHARED STATIC
DECLARE FUNCTION RndLong AS LONG(min AS LONG, max AS LONG) SHARED STATIC

DIM Range AS LONG
DIM Mask AS LONG

ASM
    jmp _tinyrand8_end
; AX+ Tinyrand8
; A fast 8-bit random generator with an internal 16bit state

; Algorithm, implementation and evaluation by Wil
; This version stores the seed as arguments and uses self-modifying code
; The name AX+ comes from the ASL, XOR and addition operation

; Size: 15 Bytes (not counting the set_seed function)
; Execution time: 18 (without RTS)
; Period 59748

_tinyrand8
_tinyrand8_b1=*+1
    lda #31
    asl
_tinyrand8_a1=*+1
    eor #53
    sta _tinyrand8_b1
    adc _tinyrand8_a1
    sta _tinyrand8_a1
    rts

_tinyrand8_end
END ASM

SUB SetSeed(Seed AS BYTE) STATIC SHARED
    ASM
        lda {Seed}
        and #217
        clc
        adc #<21263
        sta _tinyrand8_a1
        lda {Seed}
        and #255-217
        adc #>21263
        sta _tinyrand8_b1
    END ASM
END SUB

REM 419 vs 287, Speedup vs RNDB(): 45%
FUNCTION RndQByte AS BYTE() SHARED STATIC
    ASM
        jsr _tinyrand8
        sta {RndQByte}
    END ASM
END FUNCTION

FUNCTION RndByte AS BYTE(min AS BYTE, max AS BYTE) SHARED STATIC
    ASM
        sec
        lda {Max}
        sbc {Min}
        sta {Range}

        lda #2
        sta {Mask}
        jmp _rndbyte_loop1_compare

_rndbyte_loop1
        clc
        rol {Mask}
        bcs _rndbyte_loop1_exit

_rndbyte_loop1_compare
        lda {Range}
        cmp {Mask}
        bcc _rndbyte_loop1_exit
        bcs _rndbyte_loop1
_rndbyte_loop1_exit

        sec
        lda {Mask}
        sbc #1
        sta {Mask}

_rndbyte_loop4
        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        bcc _rndbyte_loop4_exit
        bne _rndbyte_loop4
_rndbyte_loop4_exit

        clc
        adc {Min}
        sta {RndByte}
    END ASM
END FUNCTION

FUNCTION RndQWord AS WORD() SHARED STATIC
    ASM
        jsr _tinyrand8
        sta {RndQWord}
        jsr _tinyrand8
        sta {RndQWord}+1
    END ASM
END FUNCTION

FUNCTION RndWord AS WORD(min AS WORD, max AS WORD) SHARED STATIC
    ASM
        sec
        lda {Max}
        sbc {Min}
        sta {Range}
        lda {Max}+1
        sbc {Min}+1
        sta {Range}+1

        lda #1
        sta {Mask}
        lda #0
        sta {Mask}+1
        jmp _rndword_loop1_compare

_rndword_loop1
        clc
        rol {Mask}
        rol {Mask}+1
        bcs _rndword_loop1_exit

_rndword_loop1_compare
        lda {Range}+1
        cmp {Mask}+1
        bcc _rndword_loop1_exit
        bne _rndword_loop1
        lda {Range}
        cmp {Mask}
        bcc _rndword_loop1_exit
        bcs _rndword_loop1
_rndword_loop1_exit

        sec
        lda {Mask}
        sbc #1
        sta {Mask}
        lda {Mask}+1
        sbc #0
        sta {Mask}+1

_rndword_loop3
        jsr _tinyrand8
        and {Mask}+1
        cmp {Range}+1
        bcc _rndword_loop3_exit
        bne _rndword_loop3
_rndword_loop3_exit
        sta {RndWord}+1

_rndword_loop4
        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        bcc _rndword_loop4_exit
        bne _rndword_loop4
_rndword_loop4_exit

        clc
        adc {Min}
        sta {RndWord}
        lda {RndWord}+1
        adc {Min}+1
        sta {RndWord}+1
    END ASM
END FUNCTION

FUNCTION RndQInt AS INT() SHARED STATIC
    ASM
        jsr _tinyrand8
        sta {RndQInt}
        jsr _tinyrand8
        sta {RndQInt}+1
    END ASM
END FUNCTION

FUNCTION RndInt AS INT(min AS INT, max AS INT) SHARED STATIC
    ASM
        sec
        lda {Max}
        sbc {Min}
        sta {Range}
        lda {Max}+1
        sbc {Min}+1
        sta {Range}+1

        lda #1
        sta {Mask}
        lda #0
        sta {Mask}+1
        jmp _rndint_loop1_compare

_rndint_loop1
        clc
        rol {Mask}
        rol {Mask}+1
        bcs _rndint_loop1_exit

_rndint_loop1_compare
        lda {Range}+1
        cmp {Mask}+1
        bcc _rndint_loop1_exit
        bne _rndint_loop1
        lda {Range}
        cmp {Mask}
        bcc _rndint_loop1_exit
        bcs _rndint_loop1
_rndint_loop1_exit

        sec
        lda {Mask}
        sbc #1
        sta {Mask}
        lda {Mask}+1
        sbc #0
        sta {Mask}+1

_rndint_loop3
        jsr _tinyrand8
        and {Mask}+1
        cmp {Range}+1
        bcc _rndint_loop3_exit
        bne _rndint_loop3
_rndint_loop3_exit
        sta {RndInt}+1

_rndint_loop4
        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        bcc _rndint_loop4_exit
        bne _rndint_loop4
_rndint_loop4_exit

        clc
        adc {Min}
        sta {RndInt}
        lda {RndInt}+1
        adc {Min}+1
        sta {RndInt}+1
    END ASM
END FUNCTION

FUNCTION RndQLong AS LONG() SHARED STATIC
    ASM
        jsr _tinyrand8
        sta {RndQLong}
        jsr _tinyrand8
        sta {RndQLong}+1
        jsr _tinyrand8
        sta {RndQLong}+2
    END ASM
END FUNCTION

FUNCTION RndLong AS LONG(min AS LONG, max AS LONG) SHARED STATIC
    ASM
        sec
        lda {Max}
        sbc {Min}
        sta {Range}
        lda {Max}+1
        sbc {Min}+1
        sta {Range}+1
        lda {Max}+2
        sbc {Min}+2
        sta {Range}+2

        lda #1
        sta {Mask}
        lda #0
        sta {Mask}+1
        sta {Mask}+2

        jmp _rndlong_loop1_compare

_rndlong_loop1
        clc
        rol {Mask}
        rol {Mask}+1
        rol {Mask}+2
        bcs _rndlong_loop1_exit

_rndlong_loop1_compare
        lda {Range}+2
        cmp {Mask}+2
        bcc _rndlong_loop1_exit
        bne _rndlong_loop1
        lda {Range}+1
        cmp {Mask}+1
        bcc _rndlong_loop1_exit
        bne _rndlong_loop1
        lda {Range}
        cmp {Mask}
        bcc _rndlong_loop1_exit
        bcs _rndlong_loop1
_rndlong_loop1_exit

        sec
        lda {Mask}
        sbc #1
        sta {Mask}
        lda {Mask}+1
        sbc #0
        sta {Mask}+1
        lda {Mask}+2
        sbc #0
        sta {Mask}+2

_rndlong_loop2
        jsr _tinyrand8
        and {Mask}+2
        cmp {Range}+2
        bcc _rndlong_loop2_exit
        bne _rndlong_loop2
_rndlong_loop2_exit
        sta {RndLong}+2

_rndlong_loop3
        jsr _tinyrand8
        and {Mask}+1
        cmp {Range}+1
        bcc _rndlong_loop3_exit
        bne _rndlong_loop3
_rndlong_loop3_exit
        sta {RndLong}+1

_rndlong_loop4
        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        bcc _rndlong_loop4_exit
        bne _rndlong_loop4
_rndlong_loop4_exit

        clc
        adc {Min}
        sta {RndLong}
        lda {RndLong}+1
        adc {Min}+1
        sta {RndLong}+1
        lda {RndLong}+2
        adc {Min}+2
        sta {RndLong}+2
    END ASM
END FUNCTION

