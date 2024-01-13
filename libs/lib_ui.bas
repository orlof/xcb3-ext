DIM SHARED Joystick AS BYTE
DIM SHARED UiDelay AS BYTE
DIM SHARED BorderFocusColor AS BYTE
DIM SHARED BorderNoFocusColor AS BYTE
DIM SHARED ClientAreaColor AS BYTE

REM *********************************
REM     CONFIGURATION PARAMETERS
REM *********************************

' SUM FOR SIMULTANEOUSLY OPEN PANELS: 2 * WIDTH * HEIGHT
' PANELS INITIALIZED WITH SaveBg=FALSE ARE IGNORED
CONST UI_CACHE_SIZE         = 1024
CONST MAX_STRING_LENGTH     = 40

' THE SCREEN CODES FOR THE PANEL DECORATIONS
CONST TOP_LEFT_CORNER       = 85
CONST TOP_RIGHT_CORNER      = 73
CONST BOTTOM_LEFT_CORNER    = 74
CONST BOTTOM_RIGHT_CORNER   = 75
CONST HORIZONTAL_LINE       = 67
CONST VERTICAL_LINE         = 93
CONST EMPTY_SPACE           = 32

CONST DISPOSE_COLOR         = 14

' PETSCII CODES FOR KEYBOARD NAVIGATION
CONST KEY_UP                = 145
CONST KEY_DOWN              = 17
CONST KEY_LEFT              = 157
CONST KEY_RIGHT             = 29
CONST KEY_FIRE              = 13

' NOT NEEDED IF lib_joy.bas is included
'CONST JOY1                  = 0
'CONST JOY2                  = 1

' THE JOYSTICK TO USE: JOY1 OR JOY2
Joystick                    = JOY2

' THE DELAY BETWEEN JOYSTICK REPETITIONS (IN FRAMES)
UiDelay                     = 10

' COLOR CODES
BorderFocusColor            = $0c
BorderNoFocusColor          = $0b
ClientAreaColor             = $0f

REM *********************************
REM     END OF CONFIGURATION
REM *********************************

SHARED CONST EVENT_UP       = $01
SHARED CONST EVENT_DOWN     = $02
SHARED CONST EVENT_LEFT     = $04
SHARED CONST EVENT_RIGHT    = $08
SHARED CONST EVENT_FIRE     = $10

SHARED CONST NO_SELECTION   = 255

'CONST FALSE                 = 0
'CONST TRUE                  = 255

DECLARE SUB UiLattice(X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SC0 AS BYTE, SC1 AS BYTE, C0 AS BYTE, C1 AS BYTE) SHARED STATIC
DECLARE FUNCTION UiPetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC
DECLARE SUB _Sleep(NrFrames AS BYTE) STATIC
DECLARE FUNCTION _GetScreenPtr AS WORD(X AS BYTE, Y AS BYTE) STATIC
DECLARE FUNCTION _GetColorPtr AS WORD(X AS BYTE, Y AS BYTE) STATIC

DIM ScreenCache(UI_CACHE_SIZE) AS BYTE
DIM ScreenCacheSize AS WORD
ScreenCacheSize = 0

DIM PETSCII_TO_SCREENCODE(8) AS BYTE @ _PETSCII_TO_SCREENCODE
DIM SCREEN_OFFSET_LO(25) AS BYTE @ _SCREEN_OFFSET_LO
DIM SCREEN_OFFSET_HI(25) AS BYTE @ _SCREEN_OFFSET_HI
DIM BANK(4) AS BYTE @ _BANK

' PUBLIC
' DRAWS THE DEFINED SCREEN AREA WITH A PATTERN OF ALTERNATING CHARACTERS
'   SC0 AND C0 - SCREEN CODE AND COLOR FOR CHARACTER 0
'   SC1 AND C1 - SCREEN CODE AND COLOR FOR CHARACTER 1
' EXAMPLE
'   CALL UiLattice(0, 0, 40, 25, 81, 81+128, 10, 13)
SUB UiLattice(X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SC0 AS BYTE, SC1 AS BYTE, C0 AS BYTE, C1 AS BYTE) SHARED STATIC
    FOR Row AS BYTE = 0 TO Height - 1
        FOR Col AS BYTE = 0 TO Width - 1
            IF (Row XOR Col) AND 1 THEN
                CHARAT X + Col, Y + Row, SC1, C1
            ELSE
                CHARAT X + Col, Y + Row, SC0, C0
            END IF

        NEXT Col
    NEXT Row
