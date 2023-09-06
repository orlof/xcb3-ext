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

' REUSABLE ZERO-PAGE PSEUDO-REGISTERS
DIM BASE AS WORD FAST
DIM DISTANCE AS WORD FAST

DIM DX AS WORD FAST         ' BYTE FOR MULTICOLOR
DIM DY AS BYTE FAST
DIM X_INC AS BYTE FAST
DIM Y_INC AS BYTE FAST
DIM COUNT AS WORD FAST      ' BYTE FOR MULTICOLOR
DIM PATTERN AS BYTE FAST
DIM MASK AS BYTE FAST
DIM TEMP AS BYTE FAST

REM **********************
REM *    DECLARATIONS    *
REM **********************

DECLARE SUB SetVideoBank(BankNumber AS BYTE) SHARED STATIC
DECLARE SUB SetGraphicsMode(Mode AS BYTE) SHARED STATIC
DECLARE SUB SetScreenMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB SetCharacterMemory(Ptr AS BYTE) SHARED STATIC
DECLARE SUB SetBitmapMemory(Ptr AS BYTE) SHARED STATIC

DECLARE SUB Plot(x AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB Draw(x1 AS WORD, y1 AS BYTE, x2 AS WORD, y2 AS BYTE, Mode AS BYTE) SHARED STATIC
DECLARE SUB PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB DrawMC(x1 AS BYTE, y1 AS BYTE, x2 AS BYTE, y2 AS BYTE, Ink AS BYTE) SHARED STATIC
DECLARE SUB FillBitmap(Value AS BYTE) SHARED STATIC
DECLARE SUB FillScreen(Value AS BYTE) SHARED STATIC
DECLARE SUB FillColorRam(Value AS BYTE) SHARED STATIC

'DECLARE SUB SetBackgroundColor1(ColorCode AS BYTE) SHARED STATIC
'DECLARE SUB SetBackgroundColor2(ColorCode AS BYTE) SHARED STATIC
'DECLARE SUB CopyCharacterSet(Set AS BYTE, Address AS BYTE) SHARED STATIC

DECLARE SUB _calc_bitmap_table() STATIC
DECLARE SUB _calc_screen_table() STATIC

REM **********************
REM *        MAIN        *
REM **********************

CALL SetVideoBank(3)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)
CALL SetGraphicsMode(STANDARD_BITMAP_MODE)
CALL FillBitmap(0)
CALL FillScreen(SHL(1, 4) OR 2)
CALL FillColorRam(3)

'CALL DrawMC(0, 0, 50, 0, 1)
'CALL DrawMC(0, 0, 50, 25, 2)
'CALL DrawMC(0, 0, 50, 50, 3)
'CALL DrawMC(0, 0, 25, 50, 2)
'CALL DrawMC(0, 0, 0, 50, 1)

'CALL DrawMC(0, 199, 50, 199, 1)
'CALL DrawMC(0, 199, 50, 174, 2)
'CALL DrawMC(0, 199, 50, 149, 3)
'CALL DrawMC(0, 199, 25, 149, 2)
'CALL DrawMC(0, 199, 0, 149, 1)

'CALL DrawMC(159, 0, 109, 0, 1)
'CALL DrawMC(159, 0, 109, 25, 2)
'CALL DrawMC(159, 0, 109, 50, 3)
'CALL DrawMC(159, 0, 134, 50, 2)
'CALL DrawMC(159, 0, 159, 50, 1)

'CALL DrawMC(159, 199, 109, 199, 1)
'CALL DrawMC(159, 199, 109, 174, 2)
'CALL DrawMC(159, 199, 109, 149, 3)
'CALL DrawMC(159, 199, 134, 149, 2)
'CALL DrawMC(159, 199, 159, 149, 1)

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


DO
LOOP

END

REM **********************
REM *  GLOBAL ASSEMBLER  *
REM **********************

REM **********************
REM *     FUNCTIONS      *
REM **********************

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

SUB SetGraphicsMode(Mode AS BYTE) SHARED STATIC
    ASM
        lda {Mode}
        and #%01100000
        sta {TEMP}

        lda $d011
        ora {TEMP}
        sta $d011

        lda {Mode}
        and #%00010000
        sta {TEMP}

        lda $d016
        ora {TEMP}
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
    ASM
        lda {Ptr}
        asl
        sta {TEMP}

        lda $d018
        and #%11110001
        ora {TEMP}
        sta $d018
    END ASM
