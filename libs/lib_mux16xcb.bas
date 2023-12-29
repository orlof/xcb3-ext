
'*******************************************************************************
' PUBLIC INTERFACE FOR SPRITE MULTIPLEXER
'*******************************************************************************

'USE THIS FROM MAIN PROGRAM TO COMMIT CHANGES IN PUBLIC SPRITE REGISTERS
DECLARE SUB SprUpdate() STATIC SHARED

'THESE ARE PUBLIC SPRITE REGISTERS THAT CAN BE CHANGED IN MAIN PROGRAM
DIM SHARED SprY(16) AS BYTE
DIM SHARED SprX(16) AS BYTE
DIM SHARED SprCol(16) AS BYTE
DIM SHARED SprShape(16) AS BYTE

'*******************************************************************************
' PUBLIC INTERFACE END
'*******************************************************************************

'Constants
CONST TRUE      = 255
CONST FALSE     = 0
CONST HEIGHT    = 21
CONST LEAD      = 9         'Call ZoneN directly if next sprite bottom is less than n lines
                            'below current scanline. Bigger number wastes more cycles waiting
                            'for the scanline in busy-loop, but smaller number risks missing
                            'the next sprite with interrupt.

'Internal data
DIM _SprNr0 AS BYTE FAST
DIM _SprNr1 AS BYTE FAST

DIM _SprIdx(16) AS BYTE FAST
DIM _SprY(16) AS BYTE
DIM _SprX(16) AS BYTE
DIM _SprCol(16) AS BYTE
DIM _SprShape(16) AS BYTE
DIM _SprScanLine AS WORD
DIM _SprUpdate AS BYTE

'Initialize sprite multiplexer
SYSTEM INTERRUPT OFF        'This is mandatory

FOR _SprNr0 = 0 TO 15
    IF _SprNr0 < 8 THEN SPRITE _SprNr0 ON
    _SprIdx(_SprNr0) = _SprNr0
    SprY(_SprNr0) = 255
NEXT _SprNr0

ON RASTER 256 GOSUB Zone0
RASTER INTERRUPT ON
CALL SprUpdate()

'This GOTO is needed so that main program's INCLUDE does not execute interrupt handlers
GOTO THE_END

'Raster interrupt-handler that assigns software sprite to hardware sprite
ZoneN:
    _SprNr1 = _SprNr0 + 8
    BORDER _SprCol(_SprNr0)
    'Skip this and go directly to Zone0 if we are already late
    IF SCAN() >= 250 THEN GOTO Zone0

    'if rest of the software sprites are in y=255 go to Zone0
    IF _SprY(_SprNr1) >= 250 THEN GOTO ZoneNDone

    'Wait for scanline to reach below current sprite before re-using it
    '(needed if ZoneN was called in advance with direct GOTO instead of interrupt)
    _SprScanLine = CWORD(_SprY(_SprNr0)) + HEIGHT
    DO WHILE SCAN() < _SprScanLine
    LOOP

    'Reuse harware sprite for next software sprite
    SPRITE _SprNr0 AT SHL(CWORD(_SprX(_SprNr1)),1), _SprY(_SprNr1) SHAPE _SprShape(_SprNr1) COLOR _SprCol(_SprNr1)

    'Back to interrupt-Zone0 if all harware sprites are re-used
    IF _SprNr0 = 7 THEN GOTO ZoneNDone

    'Prepare for next hardware sprite re-use
    _SprNr0 = _SprNr0 + 1

    'Check if next sprite re-use is so close that it needs to be called immediately
    _SprScanLine = CWORD(_SprY(_SprNr0)) + HEIGHT
    IF SCAN() + LEAD >= _SprScanLine THEN GOTO ZoneN

    'If there is time, schedule interrupt to trigger the next sprite re-use
    ON RASTER _SprScanLine GOSUB ZoneN

    BORDER 0
    RETURN

ZoneNDone:
    'If we are already late from sorting interrupt, go there directly
    IF SCAN() > 250 THEN GOTO Zone0

    'If there is time, schedule interrupt to trigger Zone0
    ON RASTER 256 GOSUB Zone0

    BORDER 0
    RETURN

'This is the once per frame interrupt that
' - sorts the software sprites by y-coordinate
' - copies public registers to internal sprite data in sorted order
' - assigns software sprites 0-7 to hardware sprites
Zone0:
    BORDER 2

    'If main program wants to commit the changes to sprite registers, do it now
    IF _SprUpdate THEN
        _SprUpdate = FALSE
        BACKGROUND 6

        'This is the sorting algorithm
        FOR _SprNr0 = 0 TO 14
            IF SprY(_SprIdx(_SprNr0)) > SprY(_SprIdx(_SprNr0 + 1)) THEN
                _SprNr1 = _SprNr0

                DO
                    SWAP _SprIdx(_SprNr1), _SprIdx(_SprNr1 + 1)
                    IF _SprNr1 = 0 THEN EXIT DO
                    _SprNr1 = _SprNr1 - 1
                LOOP UNTIL SprY(_SprIdx(_SprNr1 + 1)) >= SprY(_SprIdx(_SprNr1))
            END IF
        NEXT _SprNr0

        'Copy sprite data in sorted order from public registers to internal registers
        FOR _SprNr0 = 0 TO 15
            _SprNr1 = _SprIdx(_SprNr0)
            _SprY(_SprNr0) = SprY(_SprNr1)
            _SprX(_SprNr0) = SprX(_SprNr1)
            _SprCol(_SprNr0) = SprCol(_SprNr1)
            _SprShape(_SprNr0) = SprShape(_SprNr1)
        NEXT _SprNr0
    END IF

    'Assign software sprites 0-7 to hardware sprites
    FOR _SprNr0 = 0 TO 7
        SPRITE _SprNr0 AT SHL(CWORD(_SprX(_SprNr0)),1), _SprY(_SprNr0) SHAPE _SprShape(_SprNr0) COLOR _SprCol(_SprNr0)
    NEXT _SprNr0

    'Initialize sprite reuse counter
    _SprNr0 = 0

    'Check if first hardware sprite reuse is so close that it needs to be done immediately
    _SprScanLine = CWORD(_SprY(0)) + HEIGHT
    IF SCAN() < 256 THEN
        IF (SCAN() + LEAD) >= _SprScanLine THEN GOTO ZoneN
    END IF

    'If there is time, schedule interrupt to handle first hardware sprite reuse
    ON RASTER _SprScanLine GOSUB ZoneN

    BORDER 0
    RETURN

THE_END:

SUB SprUpdate() STATIC SHARED
    'BACKGROUND 3
    _SprUpdate = TRUE
    DO WHILE _SprUpdate     'Wait for Zone0-interrupt-handler to process sprite changes
    LOOP
END SUB