END SUB

' PUBLIC
' CONVERTS A PETSCII CHARACTER TO A SCREEN CODE
FUNCTION UiPetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC
    IF Petscii = $ff THEN RETURN $5e
    RETURN Petscii + PETSCII_TO_SCREENCODE(SHR(Petscii, 5))
END FUNCTION


' INTERNAL
' RETURNS THE SCREEN MEMORY ADDRESS FOR THE GIVEN COORDINATES
FUNCTION _GetScreenPtr AS WORD(X AS BYTE, Y AS BYTE) STATIC
    ASM
        lda $dd00
        and #%00000011
        tax

        ldy {Y}
        lda {X}
        clc
        adc {SCREEN_OFFSET_LO},y
        sta {_GetScreenPtr}

        lda {SCREEN_OFFSET_HI},y
        adc {BANK},x
        sta {_GetScreenPtr}+1

        lda $d018
        and #$f0
        lsr
        lsr
        ora {_GetScreenPtr}+1
        sta {_GetScreenPtr}+1
    END ASM
END FUNCTION

' INTERNAL
' RETURNS THE COLOR MEMORY ADDRESS FOR THE GIVEN COORDINATES
FUNCTION _GetColorPtr AS WORD(X AS BYTE, Y AS BYTE) STATIC
    ASM
        ldy {Y}
        lda {SCREEN_OFFSET_LO},y
        clc
        adc {X}
        sta {_GetColorPtr}

        lda {SCREEN_OFFSET_HI},y
        adc #$d8
        sta {_GetColorPtr}+1
    END ASM
END FUNCTION

' INTERNAL
' SLEEPS FOR THE GIVEN NUMBER OF FRAMES
SUB _Sleep(NrFrames AS BYTE) STATIC
    ASM
        ldy {NrFrames}
sleep_loop
        bit $d011
        bmi *-3
        bit $d011
        bpl *-3

        dey
        bne sleep_loop
    END ASM
END SUB