END SUB

SUB SetScreenMemory(Ptr AS BYTE) SHARED STATIC
    ASM
        lda {Ptr}
        asl
        asl
        asl
        asl
        sta {TEMP}
        lda $d018
        and #%00001111
        ora {TEMP}
        sta $d018
    END ASM
    CALL _calc_screen_table()
END SUB

SUB SetBitmapMemory(Ptr AS BYTE) SHARED STATIC
    ASM
        lda {Ptr}
        asl
        asl
        asl
        sta {TEMP}

        lda $d018
        and #%11110111
        ora {TEMP}
        sta $d018
    END ASM
    CALL _calc_bitmap_table()
END SUB

SUB Plot(x AS WORD, y AS BYTE, Mode AS BYTE) SHARED STATIC
    ASM
_plot_ram_in
        sei
        dec 1
        dec 1

_plot_init
        lda {y}             ; 4
        and #7              ; 2 these cycles are needed to calculate the index to y table
        sta {TEMP}          ; 2 not needed if the table were 250 words long

        eor {y}             ; 3
        lsr                 ; 2
        lsr                 ; 2
        tax                 ; 2

        lda  {_bitmap_y_tbl}+1,x
        adc {x}+1
        sta {BASE}+1
        lda {_bitmap_y_tbl},x
        sta {BASE}

        lda {x}
        and #7
        tax

        eor {x}
        adc {TEMP}
        tay

        lda {Mode}
        beq _plot_clr
        bpl _plot_set

_plot_flip
        lda {_hires_mask1},x
        eor ({BASE}),y
        sta ({BASE}),y
        jmp _plot_ram_out

_plot_clr
        lda {_hires_mask0},x
        and ({BASE}),y
        sta ({BASE}),y
        jmp _plot_ram_out

_plot_set
        lda {_hires_mask1},x
        ora ({BASE}),y
        sta ({BASE}),y

_plot_ram_out
        inc 1
        inc 1
        cli
_plot_end
    END ASM
END SUB

SUB Draw(x1 AS WORD, y1 AS BYTE, x2 AS WORD, y2 AS BYTE, Mode AS BYTE) SHARED STATIC
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
        ;dy   = _y      delta y 8
        ;xi   = X_INC   1/r flag 8
        ;yi   = Y_INC   u/d flag 8
        ;base = BASE   base of pixel addr 16
        ;m    = MASK   pixel mask 8
        ;c    = COUNT   count 16
        ;r    = DISTANCE   16

        ldx #0              ;xinc=right
        ldy #0              ;yinc=down

_draw_dx
        lda {x2}            ;calculate dx=x2-x1
        sec
        sbc {x1}
        sta {DX}
        lda {x2}+1
        sbc {x1}+1
        sta {DX}+1
        bcs _draw_dy

        dex                 ;dx<0, xinc=left
        lda #1
        sbc {DX}
        sta {DX}
        lda #0
        sbc {DX}+1
        sta {DX}+1          ;dx=abs(dx)

_draw_dy
        lda {y2}            ;dy=y2-y1
        sec
        sbc {y1}
        bcs _draw_store_dy
        dey                 ;dy<0, yinc=up
        eor #$ff            ;dy=abs(dy)
        adc #1

_draw_store_dy
        sta {DY}

        stx {X_INC}         ;xi: $00 or $ff
        sty {Y_INC}         ;y1: $00 or $ff

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
        sta {BASE}         ;save base
        lda {_bitmap_y_tbl}+1,x
        adc {x1}+1
        sta {BASE}+1

        lda {x1}
        and #7
        tax
        lda {_hires_mask1},x    ; mc
        sta {MASK}         ;save mask

        ora ({BASE}),y
        sta ({BASE}),y

        lda {DX}+1
        bne _draw_x
        lda {DX}            ;(dx>=dy)
        cmp {DY}
        bcs _draw_x
        jmp _draw_y
_draw_x
        ;dx>=dy
        lda {DX}+1
        sta {COUNT}+1       ;c=dx
        lsr
        sta {DISTANCE}+1       ;r=dx/2
        lda {DX}
        sta {COUNT}
        ror
        sta {DISTANCE}
        lda {COUNT}
        ora {COUNT}+1
        bne _draw_x_loop
        jmp _draw_ram_out             ;if single point

_draw_x_loop
        lda {X_INC}
        bmi _draw_x_left

