'OPTION FASTINTERRUPT

SHARED CONST TRUE = 255
SHARED CONST FALSE = 0

INCLUDE "../libs/lib_mux16xcb.bas"
INCLUDE "../libs/lib_rnd.bas"
INCLUDE "../libs/lib_joy.bas"

DIM i AS BYTE FAST
DIM Dx(16) AS BYTE
DIM Dy(16) AS BYTE

MEMSET 16256, 63, 255

FOR i = 0 TO 15
    SprX(i) = RndByte(24, 159)
    SprY(i) = RndByte(50, 229)
    SprCol(i) = 8 + (i MOD 8)
    SprShape(i) = 254
    Dx(i) = (2 * RndByte(0, 1)) - 1
    Dy(i) = (2 * RndByte(0, 1)) - 1
    'PRINT SprX(i), SprY(i), SprCol(i), SprShape(i)
NEXT i

DO
    CALL SprUpdate()
    FOR i = 0 TO 15
        IF SprX(i) = 12 THEN
            Dx(i) = 1
        ELSE
            IF SprX(i) = 160 THEN
                Dx(i) = -1
            END IF
        END IF
        IF SprY(i) = 50 THEN
            Dy(i) = 1
        ELSE
            IF SprY(i) = 229 THEN
                Dy(i) = -1
            END IF
        END IF
        SprX(i) = SprX(i) + Dx(i)
        SprY(i) = SprY(i) + Dy(i)
    NEXT i
LOOP
