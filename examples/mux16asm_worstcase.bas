OPTION FASTINTERRUPT

SHARED CONST NUM_SPRITES = 16
ASM
MAXSPR = 16
LIB_MUX24ASM_DEBUG
END ASM

INCLUDE "../libs/lib_mux24asm.bas"
INCLUDE "../libs/lib_joy.bas"

DIM i AS BYTE FAST
DIM y AS BYTE

'Sprite shape
MEMSET 16256, 63, 255

'Initial values

y = 50
FOR i = 0 TO NUM_SPRITES-1
    SprX(i) = 12 + (10 * i)
    SprColor(i) = 8 + (i MOD 8)
    SprShape(i) = 254
NEXT i


DO
    CALL JoyUpdate()
    y = y + JoyYAxis(JOY2)
    TEXTAT 0,0, "y: "+STR$(y)+ "  "

    FOR SprNr AS BYTE = 0 TO NUM_SPRITES-1
        SprY(SprNr) = y + SHL(SprNr, 2)
    NEXT SprNr
    CALL SprUpdate()

    FOR SprNr AS BYTE = 0 TO NUM_SPRITES-1
        SprY(SprNr) = y - SHL(SprNr, 2)
    NEXT SprNr
    CALL SprUpdate()
LOOP

