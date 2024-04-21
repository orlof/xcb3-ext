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

        lda #1
_rndbyte_loop1
        clc
        rol
        bcs _rndbyte_loop1_exit

_rndbyte_loop1_compare
        cmp {Range}
        bcc _rndbyte_loop1
        beq _rndbyte_loop1
_rndbyte_loop1_exit

        ;sec
        sbc #1
        sta {Mask}

_rndbyte_loop4
        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        bcc _rndbyte_loop4_exit
        beq _rndbyte_loop4_exit
        IFCONST ALLOW_BIAS
            sbc {Range}
        ELSE
            jmp _rndbyte_loop4
        ENDIF
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

FUNCTION RndWord AS WORD(Min AS WORD, Max AS WORD) SHARED STATIC
    ASM
        sec
        lda {Max}
        sbc {Min}
        sta {Range}
        lda {Max}+1
        sbc {Min}+1
        sta {Range}+1

;---------------------------------------

_rndword_mask
        lda #2
        sta {Mask}
        lda #0
        sta {Mask}+1

_rndword_mask_loop
        clc
        rol {Mask}
        rol {Mask}+1
        bcs _rndword_mask_exit

        lda {Range}+1
        cmp {Mask}+1
        bcc _rndword_mask_exit
        bne _rndword_mask_loop

        lda {Range}
        cmp {Mask}
        bcs _rndword_mask_loop
_rndword_mask_exit

        sec
        lda {Mask}
        sbc #1
        sta {Mask}
        lda {Mask}+1
        sbc #0
        sta {Mask}+1

;---------------------------------------

    IFCONST ALLOW_BIAS
        jsr _tinyrand8
        and {Mask}
        sta {RndWord}
        jsr _tinyrand8
        and {Mask}+1
        sta {RndWord}+1

        cmp {Range}+1
        bcc _rndword_exit
        bne _rndword_value_subtract

        lda {RndWord}
        cmp {Range}
        bcc _rndword_exit
        beq _rndword_exit

_rndword_value_subtract
        sec
        lda {RndWord}
        sbc {Range}
        sta {RndWord}

        lda {RndWord}+1
        sbc {Range}+1
        sta {RndWord}+1
    ELSE
_rndword_value
        jsr _tinyrand8
        and {Mask}+1
        cmp {Range}+1
        sta {RndWord}+1

        bcc _rndword_value_exit
        bne _rndword_value

        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        sta {RndWord}

        bcc _rndword_exit
        beq _rndword_exit
        jmp _rndword_value

_rndword_value_exit
        jsr _tinyrand8
        sta {RndWord}
    ENDIF

_rndword_exit
        clc
        lda {RndWord}
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

FUNCTION RndInt AS INT(Min AS INT, Max AS INT) SHARED STATIC
    ASM
        sec
        lda {Max}
        sbc {Min}
        sta {Range}
        lda {Max}+1
        sbc {Min}+1
        sta {Range}+1

;---------------------------------------

_rndint_mask
        lda #2
        sta {Mask}
        lda #0
        sta {Mask}+1

_rndint_mask_loop
        clc
        rol {Mask}
        rol {Mask}+1
        bcs _rndint_mask_exit

        lda {Range}+1
        cmp {Mask}+1
        bcc _rndint_mask_exit
        bne _rndint_mask_loop

        lda {Range}
        cmp {Mask}
        bcs _rndint_mask_loop
_rndint_mask_exit

        sec
        lda {Mask}
        sbc #1
        sta {Mask}
        lda {Mask}+1
        sbc #0
        sta {Mask}+1

;---------------------------------------

    IFCONST ALLOW_BIAS
        jsr _tinyrand8
        and {Mask}
        sta {RndInt}

        jsr _tinyrand8
        and {Mask}+1
        sta {RndInt}+1

        cmp {Range}+1
        bcc _rndint_exit
        bne _rndint_value_subtract

        lda {RndInt}
        cmp {Range}
        bcc _rndint_exit
        beq _rndint_exit

_rndint_value_subtract
        sec
        lda {RndInt}
        sbc {Range}
        sta {RndInt}

        lda {RndInt}+1
        sbc {Range}+1
        sta {RndInt}+1
    ELSE
_rndint_value
        jsr _tinyrand8
        and {Mask}+1
        cmp {Range}+1
        sta {RndInt}+1

        bcc _rndint_value_exit
        bne _rndint_value

        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        sta {RndInt}

        bcc _rndint_exit
        beq _rndint_exit
        jmp _rndint_value

_rndint_value_exit
        jsr _tinyrand8
        sta {RndInt}
    ENDIF

_rndint_exit
        clc
        lda {RndInt}
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

FUNCTION RndLong AS LONG(Min AS LONG, Max AS LONG) SHARED STATIC
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

;---------------------------------------

_rndlong_mask
        lda #2
        sta {Mask}
        lda #0
        sta {Mask}+1
        sta {Mask}+2

_rndlong_mask_loop
        clc
        rol {Mask}
        rol {Mask}+1
        rol {Mask}+2
        bcs _rndlong_mask_exit

        lda {Range}+2
        cmp {Mask}+2
        bcc _rndlong_mask_exit
        bne _rndlong_mask_loop

        lda {Range}+1
        cmp {Mask}+1
        bcc _rndlong_mask_exit
        bne _rndlong_mask_loop

        lda {Range}
        cmp {Mask}
        bcs _rndlong_mask_loop
_rndlong_mask_exit

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

;---------------------------------------

    IFCONST ALLOW_BIAS
        jsr _tinyrand8
        and {Mask}
        sta {RndLong}

        jsr _tinyrand8
        and {Mask}+1
        sta {RndLong}+1

        jsr _tinyrand8
        and {Mask}+2
        sta {RndLong}+2

        cmp {Range}+2
        bcc _rndlong_exit
        bne _rndlong_value_subtract

        lda {RndLong}+1
        cmp {Range}+1
        bcc _rndlong_exit
        bne _rndlong_value_subtract

        lda {RndLong}
        cmp {Range}
        bcc _rndlong_exit
        beq _rndlong_exit

_rndlong_value_subtract
        sec
        lda {RndLong}
        sbc {Range}
        sta {RndLong}

        lda {RndLong}+1
        sbc {Range}+1
        sta {RndLong}+1

        lda {RndLong}+2
        sbc {Range}+2
        sta {RndLong}+2
    ELSE
_rndlong_value
        jsr _tinyrand8
        and {Mask}+2
        cmp {Range}+2
        sta {RndLong}+2

        bcc _rndlong_value_exit1
        bne _rndlong_value

        jsr _tinyrand8
        and {Mask}+1
        cmp {Range}+1
        sta {RndLong}+1

        bcc _rndlong_value_exit2
        bne _rndlong_value

        jsr _tinyrand8
        and {Mask}
        cmp {Range}
        sta {RndLong}

        bcc _rndlong_exit
        beq _rndlong_exit
        jmp _rndlong_value

_rndlong_value_exit1
        jsr _tinyrand8
        sta {RndLong}+1
_rndlong_value_exit2
        jsr _tinyrand8
        sta {RndLong}
    ENDIF

_rndlong_exit
        clc
        lda {RndLong}
        adc {Min}
        sta {RndLong}
        lda {RndLong}+1
        adc {Min}+1
        sta {RndLong}+1
    END ASM
END FUNCTION

