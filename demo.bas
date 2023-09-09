INCLUDE "lib_gfx.bas"

REM **********************
REM *        MAIN        *
REM **********************
SUB TestSuiteMC() SHARED STATIC
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

    'CALL CopyCharROM(1, $d000)
    FOR Face AS BYTE = 0 TO 4
        FOR Bg AS BYTE = 0 TO 4
            CALL TextMC(8*Bg, Face+10, Face-1, Bg-1, 1, "aAbB", CWORD(1))
        NEXT
    NEXT
    CALL TextMC(0,0,3,$ff,0,"ABCDEFGHIJKLMNOPQRSTUVWXYZ",CWORD(1))
    CALL TextMC(0,1,3,$ff,0,"abcdefghijklmnopqrstuvwxyz",CWORD(1))
    CALL SetColor(0,0,39,24,1,12)

END SUB

SUB TestSuite() SHARED STATIC
    CALL SetVideoBank(3)
    CALL SetBitmapMemory(1)
    CALL SetScreenMemory(0)
    CALL SetGraphicsMode(STANDARD_BITMAP_MODE)
    CALL FillBitmap(0)
    CALL FillScreen(SHL(1, 4) OR 2)

    'FOR XW AS WORD = 0 TO 319
    '    FOR Y = 80 TO 120
    '        CALL Plot(XW, Y, (XW XOR Y) AND 1)
    '    NEXT
    'NEXT

    FOR R AS BYTE = 5 TO 95 STEP 5
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

    CALL CopyCharROM(1, $d000)
    FOR Face AS BYTE = 0 TO 2
        FOR Bg AS BYTE = 0 TO 2
            CALL Text(2+12*Bg, Face+10, Face-1, Bg-1, 1, "aAbBcC", CWORD(1))
        NEXT
    NEXT
    CALL Text(0,0,1,0,0,"aAbBcC", CWORD(1))
    CALL SetColor(0,0,3,0,1,14)

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

CALL ResetScreen()
END
