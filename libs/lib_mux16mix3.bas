'*******************************************************************************
' PUBLIC INTERFACE FOR SPRITE MULTIPLEXER
'*******************************************************************************

'USE THIS FROM MAIN PROGRAM TO COMMIT CHANGES IN PUBLIC SPRITE REGISTERS
DECLARE SUB SprUpdate() STATIC SHARED

'THESE ARE PUBLIC SPRITE REGISTERS THAT CAN BE CHANGED IN MAIN PROGRAM
DIM SHARED SprY(16) AS BYTE
DIM SHARED SprX(16) AS BYTE
DIM SHARED SprColor(16) AS BYTE
DIM SHARED SprShape(16) AS BYTE

'*******************************************************************************
' PUBLIC INTERFACE END
'*******************************************************************************
CONST TRUE      = 255
CONST FALSE     = 0

'Internal data
DIM _SprReUseNr AS BYTE FAST

DIM _SprIdx(16) AS BYTE FAST
DIM _SprNext(16) AS BYTE

DIM _SprY(17) AS BYTE
DIM _SprX(16) AS BYTE
DIM _SprColor(16) AS BYTE
DIM _SprShape(16) AS BYTE
'DIM _SprScanLine AS WORD
DIM _SprUpdate AS BYTE

'Initialize sprite multiplexer
SYSTEM INTERRUPT OFF        'This is mandatory

'INITIALIZE MUX
ASM
    ;-----------------------------
    ;init frame pointers
    lda $dd00
    and #%00000011
    tax

    lda $d018
    and #$f0
    lsr
    lsr

    ora #3
    ora bank,x
    sta reuse_sprite_sprf
    sta copy_sw2hw_sprf

    ;-----------------------------
    ;init fast variables
    lda #0
    sta {_SprUpdate}

    ldx #MAXSPR-1
spr_init_idx_loop
    txa
    sta {_SprIdx},x
    dex
    bpl spr_init_idx_loop

    lda #255
    sta $d015

    ldx #MAXSPR-1
spr_init_y_loop
    sta {SprY},x
    dex
    bpl spr_init_y_loop
END ASM

ON RASTER 250 GOSUB InterruptSelector
RASTER INTERRUPT ON
CALL SprUpdate()

'This GOTO is needed so that main program's INCLUDE does not execute interrupt handlers
GOTO SKIP_ASM


InterruptSelector:
ASM
;------------------------------------------------------------
InterruptSelectorDirect
;------------------------------------------------------------
NextInterrupt = * + 1
        jmp Zone0
;------------------------------------------------------------
;CONSTANTS
;------------------------------------------------------------
HEIGHT          = 21
SETUP_LEAD      = 5
TRIGGER_LEAD    = 2
MAXSPR          = 16
MIN_SEPARATION  = HEIGHT + 5
;------------------------------------------------------------
;DATA
;------------------------------------------------------------
bank:           dc.b %11000000
                dc.b %10000000
                dc.b %01000000
                dc.b %00000000

physicalsprtbl1:dc.b 0,1,2,3,4,5,6,7
                dc.b 0,1,2,3,4,5,6,7

physicalsprtbl2:dc.b 0,2,4,6,8,10,12,14
                dc.b 0,2,4,6,8,10,12,14

andtbl:         dc.b 255-1
ortbl:          dc.b 1
                dc.b 255-2
                dc.b 2
                dc.b 255-4
                dc.b 4
                dc.b 255-8
                dc.b 8
                dc.b 255-16
                dc.b 16
                dc.b 255-32
                dc.b 32
                dc.b 255-64
                dc.b 64
                dc.b 255-128
                dc.b 128
;------------------------------------------------------------
Zone0
;------------------------------------------------------------
        ;BORDER 2
        lda #2
        sta $d020

        lda #255
        sta $d001
        sta $d003
        sta $d005
        sta $d007
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f

        lda {_SprUpdate}
        beq *+5
            jsr Zone0Update

        ;todo? reverse loop, start from Zone0Plan_DstIdx
        ldx #0
Zone0CopyLoop
            ldy physicalsprtbl2,x           ;Physical sprite number x 2
            jsr use_sprite
            inx
            cpx #8
        bcc Zone0CopyLoop

        ldx #0
        stx {_SprReUseNr}

        jmp ScheduleNextZone
;------------------------------------------------------------
ZoneN
;------------------------------------------------------------
        ldx {_SprReUseNr}
        lda {_SprColor},x
        sta $d020

        lda {_SprY},x
        clc
        adc #HEIGHT
        cmp $d012
        bcs *-3

        sta $400

        jsr reuse_sprite

        inc {_SprReUseNr}
        jmp ScheduleNextZone
;------------------------------------------------------------
ScheduleNextZone
;------------------------------------------------------------
        ldx {_SprReUseNr}

        lda {_SprNext},x
        beq ScheduleNextZone0

ScheduleNextZoneN
        lda {_SprY},x
        clc
        adc #HEIGHT - SETUP_LEAD

        ;todo: are we absolutely sure that we are in >256 because
        ;this is the spr=0 and we are early - could it also be that
        ;we are late?
        bit $d011
            bmi ScheduleNextZoneN_Interrupt
        cmp $d012
            bcs ScheduleNextZoneN_Interrupt
                jmp ZoneN

ScheduleNextZoneN_Interrupt
        clc
        adc #SETUP_LEAD - TRIGGER_LEAD
        sta $d012

        lda #<ZoneN
        sta NextInterrupt
        lda #>ZoneN
        sta NextInterrupt+1

        jmp ScheduleNextZoneEnd

