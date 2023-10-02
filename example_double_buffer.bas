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
        THIS.x = RndByte(1, MAX_X-1)
        THIS.y = RndByte(1, MAX_Y-1)

        IF RndByte(0,1) = 0 THEN
            THIS.dx = 1
        ELSE
            THIS.dx = -1
        END IF

        IF RndByte(0,1) = 0 THEN
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
DIM Key AS BYTE
DIM LineColor AS BYTE
DIM T AS BYTE

PRINT "press any key to start"
DO
    T = RndQByte()
    GET key
LOOP UNTIL key > 0

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

BORDER COLOR_BLUE
BACKGROUND COLOR_BLACK

CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)

' SETUP BUFFER 0
CALL SetVideoBank(3)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)
CALL FillBuffer(0)

FOR T = 0 TO 39
    CALL SetColorInRect(T, 0, T, 24, 1, (T AND %11)+4)
    CALL SetColorInRect(T, 0, T, 24, 2, (T AND %11)+8)
    CALL SetColorInRect(T, 0, T, 24, 3, (T AND %11)+12)
NEXT T

CALL DoubleBufferOn()

' SETUP BUFFER 1
CALL SetVideoBank(2)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)
CALL FillBuffer(0)

FOR T = 0 TO 39
    CALL SetColorInRect(T, 0, T, 24, 1, (T AND %11)+4)
    CALL SetColorInRect(T, 0, T, 24, 2, (T AND %11)+8)
    CALL SetColorInRect(T, 0, T, 24, 3, (T AND %11)+12)
NEXT T

CALL ScreenOn()

DO
    CALL FillBuffer(0)

    FOR T = 0 TO LAST_POINT
        CALL Points(T).Move()
    NEXT T

    LineColor = 0
    FOR T = 0 TO LAST_POINT
        LineColor = LineColor + 1
        IF LineColor = 4 THEN LineColor = 1
        CALL DrawMC( _
            Points(T).x, Points(T).y, _
            Points((T+1) AND 7).x, Points((T+1) AND 7).y, _
            LineColor _
        )
    NEXT T

    CALL BufferSwap()

    GET Key
    IF Key > 0 THEN EXIT DO
LOOP

CALL ResetScreen()
