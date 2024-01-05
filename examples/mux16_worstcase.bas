OPTION FASTINTERRUPT

INCLUDE "../libs/lib_mux16asm.bas"
INCLUDE "../libs/lib_joy.bas"

DIM i AS BYTE FAST
DIM y AS BYTE

'Sprite shape
MEMSET 16256, 63, 255

'Initial values

y = 50
FOR i = 0 TO 15
    SprX(i) = 12 + (10 * i)
    SprColor(i) = 8 + (i MOD 8)
    SprShape(i) = 254
NEXT i


DO
    CALL JoyUpdate()
    y = y + JoyYAxis(JOY2)
    TEXTAT 0,0, "y: "+STR$(y)+ "  "

    FOR SprNr AS BYTE = 0 TO 15
        SprY(SprNr) = y + SHL(SprNr, 2)
    NEXT SprNr
    CALL SprUpdate()

    FOR SprNr AS BYTE = 0 TO 15
        SprY(SprNr) = y - SHL(SprNr, 2)
    NEXT SprNr
    CALL SprUpdate()
LOOP
