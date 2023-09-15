REM *************************************
REM * INCLUDES                          *
REM *************************************
INCLUDE "lib_gfx.bas"
INCLUDE "lib_random.bas"

REM *************************************
REM * CONSTANTS                         *
REM *************************************
CONST MAX_X = 159
CONST MAX_Y = 199
CONST NUM_POINTS = 8
CONST LAST_POINT = 7

REM *************************************
REM * TYPES                             *
REM *************************************
TYPE Point
    x AS INT
    y AS INT
    dx AS INT
    dy AS INT

    SUB Init() STATIC
        THIS.x = rnd8(1, MAX_X-1)
        THIS.y = rnd8(1, MAX_Y-1)

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
        THIS.x = THIS.x + THIS.dx
        THIS.y = THIS.y + THIS.dy
        IF (THIS.x = 0) OR (THIS.x = MAX_X) THEN THIS.dx = -THIS.dx
        IF (THIS.y = 0) OR (THIS.y = MAX_Y) THEN THIS.dy = -THIS.dy
    END SUB
END TYPE

REM *************************************
REM * VARIABLES                         *
REM *************************************
DIM x0 AS BYTE
DIM y0 AS BYTE
DIM x1 AS BYTE
DIM y1 AS BYTE
DIM Key AS BYTE
DIM LineColor AS BYTE
DIM Counter AS BYTE
DIM T AS BYTE

REM *************************************
REM * INITIALIZE POINTS                 *
REM *************************************
DIM Points(NUM_POINTS) AS Point
FOR T = 0 TO LAST_POINT
    CALL Points(T).Init()
NEXT T

REM *************************************
REM * INITIALIZE SCREEN                 *
REM *************************************
CALL ScreenOff()

CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)

CALL SetVideoBank(3)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)

CALL FillBuffer(0)
CALL FillScreen(SHL(COLOR_WHITE, 4) OR COLOR_BLUE)
CALL FillColorRam(COLOR_RED)

BORDER COLOR_BLUE
BACKGROUND COLOR_BLACK

REM *************************************
REM * SHOW SINGLE BUFFER ANIMATION      *
REM *************************************
CALL TextMC(7, 10, 3, 0, 1, "Single Buffer", CHARSET_LOWERCASE)

DO
    GET Key
LOOP UNTIL Key > 0

CALL ScreenOn()

FOR Counter = 0 TO 96
    CALL WaitRasterLine256()
NEXT Counter

FOR Counter AS BYTE = 0 TO 255
    CALL FillBuffer(0)

    FOR T = 0 TO LAST_POINT
        CALL Points(T).Move()
    NEXT T

    LineColor = 0
    FOR T = 0 TO LAST_POINT
        x0 = Points(T).x
        y0 = Points(T).y
        x1 = Points((T+1) AND 7).x
        y1 = Points((T+1) AND 7).y

        LineColor = LineColor + 1
        IF LineColor = 4 THEN LineColor = 1

        CALL DrawMC(x0, y0, x1, y1, LineColor)
    NEXT T

    CALL WaitRasterLine256()

    GET Key
    IF Key > 0 THEN EXIT FOR
NEXT Counter

REM *************************************
REM * SHOW DOUBLE BUFFER                *
REM *************************************
CALL TextMC(7, 10, 3, TRANSPARENT, 1, "Double Buffer", CWORD(1))

CALL DoubleBufferOn()

CALL SetVideoBank(2)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)

CALL FillScreen(SHL(COLOR_WHITE, 4) OR COLOR_BLUE)

FOR Counter = 0 TO 96
    CALL WaitRasterLine256()
NEXT Counter

DO
    CALL FillBuffer(0)

    FOR T = 0 TO LAST_POINT
        CALL Points(T).Move()
    NEXT T

    LineColor = 0
    FOR T = 0 TO LAST_POINT
        x0 = Points(T).x
        y0 = Points(T).y
        x1 = Points((T+1) AND 7).x
        y1 = Points((T+1) AND 7).y
        LineColor = LineColor + 1
        IF LineColor = 4 THEN LineColor = 1
        CALL DrawMC(x0, y0, x1, y1, LineColor)
    NEXT T

    CALL BufferSwap()

    GET Key
    IF Key > 0 THEN EXIT DO
LOOP

CALL ResetScreen()