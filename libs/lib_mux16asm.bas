'*******************************************************************************
' PUBLIC INTERFACE FOR SPRITE MULTIPLEXER
'*******************************************************************************

CONST NUM_SPRITES = 32

'USE THIS FROM MAIN PROGRAM TO COMMIT CHANGES IN PUBLIC SPRITE REGISTERS
DECLARE SUB SprUpdate() STATIC SHARED

'THESE ARE PUBLIC SPRITE REGISTERS THAT CAN BE CHANGED IN MAIN PROGRAM
DIM SHARED SprY(NUM_SPRITES) AS BYTE
DIM SHARED SprX(NUM_SPRITES) AS BYTE
DIM SHARED SprColor(NUM_SPRITES) AS BYTE
DIM SHARED SprShape(NUM_SPRITES) AS BYTE

'*******************************************************************************
' PUBLIC INTERFACE END
'*******************************************************************************
CONST TRUE      = 255
CONST FALSE     = 0

'Internal data
DIM _SprUpdate AS BYTE
DIM _SprReUseNr AS BYTE FAST

DIM _SprIdx(NUM_SPRITES) AS BYTE FAST
DIM _SprNext(NUM_SPRITES) AS BYTE

DIM _SprY(NUM_SPRITES) AS BYTE
DIM _SprX(NUM_SPRITES) AS BYTE
DIM _SprColor(NUM_SPRITES) AS BYTE
DIM _SprShape(NUM_SPRITES) AS BYTE

'Initialize sprite multiplexer
SYSTEM INTERRUPT OFF        'This is mandatory

'INITIALIZE MUX
ASM
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
SPRITE_FP       = $07f8
SPRITE_HEIGHT   = 21
SETUP_LEAD      = 4
TRIGGER_LEAD    = 1
MAXSPR          = 32
MIN_SEPARATION  = SPRITE_HEIGHT + 5

;------------------------------------------------------------
;DATA
;------------------------------------------------------------
bank:           dc.b %11000000
                dc.b %10000000
                dc.b %01000000
                dc.b %00000000

physicalsprtbl1:dc.b 0,1,2,3,4,5,6,7
                dc.b 0,1,2,3,4,5,6,7
                dc.b 0,1,2,3,4,5,6,7
                dc.b 0,1,2,3,4,5,6,7

physicalsprtbl2:dc.b 0,2,4,6,8,10,12,14
                dc.b 0,2,4,6,8,10,12,14
                dc.b 0,2,4,6,8,10,12,14
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
        bne *+5
            jmp Zone0_NoUpdate

        ;_SprUpdate = FALSE
        lda #0
        sta {_SprUpdate}

        ;---------------------------------
        ;Zone0_Update_Sort
        ;---------------------------------
        ldx #0
Zone0_Update_SortLoop
        ldy {_SprIdx}+1,x             ;Sorting code. Algorithm
        lda {SprY},y                    ;ripped from Dragon Breed :-)
        ldy {_SprIdx},x
        cmp {SprY},y
        bcs Zone0_Update_SortSkip
        stx Zone0_Update_SortReload+1
Zone0_Update_SortSwap
        lda {_SprIdx}+1,x
        sta {_SprIdx},x
        sty {_SprIdx}+1,x
        cpx #$00
        beq Zone0_Update_SortReload
        dex
        ldy {_SprIdx}+1,x
        lda {SprY},y
        ldy {_SprIdx},x
        cmp {SprY},y
        bcc Zone0_Update_SortSwap
Zone0_Update_SortReload
        ldx #$00
Zone0_Update_SortSkip
        inx
        cpx #MAXSPR-1
        bcc Zone0_Update_SortLoop

        ;---------------------------------
        ;Zone0_Update_Copy
        ;---------------------------------
        ldx #0
        stx Zone0_Update_DstIdx
Zone0_Update_CopyLoop
        ldy {_SprIdx},x
        lda {SprY},y

        cmp #30
        bcc Zone0_Update_SkipSrc
        cmp #250
        bcs Zone0_Update_Disable

        stx Zone0_Update_SrcIdx

Zone0_Update_DstIdx = * + 1             ;number of sprites on screen
        ldx #$b5

        sta {_SprY},x
        lda {SprX},y
        sta {_SprX},x
        lda {SprShape},y
        sta {_SprShape},x
        lda {SprColor},y
        sta {_SprColor},x

        inx
        stx Zone0_Update_DstIdx

Zone0_Update_SrcIdx = * + 1
        ldx #$b5
Zone0_Update_SkipSrc
        inx
        cpx #MAXSPR
        bne Zone0_Update_CopyLoop

;---------------------------------
Zone0_Update_Disable
;---------------------------------
        lda #255
        ldx Zone0_Update_DstIdx
Zone0_Update_DisableLoop
        cpx #MAXSPR
        beq Zone0_Update_DisableLoopExit

        sta {_SprY},x
        inx
        jmp Zone0_Update_DisableLoop
Zone0_Update_DisableLoopExit

        ;---------------------------------
        ;Zone0_Assign
        ;---------------------------------
        lda {_SprY}+0
        sta $d001
        lda {_SprY}+1
        sta $d003
        lda {_SprY}+2
        sta $d005
        lda {_SprY}+3
        sta $d007
        lda {_SprY}+4
        sta $d009
        lda {_SprY}+5
        sta $d00b
        lda {_SprY}+6
        sta $d00d
        lda {_SprY}+7
        sta $d00f

        lda {_SprX}+0
        asl
        ror {_SprReUseNr}
        sta $d000
        lda {_SprX}+1
        asl
        ror {_SprReUseNr}
        sta $d002
        lda {_SprX}+2
        asl
        ror {_SprReUseNr}
        sta $d004
        lda {_SprX}+3
        asl
        ror {_SprReUseNr}
        sta $d006
        lda {_SprX}+4
        asl
        ror {_SprReUseNr}
        sta $d008
        lda {_SprX}+5
        asl
        ror {_SprReUseNr}
        sta $d00a
        lda {_SprX}+6
        asl
        ror {_SprReUseNr}
        sta $d00c
        lda {_SprX}+7
        asl
        ror {_SprReUseNr}
        sta $d00e

        lda {_SprReUseNr}
        sta $d010

        lda {_SprShape}+0
        sta SPRITE_FP+0
        lda {_SprShape}+1
        sta SPRITE_FP+1
        lda {_SprShape}+2
        sta SPRITE_FP+2
        lda {_SprShape}+3
        sta SPRITE_FP+3
        lda {_SprShape}+4
        sta SPRITE_FP+4
        lda {_SprShape}+5
        sta SPRITE_FP+5
        lda {_SprShape}+6
        sta SPRITE_FP+6
        lda {_SprShape}+7
        sta SPRITE_FP+7

        lda {_SprColor}+0
        sta $d027+0
        lda {_SprColor}+1
        sta $d027+1
        lda {_SprColor}+2
        sta $d027+2
        lda {_SprColor}+3
        sta $d027+3
        lda {_SprColor}+4
        sta $d027+4
        lda {_SprColor}+5
        sta $d027+5
        lda {_SprColor}+6
        sta $d027+6
        lda {_SprColor}+7
        sta $d027+7

        ;---------------------------------
        ;Zone0_Update_Plan
        ;---------------------------------
        ldx #0
        ldy #8
Zone0_Update_PlanLoop
        cpy Zone0_Update_DstIdx
        bcs Zone0_Update_PlanExit

        lda {_SprY},x
        clc
        adc #MIN_SEPARATION
        bcs Zone0_Update_PlanExit

        cmp {_SprY},y
        bcs Zone0_Update_PlanSkip

        tya
        sta {_SprNext},x

        inx
Zone0_Update_PlanSkip
        iny
        bne Zone0_Update_PlanLoop

Zone0_Update_PlanExit
        lda #0
        sta {_SprNext},x

