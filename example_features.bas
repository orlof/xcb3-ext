INCLUDE "lib_gfx.bas"

REM **********************
REM *        MAIN        *
REM **********************
SUB TestSuiteMC() SHARED STATIC
    CALL SetVideoBank(3)
    CALL SetBitmapMemory(1)
    CALL SetScreenMemory(0)
    CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)
    CALL FillBuffer(0)
    CALL FillColorsMC(COLOR_BLACK, COLOR_WHITE, COLOR_BLUE, COLOR_RED)

    FOR X AS BYTE = 0 TO 159
        FOR Y AS BYTE = 80 TO 120
            CALL PlotMC(X, Y, (Y XOR X) AND 3)
        NEXT
    NEXT

    FOR R AS BYTE = 5 TO 75 STEP 5
        CALL CircleMC(80, 100, R, 1, MODE_TRANSPARENT)
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

    CALL CircleMC(40, 50, 10, 1, 0)
    CALL CircleMC(60, 50, 10, 2, 1)
    CALL CircleMC(80, 50, 10, 3, 2)
    CALL CircleMC(100, 50, 10, MODE_FLIP, 3)
    CALL CircleMC(120, 50, 10, 1, MODE_TRANSPARENT)

    Y = 105
    CALL RectMC(10, Y, 30, Y+10, 0, 0)
    CALL RectMC(40, Y, 60, Y+10, 0, 1)
    CALL RectMC(70, Y, 90, Y+10, 0, 2)
    CALL RectMC(100, Y, 120, Y+10, 0, 3)
    CALL RectMC(130, Y, 150, Y+10, 0, MODE_TRANSPARENT)

    Y = Y + 15
    CALL RectMC(10, Y, 30, Y+10, 1, 0)
    CALL RectMC(40, Y, 60, Y+10, 1, 1)
    CALL RectMC(70, Y, 90, Y+10, 1, 2)
    CALL RectMC(100, Y, 120, Y+10, 1, 3)
    CALL RectMC(130, Y, 150, Y+10, 1, MODE_TRANSPARENT)

    Y = Y + 15
    CALL RectMC(10, Y, 30, Y+10, 2, 0)
    CALL RectMC(40, Y, 60, Y+10, 2, 1)
    CALL RectMC(70, Y, 90, Y+10, 2, 2)
    CALL RectMC(100, Y, 120, Y+10, 2, 3)
    CALL RectMC(130, Y, 150, Y+10, 2, MODE_TRANSPARENT)

    Y = Y + 15
    CALL RectMC(10, Y, 30, Y+10, 3, 0)
    CALL RectMC(40, Y, 60, Y+10, 3, 1)
    CALL RectMC(70, Y, 90, Y+10, 3, 2)
    CALL RectMC(100, Y, 120, Y+10, 3, 3)
    CALL RectMC(130, Y, 150, Y+10, 3, MODE_TRANSPARENT)

    Y = Y + 15
    CALL RectMC(10, Y, 30, Y+10, MODE_TRANSPARENT, 0)
    CALL RectMC(40, Y, 60, Y+10, MODE_TRANSPARENT, 1)
    CALL RectMC(70, Y, 90, Y+10, MODE_TRANSPARENT, 2)
    CALL RectMC(100, Y, 120, Y+10, MODE_TRANSPARENT, 3)
    CALL RectMC(130, Y, 150, Y+10, MODE_TRANSPARENT, MODE_TRANSPARENT)

    'CALL CopyCharROM(1, $d000)
    FOR Face AS BYTE = 0 TO 4
        FOR Bg AS BYTE = 0 TO 4
            CALL TextMC(8*Bg, Face+10, Face-1, Bg-1, 1, "aAbB", ROM_CHARSET_LOWERCASE)
        NEXT
    NEXT
    CALL TextMC(0,0,3,$ff,0,"ABCDEFGHIJKLMNOPQRSTUVWXYZ",ROM_CHARSET_LOWERCASE)
    CALL TextMC(0,1,3,$ff,0,"abcdefghijklmnopqrstuvwxyz",ROM_CHARSET_LOWERCASE)

END SUB

