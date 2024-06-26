ASM
    MAC OPEN_BANK3
        IFNCONST LIB_GFX_DISABLE_BANK_3
            sei
            lda #%00110100
            sta 1
        ENDIF
    ENDM

    MAC CLOSE_BANK3
        IFNCONST LIB_GFX_DISABLE_BANK_3
            lda #%00110110
            sta 1
            cli
        ENDIF
    ENDM

TRANSPARENT =  $fe
FLIP        =  $ff
END ASM

REM **********************
REM *     CONSTANTS      *
REM **********************
SHARED CONST STANDARD_CHARACTER_MODE        = %00000000
SHARED CONST MULTICOLOR_CHARACTER_MODE      = %00010000
SHARED CONST STANDARD_BITMAP_MODE           = %00100000
SHARED CONST MULTICOLOR_BITMAP_MODE         = %00110000
SHARED CONST EXTENDED_BACKGROUND_COLOR_MODE = %01000000
SHARED CONST INVALID_MODE                   = %01100000

SHARED CONST ROM_CHARSET_UPPERCASE = 0
SHARED CONST ROM_CHARSET_LOWERCASE = 1

SHARED CONST MODE_SET   = 1
SHARED CONST MODE_CLEAR = 0
SHARED CONST MODE_FLIP  = $ff

SHARED CONST MODE_TRANSPARENT = $fe

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

DIM _hdraw_end_mask(8) AS BYTE @__hdraw_end_mask
DIM _hdraw_start_mask(8) AS BYTE @__hdraw_start_mask

DIM _hdrawmc_end_mask(4) AS BYTE @__hdrawmc_end_mask
DIM _hdrawmc_start_mask(4) AS BYTE @__hdrawmc_start_mask

DIM _mc_mask(4) AS BYTE @__mc_mask
DIM _mc_pattern(4) AS BYTE @__mc_pattern

DIM _bitmap_y_tbl(50) AS WORD
DIM _screen_y_tbl(50) AS WORD

DIM _color_y_tbl_hi(25) AS BYTE @ __color_y_tbl_hi
DIM _color_y_tbl_lo(25) AS BYTE @ __color_y_tbl_lo

DIM _petscii_to_screencode(8) AS BYTE @ __petscii_to_screencode
DIM _nible_to_byte(16) AS BYTE @ __nible_to_byte
DIM _opcodes(3) AS BYTE @ __opcodes

DIM _dbuf_nr AS BYTE
_dbuf_nr = %00000000

DIM _dbuf_on AS BYTE
_dbuf_on = %00000000

DIM _dbuf_d018 AS BYTE
DIM _dbuf_dd00 AS BYTE

REM **********************
REM *  PSEUDO REGISTERS  *
REM **********************
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

REM **********************
REM *    DECLARATIONS    *
REM **********************
DECLARE SUB SetVideoBank(BankNumber AS BYTE) SHARED STATIC
DECLARE SUB SetGraphicsMode(Mode AS BYTE) SHARED STATIC
DECLARE SUB SetScreenMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB SetCharacterMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB SetBitmapMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB ResetScreen() SHARED STATIC
DECLARE SUB DoubleBufferOn() SHARED STATIC
DECLARE SUB DoubleBufferOff() SHARED STATIC
DECLARE SUB BufferSwap() SHARED STATIC
DECLARE SUB ScreenOff() SHARED STATIC
DECLARE SUB ScreenOn() SHARED STATIC

DECLARE SUB FillBitmap(Value AS BYTE) SHARED STATIC
DECLARE SUB FillColors(Color0 AS BYTE, Color1 AS BYTE) SHARED STATIC
DECLARE SUB FillColorsMC(Color0 AS BYTE, Color1 AS BYTE, Color2 AS BYTE, Color3 AS BYTE) SHARED STATIC
DECLARE SUB FillScreenMemory(Value AS BYTE) SHARED STATIC
DECLARE SUB FillColorMemory(Value AS BYTE) SHARED STATIC

