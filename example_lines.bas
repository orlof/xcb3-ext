INCLUDE "lib_gfx.bas"

CALL SetVideoBank(3)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)
CALL SetGraphicsMode(MULTICOLOR_BITMAP_MODE)
CALL FillBuffer(0)
CALL FillColorsMC(COLOR_DARKGRAY, COLOR_MIDDLEGRAY, COLOR_LIGHTGRAY, COLOR_WHITE)

BORDER COLOR_BLACK

DIM x0 AS BYTE
DIM y0 AS BYTE
DIM x1 AS BYTE
DIM y1 AS BYTE

DIM dx0 AS BYTE
DIM dy0 AS BYTE
DIM dx1 AS BYTE
DIM dy1 AS BYTE
dx0 = 1
dy0 = 1
dx1 = 1
dy1 = 1

x0 = 50
y0 = 50
x1 = 120
y1 = 170

DIM Color AS BYTE
Color = 1
DO
    x0 = x0 + dx0
    y0 = y0 + dy0
    x1 = x1 + dx1
    y1 = y1 + dy1
    Color = Color + 1
    IF Color = 4 THEN Color = 1
    IF (x0 = 0) OR (x0 = 159) THEN dx0 = 0 - dx0
    IF (y0 = 0) OR (y0 = 199) THEN dy0 = 0 - dy0
    IF (x1 = 0) OR (x1 = 159) THEN dx1 = 0 - dx1
    IF (y1 = 0) OR (y1 = 199) THEN dy1 = 0 - dy1
    CALL DrawMC(x0, y0, x1, y1, Color)
    CALL WaitRasterLine256()
LOOP