SUB TestSuite() SHARED STATIC
    CALL SetVideoBank(3)
    CALL SetBitmapMemory(1)
    CALL SetScreenMemory(0)
    CALL SetGraphicsMode(STANDARD_BITMAP_MODE)
    CALL FillBuffer(0)
    CALL FillColors(COLOR_BLACK, COLOR_WHITE)

    FOR XW AS WORD = 0 TO 319
        FOR Y AS BYTE = 80 TO 120
            CALL Plot(XW, Y, (XW XOR Y) AND 1)
        NEXT
    NEXT

    FOR R AS BYTE = 5 TO 95 STEP 5
        CALL Circle(160, 100, R, 1, MODE_TRANSPARENT)
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

    CALL Circle(100, 50, 20, 1, 0)
    CALL Circle(140, 50, 20, 1, 1)
    CALL Circle(180, 50, 20, MODE_FLIP, MODE_FLIP)
    CALL Circle(220, 50, 20, 1, MODE_TRANSPARENT)

    Y = 135
    CALL Rect(125, Y, 135, Y+10, MODE_SET, MODE_SET)
    CALL Rect(145, Y, 155, Y+10, MODE_SET, MODE_CLEAR)
    CALL Rect(165, Y, 175, Y+10, MODE_SET, MODE_FLIP)
    CALL Rect(185, Y, 195, Y+10, MODE_SET, MODE_TRANSPARENT)

    Y = Y + 15
    CALL Rect(125, Y, 135, Y+10, MODE_CLEAR, MODE_SET)
    CALL Rect(145, Y, 155, Y+10, MODE_CLEAR, MODE_CLEAR)
    CALL Rect(165, Y, 175, Y+10, MODE_CLEAR, MODE_FLIP)
    CALL Rect(185, Y, 195, Y+10, MODE_CLEAR, MODE_TRANSPARENT)

    Y = Y + 15
    CALL Rect(125, Y, 135, Y+10, MODE_FLIP, MODE_SET)
    CALL Rect(145, Y, 155, Y+10, MODE_FLIP, MODE_CLEAR)
    CALL Rect(165, Y, 175, Y+10, MODE_FLIP, MODE_FLIP)
    CALL Rect(185, Y, 195, Y+10, MODE_FLIP, MODE_TRANSPARENT)

    Y = Y + 15
    CALL Rect(125, Y, 135, Y+10, MODE_TRANSPARENT, MODE_SET)
    CALL Rect(145, Y, 155, Y+10, MODE_TRANSPARENT, MODE_CLEAR)
    CALL Rect(165, Y, 175, Y+10, MODE_TRANSPARENT, MODE_FLIP)
    CALL Rect(185, Y, 195, Y+10, MODE_TRANSPARENT, MODE_TRANSPARENT)

    FOR Face AS BYTE = 0 TO 2
        FOR Bg AS BYTE = 0 TO 2
            CALL Text(2+12*Bg, Face+10, Face-1, Bg-1, 1, "aAbBcC", ROM_CHARSET_LOWERCASE)
        NEXT
    NEXT

    CALL Text(0,0,1,MODE_TRANSPARENT,0,"ABCDEFGHIJKLMNOPQRSTUVWXYZ",ROM_CHARSET_LOWERCASE)
    CALL Text(0,1,MODE_TRANSPARENT,1,0,"abcdefghijklmnopqrstuvwxyz",ROM_CHARSET_LOWERCASE)
END SUB

SUB TestSuiteLines() STATIC
    CALL SetVideoBank(3)
    CALL SetBitmapMemory(1)
    CALL SetScreenMemory(0)
    CALL SetGraphicsMode(STANDARD_BITMAP_MODE)
    CALL FillBuffer(0)
    CALL FillColors(COLOR_WHITE, COLOR_RED)

    FOR T AS BYTE = 0 TO 3
        CALL Text(30,24,1,0,0,"Draw",ROM_CHARSET_LOWERCASE)
        FOR Y AS BYTE = 0 TO 199
            CALL Draw(0, Y, 319, Y, MODE_FLIP)
        NEXT Y
        CALL Text(30,24,0,1,0,"VDraw",ROM_CHARSET_LOWERCASE)
        FOR X AS WORD = 0 TO 319
            CALL VDraw(X, 0, 199, MODE_FLIP)
        NEXT X
        CALL Text(30,24,1,0,0,"HDraw",ROM_CHARSET_LOWERCASE)
        FOR Y = 0 TO 199
            CALL HDraw(0, 319, Y, MODE_FLIP)
        NEXT Y
        CALL Text(30,24,1,0,0,"FillBuffer",ROM_CHARSET_LOWERCASE)
        CALL FillBuffer(0)
    NEXT T
END SUB

SUB TestSuiteLinesMC() STATIC
    CALL SetVideoBank(3)
    CALL SetBitmapMemory(1)
    CALL SetScreenMemory(0)
    CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)
    CALL FillBuffer(0)
    CALL FillColorsMC(COLOR_BLACK, COLOR_WHITE, COLOR_BLUE, COLOR_RED)

    FOR T AS BYTE = 0 TO 3
        CALL TextMC(30,24,1,0,0,"DrawMC",ROM_CHARSET_LOWERCASE)
        FOR Y AS BYTE = 0 TO 199
            CALL DrawMC(0, Y, 159, Y, Y AND 3)
        NEXT Y
        CALL TextMC(30,24,1,0,0,"VDrawMC",ROM_CHARSET_LOWERCASE)
        FOR X AS WORD = 0 TO 159
            CALL VDrawMC(X, 0, 199, X AND 3)
        NEXT X
        CALL TextMC(30,24,1,0,0,"HDrawMC",ROM_CHARSET_LOWERCASE)
        FOR Y = 0 TO 199
            CALL HDrawMC(0, 159, Y, Y AND 3)
        NEXT Y
        CALL TextMC(30,24,1,0,0,"FillBuffer",ROM_CHARSET_LOWERCASE)
        CALL FillBuffer(0)
    NEXT T
END SUB

CALL TestSuiteMC()

DIM a AS BYTE
DO
  GET a
LOOP UNTIL a > 0

CALL TestSuite()

DO
  GET a
LOOP UNTIL a > 0

CALL TestSuiteLines()
CALL TestSuiteLinesMC()

CALL ResetScreen()
END