Zone0_NoUpdate
        ldx #0
        stx {_SprReUseNr}

        ;---------------------------------
        ;Zone0_ScheduleNext
        ;---------------------------------
        lda {_SprNext}
        beq Zone0_ScheduleNextZone0_Interrupt

        ;---------------------------------
Zone0_ScheduleNextZoneN
        ;---------------------------------
        lda #<ZoneN
        sta NextInterrupt
        lda #>ZoneN
        sta NextInterrupt+1

        lda {_SprY}
        clc
        adc #SPRITE_HEIGHT - SETUP_LEAD

        bit $d011
            bmi Zone0_ScheduleNextZoneN_Interrupt
        cmp $d012
            bcc ZoneN

Zone0_ScheduleNextZoneN_Interrupt
        clc
        adc #SETUP_LEAD - TRIGGER_LEAD
        sta $d012

        jmp Zone0_ScheduleNextZoneEnd

        ;---------------------------------
Zone0_ScheduleNextZone0_Interrupt
        ;---------------------------------
        lda #250 - TRIGGER_LEAD
        sta $d012

        lda #<Zone0
        sta NextInterrupt
        lda #>Zone0
        sta NextInterrupt+1

        ;jmp ScheduleNextZoneEnd

Zone0_ScheduleNextZoneEnd
        lda #0
        sta $d020

        rts

;------------------------------------------------------------
ZoneN
;------------------------------------------------------------
        ldx {_SprReUseNr}
        lda {_SprColor},x
        sta $d020

        lda {_SprY},x
        clc
        adc #SPRITE_HEIGHT
        cmp $d012
        bcs *-3

        ;---------------------------------
        ;ZoneN_Show
        ;---------------------------------
        ldy physicalsprtbl2,x           ;Physical sprite number x 2
        lda {_SprNext},x
        tax

        lda {_SprY},x
        sta $d001,y                     ;for X & Y coordinate

        lda {_SprX},x
        asl
        sta $d000,y

        bcc ZoneN_XMsbLo           ;if carry is clear, then msb of X is 0

        lda $d010
        ora ortbl,y
        sta $d010
        bcs ZoneN_XMsbHi

ZoneN_XMsbLo
        lda $d010
        and andtbl,y
        sta $d010

ZoneN_XMsbHi
        tya
        lsr
        tay

        lda {_SprShape},x
        sta SPRITE_FP,y                     ;for color & frame
        lda {_SprColor},x
        sta $d027,y

        inc {_SprReUseNr}

        ;---------------------------------
        ;ZoneN_ScheduleNextZone
        ;---------------------------------
        ldx {_SprReUseNr}

        lda {_SprNext},x
        bne ZoneN_ScheduleNextZoneN

ZoneN_ScheduleNextZone0
        bit $d011
        bpl * + 5
            jmp Zone0

        lda #250 - SETUP_LEAD
        cmp $d012
        bcs * + 5
            jmp Zone0

ZoneN_ScheduleNextZone0_Interrupt
        lda #250 - TRIGGER_LEAD
        sta $d012

        lda #<Zone0
        sta NextInterrupt
        lda #>Zone0
        sta NextInterrupt+1

        jmp ZoneN_ScheduleNextZoneEnd

ZoneN_ScheduleNextZoneN
        lda {_SprY},x
        clc
        adc #SPRITE_HEIGHT - SETUP_LEAD

        cmp $d012
        bcs * + 5
            jmp ZoneN

ZoneN_ScheduleNextZoneN_Interrupt
        clc
        adc #SETUP_LEAD - TRIGGER_LEAD
        sta $d012

ZoneN_ScheduleNextZoneEnd
        lda #0
        sta $d020

        rts
END ASM

SKIP_ASM:

SUB SprUpdate() STATIC SHARED
    'BACKGROUND 3
    _SprUpdate = TRUE
    DO WHILE _SprUpdate     'Wait for Zone0-interrupt-handler to process sprite changes
    LOOP
END SUB
