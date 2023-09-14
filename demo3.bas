INCLUDE "lib_gfx.bas"
INCLUDE "lib_random.bas"

CONST MAX_X = 159
CONST MAX_Y = 199

DIM Counter AS BYTE

CALL ScreenOff()

CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)

CALL SetVideoBank(3)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)

CALL FillBitmap(0)
CALL FillScreen(SHL(COLOR_WHITE, 4) OR COLOR_BLUE)
CALL FillColorRam(COLOR_RED)

CALL TextMC(7, 0, 3, 0, 1, "Single Buffer", CHARSET_LOWERCASE)

BORDER COLOR_BLUE
BACKGROUND COLOR_BLACK

CALL ScreenOn()

FOR Counter = 0 TO 96
    CALL WaitRasterLine256()
NEXT Counter

CALL TextMC(7, 0, 0, 0, 1, "Single Buffer", CHARSET_LOWERCASE)

DIM x0 AS WORD
DIM y0 AS BYTE
DIM x1 AS WORD
DIM y1 AS BYTE
DIM c AS BYTE

TYPE Point
    x2 AS INT
    y2 AS INT
    x3 AS INT
    y3 AS INT
    dx AS INT
    dy AS INT

    SUB Init() STATIC
        THIS.x2 = rnd16(1, MAX_X-1)
        THIS.x3 = THIS.x2
        THIS.y2 = rnd8(1, MAX_Y-1)
        THIS.y3 = THIS.y2

        IF rnd8(0,1) = 0 THEN
            THIS.dx = 1
        ELSE
            THIS.dx = -1
        END IF

        IF rnd8(0,1) = 0 THEN
            THIS.dy = 1
        ELSE
            THIS.dy = -1
        END IF
    END SUB

    SUB Move() STATIC
        THIS.x3 = THIS.x3 + THIS.dx
        THIS.y3 = THIS.y3 + THIS.dy
        IF (THIS.x3 = 0) OR (THIS.x3 = MAX_X) THEN THIS.dx = -THIS.dx
        IF (THIS.y3 = 0) OR (THIS.y3 = MAX_Y) THEN THIS.dy = -THIS.dy
    END SUB

    SUB Move2() STATIC
        THIS.x2 = THIS.x3 + THIS.dx
        THIS.y2 = THIS.y3 + THIS.dy
        IF (THIS.x2 = 0) OR (THIS.x2 = MAX_X) THEN THIS.dx = -THIS.dx
        IF (THIS.y2 = 0) OR (THIS.y2 = MAX_Y) THEN THIS.dy = -THIS.dy
    END SUB

    SUB Move3() STATIC
        THIS.x3 = THIS.x2 + THIS.dx
        THIS.y3 = THIS.y2 + THIS.dy
        IF (THIS.x3 = 0) OR (THIS.x3 = MAX_X) THEN THIS.dx = -THIS.dx
        IF (THIS.y3 = 0) OR (THIS.y3 = MAX_Y) THEN THIS.dy = -THIS.dy
    END SUB
END TYPE

DIM T AS BYTE
DIM Points(4) AS Point
CALL Points(0).Init()
CALL Points(1).Init()
CALL Points(2).Init()
CALL Points(3).Init()

FOR Counter AS BYTE = 0 TO 255
    FOR T = 0 TO 3
        CALL Points(T).Move()
    NEXT T

    FOR T = 0 TO 3
        x0 = Points(T).x3
        y0 = Points(T).y3
        x1 = Points((T+1) AND 3).x3
        y1 = Points((T+1) AND 3).y3
        c = T
        IF c = 0 THEN c = 2
        CALL DrawMC(x0, y0, x1, y1, c)
    NEXT T

    FOR T = 0 TO 3
        x0 = Points(T).x3
        y0 = Points(T).y3
        x1 = Points((T+1) AND 3).x3
        y1 = Points((T+1) AND 3).y3
        CALL DrawMC(x0, y0, x1, y1, 0)
    NEXT T

    DIM key AS BYTE
    GET key
    IF key > 0 THEN EXIT FOR
NEXT Counter

CALL ScreenOff()

CALL DoubleBufferOn()

CALL SetVideoBank(2)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)

CALL FillBitmap(0)
CALL FillScreen(SHL(COLOR_WHITE, 4) OR COLOR_BLUE)

CALL TextMC(7, 0, 3, 0, 1, "Double Buffer", CWORD(1))
CALL BufferSwap()

CALL ScreenOn()

FOR Counter = 0 TO 96
    CALL WaitRasterLine256()
NEXT Counter

CALL BufferSwap()
CALL TextMC(7, 0, 0, 0, 1, "Double Buffer", CWORD(1))

DO
    FOR T = 0 TO 3
        x0 = Points(T).x2
        y0 = Points(T).y2
        x1 = Points((T+1) AND 3).x2
        y1 = Points((T+1) AND 3).y2
        CALL DrawMC(x0, y0, x1, y1, 0)
    NEXT T

    FOR T = 0 TO 3
        CALL Points(T).Move2()
    NEXT T

    FOR T = 0 TO 3
        x0 = Points(T).x2
        y0 = Points(T).y2
        x1 = Points((T+1) AND 3).x2
        y1 = Points((T+1) AND 3).y2
        c = T
        IF c = 0 THEN c = 2
        CALL DrawMC(x0, y0, x1, y1, c)
    NEXT T

    CALL BufferSwap()

    FOR T = 0 TO 3
        x0 = Points(T).x3
        y0 = Points(T).y3
        x1 = Points((T+1) AND 3).x3
        y1 = Points((T+1) AND 3).y3
        CALL DrawMC(x0, y0, x1, y1, 0)
    NEXT T

    FOR T = 0 TO 3
        CALL Points(T).Move3()
    NEXT T

    FOR T = 0 TO 3
        x0 = Points(T).x3
        y0 = Points(T).y3
        x1 = Points((T+1) AND 3).x3
        y1 = Points((T+1) AND 3).y3
        c = T
        IF c = 0 THEN c = 2
        CALL DrawMC(x0, y0, x1, y1, c)
    NEXT T

    CALL BufferSwap()
LOOP