DECLARE FUNCTION GetPixel AS BYTE(x AS WORD, y AS BYTE) SHARED STATIC
DECLARE FUNCTION GetPixelMC AS BYTE(x AS BYTE, y AS BYTE) SHARED STATIC
DECLARE SUB Plot(x AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB Draw(x0 AS WORD, y0 AS BYTE, x1 AS WORD, y1 AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB DrawMC(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB HDraw(x0 AS WORD, x1 AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB HDrawMC(x0 AS BYTE, x1 AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB VDraw(x AS WORD, y0 AS BYTE, y1 AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB VDrawMC(x AS BYTE, y0 AS BYTE, y1 AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB Rect(x0 AS WORD, y0 AS BYTE, x1 AS WORD, y1 AS BYTE, Mode AS BYTE, FillMode AS BYTE) SHARED STATIC
DECLARE SUB RectMC(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE, Fill AS BYTE) SHARED STATIC
DECLARE SUB Circle(x0 AS WORD, y0 AS BYTE, Radius AS BYTE, Mode AS BYTE, BgMode AS BYTE) SHARED STATIC
DECLARE SUB CircleMC(x0 AS BYTE, y0 AS BYTE, Radius AS BYTE, Ink AS BYTE, FillInk AS BYTE) SHARED STATIC

DECLARE SUB CopyCharROM(CharSet AS BYTE, DestAddr AS WORD) SHARED STATIC
DECLARE SUB TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Double AS BYTE, Text AS STRING * 40, RomCharSet AS BYTE) SHARED STATIC OVERLOAD
DECLARE SUB TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Double AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD) SHARED STATIC OVERLOAD
DECLARE SUB Text(Col AS BYTE, Row AS BYTE, Mode AS BYTE, BgMode AS BYTE, Double AS BYTE, Text AS STRING * 40, RomCharSet AS BYTE) SHARED STATIC OVERLOAD
DECLARE SUB Text(Col AS BYTE, Row AS BYTE, Mode AS BYTE, BgMode AS BYTE, Double AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD) SHARED STATIC OVERLOAD
DECLARE SUB SetColorInRect(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE, ColorId AS BYTE) SHARED STATIC
DECLARE SUB WaitRasterLine256() SHARED STATIC
DECLARE FUNCTION PetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC

DECLARE SUB _calc_bitmap_table() STATIC
DECLARE SUB _calc_screen_table() STATIC

REM **********************
REM *     FUNCTIONS      *
REM **********************
SUB RectMC(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE, Fill AS BYTE) SHARED STATIC
    IF Ink <> MODE_TRANSPARENT THEN
        CALL HDrawMC(x0, x1, y0, Ink)
        CALL HDrawMC(x0, x1, y1, Ink)
        CALL VDrawMC(x0, y0, y1, Ink)
        CALL VDrawMC(x1, y0, y1, Ink)
    END IF

    IF Fill <> MODE_TRANSPARENT THEN
        ASM
            inc {x0}
            dec {x1}
            inc {y0}
            dec {y1}
        END ASM
        FOR Y AS BYTE = y0 TO y1
            CALL HDrawMC(x0, x1, Y, Fill)
        NEXT Y
    END IF
END SUB

SUB Rect(x0 AS WORD, y0 AS BYTE, x1 AS WORD, y1 AS BYTE, Mode AS BYTE, FillMode AS BYTE) SHARED STATIC
    IF Mode <> MODE_TRANSPARENT THEN
        CALL HDraw(x0, x1, y0, Mode)
        CALL HDraw(x0, x1, y1, Mode)
        CALL VDraw(x0, y0, y1, Mode)
        CALL VDraw(x1, y0, y1, Mode)
    END IF

    IF FillMode <> MODE_TRANSPARENT THEN
        ASM
            inc {x0}
            bne _rect_no_inc
                inc {x0}+1
_rect_no_inc

            lda {x1}
            bne _rect_no_dec
                dec {x1}+1
_rect_no_dec
            dec {x1}

            inc {y0}
            dec {y1}
        END ASM
        FOR Y AS BYTE = y0 TO y1
            CALL HDraw(x0, x1, Y, FillMode)
        NEXT Y
    END IF
END SUB

SUB FillBitmap(Value AS BYTE) SHARED STATIC
    ASM
        OPEN_BANK3

        lda {_dbuf_nr}
        eor {_dbuf_on}
        bne _clear_buffer_choose1

_clear_buffer_choose0
        lda {Value}
        jsr _clear_buffer0
        jmp _clear_buffer_end

_clear_buffer_choose1
        lda {Value}
        jsr _clear_buffer1

_clear_buffer_end
        CLOSE_BANK3
    END ASM
END SUB

SUB DoubleBufferOn() SHARED STATIC
    ASM
        ;lda $d018
        ;sta {_dbuf_d018}

        ;lda $dd00
        ;sta {_dbuf_dd00}

        lda #%00000010
        sta {_dbuf_on}
    END ASM
END SUB

SUB DoubleBufferOff() SHARED STATIC
    _dbuf_on = %00000000
    IF _dbuf_nr = %00000010 THEN
        CALL BufferSwap()
    END IF
END SUB

SUB BufferSwap() SHARED STATIC
    ASM
swap_wait1
        bit $d011
        bmi swap_wait1
swap_wait2
        bit $d011
        bpl swap_wait2

        ldx $d018
        lda {_dbuf_d018}
        stx {_dbuf_d018}
        sta $d018

        ldx $dd00
        lda {_dbuf_dd00}
        stx {_dbuf_dd00}
        sta $dd00

        lda {_dbuf_nr}
        eor #%00000010
        sta {_dbuf_nr}
    END ASM
END SUB

SUB WaitRasterLine256() SHARED STATIC
    ASM
wait1:  bit $d011
        bmi wait1
wait2:  bit $d011
        bpl wait2
    END ASM
END SUB

SUB ScreenOff() SHARED STATIC
    ASM
        lda $d011
        and #%01101111
        sta $d011
    END ASM
END SUB

SUB ScreenOn() SHARED STATIC
    ASM
        lda $d011
        and #%01111111
        ora #%00010000
        sta $d011
    END ASM
END SUB

SUB TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Double AS BYTE, Text AS STRING * 40, RomCharSet AS BYTE) SHARED STATIC OVERLOAD
    CALL TextMC(Col, Row, Ink, Bg, Double, Text, CWORD(RomCharSet))
END SUB

SUB TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Double AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD) SHARED STATIC OVERLOAD
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
        sei             ; access ROM characters
        lda #%00110001
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
        OPEN_BANK3

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
        asl
        eor {_dbuf_nr}
        eor {_dbuf_on}
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
        jmp _mc_text_end
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
        bpl _mc_text_font_loop_left_bg
        lda ({ZP_W0}),y
        sta {ZP_B5}

_mc_text_font_loop_left_bg
        ;choose background
        ldx {Bg}
        bpl _mc_text_char_sx_or_dx
        lda ({ZP_W0}),y
        sta {ZP_B4}

_mc_text_char_sx_or_dx
        lda {Double}
        bne _mc_text_font_loop_left_nible

_mc_text_char_single
        lda ({ZP_W1}),y
        tax

        and #%01100000
        beq _mc_text_char_shrink0
        lda #%00110000
_mc_text_char_shrink0
        sta {ZP_B2}

        txa
        and #%00011000
        beq _mc_text_char_shrink1
        lda #%00001100
_mc_text_char_shrink1
        ora {ZP_B2}
        sta {ZP_B2}

        txa
        and #%00000110
        beq _mc_text_char_shrink2
        lda #%00000011
_mc_text_char_shrink2
        ora {ZP_B2}
        sta {ZP_B2}

        eor #$ff
        and {ZP_B4}
        sta {ZP_B3}

        lda {ZP_B5}
        and {ZP_B2}
        ora {ZP_B3}
        sta ({ZP_W0}),y

        dey
        bpl mc_text_font_loop

        ;next char
        clc
        lda {ZP_W0}
        adc #8
        sta {ZP_W0}
        bcc mc_text_char_next
        inc {ZP_W0}+1
mc_text_char_next
        jmp mc_text_loop_text

_mc_text_font_loop_left_nible
        ;lda ({ZP_W0}),y
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
        bpl _mc_text_font_loop_right_bg
        lda ({ZP_W0}),y
        sta {ZP_B5}

_mc_text_font_loop_right_bg
        ;choose background
        ldx {Bg}
        bpl _mc_text_font_loop_store_right_nible
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
        bmi _mc_text_char_double_next
        jmp mc_text_font_loop

_mc_text_char_double_next
        ;next char
        clc
        lda {ZP_W0}
        adc #16
        sta {ZP_W0}
        bcc _mc_text_next_char
        inc {ZP_W0}+1
_mc_text_next_char
        jmp mc_text_loop_text
_mc_text_end
        lda #%00110110      ; Disable ROM characters (or bank3 access)
        sta 1
        cli
    END ASM
END SUB

SUB Text(Col AS BYTE, Row AS BYTE, Mode AS BYTE, BgMode AS BYTE, Double AS BYTE, Text AS STRING * 40, RomCharSet AS BYTE) SHARED STATIC OVERLOAD
    CALL Text(Col, Row, Mode, BgMode, Double, Text, CWORD(RomCharSet))
END SUB

SUB Text(Col AS BYTE, Row AS BYTE, Mode AS BYTE, BgMode AS BYTE, Double AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD) SHARED STATIC OVERLOAD
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
        bne _text_ram
        lda {CharMemAddr}
        cmp #2
        bcs _text_ram

_text_rom
        sei             ; access ROM characters
        lda #%00110001
        sta 1

        ldx #$d8
        lda {CharMemAddr}
        bne _text_rom1
        ldx #$d0
_text_rom1
        stx {CharMemAddr}+1

        lda #0
        sta {CharMemAddr}

        jmp _text_init

_text_ram
        OPEN_BANK3

_text_init
        ;init bitmap pointer
        lda {Row}
        asl
        asl
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tay
        lda {_bitmap_y_tbl},y
        sta {ZP_W0}
        lda {_bitmap_y_tbl}+1,y
        sta {ZP_W0}+1

        lda {Col}
        asl
        asl
        asl
        bcc text_add_col_to_base
        inc {ZP_W0}+1
        clc
text_add_col_to_base
        adc {ZP_W0}
        sta {ZP_W0}
        bcc _text_init_text_pointer
        inc {ZP_W0}+1

_text_init_text_pointer
        ;init text pointer
        lda #0
        sta {ZP_B0}

text_loop_text
        ldy {ZP_B0}
        cpy {Text}
        bne text_loop_read_char
        jmp text_end
text_loop_read_char
        iny
        sty {ZP_B0}

        ;petscii to screen code
        lda {Text},y
        ldx #$5e
        cmp #255
        beq _text_init_font_base
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

_text_init_font_base
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
text_font_loop
        lda {Double}
        bne _text_char_loop_double

_text_char_single
        lda ({ZP_W1}),y
        sta {ZP_B2}
        lda {Mode}
        jsr _text_pen_and_paper
        sta {ZP_B5}

        lda {ZP_B2}
        eor #$ff
        sta {ZP_B2}
        lda {BgMode}
        jsr _text_pen_and_paper

_text_char_single_combine
        ora {ZP_B5}
        sta ({ZP_W0}),y

        dey
        bpl text_font_loop

        ;next char
        clc
        lda {ZP_W0}
        adc #8
        sta {ZP_W0}
        bcc text_char_next
        inc {ZP_W0}+1
text_char_next
        jmp text_loop_text

_text_char_loop_double
        ;lda ({ZP_W0}),y
        ;process left nible
        lda ({ZP_W1}),y
        lsr
        lsr
        lsr
        lsr
        tax
        lda {_nible_to_byte},x
        sta {ZP_B2}

_text_char_left
        jsr _text_double_pen_and_paper

_text_char_left_combine
        ora {ZP_B5}
        sta ({ZP_W0}),y

_text_char_right
        lda ({ZP_W1}),y
        and #%00001111
        tax
        lda {_nible_to_byte},x
        sta {ZP_B2}

        tya
        eor #%00001000
        tay

        jsr _text_double_pen_and_paper

_text_char_right_combine
        ora {ZP_B5}
        sta ({ZP_W0}),y


        tya
        eor #%00001000
        tay
        dey
        bmi text_char_double_next
        jmp text_font_loop

text_char_double_next
        ;next char
        clc
        lda {ZP_W0}
        adc #16
        sta {ZP_W0}
        bcc text_next_char
        inc {ZP_W0}+1
text_next_char
        jmp text_loop_text

_text_double_pen_and_paper
        lda {Mode}
        jsr _text_pen_and_paper
        sta {ZP_B5}

        lda {ZP_B2}
        eor #$ff
        sta {ZP_B2}
        lda {BgMode}

_text_pen_and_paper
        beq _text_pen_and_paper_clr
        bpl _text_pen_and_paper_set

_text_char_single_transparent
        lda {ZP_B2}
        and ({ZP_W0}),y
        .byte $2c
_text_pen_and_paper_clr
        lda #0
        .byte $2c
_text_pen_and_paper_set
        lda {ZP_B2}
        rts

text_end
        lda #%00110110          ; Disable ROM characters (or bank3 access)
        sta 1
        cli
    END ASM
END SUB

SUB CopyCharROM(CharSet AS BYTE, DestAddr AS WORD) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        sei                 ; access ROM characters
        lda #%00110001
        sta 1
    END ASM
    IF CharSet THEN
        MEMCPY $d800, DestAddr, 2048
    ELSE
        MEMCPY $d000, DestAddr, 2048
    END IF
    ASM
        lda #%00110110      ; Disable ROM characters
        sta 1
        cli
    END ASM
END SUB

SUB SetColorInRect(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE, ColorId AS BYTE) SHARED STATIC
    ASM
        lda {x1}
        cmp {x0}
        bcs _setcolorinrect_sorty
        ldx {x0}
        stx {x1}
        sta {x0}

_setcolorinrect_sorty
        lda {y1}
        cmp {y0}
        bcs _setcolorinrect_init
        ldx {y0}
        stx {y1}
        sta {y0}

_setcolorinrect_init
        lda {ColorId}
        sta {ZP_B2}

        ldy {Ink}
        lda $d016
        and #%00010000
        bne *+3
            iny

        cpy #3
        beq _set_color_mc_3

        OPEN_BANK3

        lda {y0}
        asl
        asl
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax
        lda {_screen_y_tbl}+1,x
        sta {ZP_W0}+1
        lda {_screen_y_tbl},x
        sta {ZP_W0}

        cpy #2
        beq _set_color_mc_2

_set_color_mc_1
        lda #%00001111
        sta {ZP_B3}
        lda {ZP_B2}
        asl
        asl
        asl
        asl
        sta {ZP_B2}
        jmp _set_color_init_loops

_set_color_mc_2
        lda #%11110000
        sta {ZP_B3}
        jmp _set_color_init_loops

_set_color_mc_3
        lda #0
        sta {ZP_B3}

        ldx {y0}
        lda {_color_y_tbl_lo},x
        sta {ZP_W0}
        lda {_color_y_tbl_hi},x
        sta {ZP_W0}+1

_set_color_init_loops
        sec
        lda {y1}
        sbc {y0}
        tax

_set_color_y_loop
        ldy {x0}

_set_color_x_loop
        lda ({ZP_W0}),y
        and {ZP_B3}
        ora {ZP_B2}
        sta ({ZP_W0}),y

        iny
        cpy {x1}
        bcc _set_color_x_loop
        beq _set_color_x_loop

        clc
        lda #40
        adc {ZP_W0}
        sta {ZP_W0}

        bcc *+4
            inc {ZP_W0}+1

        dex
        bpl _set_color_y_loop

        CLOSE_BANK3
    END ASM
END SUB

SUB FillColors(Color0 AS BYTE, Color1 AS BYTE) SHARED STATIC
    ASM
        lda {Color1}
        asl
        asl
        asl
        asl
        ora {Color0}
        sta {ZP_B1}
    END ASM
    CALL FillScreenMemory(ZP_B1)
END SUB

SUB FillColorsMC(Color0 AS BYTE, Color1 AS BYTE, Color2 AS BYTE, Color3 AS BYTE) SHARED STATIC
    BACKGROUND Color0
    CALL FillColors(Color2, Color1)
    CALL FillColorMemory(Color3)
END SUB

SUB FillColorMemory(Value AS BYTE) SHARED STATIC
    MEMSET $d800, 1000, Value
END SUB

SUB FillScreenMemory(Value AS BYTE) SHARED STATIC
    ASM
        lda {_dbuf_nr}
        eor {_dbuf_on}
        tax
        lda {_screen_y_tbl}+1,x
        sta {ZP_W0}+1
        lda {_screen_y_tbl},x
        sta {ZP_W0}

        OPEN_BANK3
    END ASM
    MEMSET ZP_W0, 1000, Value
    ASM
        CLOSE_BANK3
    END ASM
END SUB

SUB ResetScreen() SHARED STATIC
    CALL DoubleBufferOff()
    CALL SetVideoBank(0)
    CALL SetScreenMemory(1)
    CALL FillScreenMemory(32)
    CALL SetCharacterMemory(2)
    CALL SetGraphicsMode(STANDARD_CHARACTER_MODE)
    CALL FillColorMemory(COLOR_LIGHTBLUE)
    SCREEN 1
    BACKGROUND COLOR_BLUE
    BORDER COLOR_LIGHTBLUE
END SUB

SUB SetGraphicsMode(Mode AS BYTE) SHARED STATIC
    ' TEMP = ZP_B0
    ASM
        lda {Mode}
        and #%01100000
        sta {ZP_B0}

        lda $d011
        and #%00011111
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
        lda {_dbuf_on}
        beq _set_video_bank_single

_set_video_bank_double
        lda {_dbuf_dd00}
        and #%11111100
        ora {BankNumber}
        eor #%00000011
        sta {_dbuf_dd00}
        jmp _set_video_bank_end

_set_video_bank_single
        lda $dd00
        and #%11111100
        ora {BankNumber}
        eor #%00000011
        sta $dd00

_set_video_bank_end
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

        lda {_dbuf_on}
        beq _set_character_memory_single

_set_character_memory_double
        lda {_dbuf_d018}
        and #%11110001
        ora {ZP_B0}
        sta {_dbuf_d018}
        jmp _set_character_memory_end

_set_character_memory_single
        lda $d018
        and #%11110001
        ora {ZP_B0}
        sta $d018

_set_character_memory_end
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

        lda {_dbuf_on}
        beq _set_screen_memory_single

_set_screen_memory_double
        lda {_dbuf_d018}
        and #%00001111
        ora {ZP_B0}
        sta {_dbuf_d018}
        jmp _set_screen_memory_end

_set_screen_memory_single
        lda $d018
        and #%00001111
        ora {ZP_B0}
        sta $d018

_set_screen_memory_end
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

        lda {_dbuf_on}
        beq _set_bitmap_memory_single

_set_bitmap_memory_double
        lda {_dbuf_d018}
        and #%11110111
        ora {ZP_B0}
        sta {_dbuf_d018}
        jmp _set_bitmap_memory_end

_set_bitmap_memory_single
        lda $d018
        and #%11110111
        ora {ZP_B0}
        sta $d018

_set_bitmap_memory_end
    END ASM
    CALL _calc_bitmap_table()
END SUB

SUB CircleMC(x0 AS BYTE, y0 AS BYTE, Radius AS BYTE, Ink AS BYTE, FillInk AS BYTE) SHARED STATIC
    ' DISTANCE = ZP_I0
    ' X = ZP_B1,
    ' Y = ZP_B2
    DIM x AS BYTE
    DIM y AS BYTE
    DIM hx AS BYTE
    DIM hy AS BYTE
    DIM x_prev AS BYTE
    x = Radius
    y = 0
    ZP_I0 = SHR(Radius, 1)

    DO
        y = y + 1
        ZP_I0 = ZP_I0 - y
        IF ZP_I0 < 0 THEN x = x - 1: ZP_I0 = ZP_I0 + x

        hx = SHR(x, 1) 'x
        hy = SHR(y, 1) 'y

        IF FillInk <> MODE_TRANSPARENT THEN
            CALL HDrawMC(x0-hx+1, x0+hx-1, y0-y, FillInk)
            CALL HDrawMC(x0-hx+1, x0+hx-1, y0+y, FillInk)
            IF x <> x_prev THEN
                CALL HDrawMC(x0-hy+1, x0+hy-1, y0-x, FillInk)
                CALL HDrawMC(x0-hy+1, x0+hy-1, y0+x, FillInk)
            END IF
            x_prev = x
        END IF

        IF Ink <> MODE_TRANSPARENT THEN
            CALL PlotMC(x0+hx, y0+y, Ink)
            CALL PlotMC(x0+hx, y0-y, Ink)
            CALL PlotMC(x0-hx, y0+y, Ink)
            CALL PlotMC(x0-hx, y0-y, Ink)
            CALL PlotMC(x0+hy, y0+x, Ink)
            CALL PlotMC(x0+hy, y0-x, Ink)
            CALL PlotMC(x0-hy, y0+x, Ink)
            CALL PlotMC(x0-hy, y0-x, Ink)
        END IF
    LOOP UNTIL x <= y

    IF FillInk <> MODE_TRANSPARENT THEN
        CALL HDrawMC(x0-SHR(Radius, 1)+1, x0+SHR(Radius, 1)-1, y0, FillInk)
    END IF
    CALL PlotMC(x0+SHR(Radius, 1), y0, Ink)
    CALL PlotMC(x0-SHR(Radius, 1), y0, Ink)
    CALL PlotMC(x0, y0+Radius, Ink)
    CALL PlotMC(x0, y0-Radius, Ink)
END SUB

SUB Circle(x0 AS WORD, y0 AS BYTE, Radius AS BYTE, Mode AS BYTE, BgMode AS BYTE) SHARED STATIC
    ' DISTANCE = ZP_I0
    ' ZP_W1 = x
    ' ZP_B0 = y
    ' ZP_I0 = error distance
    '
    DIM x AS BYTE
    DIM y AS BYTE
    DIM x_prev AS BYTE

    x = Radius
    y = 0
    ZP_I0 = SHR(Radius, 1)

    DO
        y = y + 1
        ZP_I0 = ZP_I0 - y
        IF ZP_I0 < 0 THEN x = x - 1: ZP_I0 = ZP_I0 + x

        IF BgMode <> MODE_TRANSPARENT THEN
            CALL HDraw(x0-x+1, x0+x-1, y0-y, BgMode)
            CALL HDraw(x0-x+1, x0+x-1, y0+y, BgMode)
            IF x <> x_prev AND x > y THEN
                CALL HDraw(x0-y+1, x0+y-1, y0-x, BgMode)
                CALL HDraw(x0-y+1, x0+y-1, y0+x, BgMode)
            END IF
            x_prev = x
        END IF

        CALL Plot(x0+x, y0+y, Mode)
        CALL Plot(x0+x, y0-y, Mode)
        CALL Plot(x0-x, y0+y, Mode)
        CALL Plot(x0-x, y0-y, Mode)
        CALL Plot(x0+y, y0+x, Mode)
        CALL Plot(x0+y, y0-x, Mode)
        CALL Plot(x0-y, y0+x, Mode)
        CALL Plot(x0-y, y0-x, Mode)
    LOOP UNTIL x <= y

    IF BgMode <> MODE_TRANSPARENT THEN
        CALL HDraw(x0 - Radius+1, x0+Radius-1, y0, BgMode)
    END IF
    CALL Plot(x0 + Radius, y0, Mode)
    CALL Plot(x0 - Radius, y0, Mode)
    CALL Plot(x0, y0 + Radius, Mode)
    CALL Plot(x0, y0 - Radius, Mode)
END SUB

FUNCTION GetPixelColor AS BYTE(x as WORD, y AS BYTE) SHARED STATIC
    ' TODO
    IF (PEEK($d016) AND %00010000) THEN
        GetPixelColor = GetPixelMC(CBYTE(x), y)
    ELSE
        GetPixelColor = GetPixel(x, y) + 1
    END IF

    ASM
        lda {x}
        lsr
        lsr
        lsr
        tay

        lda {GetPixelColor}
        beq _getpixelcolor_0
        cmp #3
        beq _getpixelcolor_3

        lda {y}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda {_screen_y_tbl}+1,x
        sta {ZP_W0}+1
        lda {_screen_y_tbl},x
        sta {ZP_W0}

        lda {GetPixelColor}
        cmp #1
        beq _getpixelcolor_1

_getpixelcolor_2
        lda ({ZP_W0}),y
        and #%00001111

        jmp _getpixelcolor_return

_getpixelcolor_2
        lda ({ZP_W0}),y
        lsr
        lsr
        lsr
        lsr

        jmp _getpixelcolor_return

_getpixelcolor_3
        lda {y}
        lsr
        lsr
        lsr
        tax
        lda {_color_y_tbl_hi},x
        sta {ZP_W0}+1
        lda {_color_y_tbl_lo},x
        sta {ZP_W0}
        lda ({ZP_W0}),y
        and #%00001111
        jmp _getpixelcolor_return

_getpixelcolor_0
        lda #$d021

_getpixelcolor_return
        sta {GetPixelColor}
    END ASM
END FUNCTION

FUNCTION GetPixel AS BYTE(x AS WORD, y AS BYTE) SHARED STATIC
    ASM
        lda {y}
        and #7
        sta {ZP_B5}

        eor {y}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda  {_bitmap_y_tbl}+1,x
        adc {x}+1
        sta {ZP_W0}+1
        lda {_bitmap_y_tbl},x
        sta {ZP_W0}

        lda {x}
        and #7
        tax

        eor {x}
        ora {ZP_B5}
        tay

        OPEN_BANK3

        lda {_hires_mask1},x
        ldx #1
        and ({ZP_W0}),y
        bne *+4
            ldx #$00

        CLOSE_BANK3

        stx {GetPixel}
    END ASM
END FUNCTION

SUB Plot(x AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
    ASM
_plot_init
        lda {y}
        and #7
        sta {ZP_B5}

        eor {y}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda  {_bitmap_y_tbl}+1,x
        adc {x}+1
        sta {ZP_W0}+1
        lda {_bitmap_y_tbl},x
        sta {ZP_W0}

        lda {x}
        and #7
        tax

        eor {x}
        ora {ZP_B5}
        tay

_plot_ram_in
        OPEN_BANK3

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
        CLOSE_BANK3
_plot_end
    END ASM
END SUB

SUB HDrawMC(x0 AS BYTE, x1 AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
    ' B0 min(x0,x1)
    ' B1 max(x0,x1)
    ' B2 (B1>>2) - (B0>>2)
    ' B3 Mask
    ' B4 Ink pattern
    ' B5 Mask & Ink pattern
    ASM
        lda {x0}
        cmp {x1}
        bcs _hdrawmc_start_x1

_hdrawmc_start_x0
        sta {ZP_B0}
        lda {x1}
        sta {ZP_B1}
        jmp _hdrawmc_base

_hdrawmc_start_x1
        sta {ZP_B1}
        lda {x1}
        sta {ZP_B0}

_hdrawmc_base
        lda #0
        sta {ZP_W0}+1

        lda {y}
        and #7
        sta {ZP_W0}

        eor {y}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda {ZP_B0}
        and #%11111100
        asl
        rol {ZP_W0}+1
        ora {ZP_W0}
        clc
        adc {_bitmap_y_tbl},x
        sta {ZP_W0}
        lda {ZP_W0}+1
        adc {_bitmap_y_tbl}+1,x
        sta {ZP_W0}+1

_hdrawmc_dx
        lda {ZP_B0}
        lsr
        lsr
        sta {ZP_B2}
        lda {ZP_B1}
        lsr
        lsr
        sec
        sbc {ZP_B2}
        sta {ZP_B2}

_hdrawmc_ink_pattern
        ldx {Ink}
        lda {_mc_pattern},x
        sta {ZP_B4} ;pattern

_hdrawmc_start_byte
        OPEN_BANK3

        ldy #0
        lda {ZP_B0}
        and #%00000011
        tax
        lda {_hdrawmc_start_mask},x
        sta {ZP_B3} ;mask

        ldx {ZP_B2} ;dx
        beq _hdrawmc_end_byte

        and {ZP_B4}
        sta {ZP_B5} ;pattern & mask

        lda {ZP_B3}
        eor #$ff
        and ({ZP_W0}),y

        ora {ZP_B5}
        sta ({ZP_W0}),y

        lda #$ff
        sta {ZP_B3}

_hdrawmc_loop
        tya                 ; 2
        clc                 ; 2
        adc #8              ; 3
        bcc *+4             ; 3/4
            inc {ZP_W0}+1   ; 5
        tay                 ; 2 -> 12/18

        dex
        beq _hdrawmc_end_byte

        lda {ZP_B4}
        sta ({ZP_W0}),y

        jmp _hdrawmc_loop

_hdrawmc_end_byte
        lda {ZP_B1}
        and #%00000011
        tax
        lda {_hdrawmc_end_mask},x
        and {ZP_B3} ;mask & endmask
        sta {ZP_B3}

        and {ZP_B4} ;pattern & mask & endmask
        sta {ZP_B5}

        lda {ZP_B3}
        eor #$ff
        and ({ZP_W0}),y

        ora {ZP_B5}
        sta ({ZP_W0}),y

        CLOSE_BANK3
    END ASM
END SUB

SUB VDrawMC(x AS BYTE, y0 AS BYTE, y1 AS BYTE, Ink AS BYTE) SHARED STATIC
    ASM
_vdrawmc_init
        lda {y0}
        cmp {y1}
        bcs _vdrawmc_start_y1

_vdrawmc_start_y0
        sta {ZP_B0}
        lda {y1}
        sta {ZP_B1}

        jmp _vdrawmc_base

_vdrawmc_start_y1
        sta {ZP_B1}
        lda {y1}
        sta {ZP_B0}

_vdrawmc_base
        lda #0
        sta {ZP_W0}+1

        lda {ZP_B0}         ; 4
        and #7              ; 2
        sta {ZP_B5}         ; 2

        eor {ZP_B0}         ; 3
        lsr                 ; 2
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax                 ; 2

        lda  {x}
        and  #$FC
        asl
        rol  {ZP_W0}+1
        ora {ZP_B5}
        adc  {_bitmap_y_tbl},x
        sta  {ZP_W0}

        lda  {_bitmap_y_tbl}+1,x
        adc  {ZP_W0}+1
        sta  {ZP_W0}+1

        lda {ZP_W0}
        sec
        sbc {ZP_B0}
        sta {ZP_W0}
        bcs *+4
            dec {ZP_W0}+1

_vdrawmc_mask
        lda {x}
        and #3
        tax
        lda {_mc_mask},x
        eor #$ff
        sta {ZP_B4}
        eor #$ff

_vdrawmc_ink
        ldx {Ink}
        and {_mc_pattern},x
        sta {ZP_B5}

_vdrawmc_ram_in
        OPEN_BANK3

        ldy {ZP_B0}
_vdrawmc_loop
        lda  {ZP_B4}
        and  ({ZP_W0}),y
        ora  {ZP_B5}
        sta  ({ZP_W0}),y

        cpy {ZP_B1}
        beq _vdrawmc_end

        iny
        tya
        and #%00000111
        bne _vdrawmc_loop

        lda {ZP_W0}
        clc
        adc #$38
        sta {ZP_W0}
        lda {ZP_W0}+1
        adc #1
        sta {ZP_W0}+1

        jmp _vdrawmc_loop

_vdrawmc_end
        CLOSE_BANK3

    END ASM
END SUB

SUB VDraw(x AS WORD, y0 AS BYTE, y1 AS BYTE, Mode AS BYTE) SHARED STATIC
    ' ZP_W0: Base
    ' ZP_B0: dy
    ' ZP_B1: y1
    ' ZP_B5: x and %11111000
    ASM
_vdraw_ram_in
        OPEN_BANK3

_vdraw_smc_init
        lda {Mode}
        beq _vdraw_smc_init_clear
        bpl _vdraw_smc_init_set
_vdraw_smc_init_flip
        lda #$24            ; -> bit <- #$ff
        sta _vdraw_smc0
        lda #$51            ; -> eor <- ($af),y
        sta _vdraw_smc1
        jmp _vdraw_smc_init_end
_vdraw_smc_init_clear
        lda #$49            ; -> eor <- #$ff
        sta _vdraw_smc0
        lda #$31            ; -> and <- ($af),y
        sta _vdraw_smc1
        jmp _vdraw_smc_init_end
_vdraw_smc_init_set
        lda #$24            ; -> bit <- #$ff
        sta _vdraw_smc0
        lda #$11            ; -> ora <- ($af),y
        sta _vdraw_smc1
_vdraw_smc_init_end

_vdraw_init
        lda {y0}
        cmp {y1}
        bcs _vdraw_start_y1

_vdraw_start_y0
        sta {ZP_B0}
        lda {y1}
        sta {ZP_B1}

        jmp _vdraw_init_end

_vdraw_start_y1
        sta {ZP_B1}
        lda {y1}
        sta {ZP_B0}

_vdraw_init_end
        lda {ZP_B0}
        and #7              ; 2
        sta {ZP_B5}         ; 2

        eor {ZP_B0}         ; 4
        lsr                 ; 2
        eor {_dbuf_nr}      ; 4
        eor {_dbuf_on}      ; 4
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
        ora {ZP_B5}

        clc
        adc {ZP_W0}
        sta {ZP_W0}
        bcc *+4
            inc {ZP_W0}+1

        lda {ZP_W0}
        sec
        sbc {ZP_B0}
        sta {ZP_W0}
        bcs *+4
            dec {ZP_W0}+1

        lda {_hires_mask1},x
_vdraw_smc0
        bit $ff
        tax

        ldy {ZP_B0}
_vdraw_loop
        txa
_vdraw_smc1
        ora ({ZP_W0}),y
        sta ({ZP_W0}),y

        cpy {ZP_B1}
        beq _vdraw_end

        iny
        tya
        and #%00000111
        bne _vdraw_loop

        lda {ZP_W0}
        clc
        adc #$38
        sta {ZP_W0}
        lda {ZP_W0}+1
        adc #1
        sta {ZP_W0}+1

        jmp _vdraw_loop

_vdraw_end
        CLOSE_BANK3
    END ASM
END SUB

SUB HDraw(x0 AS WORD, x1 AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
    ' ZP_W0: Base
    ' ZP_B0: y & 7
    ' ZP_B1: x0
    ' ZP_B2: x1
    ' ZP_B3: Count
    ' ZP_B4: End Mask
    ASM
_hdraw_ram_in
        OPEN_BANK3

_hdraw_init
        ldx {Mode}
        inx

        lda _hdraw_mode_lo,x
        sta {ZP_W1}
        lda _hdraw_mode_hi,x
        sta {ZP_W1}+1

_hdraw_init_end
        lda {y}             ; 4
        and #7              ; 2
        sta {ZP_B0}         ; 2

        eor {y}             ; 4
        lsr                 ; 2
        eor {_dbuf_nr}      ; 4
        eor {_dbuf_on}      ; 4
        tax                 ; 2

        lda {_bitmap_y_tbl},x
        sta {ZP_W0}

        ; calculate DX
        lda {x0}+1
        ror
        lda {x0}
        sta {ZP_B1}
        ror
        lsr
        lsr
        sta {ZP_B4}

        lda {x1}+1
        ror
        lda {x1}
        sta {ZP_B2}
        ror
        lsr
        lsr

        sec
        sbc {ZP_B4}
        bcs _hdraw_start_x0

_hdraw_start_x1
        eor #$ff
        clc
        adc #1
        sta {ZP_B3}

        ; calc base hi
        lda  {_bitmap_y_tbl}+1,x
        clc
        adc {x1}+1
        sta {ZP_W0}+1

        ; store end mask
        lda {ZP_B1}
        and #%00000111
        tax
        lda {_hdraw_end_mask},x
        sta {ZP_B4}

        ; calc base offset
        lda {ZP_B2}
        and #%11111000
        ora {ZP_B0}
        tay

        lda {ZP_B2}

        jmp _hdraw_start_mask

_hdraw_start_x0
        sta {ZP_B3}

        ; calc base hi
        lda  {_bitmap_y_tbl}+1,x
        clc
        adc {x0}+1
        sta {ZP_W0}+1

        ; store end mask
        lda {ZP_B2}
        and #%00000111
        tax
        lda {_hdraw_end_mask},x
        sta {ZP_B4}

        ; calc base offset
        lda {ZP_B1}
        and #%11111000
        ora {ZP_B0}
        tay

        lda {ZP_B1}

_hdraw_start_mask
        ; load start mask
        and #7
        tax
        lda {_hdraw_start_mask},x

        ; load counter
        ldx {ZP_B3}
        bne _hdraw_start_loop

        and {ZP_B4}

_hdraw_start_loop
        ; draw byte
        jmp ({ZP_W1})

_hdraw_set
        ora ({ZP_W0}),y
        sta ({ZP_W0}),y

_hdraw_shared_loop
        ;addr += 8
        tya
        clc
        adc #8
        tay
        bcc *+4
            inc {ZP_W0}+1

        lda #$ff

        ;loop until addr = end
        dex
        bmi _hdraw_end
        bne *+4
            and {ZP_B4}
        jmp ({ZP_W1})

_hdraw_clear
        eor #$ff
        and ({ZP_W0}),y
        sta ({ZP_W0}),y

        jmp _hdraw_shared_loop

_hdraw_flip
        eor ({ZP_W0}),y
        sta ({ZP_W0}),y

        jmp _hdraw_shared_loop

_hdraw_mode_hi
        .byte #>_hdraw_flip, #>_hdraw_clear, #>_hdraw_set
_hdraw_mode_lo
        .byte #<_hdraw_flip, #<_hdraw_clear, #<_hdraw_set

_hdraw_end
        CLOSE_BANK3
    END ASM
END SUB


SUB Draw(x0 AS WORD, y0 AS BYTE, x1 AS WORD, y1 AS BYTE, Mode AS BYTE) SHARED STATIC
    ' ZP_W0: Base
    ' ZP_W1: Dx
    ' ZP_W2: Count
    ' ZP_I0: Error
    ' ZP_B0: Dy
    ' ZP_B1: Xi
    ' ZP_B2: Yi
    ' ZP_B4: Mask
    ' DX ZP_W1
    ASM
_draw_ram_in
        OPEN_BANK3

_draw_init
        lda {Mode}
        beq _draw_smc_init_clr
        bpl _draw_smc_init_set
_draw_smc_init_flip
        lda #$24            ; -> bit <- $ad
        sta _draw_smc0
        sta _draw_smc1
        sta _draw_smc2
        lda #$51            ; -> eor <- ($af),y
        sta _draw_smc0+2
        sta _draw_smc1+2
        sta _draw_smc2+2
        jmp _draw_smc_init_end
_draw_smc_init_clr
        lda #$49            ; -> eor <- #$ff
        sta _draw_smc0
        sta _draw_smc1
        sta _draw_smc2
        lda #$31            ; -> and <- ($af),y
        sta _draw_smc0+2
        sta _draw_smc1+2
        sta _draw_smc2+2
        jmp _draw_smc_init_end
_draw_smc_init_set
        lda #$24            ; -> bit <- $ad
        sta _draw_smc0
        sta _draw_smc1
        sta _draw_smc2
        lda #$11            ; -> ora <- ($af),y
        sta _draw_smc0+2
        sta _draw_smc1+2
        sta _draw_smc2+2    ; 29 cycles / 4 cycles
_draw_smc_init_end

        ldx #0              ;xinc=right
        ldy #0              ;yinc=down

_draw_dx
        lda {x1}            ;calculate dx=x1-x0
        sec
        sbc {x0}
        sta {ZP_W1}
        lda {x1}+1
        sbc {x0}+1
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
        lda {y1}            ;dy=y1-y0
        sec
        sbc {y0}
        bcs _draw_store_dy
        dey                 ;dy<0, yinc=up
        eor #$ff            ;dy=abs(dy)
        adc #1

_draw_store_dy
        sta {ZP_B0}

        stx {ZP_B1}         ;xi: $00 or $ff
        sty {ZP_B2}         ;y0: $00 or $ff

        lda {y0}            ;plot (x0, y0)
        and #%00000111
        tay

        eor {y0}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda {x0}
        and #%11111000
        adc {_bitmap_y_tbl},x
        sta {ZP_W0}         ;save base
        lda {_bitmap_y_tbl}+1,x
        adc {x0}+1
        sta {ZP_W0}+1

        lda {x0}
        and #%00000111
        tax
        lda {_hires_mask1},x    ; mc
        sta {ZP_B4}         ;save mask
_draw_smc0
        bit $ff
        ora ({ZP_W0}),y
        sta ({ZP_W0}),y

        lda {ZP_W1}+1           ; if dx>=dy: _draw_x else: _draw_y
        bne _draw_x
        lda {ZP_W1}
        cmp {ZP_B0}
        bcs _draw_x
        jmp _draw_y
_draw_x
        ;dx>=dy
        lda {ZP_W1}+1
        sta {ZP_W2}+1       ;c=dx
        lsr
        sta {ZP_I0}+1       ;r=dx/2 always 0, but must be stored anyway
        lda {ZP_W1}
        sta {ZP_W2}
        ror
        sta {ZP_I0}

        lda {ZP_W2}
        ora {ZP_W2}+1
        bne _draw_x_loop
        jmp _draw_ram_out             ;if single point

_draw_x_loop
        lda {ZP_B1}                     ;Xi
        bmi _draw_x_left

_draw_x_right
        lsr {ZP_B4}                     ; mask >>= 1
        bcc _draw_x_add_dy

        ror {ZP_B4}                     ; mask = %10000000
        lda {ZP_W0}
        adc #8
        sta {ZP_W0}
        bcc _draw_x_add_dy
        inc {ZP_W0}+1
        bne _draw_x_add_dy

_draw_x_left
        asl {ZP_B4}                     ; mask <<= 1
        bcc _draw_x_add_dy

        rol {ZP_B4}
        lda {ZP_W0}
        sbc #7
        sta {ZP_W0}
        bcs _draw_x_add_dy
        dec {ZP_W0}+1

_draw_x_add_dy
        lda {ZP_I0}                     ; Error += Dy
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
        bcc _draw_x_plot                ; if Error < Dx

        stx {ZP_I0}                     ; Error -= Dx
        sta {ZP_I0}+1

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
        lda {ZP_B4}
_draw_smc1
        bit $ff
        ora ({ZP_W0}),y
        sta ({ZP_W0}),y     ;plot (x,y) mc

        ldx {ZP_W2}
        bne _draw_dec_count_lo
        dec {ZP_W2}+1
        bne _draw_x_end
_draw_dec_count_lo
        dex
        stx {ZP_W2}
        bne _draw_x_loop
        ldx {ZP_W2}+1
        bne _draw_x_loop
_draw_x_end
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
        lda {ZP_B4}
_draw_smc2
        bit $ff
        ora ({ZP_W0}),y
        sta ({ZP_W0}),y     ;plot (x, y)

        dec {ZP_W2}
        bne _draw_y_loop            ;next

_draw_ram_out
        CLOSE_BANK3
    END ASM
END SUB

FUNCTION GetPixelMC AS BYTE(x AS BYTE, y AS BYTE) SHARED STATIC
    ' BASE = ZP_W0
    ASM
        lda #0
        sta {ZP_W0}+1

        lda {y}
        and #7
        tay

        eor {y}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda  {x}
        and  #$FC
        asl
        rol  {ZP_W0}+1
        adc  {_bitmap_y_tbl},x
        sta  {ZP_W0}

        lda  {_bitmap_y_tbl}+1,x
        adc  {ZP_W0}+1
        sta  {ZP_W0}+1

        lda {x}
        and #3
        tax

        OPEN_BANK3

        lda  ({ZP_W0}),y

        rol
_getpixelmc_loop
        rol
        rol
        dex
        bpl _getpixelmc_loop

        and #%11
        sta {GetPixelMC}

        CLOSE_BANK3
    END ASM
END FUNCTION

SUB PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
    ' BASE = ZP_W0
    ASM
_plotmc_init
        lda #0
        sta {ZP_W0}+1

        lda {y}
        and #7
        tay

        eor {y}
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

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
        sta {ZP_B5}

_plotmc_ram_in
        OPEN_BANK3

_plotmc_draw
        lda  {ZP_B4}
        eor  #$FF
        and  ({ZP_W0}),y
        ora  {ZP_B5}
        sta  ({ZP_W0}),y

_plotmc_ram_out:
        CLOSE_BANK3

_plotmc_end:
    END ASM
END SUB

SUB DrawMC(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE) SHARED STATIC
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
        OPEN_BANK3

_drawmc_init
        ldx  {Ink}
        lda  {_mc_pattern},x
        sta  {ZP_B3}

        ldx  #0
        ldy  #0
        sty {ZP_W0}+1
        sty {ZP_I0}+1

        lda  {x1}             ; dx = abs(x1 - x0)
        sec
        sbc  {x0}
        bcs  _drawmc_store_dx
        dex
        eor  #$FF
        adc  #1
_drawmc_store_dx:
        sta  {ZP_W1}

        lda  {y1}             ; dy = abs(y1 - y0)
        sec
        sbc  {y0}
        bcs  _drawmc_store_dy
        dey
        eor  #$FF
        adc  #1
_drawmc_store_dy:
        sta  {ZP_B0}

        stx  {ZP_B1}
        sty  {ZP_B2}

        lda  {y0}     ; y0 & %00000111
        and  #7
        tay

        eor  {y0}     ; (y0 & %11111000) << 2
        lsr
        eor {_dbuf_nr}
        eor {_dbuf_on}
        tax

        lda  {x0}
        and  #$FC
        asl
        rol  {ZP_W0}+1
        adc  {_bitmap_y_tbl},x
        sta  {ZP_W0}

        lda  {_bitmap_y_tbl}+1,x
        adc  {ZP_W0}+1
        sta  {ZP_W0}+1

        lda  {x0}
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
        CLOSE_BANK3
_drawmc_end:
    END ASM
END SUB

SUB _calc_bitmap_table() STATIC
    ASM
        lda #0
        sta {ZP_W0}

        lda {_dbuf_on}
        beq _calc_bitmap_table_single

_calc_bitmap_table_double
        lda {_dbuf_dd00}
        sta {ZP_B0}
        lda {_dbuf_d018}
        jmp _calc_bitmap_table_address

_calc_bitmap_table_single
        lda $dd00
        sta {ZP_B0}
        lda $d018

_calc_bitmap_table_address
        and #%00001000
        asl
        asl
        sta {ZP_W0}+1

        lda {ZP_B0}           ; vic bank
        and #%00000011
        eor #%00000011
        lsr
        ror
        ror
        ora {ZP_W0}+1
        sta {ZP_W0}+1       ; bank + bitmap memory

        lda {_dbuf_nr}
        eor {_dbuf_on}
        bne _calc_bitmap_buffer1
_calc_bitmap_buffer0
        jsr _update_buffer0_clear
        ldy #0
        jmp _calc_table_bitmap_loop

_calc_bitmap_buffer1
        jsr _update_buffer1_clear
        ldy #2

_calc_table_bitmap_loop
        lda {ZP_W0}+1
        sta {_bitmap_y_tbl}+1,y
        lda {ZP_W0}
        sta {_bitmap_y_tbl},y
        iny
        iny

_calc_table_bitmap_add_320
        clc
        adc #$40
        sta {ZP_W0}

        lda {ZP_W0}+1
        adc #$1
        sta {ZP_W0}+1

        iny
        iny

        cpy #100
        bcc _calc_table_bitmap_loop
    END ASM
END SUB

SUB _calc_screen_table() STATIC
    ASM
        lda #0
        sta {ZP_W0}

        lda {_dbuf_on}
        beq _calc_screen_table_single

_calc_screen_table_double
        lda {_dbuf_dd00}
        sta {ZP_B0}
        lda {_dbuf_d018}
        jmp _calc_screen_table_address

_calc_screen_table_single
        lda $dd00
        sta {ZP_B0}
        lda $d018

_calc_screen_table_address
        and #%11110000
        lsr
        lsr
        sta {ZP_W0}+1

        lda {ZP_B0}           ; vic bank
        and #%00000011
        eor #%00000011
        lsr
        ror
        ror
        ora {ZP_W0}+1
        sta {ZP_W0}+1       ; bank + bitmap memory

        lda {_dbuf_nr}
        ;eor #%00000010
        eor {_dbuf_on}
        tay
_calc_table_screen_loop
        lda {ZP_W0}+1
        sta {_screen_y_tbl}+1,y
        lda {ZP_W0}
        sta {_screen_y_tbl},y
        iny
        iny

        clc
        adc #40
        sta {ZP_W0}

        lda {ZP_W0}+1
        adc #0
        sta {ZP_W0}+1

        iny
        iny
        cpy #50
        bcc _calc_table_screen_loop
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

GOTO THE_END

__hdrawmc_start_mask:
DATA AS BYTE %11111111, %00111111, %00001111, %00000011
__hdrawmc_end_mask:
DATA AS BYTE %11000000, %11110000, %11111100, %11111111

__hdraw_start_mask:
DATA AS BYTE %11111111, %01111111, %00111111, %00011111, %00001111, %00000111, %00000011, %00000001
__hdraw_end_mask:
DATA AS BYTE %10000000, %11000000, %11100000, %11110000, %11111000, %11111100, %11111110, %11111111

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
DATA AS BYTE %11000000, %00110000, %00001100, %00000011
__mc_pattern:
DATA AS BYTE %00000000, %01010101, %10101010, %11111111

__petscii_to_screencode:
DATA AS BYTE $80, $00, $c0, $e0, $40, $c0, $80, $80

__nible_to_byte:
DATA AS BYTE %00000000, %00000011, %00001100, %00001111
DATA AS BYTE %00110000, %00110011, %00111100, %00111111
DATA AS BYTE %11000000, %11000011, %11001100, %11001111
DATA AS BYTE %11110000, %11110011, %11111100, %11111111

__opcodes:
DATA AS BYTE $45, $25, $05

REM **********************
REM *     ASSEMBLER      *
REM **********************
ASM
_update_buffer0_clear
        lda {ZP_W0}+1
        clc
        adc #30
        ldx #92
        sec

_update_buffer0_clear_loop
        sta _clear_buffer0_loop,x
        sbc #1
        dex
        dex
        dex
        bpl _update_buffer0_clear_loop

        lda {ZP_W0}+1
        clc
        adc #31
        ldx #11

_update_buffer0_clear_loop2
        sta _clear_buffer0_loop2,x
        dex
        dex
        dex
        bpl _update_buffer0_clear_loop2

        rts

_clear_buffer0
        ;33364 cycles to clear the buffer
        ldx #0
_clear_buffer0_loop
        sta $e000,x
        sta $e100,x
        sta $e200,x
        sta $e300,x
        sta $e400,x
        sta $e500,x
        sta $e600,x
        sta $e700,x
        sta $e800,x
        sta $e900,x
        sta $ea00,x
        sta $eb00,x
        sta $ec00,x
        sta $ed00,x
        sta $ee00,x
        sta $ef00,x
        sta $f000,x
        sta $f100,x
        sta $f200,x
        sta $f300,x
        sta $f400,x
        sta $f500,x
        sta $f600,x
        sta $f700,x
        sta $f800,x
        sta $f900,x
        sta $fa00,x
        sta $fb00,x
        sta $fc00,x
        sta $fd00,x
        sta $fe00,x
        ;sta $ff00,x
        dex
        bne _clear_buffer0_loop
        ldx #15
_clear_buffer0_loop2
        sta $ff00,x
        sta $ff10,x
        sta $ff20,x
        sta $ff30,x
        dex
        bpl _clear_buffer0_loop2
        rts

_update_buffer1_clear
        lda {ZP_W0}+1
        clc
        adc #30
        ldx #92
        sec

_update_buffer1_clear_loop
        sta _clear_buffer1_loop,x
        sbc #1
        dex
        dex
        dex
        bpl _update_buffer1_clear_loop

        lda {ZP_W0}+1
        clc
        adc #31
        ldx #11

_update_buffer1_clear_loop2
        sta _clear_buffer1_loop2,x
        dex
        dex
        dex
        bpl _update_buffer1_clear_loop2

        rts

_clear_buffer1
        ldx #0
_clear_buffer1_loop
        sta $a000,x
        sta $a100,x
        sta $a200,x
        sta $a300,x
        sta $a400,x
        sta $a500,x
        sta $a600,x
        sta $a700,x
        sta $a800,x
        sta $a900,x
        sta $aa00,x
        sta $ab00,x
        sta $ac00,x
        sta $ad00,x
        sta $ae00,x
        sta $af00,x
        sta $b000,x
        sta $b100,x
        sta $b200,x
        sta $b300,x
        sta $b400,x
        sta $b500,x
        sta $b600,x
        sta $b700,x
        sta $b800,x
        sta $b900,x
        sta $ba00,x
        sta $bb00,x
        sta $bc00,x
        sta $bd00,x
        sta $be00,x
        ;sta $bf00,x
        dex
        bne _clear_buffer1_loop
        ldx #15
_clear_buffer1_loop2
        sta $bf00,x
        sta $bf10,x
        sta $bf20,x
        sta $bf30,x
        dex
        bpl _clear_buffer1_loop2
        rts
END ASM
THE_END:
