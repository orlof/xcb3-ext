INCLUDE "lib_joy.bas"

REM *********************************
REM        PUBLIC INTERFACE
REM *********************************

DECLARE SUB UiLattice(X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SC0 AS BYTE, SC1 AS BYTE, C0 AS BYTE, C1 AS BYTE) SHARED STATIC
DECLARE FUNCTION UiPetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC

REM PUBLIC METHODS OF UiPanel
'DECLARE SUB UiPanel.Init(Title AS String*20, X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SaveBg AS BYTE) SHARED STATIC
'DECLARE SUB UiPanel.SetEvents(Up AS BYTE, Down AS BYTE, Left AS BYTE, Right AS BYTE, Fire AS BYTE) SHARED STATIC
'DECLARE SUB UiPanel.SetFocus(Focus AS BYTE) SHARED STATIC
'DECLARE SUB UiPanel.Dispose() SHARED STATIC
'DECLARE SUB UiPanel.Left(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) SHARED STATIC OVERLOAD
'DECLARE SUB UiPanel.Left(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) SHARED STATIC OVERLOAD
'DECLARE SUB UiPanel.Right(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) SHARED STATIC OVERLOAD
'DECLARE SUB UiPanel.Right(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) SHARED STATIC OVERLOAD
'DECLARE SUB UiPanel.Center(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) SHARED STATIC OVERLOAD
'DECLARE SUB UiPanel.Center(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) SHARED STATIC

REM THESE ARE NOT TYPICALLY NEEDED
'DECLARE SUB UiPanel.Push() SHARED STATIC
'DECLARE SUB UiPanel.Draw(Focus AS BYTE, ClearBg AS BYTE) SHARED STATIC

REM PUBLIC PROPERTIES OF UiPanel
'DECLARE PROPERTY UiPanel.Selected AS BYTE
'DECLARE PROPERTY UiPanel.Event AS BYTE
'    EVENT_UP
'    EVENT_DOWN
'    EVENT_LEFT
'    EVENT_RIGHT
'    EVENT_FIRE

CONST UI_CACHE_SIZE = 1024              'CONFIGURE THIS TO YOUR NEEDS

SHARED CONST EVENT_UP       = $80
SHARED CONST EVENT_DOWN     = $81
SHARED CONST EVENT_LEFT     = $82
SHARED CONST EVENT_RIGHT    = $83
SHARED CONST EVENT_FIRE     = $84

CONST TOP_LEFT_CORNER       = 85
CONST TOP_RIGHT_CORNER      = 73
CONST BOTTOM_LEFT_CORNER    = 74
CONST BOTTOM_RIGHT_CORNER   = 75
CONST HORIZONTAL_LINE       = 67
CONST VERTICAL_LINE         = 93
CONST EMPTY_SPACE           = 32

DIM SHARED Joystick AS BYTE
DIM SHARED UiDelay AS BYTE
DIM SHARED BorderFocusColor AS BYTE
DIM SHARED BorderNoFocusColor AS BYTE
DIM SHARED BackgroundColor AS BYTE

Joystick            = JOY2              'CONFIGURE THIS TO YOUR NEEDS
UiDelay             = 10                'CONFIGURE THIS TO YOUR NEEDS
BorderFocusColor    = $0c               'CONFIGURE THIS TO YOUR NEEDS
BorderNoFocusColor  = $0b               'CONFIGURE THIS TO YOUR NEEDS
BackgroundColor     = $0f               'CONFIGURE THIS TO YOUR NEEDS

REM *********************************
REM     END OF PUBLIC INTERFACE
REM *********************************

CONST FALSE                 = 0
CONST TRUE                  = 255

CONST EVENT_UP_FLAG         = $01
CONST EVENT_DOWN_FLAG       = $02
CONST EVENT_LEFT_FLAG       = $04
CONST EVENT_RIGHT_FLAG      = $08
CONST EVENT_FIRE_FLAG       = $10

DIM ScreenCache(UI_CACHE_SIZE) AS BYTE
DIM ScreenCacheSize AS WORD
ScreenCacheSize = 0

DIM PETSCII_TO_SCREENCODE(8) AS BYTE @ _PETSCII_TO_SCREENCODE
DIM SCREEN_OFFSET_LO(25) AS BYTE @ _SCREEN_OFFSET_LO
DIM SCREEN_OFFSET_HI(25) AS BYTE @ _SCREEN_OFFSET_HI
DIM BANK(25) AS BYTE @ _BANK

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

FUNCTION UiPetsciiToScreenCode AS BYTE(Petscii AS BYTE) SHARED STATIC
    IF Petscii = $ff THEN RETURN $5e
    RETURN Petscii + PETSCII_TO_SCREENCODE(SHR(Petscii, 5))
END FUNCTION

SUB _SetCharModeAt(X AS BYTE, Y AS BYTE, Mode AS BYTE) STATIC
    DIM Ptr AS WORD
    Ptr = _GetScreenPtr(X, Y)
    IF Mode THEN
        POKE Ptr, PEEK(Ptr) OR 128
    ELSE
        POKE Ptr, PEEK(Ptr) AND %01111111
    END IF
END SUB

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
    Title AS STRING*20
    SaveBg AS BYTE

    FocusRows AS LONG
    Events AS BYTE

    Selected AS BYTE
    Event AS BYTE

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

    SUB Dispose() STATIC
        IF THIS.SaveBg THEN
            FOR CY AS INT = THIS.Y + THIS.Height - 1 TO THIS.Y STEP -1
                FOR CX AS INT = THIS.X + THIS.Width - 1 TO THIS.X STEP -1
                    ScreenCacheSize = ScreenCacheSize - 2
                    POKE _GetScreenPtr(CBYTE(CX), CBYTE(CY)), ScreenCache(ScreenCacheSize)
                    POKE _GetColorPtr(CBYTE(CX), CBYTE(CY)), ScreenCache(ScreenCacheSize+1)
                NEXT CX
            NEXT CY
        END IF
    END SUB

    SUB SetEvents(Up AS BYTE, Down AS BYTE, Left AS BYTE, Right AS BYTE, Fire AS BYTE) STATIC
        THIS.Events = 0
        IF Up THEN
            THIS.Events = THIS.Events OR EVENT_UP_FLAG
        END IF
        IF Down THEN
            THIS.Events = THIS.Events OR EVENT_DOWN_FLAG
        END IF
        IF Left THEN
            THIS.Events = THIS.Events OR EVENT_LEFT_FLAG
        END IF
        IF Right THEN
            THIS.Events = THIS.Events OR EVENT_RIGHT_FLAG
        END IF
        IF Fire THEN
            THIS.Events = THIS.Events OR EVENT_FIRE_FLAG
        END IF
    END SUB

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
                    CHARAT Col, Row, EMPTY_SPACE, BackgroundColor
                NEXT Col
            END IF
        NEXT Row
        TEXTAT THIS.X+1, THIS.Y, THIS.Title, BorderColor
    END SUB

    SUB SetFocus(Focus AS BYTE) STATIC
        CALL THIS.Draw(Focus, FALSE)
    END SUB

    SUB Init(Title AS String*20, X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SaveBg AS BYTE) STATIC
        THIS.Title = LEFT$(Title, Width-2)
        THIS.X = X
        THIS.Y = Y
        THIS.Width = Width
        THIS.Height = Height

        THIS.Selected = 255
        THIS.Events = EVENT_FIRE_FLAG
        THIS.FocusRows = 0

        THIS.SaveBg = SaveBg
        IF SaveBg THEN CALL THIS.Push()

        'HEURISTICS: IF THE PANEL IS TEMPORARY, IT HAS FOCUS
        CALL THIS.Draw(SaveBg, TRUE)
    END SUB

    SUB _TextAt(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC
        DIM SC AS BYTE
        FOR Pos AS BYTE = 0 TO LEN(Text) - 1
            SC = UiPetsciiToScreenCode(PEEK(@Text+Pos+1))
            IF Y = THIS.Selected THEN SC = SC OR 128
            CHARAT THIS.X + X + Pos + 1, THIS.Y + Y + 1, SC, TextColor
        NEXT Pos

        IF Focusable THEN
            THIS.FocusRows = (THIS.FocusRows OR SHL(CLONG(1), Y))
        ELSE
            THIS.FocusRows = (THIS.FocusRows AND SHL($7ffffe, Y))
        END IF
    END SUB

    SUB Left(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(0, Y, Text, TextColor, Focusable)
    END SUB
    SUB Left(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(X, Y, Text, TextColor, Focusable)
    END SUB
    SUB Right(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(THIS.Width - LEN(Text) - 2, Y, Text, TextColor, Focusable)
    END SUB
    SUB Right(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(X + 1 - LEN(Text), Y, Text, TextColor, Focusable)
    END SUB
    SUB Center(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt((THIS.Width - LEN(Text) - 2) / 2, Y, Text, TextColor, Focusable)
    END SUB
    SUB Center(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE) STATIC OVERLOAD
        CALL THIS._TextAt(X - (LEN(Text) / 2), Y, Text, TextColor, Focusable)
    END SUB

    SUB _SetRowMode(Y AS BYTE, Set AS BYTE) STATIC
        DIM Row AS BYTE
        Row = THIS.Y + Y + 1
        FOR Col AS BYTE = THIS.X + 1 TO THIS.X + THIS.Width - 2
            CALL _SetCharModeAt(Col, Row, Set)
        NEXT Col
    END SUB

    SUB WaitEvent(AllowRepeat AS BYTE) STATIC
        IF NOT AllowRepeat THEN CALL JoyWaitIdle(Joystick)

        DO
            CALL _Sleep(1)
            CALL JoyUpdate()
            IF JoySame(Joystick) AND (JoyUp(Joystick) OR JoyDown(Joystick)) THEN
                CALL _Sleep(UiDelay)
                CALL JoyUpdate()
            END IF
            IF JoyUp(Joystick) THEN
                IF THIS.Selected < 255 THEN
                    CALL THIS._SetRowMode(THIS.Selected, FALSE)
                    DO
                        THIS.Selected = THIS.Selected - 1
                        IF THIS.Selected = 255 THEN
                            IF (THIS.Events AND EVENT_UP_FLAG) THEN
                                THIS.Event = EVENT_UP
                                EXIT SUB
                            END IF
                            THIS.Selected = THIS.Height - 3
                        END IF
                    LOOP UNTIL (SHR(THIS.FocusRows, THIS.Selected) AND 1) > 0
                    CALL THIS._SetRowMode(THIS.Selected, TRUE)
                END IF
            END IF
            IF JoyDown(Joystick) THEN
                IF THIS.Selected < 255 THEN
                    CALL THIS._SetRowMode(THIS.Selected, FALSE)
                    DO
                        THIS.Selected = THIS.Selected + 1
                        IF THIS.Selected = (THIS.Height - 2) THEN
                            IF (THIS.Events AND EVENT_DOWN_FLAG) THEN
                                THIS.Event = EVENT_DOWN
                                EXIT SUB
                            END IF
                            THIS.Selected = 0
                        END IF
                    LOOP UNTIL (SHR(THIS.FocusRows, THIS.Selected) AND 1) > 0
                    CALL THIS._SetRowMode(THIS.Selected, TRUE)
                END IF
            END IF
            IF JoyLeft(Joystick) THEN
                IF (THIS.Events AND EVENT_LEFT_FLAG) THEN
                    'THIS.Selected = 255
                    THIS.Event = EVENT_LEFT
                    EXIT SUB
                END IF
            END IF
            IF JoyRight(Joystick) THEN
                IF (THIS.Events AND EVENT_RIGHT_FLAG) THEN
                    THIS.Event = EVENT_RIGHT
                    EXIT SUB
                END IF
            END IF
            IF JoyFire(Joystick) THEN
                IF (THIS.Events AND EVENT_FIRE_FLAG) THEN
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