TYPE UiPanel
    X AS BYTE
    Y AS BYTE
    Width AS BYTE
    Height AS BYTE
    Title AS String*MAX_STRING_LENGTH
    SaveBg AS BYTE

    FocusRows AS LONG
    Events AS BYTE

    Selected AS BYTE
    Event AS BYTE

    ' INTERNAL (PUBLIC)
    ' SAVES THE SCREEN BEHIND THE PANEL
    ' CALLED BY Init() IF SaveBg IS TRUE
    SUB Push() STATIC
        IF ScreenCacheSize + 2 * THIS.Width * THIS.Height > UI_CACHE_SIZE THEN
            ERROR 90 'OUT OF MEMORY
            END
        END IF
        FOR Row AS BYTE = THIS.Y TO THIS.Y + THIS.Height - 1
            FOR Col AS BYTE = THIS.X TO THIS.X + THIS.Width - 1
                ScreenCache(ScreenCacheSize) = PEEK(_GetScreenPtr(Col, Row))
                ScreenCache(ScreenCacheSize+1) = PEEK(_GetColorPtr(Col, Row))
                ScreenCacheSize = ScreenCacheSize + 2
            NEXT Col
        NEXT Row
    END SUB

    ' PUBLIC
    ' IF PANEL IS INITIALIZED WITH SaveBg=TRUE, THE SCREEN BEHIND THE PANEL IS RESTORED
    ' OTHERWISE CLEARS THE PANEL AREA WITH EMPTY SPACE AND DISPOSE COLOR
    SUB Dispose() STATIC
        FOR CY AS INT = THIS.Y + THIS.Height - 1 TO THIS.Y STEP -1
            FOR CX AS INT = THIS.X + THIS.Width - 1 TO THIS.X STEP -1
                IF THIS.SaveBg THEN
                    ScreenCacheSize = ScreenCacheSize - 2
                    POKE _GetScreenPtr(CBYTE(CX), CBYTE(CY)), ScreenCache(ScreenCacheSize)
                    POKE _GetColorPtr(CBYTE(CX), CBYTE(CY)), ScreenCache(ScreenCacheSize+1)
                ELSE
                    CHARAT CBYTE(CX), CBYTE(CY), EMPTY_SPACE, DISPOSE_COLOR
                END IF
            NEXT CX
        NEXT CY
    END SUB

    ' PUBLIC
    ' SPECIFIES THE EVENTS THAT CAN TRIGGER IN WaitEvent()
    '   U
    '       IF 1, EVENT_UP IS TRIGGERED WHEN USER NAVIGATES UP FROM TOP ROW
    '       IF 0, EVENT_UP IS NOT TRIGGERED AND FOCUS WRAPS FROM TOP TO BOTTOM
    '   Down
    '       IF 1, EVENT_DOWN IS TRIGGERED WHEN USER NAVIGATES DOWN FROM BOTTOM ROW
    '       IF 0, EVENT_DOWN IS NOT TRIGGERED AND FOCUS WRAPS FROM BOTTOM TO TOP
    '   Left
    '       IF 1, EVENT_LEFT IS TRIGGERED WHEN USER PRESSES LEFT
    '       IF 0, LEFT PRESS IS IGNORED
    '   Right
    '       IF 1, EVENT_RIGHT IS TRIGGERED WHEN USER PRESSES RIGHT
    '       IF 0, RIGHT PRESS IS IGNORED
    '   Fire
    '       IF 1, EVENT_FIRE IS TRIGGERED WHEN USER PRESSES FIRE
    '       IF 0, FIRE PRESS IS IGNORED
    SUB SetEvents(Events AS BYTE) STATIC
        THIS.Events = Events
    END SUB

    ' INTERNAL (PUBLIC)
    ' DRAWS THE PANEL BORDER AND OPTIONALLY CLEARS THE CLIENT AREA
    ' CALLED AUTOMATICALLY BY Init() AND SetFocus()
    '   Focus
    '       IF TRUE, BORDER IS DRAWN WITH FOCUS COLOR
    '       IF FALSE, BORDER IS DRAWN WITH NO-FOCUS COLOR
    '   ClearBg
    '       IF TRUE, CLIENT AREA IS CLEARED WITH BACKGROUND COLOR
    '       IF FALSE, CLIENT AREA IS LEFT INTACT
    SUB Draw(Focus AS BYTE, ClearBg AS BYTE) STATIC
        DIM LastCol AS BYTE, LastRow AS BYTE, BorderColor AS BYTE
        LastCol = THIS.X + THIS.Width - 1
        LastRow = THIS.Y + THIS.Height - 1
        IF Focus THEN
            BorderColor = BorderFocusColor
        ELSE
            BorderColor = BorderNoFocusColor
        END IF
        CHARAT THIS.X, THIS.Y, TOP_LEFT_CORNER, BorderColor
        CHARAT LastCol, THIS.Y, TOP_RIGHT_CORNER, BorderColor
        CHARAT THIS.X, LastRow, BOTTOM_LEFT_CORNER, BorderColor
        CHARAT LastCol, LastRow, BOTTOM_RIGHT_CORNER, BorderColor
        FOR Col AS BYTE = THIS.X+1 TO LastCol - 1
            CHARAT Col, THIS.Y, HORIZONTAL_LINE, BorderColor
            CHARAT Col, LastRow, HORIZONTAL_LINE, BorderColor
        NEXT Col
        FOR Row AS BYTE = THIS.Y+1 TO LastRow - 1
            CHARAT THIS.X, Row, VERTICAL_LINE, BorderColor
            CHARAT LastCol, Row, VERTICAL_LINE, BorderColor
            IF ClearBg THEN
                FOR Col = THIS.X+1 TO LastCol - 1
                    CHARAT Col, Row, EMPTY_SPACE, ClientAreaColor
                NEXT Col
            END IF
        NEXT Row
        TEXTAT THIS.X+1, THIS.Y, THIS.Title, BorderColor
    END SUB

    ' PUBLIC
    ' SETS OR REMOVES THE FOCUS TO/FROM THE PANEL BY REDRAWING THE BORDER
    ' CURRENTLY SAME AS Draw(Focus, FALSE)
    '   Focus
    '       IF TRUE, THE PANEL HAS FOCUS AND THE BORDER IS DRAWN WITH FOCUS COLOR
    '       IF FALSE, THE PANEL HAS NO FOCUS AND THE BORDER IS DRAWN WITH NO FOCUS COLOR
    SUB SetFocus(Focus AS BYTE) STATIC
        CALL THIS.Draw(Focus, FALSE)
    END SUB

    ' PUBLIC
    ' INITIALIZES THE PANEL
    '   Title - THE TITLE OF THE PANEL (MAX LENGTH IS 20 CHARACTERS)
    '   X - THE X COORDINATE OF THE TOP LEFT BORDER
    '   Y - THE Y COORDINATE OF THE TOP LEFT BORDER
    '   Width - THE WIDTH OF THE PANEL INCLUDING THE BORDERS
    '   Height - THE HEIGHT OF THE PANEL INCLUDING THE BORDERS
    '   SaveBg - IF TRUE, THE PANEL WILL SAVE THE SCREEN BEHIND IT AND CAN BE DISPOSED
    SUB Init(Title AS String*MAX_STRING_LENGTH, X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SaveBg AS BYTE) STATIC
        THIS.Title = LEFT$(Title, Width-2)
        THIS.X = X
        THIS.Y = Y
        THIS.Width = Width
        THIS.Height = Height

        THIS.Selected = 255
        THIS.Events = EVENT_FIRE
        THIS.FocusRows = 0

        THIS.SaveBg = SaveBg
        IF SaveBg THEN CALL THIS.Push()

        'HEURISTICS: IF THE PANEL IS TEMPORARY, IT HAS FOCUS
        CALL THIS.Draw(SaveBg, TRUE)
    END SUB

    ' INTERNAL
    SUB _SetRowMode(Y AS BYTE, IsSelected AS BYTE) STATIC
        DIM Row AS BYTE
        Row = THIS.Y + Y + 1
        FOR Col AS BYTE = THIS.X + 1 TO THIS.X + THIS.Width - 2
            DIM Ptr AS WORD
            Ptr = _GetScreenPtr(Col, Row)
            IF IsSelected THEN
                POKE Ptr, PEEK(Ptr) OR 128
            ELSE
                POKE Ptr, PEEK(Ptr) AND %01111111
            END IF
        NEXT Col
    END SUB

    SUB SetSelected(Selected AS BYTE) STATIC
        IF THIS.Selected < 255 THEN
            CALL THIS._SetRowMode(THIS.Selected, FALSE)
        END IF
        THIS.Selected = Selected
        IF Selected < 255 THEN
            CALL THIS._SetRowMode(THIS.Selected, TRUE)
        END IF
    END SUB

    ' INTERNAL
    SUB _TextAt(X AS BYTE, Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC
        DIM SC AS BYTE
        FOR Pos AS BYTE = 0 TO LEN(Text) - 1
            SC = UiPetsciiToScreenCode(PEEK(@Text+Pos+1))
            CHARAT THIS.X + X + Pos + 1, THIS.Y + Y + 1, SC, TextColor
        NEXT Pos

        IF Focusable THEN
            IF Y = THIS.Selected THEN CALL THIS._SetRowMode(Y, TRUE)
            THIS.FocusRows = (THIS.FocusRows OR SHL(CLONG(1), Y))
        ELSE
            THIS.FocusRows = (THIS.FocusRows AND (SHL(CLONG(1), Y) XOR $7fffff))
        END IF
    END SUB

    ' ADD LEFT ALIGNED TEXT
    '   Y - THE Y COORDINATE OF THE TEXT (0 IS THE FIRST ROW AFTER THE BORDER)
    '   Text - THE TEXT TO DISPLAY (MAX LENGTH IS 20 CHARACTERS)
    '   TextColor - THE COLOR OF THE TEXT
    '   Focusable
    '       IF TRUE, THE TEXT CAN BE SELECTED
    '       IF FALSE, THE TEXT IS NON SELECTABLE LABEL
    SUB Left(Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(0, Y, Text, TextColor, Focusable)
    END SUB

    ' ADD LEFT ALIGNED TEXT TO GIVEN X COORDINATE
    '   X - THE X COORDINATE OF THE FIRST CHARACTER (0 IS THE FIRST COLUMN AFTER THE BORDER)
    '   Y - THE Y COORDINATE OF THE TEXT (0 IS THE FIRST ROW AFTER THE BORDER)
    '   Text - THE TEXT TO DISPLAY (MAX LENGTH IS 20 CHARACTERS)
    '   TextColor - THE COLOR OF THE TEXT
    '   Focusable
    '       IF TRUE, THE TEXT CAN BE SELECTED
    '       IF FALSE, THE TEXT IS NON SELECTABLE LABEL
    SUB Left(X AS BYTE, Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(X, Y, Text, TextColor, Focusable)
    END SUB

    ' ADD RIGHT ALIGNED TEXT
    '   Y - THE Y COORDINATE OF THE TEXT (0 IS THE FIRST ROW AFTER THE BORDER)
    '   Text - THE TEXT TO DISPLAY (MAX LENGTH IS 20 CHARACTERS)
    '   TextColor - THE COLOR OF THE TEXT
    '   Focusable
    '       IF TRUE, THE TEXT CAN BE SELECTED
    '       IF FALSE, THE TEXT IS NON SELECTABLE LABEL
    SUB Right(Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(THIS.Width - LEN(Text) - 2, Y, Text, TextColor, Focusable)
    END SUB

    ' ADD RIGHT ALIGNED TEXT TO GIVEN X COORDINATE
    '   X - THE X COORDINATE OF THE LAST CHARACTER (0 IS THE FIRST COLUMN AFTER THE BORDER)
    '   Y - THE Y COORDINATE OF THE TEXT (0 IS THE FIRST ROW AFTER THE BORDER)
    '   Text - THE TEXT TO DISPLAY (MAX LENGTH IS 20 CHARACTERS)
    '   TextColor - THE COLOR OF THE TEXT
    '   Focusable
    '       IF TRUE, THE TEXT CAN BE SELECTED
    '       IF FALSE, THE TEXT IS NON SELECTABLE LABEL
    SUB Right(X AS BYTE, Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(X + 1 - LEN(Text), Y, Text, TextColor, Focusable)
    END SUB

    ' ADD CENTERED TEXT
    '   Y - THE Y COORDINATE OF THE TEXT (0 IS THE FIRST ROW AFTER THE BORDER)
    '   Text - THE TEXT TO DISPLAY (MAX LENGTH IS 20 CHARACTERS)
    '   TextColor - THE COLOR OF THE TEXT
    '   Focusable
    '       IF TRUE, THE TEXT CAN BE SELECTED
    '       IF FALSE, THE TEXT IS NON SELECTABLE LABEL
    SUB Center(Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt((THIS.Width - LEN(Text) - 2) / 2, Y, Text, TextColor, Focusable)
    END SUB

    ' ADD CENTERED TEXT TO THE GIVEN X COORDINATE
    '   X - THE X COORDINATE OF THE CENTER (0 IS THE FIRST COLUMN AFTER THE BORDER)
    '   Y - THE Y COORDINATE OF THE TEXT (0 IS THE FIRST ROW AFTER THE BORDER)
    '   Text - THE TEXT TO DISPLAY (MAX LENGTH IS 20 CHARACTERS)
    '   TextColor - THE COLOR OF THE TEXT
    '   Focusable
    '       IF TRUE, THE TEXT CAN BE SELECTED
    '       IF FALSE, THE TEXT IS NON SELECTABLE LABEL
    SUB Center(X AS BYTE, Y AS BYTE, Text AS String*MAX_STRING_LENGTH, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(X - (LEN(Text) / 2), Y, Text, TextColor, Focusable)
    END SUB

    ' PUBLIC
    ' WAITS FOR USER TO TRIGGER AN EVENT
    '   AllowRepeat
    '       IF TRUE, THE PREVIOUS EVENT CAN REPEAT BY HOLDING THE JOYSTICK POSITION
    '       IF FALSE, THE PREVIOUS EVENT CANNOT REPEAT WITHOUT RELEASING THE JOYSTICK
    ' WHEN THIS METHOD RETURNS, CALLER SHOULD CHECK
    '   UiPanel.Selected - ROW THAT ORIGINATED THE EVENT
    '   UiPanel.Event - EVENT TYPE. ONE OF
    '       EVENT_UP
    '       EVENT_DOWN
    '       EVENT_LEFT
    '       EVENT_RIGHT
    '       EVENT_FIRE
    SUB WaitEvent(AllowRepeat AS BYTE) STATIC
        DIM Key AS BYTE
        IF NOT AllowRepeat THEN CALL JoyWaitIdle(Joystick)

        DO
            CALL _Sleep(1)
            CALL JoyUpdate()
            GET Key
            IF JoySame(Joystick) AND (JoyUp(Joystick) OR JoyDown(Joystick)) THEN
                CALL _Sleep(UiDelay)
                CALL JoyUpdate()
            END IF
            IF JoyUp(Joystick) OR Key=KEY_UP THEN
                IF THIS.Selected < 255 THEN
                    CALL THIS._SetRowMode(THIS.Selected, FALSE)
                    DO
                        THIS.Selected = THIS.Selected - 1
                        IF THIS.Selected = 255 THEN
                            IF (THIS.Events AND EVENT_UP) THEN
                                THIS.Event = EVENT_UP
                                EXIT SUB
                            END IF
                            THIS.Selected = THIS.Height - 3
                        END IF
                    LOOP UNTIL (SHR(THIS.FocusRows, THIS.Selected) AND 1) > 0
                    CALL THIS._SetRowMode(THIS.Selected, TRUE)
                END IF
            END IF
            IF JoyDown(Joystick) OR Key=KEY_DOWN THEN
                IF THIS.Selected < 255 THEN
                    CALL THIS._SetRowMode(THIS.Selected, FALSE)
                    DO
                        THIS.Selected = THIS.Selected + 1
                        IF THIS.Selected = (THIS.Height - 2) THEN
                            IF (THIS.Events AND EVENT_DOWN) THEN
                                THIS.Event = EVENT_DOWN
                                EXIT SUB
                            END IF
                            THIS.Selected = 0
                        END IF
                    LOOP UNTIL (SHR(THIS.FocusRows, THIS.Selected) AND 1) > 0
                    CALL THIS._SetRowMode(THIS.Selected, TRUE)
                END IF
            END IF
            IF JoyLeft(Joystick) OR Key=KEY_LEFT THEN
                IF (THIS.Events AND EVENT_LEFT) THEN
                    'THIS.Selected = 255
                    THIS.Event = EVENT_LEFT
                    EXIT SUB
                END IF
            END IF
            IF JoyRight(Joystick) OR Key=KEY_RIGHT THEN
                IF (THIS.Events AND EVENT_RIGHT) THEN
                    THIS.Event = EVENT_RIGHT
                    EXIT SUB
                END IF
            END IF
            IF JoyFire(Joystick) OR Key=KEY_FIRE THEN
                IF (THIS.Events AND EVENT_FIRE) THEN
                    THIS.Event = EVENT_FIRE
                    EXIT SUB
                END IF
            END IF
        LOOP
    END SUB
END TYPE

_PETSCII_TO_SCREENCODE:
DATA AS BYTE $80, $00, $c0, $e0, $40, $c0, $80, $80
_SCREEN_OFFSET_LO:
DATA AS BYTE 0, 40, 80, 120, 160, 200, 240, 24, 64, 104, 144, 184, 224, 8, 48, 88, 128, 168, 208, 248, 32, 72, 112, 152, 192
_SCREEN_OFFSET_HI:
DATA AS BYTE 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3
_BANK:
DATA AS BYTE %11000000, %10000000, %01000000, %00000000