_draw_x_right
        lsr {MASK}         ;right mc
        bcc _draw_x_add_dy
        ror {MASK}
        lda {BASE}
        adc #8
        sta {BASE}
        bcc _draw_x_add_dy
        inc {BASE}+1
        bne _draw_x_add_dy
_draw_x_left
        asl {MASK}         ;left mc
        bcc _draw_x_add_dy
        rol {MASK}
        lda {BASE}
        sbc #7
        sta {BASE}
        bcs _draw_x_add_dy
        dec {BASE}+1
_draw_x_add_dy
        lda {DISTANCE}         ;r=r+dy
        clc
        adc {DY}
        sta {DISTANCE}
        bcc _draw_x_sub_dx
        inc {DISTANCE}+1
_draw_x_sub_dx
        sec
        sbc {DX}
        tax

        lda {DISTANCE}+1
        sbc {DX}+1
        bcc _draw_x_plot

        stx {DISTANCE}         ;r>=dx
        sta {DISTANCE}+1       ;r=r-dx

        lda {Y_INC}
        bmi _draw_x_up

_draw_x_down
        iny                 ;down
        cpy #8
        bcc _draw_x_plot

        ldy #0
        lda {BASE}
        adc #$3f
        sta {BASE}
        lda {BASE}+1
        adc #1
        bcc _draw_x_store_base_hi

_draw_x_up
        dey                 ;up
        bpl _draw_x_plot
        ldy #7
        lda {BASE}
        sbc #$40
        sta {BASE}
        lda {BASE}+1
        sbc #1
_draw_x_store_base_hi
        sta {BASE}+1

_draw_x_plot
        lda ({BASE}),y
        ora {MASK}
        sta ({BASE}),y     ;plot (x,y) mc

        dec {COUNT}
        bne _draw_x_loop             ;next
        dec {COUNT}+1
        beq _draw_x_loop             ;next
        jmp _draw_ram_out

_draw_y
        ; dy>dx
        lda {DY}
        beq _draw_ram_out            ;single point

        sta {COUNT}         ;c=dy
        lsr
        sta {DISTANCE}         ;r=dy/2

_draw_y_loop
        lda {Y_INC}
        bmi _draw_y_up

_draw_y_down
        iny                 ;down
        cpy #8
        bcc _draw_y_add_dx
        ldy #0
        lda {BASE}
        adc #$3f
        sta {BASE}
        lda {BASE}+1
        adc #1
        bcc _draw_y_store_base_hi

_draw_y_up
        dey                 ;up
        bpl _draw_y_add_dx
        ldy #7
        sec
        lda {BASE}
        sbc #$40
        sta {BASE}
        lda {BASE}+1

        sbc #1
_draw_y_store_base_hi
        sta {BASE}+1

_draw_y_add_dx
        ldx #0
        lda {DISTANCE}         ;r=r+dx
        clc
        adc {DX}
        sta {DISTANCE}
        bcs _draw_y_sub_dy
        inx
        sec
_draw_y_sub_dy
        sbc {DY}
        bcs _draw_y_distance
        dex
        beq _draw_y_plot
_draw_y_distance
        sta {DISTANCE}         ;r>=dy, r=r-dy
        lda {X_INC}
        bmi _draw_y_left

_draw_y_right
        lsr {MASK}         ;right
        bcc _draw_y_plot
        ror {MASK}
        lda {BASE}
        adc #8
        sta {BASE}
        bcc _draw_y_plot
        inc {BASE}+1
        bne _draw_y_plot

_draw_y_left
        asl {MASK}         ;left
        bcc _draw_y_plot
        rol {MASK}
        lda {BASE}
        sbc #7
        sta {BASE}
        bcs _draw_y_plot
        dec {BASE}+1

_draw_y_plot
        lda ({BASE}),y
        ora {MASK}
        sta ({BASE}),y     ;plot (x, y)

        dec {COUNT}
        bne _draw_y_loop            ;next

_draw_ram_out
        inc 1
        inc 1
        cli
    END ASM
END SUB

SUB PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE) SHARED STATIC
    ASM
_plotmc_ram_in
        sei
        lda %00110100
        sta 1

_plotmc_init
        lda #0
        sta {BASE}+1

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
        rol  {BASE}+1
        adc  {_bitmap_y_tbl},x
        sta  {BASE}

        lda  {_bitmap_y_tbl}+1,x
        adc  {BASE}+1
        sta  {BASE}+1

