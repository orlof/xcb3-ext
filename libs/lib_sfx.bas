SHARED CONST NOISE = 128
SHARED CONST PULSE = 64
SHARED CONST SAWTOOTH = 32
SHARED CONST TRIANGLE = 16

DECLARE SUB SfxInstall(PAL AS BYTE) SHARED STATIC
DECLARE SUB SfxUnInstall() SHARED STATIC
DECLARE SUB SfxPlay(Effect AS WORD) SHARED STATIC OVERLOAD
DECLARE SUB SfxPlay(VoiceNr AS BYTE, Effect AS WORD) SHARED STATIC OVERLOAD
DECLARE SUB SfxStop(VoiceNr AS BYTE) SHARED STATIC
DECLARE SUB SfxUpdate() SHARED STATIC

DIM sfx_next AS BYTE
DIM sfx_request(3) AS BYTE
DIM sfx_request_hi(3) AS BYTE
DIM sfx_request_lo(3) AS BYTE
    FOR sfx_next = 0 TO 2
        sfx_request(sfx_next) = FALSE
        sfx_request_hi(sfx_next) = 0
        sfx_request_lo(sfx_next) = 0
    NEXT

ASM
sid = $d400
initsfx
        lda #$00
        ldx #$17
initsfx_reset_loop
        sta sid,x
        dex
        bpl initsfx_reset_loop

        lda #$0f
        sta $d418
END ASM

DIM ptr AS WORD FAST

TYPE SFX
    Duration AS BYTE
    Waveform AS BYTE
    AttackDecay AS BYTE
    SustainRelease AS BYTE
    Frequency AS WORD
    FrequencySlide AS LONG
    Bounce AS BYTE
    Pulse AS WORD
END TYPE

SUB SfxInstall(PAL AS BYTE) SHARED STATIC
    IF PAL THEN
        ON TIMER 19656 GOSUB SfxIrq
    ELSE
        ON TIMER 17095 GOSUB SfxIrq
    END IF
    TIMER INTERRUPT ON
    EXIT SUB

SfxIrq:
    CALL SfxUpdate()
    RETURN
END SUB

SUB SfxUnInstall() SHARED STATIC
    TIMER INTERRUPT OFF
END SUB

SUB SfxPlay(Effect AS WORD) SHARED STATIC OVERLOAD
    sfx_next = sfx_next + 1
    IF sfx_next > 2 THEN
        sfx_next = 0
    END IF
    CALL SfxPlay(sfx_next, Effect)
END SUB

SUB SfxPlay(VoiceNr AS BYTE, Effect AS WORD) SHARED STATIC OVERLOAD
    sfx_request_lo(VoiceNr) = PEEK(@Effect)
    sfx_request_hi(VoiceNr) = PEEK(@Effect + 1)
    sfx_request(VoiceNr) = TRUE
END SUB

SUB SfxStop(VoiceNr AS BYTE) SHARED STATIC
    sfx_request_lo(VoiceNr) = $ff
    sfx_request_hi(VoiceNr) = $ff
    sfx_request(VoiceNr) = TRUE
END SUB

SUB SfxUpdate() SHARED STATIC
    ASM
sid = $d400

sfx_duration            = 0
sfx_waveform            = 1
sfx_atdc                = 2
sfx_ssrl                = 3
sfx_frequency           = 4
sfx_frequency_slide     = 6
sfx_frequency_bounce    = 9
sfx_pulse               = 10

sfx_play
        ldx #3
sfx_loop
        dex
        bpl sfx_loop_1
        rts

sfx_loop_1
        ldy _voice_offset,x

        lda {sfx_request},x            ;Jump here from interrupt
        beq sfx_loop_2
        jmp sfx_new_or_stop

sfx_loop_2
        lda _duration,x
        beq sfx_loop

        cmp #$ff
        beq sfx_continue
        dec _duration,x        ;sound still playing
        bne sfx_continue

sfx_release
        lda #$00
        sta _duration,x
        lda _waveform,x
        and #254
        sta sid+4,y        ;sound over
        jmp sfx_loop

sfx_stop
        lda #$00
        sta _duration,x
        sta sid+4,y        ;sound over
        jmp sfx_loop

sfx_continue
        lda _frequency_slide0,x
        bne sfx_frequency_slide_effect       ;frequency_slide on sound?
        lda _frequency_slide1,x
        bne sfx_frequency_slide_effect       ;frequency_slide on sound?
        jmp sfx_loop

