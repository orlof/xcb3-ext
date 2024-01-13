OPTION FASTINTERRUPT

'Number of sprites 16 or 24
SHARED CONST NUM_SPRITES = 24
ASM
MAXSPR = 24
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
    SprX(i) = 12 + (6 * i)
    SprColor(i) = 8 + (i MOD 8)
    SprShape(i) = 254
NEXT i


DO
    CALL SprUpdate()
    CALL JoyUpdate()
    y = y + JoyYAxis(JOY2)
    TEXTAT 0,0, "y: "+STR$(y)+ "  "
    FOR i AS BYTE = 0 TO NUM_SPRITES-1
        SprY(i) = y + SHL(i, 2)
    NEXT i
LOOP
