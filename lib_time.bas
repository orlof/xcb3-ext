INCLUDE "lib_sysinfo.bas"

IF sysinfo_tod50hz() THEN
    ASM
        lda $dc0e
        ora #%10000000
        sta $dc0e
        lda $dd0e
        ora #%10000000
        sta $dd0e
    END ASM
ELSE
    ASM
        lda $dc0e
        and #%01111111
        sta $dc0e
        lda $dd0e
        and #%01111111
        sta $dd0e
    END ASM
END IF


SHARED CONST CIA1 = 1
SHARED CONST CIA2 = 2

TYPE TOD
    Frac AS BYTE
    Second AS BYTE
    Minute AS BYTE
    Hour AS BYTE
END TYPE

DIM TOD_VALUE AS TOD SHARED

DIM _CIA1_TOD AS TOD @$DC08
DIM _CIA2_TOD AS TOD @$DD08
DIM hour_24_to_12(24) AS BYTE @_HOUR_24_TO_12

SUB SetTime(Hour AS BYTE, Minute AS BYTE, Second AS BYTE, Frac AS BYTE) STATIC SHARED
    ASM
        ;lda $dc0f
        ;and #%01111111
        ;sta $dc0f

        ldx {Hour}
        lda {hour_24_to_12},x
        sta {TOD_VALUE}+3

        lda {Minute}
        sta _bin_to_bcd_argument
        jsr _bin_to_bcd
        sta {TOD_VALUE}+2

        lda {Second}
        sta _bin_to_bcd_argument
        jsr _bin_to_bcd
        sta {TOD_VALUE}+1

        lda {Frac}
        sta _bin_to_bcd_argument
        jsr _bin_to_bcd
        sta {TOD_VALUE}+0
    END ASM
END SUB

SUB ReadCIA(CIA AS BYTE) STATIC SHARED
    ASM
        lda {CIA}
        cmp #1
        bne _readcia2

_readcia1
        lda {_CIA1_TOD}+3
        sta {TOD_VALUE}+3
        lda {_CIA1_TOD}+2
        sta {TOD_VALUE}+2
        lda {_CIA1_TOD}+1
        sta {TOD_VALUE}+1
        lda {_CIA1_TOD}+0
        sta {TOD_VALUE}+0
        jmp _readcia_end

_readcia2
        lda {_CIA2_TOD}+3
        sta {TOD_VALUE}+3
        lda {_CIA2_TOD}+2
        sta {TOD_VALUE}+2
        lda {_CIA2_TOD}+1
        sta {TOD_VALUE}+1
        lda {_CIA2_TOD}+0
        sta {TOD_VALUE}+0

_readcia_end
    END ASM
END SUB

SUB WriteCIA(CIA AS BYTE, Timer AS BYTE) STATIC SHARED
    ASM
        lda {CIA}
        cmp #1
        bne _writecia2

_writecia1
        lda {Timer}
        beq _writecia1_tod
_writecia1_alarm
        lda $dc0f
        ora #%10000000
        sta $dc0f
        jmp _writecia1_hmsf
_writecia1_alarm
        lda $dc0f
        and #%01111111
        sta $dc0f

_writecia1_hmsf
        lda {TOD_VALUE}+3
        sta {_CIA1_TOD}+3
        lda {TOD_VALUE}+2
        sta {_CIA1_TOD}+2
        lda {TOD_VALUE}+1
        sta {_CIA1_TOD}+1
        lda {TOD_VALUE}+0
        sta {_CIA1_TOD}+0
        jmp _readcia_end

_writecia2
        lda {Timer}
        beq _writecia2_tod
_writecia2_alarm
        lda $dd0f
        ora #%10000000
        sta $dd0f
        jmp _writecia2_hmsf
_writecia2_alarm
        lda $dd0f
        and #%01111111
        sta $dd0f

_writecia2_hmsf
        lda {TOD_VALUE}+3
        sta {_CIA2_TOD}+3
        lda {TOD_VALUE}+2
        sta {_CIA2_TOD}+2
        lda {TOD_VALUE}+1
        sta {_CIA2_TOD}+1
        lda {TOD_VALUE}+0
        sta {_CIA2_TOD}+0

_writecia_end
    END ASM
END SUB

FUNCTION GetHour AS BYTE() STATIC SHARED
    ASM
        lda {TOD_VALUE}+3
        and #%00011111
        cmp #16
        bcc _get_hour_am_or_pm