sfx_frequency_slide_effect
        clc
        lda _frequency_lo,x        ;get voice freq lo byte and add
        adc _frequency_slide0,x
        sta sid,y
        sta _frequency_lo,x

        lda _frequency_hi,x        ;get voice freq hi byte and add
        adc _frequency_slide1,x
        sta sid+1,y
        sta _frequency_hi,x

        lda _bouncetime,x
        bne sfx_frequency_slide_bounce
        jmp sfx_loop

sfx_frequency_slide_bounce
        sec
        sbc #1
        beq sfx_frequency_slide_bounce_switch
        sta _bouncetime,x
        jmp sfx_loop

sfx_frequency_slide_bounce_switch
        lda #$ff
        eor _frequency_slide0,x
        sta _frequency_slide0,x
        lda #$ff
        eor _frequency_slide1,x
        sta _frequency_slide1,x
        lda #$ff
        eor _frequency_slide2,x
        sta _frequency_slide2,x

        inc _frequency_slide0,x
        bne sfx_frequency_slide_bounce_switch_done
        inc _frequency_slide1,x
        bne sfx_frequency_slide_bounce_switch_done
        inc _frequency_slide2,x

sfx_frequency_slide_bounce_switch_done
        lda _bouncemax,x
        sta _bouncetime,x  ;reset timer
        jmp sfx_loop

sfx_new_or_stop
        lda #0
        sta {sfx_request},x

        lda {sfx_request_lo},x            ; init ptr to sfx struct
        cmp #$ff
        bne sfx_new
        lda {sfx_request_hi},x
        cmp #$ff
        bne sfx_new_or_stop_1
        jmp sfx_stop

sfx_new_or_stop_1
        lda {sfx_request_lo},x
sfx_new
        sta {ptr}
        lda {sfx_request_hi},x
        sta {ptr}+1

        ldy #sfx_duration
        lda ({ptr}),y
        sta _duration,x

        ldy #sfx_frequency_bounce
        lda ({ptr}),y
        sta _bouncetime,x
        sta _bouncemax,x

        ldy #sfx_frequency_slide
        lda ({ptr}),y
        sta _frequency_slide0,x
        iny
        lda ({ptr}),y
        sta _frequency_slide1,x
        iny
        lda ({ptr}),y
        sta _frequency_slide2,x

        ldy #sfx_frequency
        lda ({ptr}),y
        sta _frequency_lo,x
        iny
        lda ({ptr}),y
        sta _frequency_hi,x

        ldy #sfx_pulse
        lda ({ptr}),y
        sta _pulse_lo,x
        iny
        lda ({ptr}),y
        sta _pulse_hi,x

        ldy #sfx_atdc
        lda ({ptr}),y
        sta _atdc,x

        ldy #sfx_ssrl
        lda ({ptr}),y
        sta _ssrl,x

        ldy #sfx_waveform
        lda ({ptr}),y
        ora #1
        sta _waveform,x

        ldy _voice_offset,x

        lda _frequency_lo,x
        sta sid,y
        lda _frequency_hi,x
        sta sid+1,y
        lda _pulse_lo,x
        sta sid+2,y
        lda _pulse_hi,x
        sta sid+3,y
        lda _atdc,x
        sta sid+5,y
        lda _ssrl,x
        sta sid+6,y
        lda _waveform,x
        sta sid+4,y

        lda #$00
        sta {sfx_request_lo},x
        sta {sfx_request_hi},x
        jmp sfx_loop

_duration
        .byte 0,0,0 ;decrement
_bouncetime
        .byte 0,0,0 ;time until slide reversed
_bouncemax
        .byte 0,0,0 ;holds the reset value for bouncetime
_frequency_slide0
        .byte 0,0,0
_frequency_slide1
        .byte 0,0,0
_frequency_slide2
        .byte 0,0,0
_frequency_lo
        .byte 0,0,0
_frequency_hi
        .byte 0,0,0
_pulse_lo
        .byte 0,0,0
_pulse_hi
        .byte 0,0,0
_atdc
        .byte 0,0,0
_ssrl
        .byte 0,0,0
_waveform
        .byte 0,0,0

_voice_offset
        .byte 0, 7, 14
    END ASM
END SUB