ScheduleNextZone0
        lda #250 - SETUP_LEAD

        bit $d011
        bmi ScheduleNextZone0_Interrupt
            cmp $d012
            bcs ScheduleNextZone0_Interrupt
                jmp Zone0

ScheduleNextZone0_Interrupt
        clc
        adc #SETUP_LEAD - TRIGGER_LEAD
        sta $d012

        lda #<Zone0
        sta NextInterrupt
        lda #>Zone0
        sta NextInterrupt+1

ScheduleNextZoneEnd
        lda #0
        sta $d020

        rts
;------------------------------------------------------------
Zone0Update
;------------------------------------------------------------
        ;_SprUpdate = FALSE
        lda #0
        sta {_SprUpdate}

        ldx #0
Zone0Update_SortLoop
        ldy {_SprIdx}+1,x             ;Sorting code. Algorithm
        lda {SprY},y                    ;ripped from Dragon Breed :-)
        ldy {_SprIdx},x
        cmp {SprY},y
        bcs Zone0Update_SortSkip
        stx Zone0Update_SortReload+1
Zone0Update_SortSwap
        lda {_SprIdx}+1,x
        sta {_SprIdx},x
        sty {_SprIdx}+1,x
        cpx #$00
        beq Zone0Update_SortReload
        dex
        ldy {_SprIdx}+1,x
        lda {SprY},y
        ldy {_SprIdx},x
        cmp {SprY},y
        bcc Zone0Update_SortSwap
Zone0Update_SortReload
        ldx #$00
Zone0Update_SortSkip
        inx
        cpx #MAXSPR-1
        bcc Zone0Update_SortLoop
;---------------------------------
        ldx #0
        stx Zone0Update_DstIdx
Zone0Update_CopyLoop
        ldy {_SprIdx},x
        lda {SprY},y

        cmp #30
        bcc Zone0Update_SkipSrc
        cmp #250
        bcs Zone0Update_SkipSrc

        stx Zone0Update_SrcIdx

Zone0Update_DstIdx = * + 1             ;number of sprites on screen
        ldx #0

        sta {_SprY},x
        lda {SprX},y
        sta {_SprX},x
        lda {SprShape},y
        sta {_SprShape},x
        lda {SprColor},y
        sta {_SprColor},x

        inx
        stx Zone0Update_DstIdx

Zone0Update_SrcIdx = * + 1
        ldx #0
Zone0Update_SkipSrc
        inx
        cpx #MAXSPR
        bne Zone0Update_CopyLoop


        lda #255
        ldx Zone0Update_DstIdx

Zone0Update_ClearLoop
        cpx #MAXSPR
        beq Zone0Update_ClearLoopExit

        sta {_SprY},x
        inx
        jmp Zone0Update_ClearLoop
Zone0Update_ClearLoopExit

        ;rts
;------------------------------------------------------------
Zone0Plan
;------------------------------------------------------------
        ldx #0
        ldy #8
Zone0Plan_Loop
        cpy Zone0Update_DstIdx
        bcs Zone0Plan_Exit

        lda {_SprY},x
        clc
        adc #MIN_SEPARATION
        bcs Zone0Plan_Exit

        cmp {_SprY},y
        bcs Zone0Plan_Skip

        tya
        sta {_SprNext},x

        inx
Zone0Plan_Skip
        iny
        bne Zone0Plan_Loop

Zone0Plan_Exit
        lda #0
        sta {_SprNext},x

        rts
;------------------------------------------------------------
reuse_sprite
;------------------------------------------------------------
; x: re-used sprite number
        ldy physicalsprtbl2,x           ;Physical sprite number x 2
        lda {_SprNext},x
        tax

;------------------------------------------------------------
use_sprite
;------------------------------------------------------------
        lda {_SprY},x
        sta $d001,y                     ;for X & Y coordinate

        lda {_SprX},x
        asl
        sta $d000,y

        bcc reuse_sprite_lowmsb           ;if carry is clear, then msb of X is 0

        lda $d010
        ora ortbl,y
        sta $d010
        bcs reuse_sprite_msbok

reuse_sprite_lowmsb
        lda $d010
        and andtbl,y
        sta $d010

reuse_sprite_msbok
        tya
        lsr
        tay

        lda {_SprShape},x
reuse_sprite_sprf = * + 2
        sta $07f8,y                     ;for color & frame
        lda {_SprColor},x
        sta $d027,y

        rts
;------------------------------------------------------------
copy_sw2hw
;------------------------------------------------------------
        ldy physicalsprtbl2,x           ;Physical sprite number x 2

        lda {_SprY},x
        sta $d001,y                     ;for X & Y coordinate

        lda {_SprX},x
        asl
        sta $d000,y

        bcc copy_sw2hw_lowmsb           ;if carry is clear, then msb of X is 0

        lda $d010
        ora ortbl,y
        sta $d010
        bcs copy_sw2hw_msbok

copy_sw2hw_lowmsb
        lda $d010
        and andtbl,y
        sta $d010

copy_sw2hw_msbok
        ldy physicalsprtbl1,x           ;Physical sprite number x 1

        lda {_SprShape},x
copy_sw2hw_sprf = * + 2
        sta $07f8,y                     ;for color & frame
        lda {_SprColor},x
        sta $d027,y

        rts
END ASM

SKIP_ASM:

SUB SprUpdate() STATIC SHARED
    'BACKGROUND 3
    _SprUpdate = TRUE
    DO WHILE _SprUpdate     'Wait for Zone0-interrupt-handler to process sprite changes
    LOOP
END SUB
