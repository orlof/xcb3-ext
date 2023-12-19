DIM flags AS BYTE: flags = 0

FUNCTION sysinfo_ntsc AS BYTE() SHARED STATIC
    RETURN (flags AND %00000001) = 0
END FUNCTION

FUNCTION sysinfo_pal AS BYTE() SHARED STATIC
    RETURN (flags AND %00000001) > 0
END FUNCTION

FUNCTION sysinfo_tod60 AS BYTE() SHARED STATIC
    RETURN (flags AND %00000010) = 0
END FUNCTION

FUNCTION sysinfo_tod50 AS BYTE() SHARED STATIC
    RETURN (flags AND %00000010) > 0
END FUNCTION

FUNCTION sysinfo_sid8580 AS BYTE() SHARED STATIC
    RETURN (flags AND %00000100) > 0
END FUNCTION

FUNCTION sysinfo_sid6581 AS BYTE() SHARED STATIC
    RETURN (flags AND %00000100) = 0
END FUNCTION

SUB sysinfo_debug() SHARED STATIC
    PRINT "ntsc", sysinfo_ntsc()
    PRINT "pal", sysinfo_pal()
    PRINT "tod50hz", sysinfo_tod50()
    PRINT "tod60hz", sysinfo_tod60()
    PRINT "sid8580", sysinfo_sid8580()
    PRINT "sid6581", sysinfo_sid6581()
END SUB

ASM
    ; Detecting TOD frequency by Silver Dream ! / Thorgal / W.F.M.H.
    sei             ; accounting for NMIs is not needed when
    lda #$00        ; used as part of application initialisation
    sta $dd08       ; TO2TEN start TOD - in case it wasn't running
c0:
    cmp $dd08       ; TO2TEN wait until tenths
    beq c0          ; register changes its value

    lda #$ff        ; count from $ffff (65535) down
    sta $dd04       ; TI2ALO both timer A register
    sta $dd05       ; TI2AHI set to $ff

    lda #%00010001  ; bit seven = 0 - 60Hz TOD mode
    sta $dd0e       ; CI2CRA start the timer

    lda $dd08       ; TO2TEN
c1:
    cmp $dd08       ; poll TO2TEN for change
    beq c1

    lda $dd05       ; TI2AHI expect (approximate) $7f4a $70a6 $3251 $20c0
    cli

    cmp #$51        ; about the middle (average is $50c0)
    bcs ticks_60hz

    ; 50Hz on TOD pin
    cmp #$29        ; about the middle between $20(c0) and $32(51)
    bcs pal50
    ; we run on NTSC machine with 50Hz TOD clock
    lda #%10
    sta {flags}
    jmp sid_detection

pal50:
    ; we run on PAL machine with 50Hz TOD clock
    lda #%11
    sta {flags}
    jmp sid_detection

ticks_60hz:
    cmp #$78        ; about the middle between $70(a6) and $7f(4a)
    bcc ntsc60

pal60:
    ; we run on PAL machine with 60Hz TOD clock
    lda #%01
    sta {flags}

ntsc60:
sid_detection:
    ;SID DETECTION ROUTINE

    ;By SounDemon - Based on a tip from Dag Lem.
    ;Put together by FTC after SounDemons instructions
    ;...and tested by Rambones and Jeff.

    ; - Don't run this routine on a badline

    sei         ;No disturbing interrupts
    lda #$ff
sid_loop:
    cmp $d012   ;Don't run it on a badline.
    bne sid_loop

    ;Detection itself starts here
    lda #$ff    ;Set frequency in voice 3 to $ffff
    sta $d412   ;...and set testbit (other bits don't matter) in VCREG3 ($d412) to disable oscillator
    sta $d40e
    sta $d40f
    lda #$20    ;Sawtooth wave and gatebit OFF to start oscillator again.
    sta $d412
    lda $d41b   ;Accu now has different value depending on sid model (6581=3/8580=2)
    lsr         ;...that is: Carry flag is set for 6581, and clear for 8580.
    bcs model_6581

model_8580:
    lda {flags}
    ora #%00000100
    sta {flags}

model_6581:
END ASM
