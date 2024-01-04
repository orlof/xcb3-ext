
'*******************************************************************************
' PUBLIC INTERFACE FOR SPRITE MULTIPLEXER
'*******************************************************************************

'USE THIS FROM MAIN PROGRAM TO COMMIT CHANGES IN PUBLIC SPRITE REGISTERS
DECLARE SUB SprUpdate() STATIC SHARED

'THESE ARE PUBLIC SPRITE REGISTERS THAT CAN BE CHANGED IN MAIN PROGRAM
DIM SHARED SprY(16) AS BYTE FAST
DIM SHARED SprX(16) AS BYTE
DIM SHARED SprColor(16) AS BYTE
DIM SHARED SprShape(16) AS BYTE

'*******************************************************************************
' PUBLIC INTERFACE END
'*******************************************************************************

'Constants
ASM
HEIGHT          = 21
LEAD            = 8
MAXSPR          = 16
END ASM

CONST TRUE      = 255
CONST FALSE     = 0

'Internal data
DIM _SprNr0 AS BYTE FAST
DIM _SprNr1 AS BYTE FAST

DIM _SprIdx(16) AS BYTE FAST
DIM _SprY(16) AS BYTE
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
    sta copy_sw2hw_sprf+2

    ;-----------------------------
    ;init fast variables
    lda #0
    sta {_SprUpdate}

    ldx #MAXSPR-1
spr_init_loop
    txa
    sta {_SprIdx},x
    lda #255
    sta {_SprY},x
    dex
    bpl spr_init_loop

    lda #255
    sta $d015
END ASM

ON RASTER 250 GOSUB InterruptSelector
RASTER INTERRUPT ON
CALL SprUpdate()

'This GOTO is needed so that main program's INCLUDE does not execute interrupt handlers
GOTO THE_END

InterruptSelector:
ASM
InterruptSelectorDirect
        jmp Zone0Direct

Zone0Update
        ;_SprUpdate = FALSE
        lda #0
        sta {_SprUpdate}

        ldx #0
irq1_sortloop
        ldy {_SprIdx}+1,x             ;Sorting code. Algorithm
        lda {SprY},y                    ;ripped from Dragon Breed :-)
        ldy {_SprIdx},x
        cmp {SprY},y
        bcs irq1_sortskip
        stx irq1_sortreload+1
irq1_sortswap
        lda {_SprIdx}+1,x
        sta {_SprIdx},x
        sty {_SprIdx}+1,x
        cpx #$00
        beq irq1_sortreload
        dex
        ldy {_SprIdx}+1,x
        lda {SprY},y
        ldy {_SprIdx},x
        cmp {SprY},y
        bcc irq1_sortswap
irq1_sortreload
        ldx #$00
irq1_sortskip
        inx
        cpx #MAXSPR-1
        bcc irq1_sortloop

        ;ldx #MAXSPR
        ;lda #$ff                        ;$ff is the endmark for the
        ;sta sortspry,x                  ;sprite interrupt routine

        ;ldx #MAXSPR-1
irq1_sortloop3
        ldy {_SprIdx},x               ;Final loop:
        lda {SprY},y                    ;Now copy sprite variables to
        sta {_SprY},x                  ;the sorted table
        lda {SprX},y
        sta {_SprX},x
        lda {SprShape},y
        sta {_SprShape},x
        lda {SprColor},y
        sta {_SprColor},x

        dex
        bpl irq1_sortloop3

        rts

copy_sw2hw
; y: sw spr number
        ldx physicalsprtbl2,y           ;Physical sprite number x 2
        lda {_SprY},y
        sta $d001,x                     ;for X & Y coordinate

        ;cmp #29
        ;bcs *+3
        ;    rts

        lda {_SprX},y
        asl
        sta $d000,x

        bcc copy_sw2hw_lowmsb           ;if carry is clear, then msb of X is 0

        lda $d010
        ora ortbl,x
        sta $d010
        bcs copy_sw2hw_msbok

copy_sw2hw_lowmsb
        lda $d010
        and andtbl,x
        sta $d010

copy_sw2hw_msbok
        ldx physicalsprtbl1,y           ;Physical sprite number x 1
        lda {_SprShape},y
copy_sw2hw_sprf
        sta $07f8,x                     ;for color & frame
        lda {_SprColor},y
        sta $d027,x

        rts

bank:           dc.b %11000000
                dc.b %10000000
                dc.b %01000000
                dc.b %00000000

d015tbl:        dc.b %00000000                  ;Table of sprites that are "on"
                dc.b %00000001                  ;for $d015
                dc.b %00000011
                dc.b %00000111
                dc.b %00001111
                dc.b %00011111
                dc.b %00111111
                dc.b %01111111
                dc.b %11111111

physicalsprtbl1:dc.b 0,1,2,3,4,5,6,7            ;Indexes to frame & color
                dc.b 0,1,2,3,4,5,6,7            ;registers


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
END ASM

'Raster interrupt-handler that assigns software sprite to hardware sprite
ZoneN:
    ASM
ZoneNDirect
        ;_SprNr1 = _SprNr0 + 8
        lda {_SprNr0}
        tax
        ora #8
        tay
        ;sta {_SprNr1}

        ;BORDER _SprColor(_SprNr0)
        lda {_SprColor},x
        sta $d020

        ;IF SCAN() > 249 THEN GOTO Zone0
        lda $d012
        cmp #250
        bcc *+5
            jmp Zone0Direct

        ;IF _SprY(_SprNr1) > 249 THEN GOTO ZoneNDone
        lda {_SprY},y
        cmp #250
        bcs ZoneNDone

        ;_SprScanLine = CWORD(_SprY(_SprNr0)) + HEIGHT
        ;DO WHILE SCAN() < _SprScanLine
        ;LOOP
        lda {_SprY},x
        clc
        adc #HEIGHT
        bcs ZoneNDone
        cmp #250
        bcs ZoneNDone
        cmp $d012
        bcs *-3

        jsr copy_sw2hw

        ;IF _SprNr0 = 7 THEN GOTO ZoneNDone
        cpx #7
        beq ZoneNDone

        ;_SprNr0 = _SprNr0 + 1
        inx
        stx {_SprNr0}

        ;_SprScanLine = CWORD(_SprY(_SprNr0)) + HEIGHT
        ;IF SCAN() + LEAD >= _SprScanLine THEN GOTO ZoneN
        lda {_SprY},x
        clc
        adc #HEIGHT-LEAD
        bcs ZoneNDone
        cmp #250
        bcs ZoneNDone
        cmp $d012
        bcc ZoneNDirect
        clc
        adc #LEAD
        sta $d012
        ;sta {_SprScanLine}
        ;lda #0
        ;sta {_SprScanLine}+1

        lda #<ZoneNDirect
        sta InterruptSelectorDirect+1
        lda #>ZoneNDirect
        sta InterruptSelectorDirect+2

        ldx #0
        stx $d020

        rts
    END ASM

    'If there is time, schedule interrupt to trigger the next sprite re-use
    'ON RASTER _SprScanLine GOSUB ZoneN

    'RETURN

    ASM
ZoneNDone
        ;IF SCAN() > 249 THEN GOTO Zone0
        lda $d012
        cmp #244
        bcs Zone0Direct

        ;BORDER 0
        lda #0
        sta $d020

        lda #250
        sta $d012

        lda #<Zone0Direct
        sta InterruptSelectorDirect+1
        lda #>Zone0Direct
        sta InterruptSelectorDirect+2

        rts
    END ASM

    END

    'If there is time, schedule interrupt to trigger Zone0
    'ON RASTER 250 GOSUB Zone0

    'RETURN

'This is the once per frame interrupt that
' - sorts the software sprites by y-coordinate
' - copies public registers to internal sprite data in sorted order
' - assigns software sprites 0-7 to hardware sprites
Zone0:
    ASM
Zone0Direct
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
        ;inc $d020



        ldy #0
Zone0CopyLoop
        jsr copy_sw2hw
        iny
        cpy #8
        bcc Zone0CopyLoop

        lda #0
        sta {_SprNr0}

        ;_SprScanLine = CWORD(_SprY(_SprNr0)) + HEIGHT
        lda {_SprY}
        clc
        adc #HEIGHT
        bcs Zone0Repeat
        cmp #250
        bcs Zone0Repeat

        bit $d011
        bmi Zone0Interrupt

        sec
        sbc #LEAD
        cmp $d012
        bcs *+5
            jmp ZoneNDirect

        clc
        adc #LEAD
Zone0Interrupt
        sta $d012

        lda #<ZoneNDirect
        sta InterruptSelectorDirect+1
        lda #>ZoneNDirect
        sta InterruptSelectorDirect+2

        jmp Zone0End

Zone0Repeat
        lda #250
        sta $d012

        lda #<Zone0Direct
        sta InterruptSelectorDirect+1
        lda #>Zone0Direct
        sta InterruptSelectorDirect+2

Zone0End
        lda #0
        sta $d020

        rts
    END ASM

    END

    'IF _SprScanLine = 255 THEN
        'If there is time, schedule interrupt to trigger Zone0
    '    ON RASTER 250 GOSUB Zone0
    'ELSE
        'If there is time, schedule interrupt to trigger the next sprite re-use
    '    ON RASTER _SprScanLine GOSUB ZoneN
    'END IF
    'RETURN

THE_END:

SUB SprUpdate() STATIC SHARED
    'BACKGROUND 3
    _SprUpdate = TRUE
    DO WHILE _SprUpdate     'Wait for Zone0-interrupt-handler to process sprite changes
    LOOP
END SUB