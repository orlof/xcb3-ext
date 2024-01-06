OPTION FASTINTERRUPT

'Number of sprites 16 or 24
SHARED CONST NUM_SPRITES = 16
ASM
MAXSPR = 16
END ASM

INCLUDE "../libs/lib_mux24asm.bas"
INCLUDE "../libs/lib_rnd.bas"

CONST TRUE = 255
CONST FALSE = 0

DIM i AS BYTE FAST
DIM Dx(NUM_SPRITES) AS BYTE
DIM Dy(NUM_SPRITES) AS BYTE

'Sprite shape
MEMSET 16256, 63, 255

'Initial values
FOR i = 0 TO NUM_SPRITES-1
    SprX(i) = RndByte(24, 159)
    SprY(i) = RndByte(50, 229)
    SprColor(i) = 8 + (i AND 7)
    SprShape(i) = 254
    Dx(i) = (2 * RndByte(0, 1)) - 1
    Dy(i) = (2 * RndByte(0, 1)) - 1
NEXT i

'Main loop
DO
    CALL SprUpdate()
    FOR i = 0 TO NUM_SPRITES-1
        IF SprX(i) = 12 THEN
            Dx(i) = 1
        ELSE
            IF SprX(i) = 160 THEN
                Dx(i) = 255
            END IF
        END IF
        IF SprY(i) = 51 THEN
            Dy(i) = 1
        ELSE
            IF SprY(i) = 229 THEN
                Dy(i) = 255
            END IF
        END IF
        SprX(i) = SprX(i) + Dx(i)
        SprY(i) = SprY(i) + Dy(i)
    NEXT i
LOOP