_plotmc_mask
        lda {x}
        and #3
        tax
        lda {_mc_mask},x
        sta {MASK}

_plotmc_ink
        ldx {Ink}
        and {_mc_pattern},x
        sta  {TEMP}

_plotmc_draw
        lda  {MASK}
        eor  #$FF
        and  ({BASE}),y
        ora  {TEMP}
        sta  ({BASE}),y

_plotmc_ram_out:
        lda %00110110
        sta 1
        cli

_plotmc_end:
    END ASM
END SUB

SUB DrawMC(x1 AS BYTE, y1 AS BYTE, x2 AS BYTE, y2 AS BYTE, Ink AS BYTE) SHARED STATIC
    ASM
        ;fast line draw
        ;passed: x1, y1, x2, y2

        ;altered:
        ;dx   = DX      delta x 16
        ;dy   = DY      delta y 8
        ;xi   = X_INC
        ;yi   = Y_INC
        ;base = BASE   base of pixel addr 16
        ;m    = MASK   pixel mask 8
        ;c    = COUNT   count 16
        ;r    = DISTANCE   16
_drawmc_ram_in
        sei
        lda %00110100
        sta 1

_drawmc_init
        ldx  {Ink}
        lda  {_mc_pattern},x
        sta  {PATTERN}

        ldx  #0
        ldy  #0
        sty {BASE}+1
        sty {DISTANCE}+1

        lda  {x2}             ; dx = abs(x2 - x1)
        sec
        sbc  {x1}
        bcs  _drawmc_store_dx
        dex
        eor  #$FF
        adc  #1
_drawmc_store_dx:
        sta  {DX}

        lda  {y2}             ; dy = abs(y2 - y1)
        sec
        sbc  {y1}
        bcs  _drawmc_store_dy
        dey
        eor  #$FF
        adc  #1
_drawmc_store_dy:
        sta  {DY}

        stx  {X_INC}
        sty  {Y_INC}

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
        rol  {BASE}+1
        adc  {_bitmap_y_tbl},x
        sta  {BASE}

        lda  {_bitmap_y_tbl}+1,x
        adc  {BASE}+1
        sta  {BASE}+1

        lda  {x1}
        and  #3
        tax

        lda  {_mc_mask},x
        sta  {MASK}

        and  {PATTERN}
        sta  {TEMP}
        lda  {MASK}
        eor  #$FF
        and  ({BASE}),y
        ora  {TEMP}
        sta  ({BASE}),y

        lda  {DX}
        cmp  {DY}
        bcs  _drawmc_x
        jmp  _drawmc_y

_drawmc_x:
        lda  {DX}
        bne  _drawmc_x_init
        jmp  _drawmc_ram_out

_drawmc_x_init:
        sta  {COUNT}
        lsr
        sta  {DISTANCE}

_drawmc_x_loop:
        lda  {X_INC}
        bmi  _drawmc_x_left

_drawmc_x_right:
        lsr  {MASK}
        ror  {MASK}
        bcc  _drawmc_x_add_dy
        ror  {MASK}
        lda  {BASE}
        adc  #8
        sta  {BASE}
        bcc  _drawmc_x_add_dy
        inc  {BASE}+1
        bne  _drawmc_x_add_dy

_drawmc_x_left:
        asl  {MASK}
        rol  {MASK}
        bcc  _drawmc_x_add_dy
        rol  {MASK}
        sec
        lda  {BASE}
        sbc  #8
        sta  {BASE}
        bcs  _drawmc_x_add_dy
        dec  {BASE}+1

_drawmc_x_add_dy:
        lda  {DISTANCE}
        clc
        adc  {DY}
        sta  {DISTANCE}
        bcc  _drawmc_x_sub_dx
        inc  {DISTANCE}+1

_drawmc_x_sub_dx:
        sec
        sbc  {DX}
        tax

        lda  {DISTANCE}+1
        sbc  #0
        bcc  _drawmc_x_plot

        stx  {DISTANCE}
        sta  {DISTANCE}+1

        lda  {Y_INC}
        bmi  _drawmc_x_up

_drawmc_x_down:
        iny
        cpy  #8
        bcc  _drawmc_x_plot

        ldy  #0
        lda  {BASE}
        adc  #$3F
        sta  {BASE}
        lda  {BASE}+1
        adc  #$01
        bcc  _drawmc_x_store_base_hi