_get_hour_gt9
        and #$0f
        clc
        adc #10

_get_hour_am_or_pm
        bit {TOD_VALUE}+3
        bpl _get_hour_am

_get_hour_pm
        adc #12
_get_hour_am
        sta {GetHour}
    END ASM
END FUNCTION

FUNCTION GetMinute AS BYTE() STATIC SHARED
    ASM
        lda {TOD_VALUE}+2
        jsr bcd_to_bin
        sta {GetMinute}
    END ASM
END FUNCTION

FUNCTION GetSecond AS BYTE() STATIC SHARED
    ASM
        lda {TOD_VALUE}+1
        jsr bcd_to_bin
        sta {GetSecond}
    END ASM
END FUNCTION

FUNCTION GetFrac AS BYTE() STATIC SHARED
    ASM
        lda {TOD_VALUE}+0
        jsr bcd_to_bin
        sta {GetFrac}
    END ASM
END FUNCTION

FUNCTION GetISO8601 AS STRING * 10() STATIC SHARED
    ASM
_getiso8601
        lda #10 ; len
        sta {GetISO8601}

        lda #58 ; :
        sta {GetISO8601} + 3
        sta {GetISO8601} + 6
        lda #46 ; .
        sta {GetISO8601} + 9

_getiso8601_hour
        lda {TOD_VALUE}+3
        tax
        cmp #$80
        bcc _getiso8601_hour_am

_getiso8601_hour_pm
        sed
        sec
        sbc #$68
        cld
        tax

_getiso8601_hour_am
        lsr
        lsr
        lsr
        lsr
        clc
        adc #48
        sta {GetISO8601} + 1

        txa
        and #%00001111
        clc
        adc #48
        sta {GetISO8601} + 2

_getiso8601_minute
        lda {TOD_VALUE}+2
        lsr
        lsr
        lsr
        lsr
        clc
        adc #48
        sta {GetISO8601} + 4

        lda {TOD_VALUE}+2
        and #%00001111
        clc
        adc #48
        sta {GetISO8601} + 5

_getiso8601_second
        lda {TOD_VALUE}+1
        lsr
        lsr
        lsr
        lsr
        clc
        adc #48
        sta {GetISO8601} + 7

        lda {TOD_VALUE}+1
        and #%00001111
        clc
        adc #48
        sta {GetISO8601} + 8

_getiso8601_frac
        lda {TOD_VALUE}+0
        and #%00001111
        clc
        adc #48
        sta {GetISO8601} + 10
    END ASM
END FUNCTION

SUB time_pause(jiffys AS BYTE) SHARED STATIC
    ASM
        ldx {jiffys}
time_pause_wait_positive
        bit $d011
        bmi time_pause_wait_positive
time_pause_wait_negative
        bit $d011
        bpl time_pause_wait_negative

        dex
        bne time_pause_wait_positive
    END ASM
END SUB


GOTO THE_END
_HOUR_24_TO_12:
DATA AS BYTE $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11
DATA AS BYTE $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91

ASM
bcd_to_bin
    tax
    and	#$f0
    lsr
    sta	bcd_to_bin_temp
    lsr
    lsr
    adc	bcd_to_bin_temp
    sta	bcd_to_bin_temp
    txa
    and	#$0f
    adc	bcd_to_bin_temp
    rts
bcd_to_bin_temp
    dc.b 0

_bin_to_bcd
        ; table of BCD values for each binary bit, put this somewhere.
        ; note! values are -1 as the ADC is always done with the carry set
        sed			        ; all adds in decimal mode
        lda #$00    	    ; clear A
        ldx #$07            ; set bit count
_bin_to_bcd_bit_loop
        lsr _bin_to_bcd_argument             ; bit to carry
        bcc _bin_to_bcd_bit_loop_skip_add        ; branch if no add
        adc _bin_to_bcd_b2b_table-1,x   ; else add BCD value
_bin_to_bcd_bit_loop_skip_add
        dex                 ; decrement bit count
        bne _bin_to_bcd_bit_loop        ; loop if more to do
        cld                 ; clear decimal mode
        rts

_bin_to_bcd_b2b_table
        dc.b $63,$31,$15,$07,$03,$01,$00
_bin_to_bcd_argument
        dc.b 0
END ASM

THE_END:
