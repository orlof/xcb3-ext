REM **********************
REM *     CONSTANTS      *
REM **********************

SHARED CONST STANDARD_CHARACTER_MODE        = %00000000
SHARED CONST MULTICOLOR_CHARACTER_MODE      = %00010000
SHARED CONST STANDARD_BITMAP_MODE           = %00100000
SHARED CONST MULTICOLOR_BITMAP_MODE         = %00110000
SHARED CONST EXTENDED_BACKGROUND_COLOR_MODE = %01000000

SHARED CONST PLOT_SET   = 1
SHARED CONST PLOT_CLEAR = 0
SHARED CONST PLOT_FLIP  = -1

SHARED CONST COLOR_BLACK       = $0
SHARED CONST COLOR_WHITE       = $1
SHARED CONST COLOR_RED         = $2
SHARED CONST COLOR_CYAN        = $3
SHARED CONST COLOR_PURPLE      = $4
SHARED CONST COLOR_GREEN       = $5
SHARED CONST COLOR_BLUE        = $6
SHARED CONST COLOR_YELLOW      = $7
SHARED CONST COLOR_ORANGE      = $8
SHARED CONST COLOR_BROWN       = $9
SHARED CONST COLOR_LIGHTRED    = $a
SHARED CONST COLOR_DARKGRAY    = $b
SHARED CONST COLOR_MIDDLEGRAY  = $c
SHARED CONST COLOR_LIGHTGREEN  = $d
SHARED CONST COLOR_LIGHTBLUE   = $e
SHARED CONST COLOR_LIGHTGRAY   = $f

REM **********************
REM *     VARIABLES      *
REM **********************

DIM _hires_mask0(8) AS BYTE @__hires_mask0
DIM _hires_mask1(8) AS BYTE @__hires_mask1

DIM _mc_mask(4) AS BYTE @__mc_mask
DIM _mc_pattern(4) AS BYTE @__mc_pattern

DIM _bitmap_y_tbl(25) AS WORD

DIM _screen_y_tbl_hi(25) AS BYTE
DIM _screen_y_tbl_lo(25) AS BYTE

DIM _color_y_tbl_hi(25) AS BYTE @ __color_y_tbl_hi
DIM _color_y_tbl_lo(25) AS BYTE @ __color_y_tbl_lo

DIM _petscii_to_screencode(8) AS BYTE @ __petscii_to_screencode
DIM _nible_to_byte(16) AS BYTE @ __nible_to_byte

' REUSABLE ZERO-PAGE PSEUDO-REGISTERS
DIM ZP_W0 AS WORD FAST  ' BASE
DIM ZP_W1 AS WORD FAST  ' DX
DIM ZP_W2 AS WORD FAST  ' COUNT
DIM ZP_I0 AS INT FAST   ' DISTANCE

DIM ZP_B0 AS BYTE FAST  ' DY
DIM ZP_B1 AS BYTE FAST  ' X_INC
DIM ZP_B2 AS BYTE FAST  ' Y_INC
DIM ZP_B3 AS BYTE FAST  ' PATTERN
DIM ZP_B4 AS BYTE FAST  ' MASK
DIM ZP_B5 AS BYTE FAST  ' TEMP TEMP0
DIM ZP_B6 AS BYTE FAST  ' MASK TEMP1

'DIM DY AS BYTE FAST
'DIM X_INC AS BYTE FAST
'DIM Y_INC AS BYTE FAST
'DIM PATTERN AS BYTE FAST
'DIM MASK AS BYTE FAST
'DIM TEMP AS BYTE FAST

REM **********************
REM *    DECLARATIONS    *
REM **********************

DECLARE SUB SetVideoBank(BankNumber AS BYTE) SHARED STATIC
DECLARE SUB SetGraphicsMode(Mode AS BYTE) SHARED STATIC
DECLARE SUB SetScreenMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB SetCharacterMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB SetBitmapMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB ResetScreen() SHARED STATIC

DECLARE SUB FillBitmap(Value AS BYTE) SHARED STATIC
DECLARE SUB FillScreen(Value AS BYTE) SHARED STATIC
DECLARE SUB FillColorRam(Value AS BYTE) SHARED STATIC