_drawmc_x_up:
        dey
        bpl  _drawmc_x_plot

        ldy  #7
        lda  {BASE}
        sbc  #$40
        sta  {BASE}
        lda  {BASE}+1
        sbc  #$01
_drawmc_x_store_base_hi:
        sta  {BASE}+1

_drawmc_x_plot:
        lda  {MASK}
        and  {PATTERN}
        sta  {TEMP}
        lda  {MASK}
        eor  #$FF
        and  ({BASE}),y
        ora  {TEMP}
        sta  ({BASE}),y

        dec  {COUNT}
        bne  _drawmc_x_loop
        jmp  _drawmc_ram_out

_drawmc_y:
      lda  {DY}
      bne  _drawmc_y_init
      jmp  _drawmc_ram_out

_drawmc_y_init:
      sta  {COUNT}
      lsr
      sta  {DISTANCE}
_drawmc_y_loop:
      lda  {Y_INC}
      bmi  _drawmc_y_up

_drawmc_y_down:
      iny
      cpy  #8
      bcc  _drawmc_y_add_dx
      ldy  #0
      lda  {BASE}
      adc  #$3F
      sta  {BASE}
      lda  {BASE}+1
      adc  #$01
      bcc  _drawmc_y_store_base

_drawmc_y_up:
      dey
      bpl  _drawmc_y_add_dx
      ldy  #7
      sec
      lda  {BASE}
      sbc  #$40
      sta  {BASE}
      lda  {BASE}+1
      sbc  #$01
_drawmc_y_store_base:
      sta  {BASE}+1

_drawmc_y_add_dx:
      ldx  #0
      lda  {DISTANCE}
      clc
      adc  {DX}
      sta  {DISTANCE}
      bcs  _drawmc_y_sub_dy
      inx
      sec

_drawmc_y_sub_dy:
      sbc  {DY}
      bcs  _drawmc_y_distance
      dex
      beq  _drawmc_y_plot

_drawmc_y_distance:
      sta  {DISTANCE}

      lda  {X_INC}
      bmi  _drawmc_y_left

_drawmc_y_right
      lsr  {MASK}
      ror  {MASK}
      bcc  _drawmc_y_plot
      ror  {MASK}
      lda  {BASE}
      adc  #8
      sta  {BASE}
      bcc  _drawmc_y_plot
      inc  {BASE}+1
      bne  _drawmc_y_plot

_drawmc_y_left:
      asl  {MASK}
      rol  {MASK}
      bcc  _drawmc_y_plot
      rol  {MASK}
      sec
      lda  {BASE}
      sbc  #8
      sta  {BASE}
      bcs  _drawmc_y_plot
      dec  {BASE}+1

_drawmc_y_plot:
      lda  {MASK}
      and  {PATTERN}
      sta  {TEMP}
      lda  {MASK}
      eor  #$FF
      and  ({BASE}),y
      ora  {TEMP}
      sta  ({BASE}),y

      dec  {COUNT}
      bne  _drawmc_y_loop

_drawmc_ram_out:
        lda %00110110
        sta 1
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
        sta {BASE}+1

        lda $dd00           ; vic bank
        and #%00000011
        eor #%00000011
        lsr
        ror
        ror
        ora {BASE}+1
        sta {BASE}+1       ; bank + bitmap memory

        ldy #0
        sty {BASE}
_calc_table_bitmap_loop
        lda {BASE}
        sta {_bitmap_y_tbl},y
        iny
        lda {BASE}+1
        sta {_bitmap_y_tbl},y
        iny

_calc_table_bitmap_add_320
        clc
        lda {BASE}
        adc #$40
        sta {BASE}

        lda {BASE}+1
        adc #$1
        sta {BASE}+1

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
        sta {BASE}+1

        lda $dd00           ; vic bank
        and #%00000011
        eor #%00000011
        lsr
        ror
        ror
        ora {BASE}+1
        sta {BASE}+1       ; bank + bitmap memory

        ldy #0
        sty {BASE}
_calc_table_screen_loop
        lda {BASE}+1
        sta {_screen_y_tbl_hi},y
        lda {BASE}
        sta {_screen_y_tbl_lo},y

        clc
        adc #40
        sta {BASE}

        lda {BASE}+1
        adc #0
        sta {BASE}+1

        iny
        cpy #25
        bne _calc_table_screen_loop
    END ASM
END SUB

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