DECLARE SUB Plot(x AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB Draw(x1 AS WORD, y1 AS BYTE, x2 AS WORD, y2 AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB DrawMC(x1 AS BYTE, y1 AS BYTE, x2 AS BYTE, y2 AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB Circle(X0 AS WORD, Y0 AS BYTE, Radius AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB CircleMC(X0 AS BYTE, Y0 AS BYTE, Radius AS BYTE, Ink AS BYTE) SHARED STATIC

DECLARE SUB CopyCharROM(CharSet AS BYTE, DestAddr AS WORD) SHARED STATIC
DECLARE SUB TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD) SHARED STATIC

DECLARE FUNCTION Check AS BYTE(X AS WORD, Y AS BYTE) SHARED STATIC
DECLARE FUNCTION CheckMC AS BYTE(X AS BYTE, Y AS BYTE) SHARED STATIC
DECLARE FUNCTION PetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC

'DECLARE SUB SetBackgroundColor1(ColorCode AS BYTE) SHARED STATIC
'DECLARE SUB SetBackgroundColor2(ColorCode AS BYTE) SHARED STATIC
'DECLARE SUB CopyCharacterSet(Set AS BYTE, Address AS BYTE) SHARED STATIC

DECLARE SUB _calc_bitmap_table() STATIC
DECLARE SUB _calc_screen_table() STATIC

REM **********************
REM *        MAIN        *
REM **********************
SUB TestSuite() SHARED STATIC
    CALL SetVideoBank(3)
    CALL SetBitmapMemory(1)
    CALL SetScreenMemory(0)
    CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)
    CALL FillBitmap(0)
    CALL FillScreen(SHL(1, 4) OR 2)
    CALL FillColorRam(3)

    FOR X AS BYTE = 0 TO 159
        FOR Y AS BYTE = 80 TO 120
            CALL PlotMC(X, Y, (Y XOR X) AND 3)
        NEXT
    NEXT

    FOR R AS BYTE = 5 TO 75 STEP 5
        CALL CircleMC(80, 100, R, 2)
    NEXT

    CALL DrawMC(0, 0, 50, 0, 1)
    CALL DrawMC(0, 0, 50, 25, 2)
    CALL DrawMC(0, 0, 50, 50, 3)
    CALL DrawMC(0, 0, 25, 50, 2)
    CALL DrawMC(0, 0, 0, 50, 1)
    CALL DrawMC(0, 199, 50, 199, 1)
    CALL DrawMC(0, 199, 50, 174, 2)
    CALL DrawMC(0, 199, 50, 149, 3)
    CALL DrawMC(0, 199, 25, 149, 2)
    CALL DrawMC(0, 199, 0, 149, 1)
    CALL DrawMC(159, 0, 109, 0, 1)
    CALL DrawMC(159, 0, 109, 25, 2)
    CALL DrawMC(159, 0, 109, 50, 3)
    CALL DrawMC(159, 0, 134, 50, 2)
    CALL DrawMC(159, 0, 159, 50, 1)
    CALL DrawMC(159, 199, 109, 199, 1)
    CALL DrawMC(159, 199, 109, 174, 2)
    CALL DrawMC(159, 199, 109, 149, 3)
    CALL DrawMC(159, 199, 134, 149, 2)
    CALL DrawMC(159, 199, 159, 149, 1)
    CALL DrawMC(0, 0, 159, 199, 1)
    CALL DrawMC(159, 0, 0, 199, 1)

'    CALL CopyCharROM(1, $d000)
    FOR Face AS BYTE = 0 TO 4
    FOR Bg AS BYTE = 0 TO 4
    CALL TextMC(8*Bg, Face+10, Face-1, Bg-1, "aAbB", CWORD(1))
    NEXT
    NEXT


    DO
    LOOP

    CALL SetGraphicsMode(STANDARD_BITMAP_MODE)
    CALL FillBitmap(0)
    CALL FillScreen(SHL(1, 4) OR 2)

    'FOR XW AS WORD = 0 TO 319
    '    FOR Y = 80 TO 120
    '        CALL Plot(XW, Y, (XW XOR Y) AND 1)
    '    NEXT
    'NEXT

    FOR R = 5 TO 95 STEP 5
        CALL Circle(160, 100, R, 1)
    NEXT

    CALL Draw(0,0,50,0,1)
    CALL Draw(0,0,50,25,1)
    CALL Draw(0,0,50,50,1)
    CALL Draw(0,0,25,50,1)
    CALL Draw(0,0,0,50,1)
    CALL Draw(319,0,269,0,1)
    CALL Draw(319,0,269,25,1)
    CALL Draw(319,0,269,50,1)
    CALL Draw(319,0,294,50,1)
    CALL Draw(319,0,319,50,1)
    CALL Draw(0,199,50,199,1)
    CALL Draw(0,199,50,174,1)
    CALL Draw(0,199,50,149,1)
    CALL Draw(0,199,25,149,1)
    CALL Draw(0,199,0,149,1)
    CALL Draw(319,199,269,199,1)
    CALL Draw(319,199,269,174,1)
    CALL Draw(319,199,269,149,1)
    CALL Draw(319,199,294,149,1)
    CALL Draw(319,199,319,149,1)
    CALL Draw(0,0,319,199,1)
    CALL Draw(319,0,0,199,1)
END SUB

CALL TestSuite()

END

REM **********************
REM *     FUNCTIONS      *
REM **********************
SUB TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD) SHARED STATIC
    DIM ProcessorFlag AS BYTE
    ' BITMAP_BASE:  ZP_W0
    ' FONT_BASE:    ZP_W1
    ' TEXT_POS:     ZP_B0
    ' FONT_POS:     ZP_B1
    ' FONT_BYTE:    ZP_B2
    ' SCREEN_BYTE:  ZP_B3
    ' BG_BYTE:      ZP_B4
    ' FG_BYTE:      ZP_B5
    ASM
        lda {CharMemAddr}+1
        bne _mc_text_ram
        lda {CharMemAddr}
        cmp #2
        bcs _mc_text_ram

_mc_text_rom
        sei
        lda 1
        sta {ProcessorFlag}
        and #%11111000
        ora #%00000001
        sta 1

        ldx #$d8
        lda {CharMemAddr}
        bne _mc_text_rom1
        ldx #$d0
_mc_text_rom1
        stx {CharMemAddr}+1

        lda #0
        sta {CharMemAddr}

        jmp _mc_text_init

_mc_text_ram
        sei
        lda 1
        sta {ProcessorFlag}
        and #%11111000
        sta 1

_mc_text_init
        ;init color patterns
        ldx {Bg}
        lda {_mc_pattern},x
        sta {ZP_B4}

        ldx {Ink}
        lda {_mc_pattern},x
        sta {ZP_B5}

        ;init bitmap pointer
        lda {Row}
        asl
        tay
        lda {_bitmap_y_tbl},y
        sta {ZP_W0}
        lda {_bitmap_y_tbl}+1,y
        sta {ZP_W0}+1

        lda {Col}
        asl
        asl
        asl
        bcc mc_text_add_col_to_base
        inc {ZP_W0}+1
        clc
mc_text_add_col_to_base
        adc {ZP_W0}
        sta {ZP_W0}
        bcc _mc_text_init_text_pointer
        inc {ZP_W0}+1

_mc_text_init_text_pointer
        ;init text pointer
        lda #0
        sta {ZP_B0}

mc_text_loop_text
        ldy {ZP_B0}
        cpy {Text}
        bne mc_text_loop_read_char
        jmp mc_text_end
mc_text_loop_read_char
        iny
        sty {ZP_B0}

        ;petscii to screen code
        lda {Text},y
        ldx #$5e
        cmp #255
        beq _mc_text_init_font_base
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        clc
        lda {_petscii_to_screencode},x
        adc {Text},y
        tax

_mc_text_init_font_base
        lda #0
        sta {ZP_W1}+1

        txa
        asl
        rol {ZP_W1}+1
        asl
        rol {ZP_W1}+1
        asl
        rol {ZP_W1}+1

        adc {CharMemAddr}
        sta {ZP_W1}

        lda {ZP_W1}+1
        adc {CharMemAddr}+1
        sta {ZP_W1}+1

        ;init font loop
        ldy #7
mc_text_font_loop
        ;choose foreground
        ldx {Ink}
        cpx #$ff
        bne _mc_text_font_loop_left_bg
        lda ({ZP_W0}),y
        sta {ZP_B5}

_mc_text_font_loop_left_bg
        ;choose background
        ldx {Bg}
        cpx #$ff
        bne _mc_text_font_loop_left_nible
        lda ({ZP_W0}),y
        sta {ZP_B4}

_mc_text_font_loop_left_nible
        lda ({ZP_W0}),y
        ;process left nible
        lda ({ZP_W1}),y
        lsr
        lsr
        lsr
        lsr
        tax
        lda {_nible_to_byte},x
        sta {ZP_B2}

        eor #$ff
        and {ZP_B4}
        sta {ZP_B3}

        lda {ZP_B5}
        and {ZP_B2}
        ora {ZP_B3}
        sta ({ZP_W0}),y

        ;process right nible
        lda ({ZP_W1}),y
        and #%00001111
        tax
        lda {_nible_to_byte},x
        sta {ZP_B2}

        tya
        eor #%00001000
        tay

        ;choose foreground
        ldx {Ink}
        cpx #$ff
        bne _mc_text_font_loop_right_bg
        lda ({ZP_W0}),y
        sta {ZP_B5}

_mc_text_font_loop_right_bg
        ;choose background
        ldx {Bg}
        cpx #$ff
        bne _mc_text_font_loop_store_right_nible
        lda ({ZP_W0}),y
        sta {ZP_B4}

_mc_text_font_loop_store_right_nible
        lda {ZP_B2}
        eor #$ff
        and {ZP_B4}
        sta {ZP_B3}

        lda {ZP_B5}
        and {ZP_B2}
        ora {ZP_B3}
        sta ({ZP_W0}),y

        tya
        eor #%00001000
        tay
        dey
        bpl mc_text_font_loop

        ;next char
        clc
        lda {ZP_W0}
        adc #16
        sta {ZP_W0}
        bcc mc_text_next_char
        inc {ZP_W0}+1
mc_text_next_char
        jmp mc_text_loop_text
mc_text_end
        lda {ProcessorFlag}
        sta 1
        cli
    END ASM
END SUB


SUB CopyCharROM(CharSet AS BYTE, DestAddr AS WORD) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        sei
        lda 1
        sta {ZP_B0}
        and #%11111000
        ora #%00000001
        sta 1
    END ASM
    IF CharSet THEN
        MEMCPY $d800, DestAddr, 2048
    ELSE
        MEMCPY $d000, DestAddr, 2048
    END IF
    ASM
        lda {ZP_B0}
        sta $01
        cli
    END ASM
END SUB


SUB FillColorRam(Value AS BYTE) SHARED STATIC
    MEMSET $d800, 1000, Value
END SUB

SUB FillScreen(Value AS BYTE) SHARED STATIC
    IF _screen_y_tbl_hi(0) >= $d0 THEN
        ASM
            sei
            dec 1
            dec 1
        END ASM
    END IF
    MEMSET SHL(CWORD(_screen_y_tbl_hi(0)), 8) OR _screen_y_tbl_lo(0), 1000, Value
    IF _screen_y_tbl_hi(0) >= $d0 THEN
        ASM
            inc 1
            inc 1
            cli
        END ASM
    END IF
END SUB

SUB FillBitmap(Value AS BYTE) SHARED STATIC
    IF _bitmap_y_tbl(0) >= $c000 THEN
        ASM
            sei
            dec 1
            dec 1
        END ASM
    END IF
    MEMSET _bitmap_y_tbl(0), 8000, Value
    IF _bitmap_y_tbl(0) >= $c000 THEN
        ASM
            inc 1
            inc 1
            cli
        END ASM
    END IF
END SUB

SUB ResetScreen() SHARED STATIC
    CALL SetVideoBank(0)
    CALL SetScreenMemory(1)
    CALL SetCharacterMemory(2)
    CALL SetGraphicsMode(STANDARD_CHARACTER_MODE)
END SUB

SUB SetGraphicsMode(Mode AS BYTE) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        lda {Mode}
        and #%01100000
        sta {ZP_B0}

        lda $d011
        and #%10011111
        ora {ZP_B0}
        sta $d011

        lda {Mode}
        and #%00010000
        sta {ZP_B0}

        lda $d016
        and #%11101111
        ora {ZP_B0}
        sta $d016
    END ASM
END SUB

SUB SetVideoBank(BankNumber AS BYTE) SHARED STATIC
    ASM
        lda $dd00
        and #%11111100
        ora {BankNumber}
        eor #%00000011
        sta $dd00
    END ASM
    CALL _calc_bitmap_table()
    CALL _calc_screen_table()
END SUB

SUB SetCharacterMemory(Ptr AS BYTE) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        lda {Ptr}
        asl
        sta {ZP_B0}

        lda $d018
        and #%11110001
        ora {ZP_B0}
        sta $d018
    END ASM
END SUB

SUB SetScreenMemory(Ptr AS BYTE) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        lda {Ptr}
        asl
        asl
        asl
        asl
        sta {ZP_B0}
        lda $d018
        and #%00001111
        ora {ZP_B0}
        sta $d018
    END ASM
    CALL _calc_screen_table()
END SUB

SUB SetBitmapMemory(Ptr AS BYTE) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        lda {Ptr}
        asl
        asl
        asl
        sta {ZP_B0}

        lda $d018
        and #%11110111
        ora {ZP_B0}
        sta $d018
    END ASM
    CALL _calc_bitmap_table()
END SUB

FUNCTION Check AS BYTE(X AS WORD, Y AS BYTE) SHARED STATIC
    ASM
check
        lda #$ff
        sta {Check}

        lda {Y}
        cmp #200
        bcs _check_end

        lda {X}+1
        cmp #$1
        bcc _check_ok
        bne _check_end
        lda {X}
        cmp #$40
        bcs _check_end
_check_ok
        inc {Check}
_check_end
    END ASM
END FUNCTION

FUNCTION CheckMC AS BYTE(X AS BYTE, Y AS BYTE) SHARED STATIC
    ASM
checkmc
        lda #$ff
        sta {CheckMC}

        lda {Y}
        cmp #200
        bcs _check_end

        lda {X}
        cmp #160
        bcs _check_end
_checkmc_ok
        inc {CheckMC}
_checkmc_end
    END ASM
END FUNCTION

SUB CircleMC(X0 AS BYTE, Y0 AS BYTE, Radius AS BYTE, Ink AS BYTE) SHARED STATIC
    ' DISTANCE = ZP_I0
    ' X = ZP_B1,
    ' Y = ZP_B2
    ZP_B1 = Radius
    ZP_B2 = 0
    ZP_I0 = ZP_B1 / 2

    DO
        ZP_B2 = ZP_B2 + 1
        ZP_I0 = ZP_I0 - ZP_B2
        IF ZP_I0 < 0 THEN ZP_B1 = ZP_B1 - 1: ZP_I0 = ZP_I0 + ZP_B1

        CALL PlotMC(X0+ZP_B1, Y0+ZP_B2, Ink)
        CALL PlotMC(X0+ZP_B1, Y0-ZP_B2, Ink)
        CALL PlotMC(X0-ZP_B1, Y0+ZP_B2, Ink)
        CALL PlotMC(X0-ZP_B1, Y0-ZP_B2, Ink)
        CALL PlotMC(X0+ZP_B2, Y0+ZP_B1, Ink)
        CALL PlotMC(X0+ZP_B2, Y0-ZP_B1, Ink)
        CALL PlotMC(X0-ZP_B2, Y0+ZP_B1, Ink)
        CALL PlotMC(X0-ZP_B2, Y0-ZP_B1, Ink)
    LOOP UNTIL ZP_B1 <= ZP_B2

    CALL PlotMC(X0+Radius, Y0, Ink)
    CALL PlotMC(X0-Radius, Y0, Ink)
    CALL PlotMC(X0, Y0+Radius, Ink)
    CALL PlotMC(X0, Y0-Radius, Ink)
END SUB

SUB Circle(X0 AS WORD, Y0 AS BYTE, Radius AS BYTE, Mode AS BYTE) SHARED STATIC
    ' WE USE DX AND DY BECAUSE THOSE ARE CONVENIENTLY FREE WORD AND BYTE VARIABLES
    ' DISTANCE = ZP_I0
    ' DY = ZP_B0
    ZP_W1 = Radius
    ZP_B0 = 0
    ZP_I0 = ZP_W1 / 2

    DO
        ZP_B0 = ZP_B0 + 1
        ZP_I0 = ZP_I0 - ZP_B0
        IF ZP_I0 < 0 THEN ZP_W1 = ZP_W1 - 1: ZP_I0 = ZP_I0 + ZP_W1

        CALL Plot(X0+ZP_W1, Y0+ZP_B0, Mode)
        CALL Plot(X0+ZP_W1, Y0-ZP_B0, Mode)
        CALL Plot(X0-ZP_W1, Y0+ZP_B0, Mode)
        CALL Plot(X0-ZP_W1, Y0-ZP_B0, Mode)
        CALL Plot(X0+ZP_B0, Y0+ZP_W1, Mode)
        CALL Plot(X0+ZP_B0, Y0-ZP_W1, Mode)
        CALL Plot(X0-ZP_B0, Y0+ZP_W1, Mode)
        CALL Plot(X0-ZP_B0, Y0-ZP_W1, Mode)
    LOOP UNTIL ZP_W1 <= ZP_B0

    CALL Plot(X0 + Radius, Y0, Mode)
    CALL Plot(X0 - Radius, Y0, Mode)
    CALL Plot(X0, Y0 + Radius, Mode)
    CALL Plot(X0, Y0 - Radius, Mode)
END SUB

SUB Plot(x AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
    'ABOUT 235 pixels per jiffy (average 142 pixels per line)
    ASM
_plot_ram_in
        sei
        dec 1
        dec 1

_plot_init
        lda {y}             ; 4
        and #7              ; 2 these cycles are needed to calculate the index to y table
        sta {ZP_B5}          ; 2 not needed if the table were 250 words long

        eor {y}             ; 3
        lsr                 ; 2
        lsr                 ; 2
        tax                 ; 2

        lda  {_bitmap_y_tbl}+1,x
        adc {x}+1
        sta {ZP_W0}+1
        lda {_bitmap_y_tbl},x
        sta {ZP_W0}

        lda {x}
        and #7
        tax

        eor {x}
        adc {ZP_B5}
        tay

        lda {Mode}
        beq _plot_clr
        bpl _plot_set

_plot_flip
        lda {_hires_mask1},x
        eor ({ZP_W0}),y
        sta ({ZP_W0}),y
        jmp _plot_ram_out

_plot_clr
        lda {_hires_mask0},x
        and ({ZP_W0}),y
        sta ({ZP_W0}),y
        jmp _plot_ram_out

_plot_set
        lda {_hires_mask1},x
        ora ({ZP_W0}),y
        sta ({ZP_W0}),y

_plot_ram_out
        inc 1
        inc 1
        cli
_plot_end
    END ASM
END SUB

SUB Draw(x1 AS WORD, y1 AS BYTE, x2 AS WORD, y2 AS BYTE, Mode AS BYTE) SHARED STATIC
    ' DX ZP_W1
    ASM
_draw_ram_in
        sei
        dec 1
        dec 1

_draw_init
        ;fast line draw
        ;passed: x1, y1, x2, y2

        ;altered:
        ;dx   = _x      delta x 16
        ;dy   = ZP_B0      delta y 8
        ;xi   = ZP_B1   1/r flag 8
        ;yi   = ZP_B2   u/d flag 8
        ;base = ZP_W0   base of pixel addr 16
        ;m    = MASK   pixel mask 8
        ;c    = COUNT   ZP_W2 count 16
        ;r    = DISTANCE   16 ZP_I0

        ldx #0              ;xinc=right
        ldy #0              ;yinc=down

_draw_dx
        lda {x2}            ;calculate dx=x2-x1
        sec
        sbc {x1}
        sta {ZP_W1}
        lda {x2}+1
        sbc {x1}+1
        sta {ZP_W1}+1
        bcs _draw_dy

        dex                 ;dx<0, xinc=left
        lda #1
        sbc {ZP_W1}
        sta {ZP_W1}
        lda #0
        sbc {ZP_W1}+1
        sta {ZP_W1}+1          ;dx=abs(dx)

_draw_dy
        lda {y2}            ;dy=y2-y1
        sec
        sbc {y1}
        bcs _draw_store_dy
        dey                 ;dy<0, yinc=up
        eor #$ff            ;dy=abs(dy)
        adc #1

_draw_store_dy
        sta {ZP_B0}

        stx {ZP_B1}         ;xi: $00 or $ff
        sty {ZP_B2}         ;y1: $00 or $ff

        lda {y1}            ;plot (x1, y1)
        and #7
        tay

        eor {y1}
        lsr
        lsr
        tax

        lda {x1}
        and #$f8
        adc {_bitmap_y_tbl},x
        sta {ZP_W0}         ;save base
        lda {_bitmap_y_tbl}+1,x
        adc {x1}+1
        sta {ZP_W0}+1

        lda {x1}
        and #7
        tax
        lda {_hires_mask1},x    ; mc
        sta {ZP_B4}         ;save mask

        ora ({ZP_W0}),y
        sta ({ZP_W0}),y

        lda {ZP_W1}+1
        bne _draw_x
        lda {ZP_W1}            ;(dx>=dy)
        cmp {ZP_B0}
        bcs _draw_x
        jmp _draw_y
_draw_x
        ;dx>=dy
        lda {ZP_W1}+1
        sta {ZP_W2}+1       ;c=dx
        lsr
        sta {ZP_I0}+1       ;r=dx/2
        lda {ZP_W1}
        sta {ZP_W2}
        ror
        sta {ZP_I0}
        lda {ZP_W2}
        ora {ZP_W2}+1
        bne _draw_x_loop
        jmp _draw_ram_out             ;if single point

_draw_x_loop
        lda {ZP_B1}
        bmi _draw_x_left

_draw_x_right
        lsr {ZP_B4}         ;right mc
        bcc _draw_x_add_dy
        ror {ZP_B4}
        lda {ZP_W0}
        adc #8
        sta {ZP_W0}
        bcc _draw_x_add_dy
        inc {ZP_W0}+1
        bne _draw_x_add_dy
_draw_x_left
        asl {ZP_B4}         ;left mc
        bcc _draw_x_add_dy
        rol {ZP_B4}
        lda {ZP_W0}
        sbc #7
        sta {ZP_W0}
        bcs _draw_x_add_dy
        dec {ZP_W0}+1
_draw_x_add_dy
        lda {ZP_I0}         ;r=r+dy
        clc
        adc {ZP_B0}
        sta {ZP_I0}
        bcc _draw_x_sub_dx
        inc {ZP_I0}+1
_draw_x_sub_dx
        sec
        sbc {ZP_W1}
        tax

        lda {ZP_I0}+1
        sbc {ZP_W1}+1
        bcc _draw_x_plot

        stx {ZP_I0}         ;r>=dx
        sta {ZP_I0}+1       ;r=r-dx

        lda {ZP_B2}
        bmi _draw_x_up

_draw_x_down
        iny                 ;down
        cpy #8
        bcc _draw_x_plot

        ldy #0
        lda {ZP_W0}
        adc #$3f
        sta {ZP_W0}
        lda {ZP_W0}+1
        adc #1
        bcc _draw_x_store_base_hi

_draw_x_up
        dey                 ;up
        bpl _draw_x_plot
        ldy #7
        lda {ZP_W0}
        sbc #$40
        sta {ZP_W0}
        lda {ZP_W0}+1
        sbc #1
_draw_x_store_base_hi
        sta {ZP_W0}+1

_draw_x_plot
        lda ({ZP_W0}),y
        ora {ZP_B4}
        sta ({ZP_W0}),y     ;plot (x,y) mc

        dec {ZP_W2}
        bne _draw_x_loop             ;next
        dec {ZP_W2}+1
        beq _draw_x_loop             ;next
        jmp _draw_ram_out

_draw_y
        ; dy>dx
        lda {ZP_B0}
        beq _draw_ram_out            ;single point

        sta {ZP_W2}         ;c=dy
        lsr
        sta {ZP_I0}         ;r=dy/2

_draw_y_loop
        lda {ZP_B2}
        bmi _draw_y_up

_draw_y_down
        iny                 ;down
        cpy #8
        bcc _draw_y_add_dx
        ldy #0
        lda {ZP_W0}
        adc #$3f
        sta {ZP_W0}
        lda {ZP_W0}+1
        adc #1
        bcc _draw_y_store_base_hi

_draw_y_up
        dey                 ;up
        bpl _draw_y_add_dx
        ldy #7
        sec
        lda {ZP_W0}
        sbc #$40
        sta {ZP_W0}
        lda {ZP_W0}+1

        sbc #1
_draw_y_store_base_hi
        sta {ZP_W0}+1

_draw_y_add_dx
        ldx #0
        lda {ZP_I0}         ;r=r+dx
        clc
        adc {ZP_W1}
        sta {ZP_I0}
        bcs _draw_y_sub_dy
        inx
        sec
_draw_y_sub_dy
        sbc {ZP_B0}
        bcs _draw_y_distance
        dex
        beq _draw_y_plot
_draw_y_distance
        sta {ZP_I0}         ;r>=dy, r=r-dy
        lda {ZP_B1}
        bmi _draw_y_left

_draw_y_right
        lsr {ZP_B4}         ;right
        bcc _draw_y_plot
        ror {ZP_B4}
        lda {ZP_W0}
        adc #8
        sta {ZP_W0}
        bcc _draw_y_plot
        inc {ZP_W0}+1
        bne _draw_y_plot

_draw_y_left
        asl {ZP_B4}         ;left
        bcc _draw_y_plot
        rol {ZP_B4}
        lda {ZP_W0}
        sbc #7
        sta {ZP_W0}
        bcs _draw_y_plot
        dec {ZP_W0}+1

_draw_y_plot
        lda ({ZP_W0}),y
        ora {ZP_B4}
        sta ({ZP_W0}),y     ;plot (x, y)

        dec {ZP_W2}
        bne _draw_y_loop            ;next

_draw_ram_out
        inc 1
        inc 1
        cli
    END ASM
END SUB

SUB PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
    ' BASE = ZP_W0
    ASM
_plotmc_ram_in
        sei
        dec 1
        dec 1

_plotmc_init
        lda #0
        sta {ZP_W0}+1

        lda {y}             ; 4
        and #7              ; 2 these cycles are needed to calculate the index to y table
        tay                 ; 2 not needed if the table were 250 words long

        eor {y}             ; 3
        lsr                 ; 2
        lsr                 ; 2
        tax                 ; 2

_plotmc_base
        lda  {x}
        and  #$FC
        asl
        rol  {ZP_W0}+1
        adc  {_bitmap_y_tbl},x
        sta  {ZP_W0}

        lda  {_bitmap_y_tbl}+1,x
        adc  {ZP_W0}+1
        sta  {ZP_W0}+1

_plotmc_mask
        lda {x}
        and #3
        tax
        lda {_mc_mask},x
        sta {ZP_B4}

_plotmc_ink
        ldx {Ink}
        and {_mc_pattern},x
        sta  {ZP_B5}

_plotmc_draw
        lda  {ZP_B4}
        eor  #$FF
        and  ({ZP_W0}),y
        ora  {ZP_B5}
        sta  ({ZP_W0}),y

_plotmc_ram_out:
        inc 1
        inc 1
        cli

_plotmc_end:
    END ASM
END SUB

SUB DrawMC(x1 AS BYTE, y1 AS BYTE, x2 AS BYTE, y2 AS BYTE, Ink AS BYTE) SHARED STATIC
    '180 pixels per jiffy (average line length 94 pixels)
    ASM
        ;altered:
        ;  DX ZP_W1 8
        ;  DY ZP_B0 8
        ;  X_INC ZP_B1 8
        ;  Y_INC ZP_B2 8
        ;  BASE ZP_W0 16
        ;  MASK ZP_B4 8
        ;  COUNT 8 ZP_W2
        ;  DISTANCE 16 ZP_I0
_drawmc_ram_in
        sei
        dec 1
        dec 1

_drawmc_init
        ldx  {Ink}
        lda  {_mc_pattern},x
        sta  {ZP_B3}

        ldx  #0
        ldy  #0
        sty {ZP_W0}+1
        sty {ZP_I0}+1

        lda  {x2}             ; dx = abs(x2 - x1)
        sec
        sbc  {x1}
        bcs  _drawmc_store_dx
        dex
        eor  #$FF
        adc  #1
_drawmc_store_dx:
        sta  {ZP_W1}

        lda  {y2}             ; dy = abs(y2 - y1)
        sec
        sbc  {y1}
        bcs  _drawmc_store_dy
        dey
        eor  #$FF
        adc  #1
_drawmc_store_dy:
        sta  {ZP_B0}

        stx  {ZP_B1}
        sty  {ZP_B2}

        lda  {y1}     ; y1 & %00000111
        and  #7
        tay

        eor  {y1}     ; (y1 & %11111000) << 2
        lsr
        lsr
        tax

        lda  {x1}
        and  #$FC
        asl
        rol  {ZP_W0}+1
        adc  {_bitmap_y_tbl},x
        sta  {ZP_W0}

        lda  {_bitmap_y_tbl}+1,x
        adc  {ZP_W0}+1
        sta  {ZP_W0}+1

        lda  {x1}
        and  #3
        tax

        lda  {_mc_mask},x
        sta  {ZP_B4}

        and  {ZP_B3}
        sta  {ZP_B5}
        lda  {ZP_B4}
        eor  #$FF
        and  ({ZP_W0}),y
        ora  {ZP_B5}
        sta  ({ZP_W0}),y

        lda  {ZP_W1}
        cmp  {ZP_B0}
        bcs  _drawmc_x
        jmp  _drawmc_y

_drawmc_x:
        lda  {ZP_W1}
        bne  _drawmc_x_init
        jmp  _drawmc_ram_out

_drawmc_x_init:
        sta  {ZP_W2}
        lsr
        sta  {ZP_I0}

_drawmc_x_loop:
        lda  {ZP_B1}
        bmi  _drawmc_x_left

_drawmc_x_right:
        lsr  {ZP_B4}
        ror  {ZP_B4}
        bcc  _drawmc_x_add_dy
        ror  {ZP_B4}
        lda  {ZP_W0}
        adc  #8
        sta  {ZP_W0}
        bcc  _drawmc_x_add_dy
        inc  {ZP_W0}+1
        bne  _drawmc_x_add_dy

_drawmc_x_left:
        asl  {ZP_B4}
        rol  {ZP_B4}
        bcc  _drawmc_x_add_dy
        rol  {ZP_B4}
        sec
        lda  {ZP_W0}
        sbc  #8
        sta  {ZP_W0}
        bcs  _drawmc_x_add_dy
        dec  {ZP_W0}+1

_drawmc_x_add_dy:
        lda  {ZP_I0}
        clc
        adc  {ZP_B0}
        sta  {ZP_I0}
        bcc  _drawmc_x_sub_dx
        inc  {ZP_I0}+1

_drawmc_x_sub_dx:
        sec
        sbc  {ZP_W1}
        tax

        lda  {ZP_I0}+1
        sbc  #0
        bcc  _drawmc_x_plot

        stx  {ZP_I0}
        sta  {ZP_I0}+1

        lda  {ZP_B2}
        bmi  _drawmc_x_up

_drawmc_x_down:
        iny
        cpy  #8
        bcc  _drawmc_x_plot

        ldy  #0
        lda  {ZP_W0}
        adc  #$3F
        sta  {ZP_W0}
        lda  {ZP_W0}+1
        adc  #$01
        bcc  _drawmc_x_store_base_hi

_drawmc_x_up:
        dey
        bpl  _drawmc_x_plot

        ldy  #7
        lda  {ZP_W0}
        sbc  #$40
        sta  {ZP_W0}
        lda  {ZP_W0}+1
        sbc  #$01
_drawmc_x_store_base_hi:
        sta  {ZP_W0}+1

_drawmc_x_plot:
        lda  {ZP_B4}
        and  {ZP_B3}
        sta  {ZP_B5}
        lda  {ZP_B4}
        eor  #$FF
        and  ({ZP_W0}),y
        ora  {ZP_B5}
        sta  ({ZP_W0}),y

        dec  {ZP_W2}
        bne  _drawmc_x_loop
        jmp  _drawmc_ram_out

_drawmc_y:
      lda  {ZP_B0}
      bne  _drawmc_y_init
      jmp  _drawmc_ram_out

_drawmc_y_init:
      sta  {ZP_W2}
      lsr
      sta  {ZP_I0}
_drawmc_y_loop:
      lda  {ZP_B2}
      bmi  _drawmc_y_up

_drawmc_y_down:
      iny
      cpy  #8
      bcc  _drawmc_y_add_dx
      ldy  #0
      lda  {ZP_W0}
      adc  #$3F
      sta  {ZP_W0}
      lda  {ZP_W0}+1
      adc  #$01
      bcc  _drawmc_y_store_base

_drawmc_y_up:
      dey
      bpl  _drawmc_y_add_dx
      ldy  #7
      sec
      lda  {ZP_W0}
      sbc  #$40
      sta  {ZP_W0}
      lda  {ZP_W0}+1
      sbc  #$01
_drawmc_y_store_base:
      sta  {ZP_W0}+1

_drawmc_y_add_dx:
      ldx  #0
      lda  {ZP_I0}
      clc
      adc  {ZP_W1}
      sta  {ZP_I0}
      bcs  _drawmc_y_sub_dy
      inx
      sec

_drawmc_y_sub_dy:
      sbc  {ZP_B0}
      bcs  _drawmc_y_distance
      dex
      beq  _drawmc_y_plot

_drawmc_y_distance:
      sta  {ZP_I0}

      lda  {ZP_B1}
      bmi  _drawmc_y_left

_drawmc_y_right
      lsr  {ZP_B4}
      ror  {ZP_B4}
      bcc  _drawmc_y_plot
      ror  {ZP_B4}
      lda  {ZP_W0}
      adc  #8
      sta  {ZP_W0}
      bcc  _drawmc_y_plot
      inc  {ZP_W0}+1
      bne  _drawmc_y_plot

_drawmc_y_left:
      asl  {ZP_B4}
      rol  {ZP_B4}
      bcc  _drawmc_y_plot
      rol  {ZP_B4}
      sec
      lda  {ZP_W0}
      sbc  #8
      sta  {ZP_W0}
      bcs  _drawmc_y_plot
      dec  {ZP_W0}+1

_drawmc_y_plot:
      lda  {ZP_B4}
      and  {ZP_B3}
      sta  {ZP_B5}
      lda  {ZP_B4}
      eor  #$FF
      and  ({ZP_W0}),y
      ora  {ZP_B5}
      sta  ({ZP_W0}),y

      dec  {ZP_W2}
      bne  _drawmc_y_loop

_drawmc_ram_out:
        inc 1
        inc 1
        cli
_drawmc_end:
    END ASM
END SUB

SUB _calc_bitmap_table() STATIC
    ASM
        lda $d018           ; bitmap memory
        and #%00001000
        asl
        asl
        sta {ZP_W0}+1

        lda $dd00           ; vic bank
        and #%00000011
        eor #%00000011
        lsr
        ror
        ror
        ora {ZP_W0}+1
        sta {ZP_W0}+1       ; bank + bitmap memory

        ldy #0
        sty {ZP_W0}
_calc_table_bitmap_loop
        lda {ZP_W0}
        sta {_bitmap_y_tbl},y
        iny
        lda {ZP_W0}+1
        sta {_bitmap_y_tbl},y
        iny

_calc_table_bitmap_add_320
        clc
        lda {ZP_W0}
        adc #$40
        sta {ZP_W0}

        lda {ZP_W0}+1
        adc #$1
        sta {ZP_W0}+1

        cpy #50
        bne _calc_table_bitmap_loop
    END ASM
END SUB

SUB _calc_screen_table() STATIC
    ASM
        lda $d018           ; bitmap memory
        and #%11110000
        lsr
        lsr
        sta {ZP_W0}+1

        lda $dd00           ; vic bank
        and #%00000011
        eor #%00000011
        lsr
        ror
        ror
        ora {ZP_W0}+1
        sta {ZP_W0}+1       ; bank + bitmap memory

        ldy #0
        sty {ZP_W0}
_calc_table_screen_loop
        lda {ZP_W0}+1
        sta {_screen_y_tbl_hi},y
        lda {ZP_W0}
        sta {_screen_y_tbl_lo},y

        clc
        adc #40
        sta {ZP_W0}

        lda {ZP_W0}+1
        adc #0
        sta {ZP_W0}+1

        iny
        cpy #25
        bne _calc_table_screen_loop
    END ASM
END SUB

FUNCTION PetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC
    ASM
        ldx #$5e
        lda {Petscii}
        cmp #255
        beq _petscii_to_screencode_end
        lsr
        lsr
        lsr
        lsr
        lsr
        sty
        clc
        lda {_petscii_to_screencode},y
        adc {Petscii}
        tax
_petscii_to_screencode_end
        stx {PetsciiToScreenCode}
    END ASM
END FUNCTION

__color_y_tbl_hi:
DATA AS BYTE $d8, $d8, $d8, $d8, $d8, $d8, $d8, $d9, $d9, $d9, $d9, $d9, $d9, $da, $da, $da
DATA AS BYTE $da, $da, $da, $da, $db, $db, $db, $db, $db
__color_y_tbl_lo:
DATA AS BYTE $00, $28, $50, $78, $a0, $c8, $f0, $18, $40, $68, $90, $b8, $e0, $08, $30, $58
DATA AS BYTE $80, $a8, $d0, $f8, $20, $48, $70, $98, $c0

__hires_mask0:
DATA AS BYTE $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe
__hires_mask1:
DATA AS BYTE $80, $40, $20, $10, $08, $04, $02, $01

__mc_mask:
DATA AS BYTE $c0,$30,$0c,$03
__mc_pattern:
DATA AS BYTE %00000000, %01010101, %10101010, %11111111

__petscii_to_screencode:
DATA AS BYTE $80, $00, $c0, $e0, $40, $c0, $80, $80

__nible_to_byte:
DATA AS BYTE %00000000, %00000011, %00001100, %00001111
DATA AS BYTE %00110000, %00110011, %00111100, %00111111
DATA AS BYTE %11000000, %11000011, %11001100, %11001111
DATA AS BYTE %11110000, %11110011, %11111100, %11111111