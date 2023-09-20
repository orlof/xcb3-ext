REM **********************
REM *      GENERAL       *
REM **********************

CONST JOY1 = $dc01  ' Address for joystick 1
CONST JOY2 = $dc00  ' Address for joystick 2

' Define constants for joystick directions
CONST JOY_UP      = %00000001
CONST JOY_DOWN    = %00000010
CONST JOY_LEFT    = %00000100
CONST JOY_RIGHT   = %00001000
CONST JOY_FIRE    = %00010000
CONST JOY_ANY_DIR = %00001111
CONST JOY_ANY     = %00011111

' Declare variables to store joystick values
DIM Value1 AS BYTE
DIM Value2 AS BYTE

' Initialize joystick values
DIM Prev1 AS BYTE
Value1 = PEEK(JOY1) AND JOY_ANY
Prev1 = Value1

DIM Prev2 AS BYTE
Value2 = PEEK(JOY2) AND JOY_ANY
Prev2 = Value2

' Update all joystick registers with new values
SUB JoyUpdate() STATIC SHARED
    Prev1 = Value1
    Prev2 = Value2
    Value1 = PEEK(JOY1) AND JOY_ANY
    Value2 = PEEK(JOY2) AND JOY_ANY
END SUB

REM **********************
REM *    JOYSTICK 1      *
REM **********************

' Check current joystick states
FUNCTION Joy1Up AS BYTE() STATIC SHARED
    RETURN (Value1 AND JOY_UP) = 0
END FUNCTION

FUNCTION Joy1Down AS BYTE() STATIC SHARED
    RETURN (Value1 AND JOY_DOWN) = 0
END FUNCTION

FUNCTION Joy1Right AS BYTE() STATIC SHARED
    RETURN (Value1 AND JOY_RIGHT) = 0
END FUNCTION

FUNCTION Joy1Left AS BYTE() STATIC SHARED
    RETURN (Value1 AND JOY_LEFT) = 0
END FUNCTION

FUNCTION Joy1Fire AS BYTE() STATIC SHARED
    RETURN (Value1 AND JOY_FIRE) = 0
END FUNCTION

' Check if fire button state has changed
FUNCTION Joy1FirePressed AS BYTE() STATIC SHARED
    RETURN ((Prev1 AND JOY_FIRE) > 0) AND ((Value1 AND JOY_FIRE) = 0)
END FUNCTION

FUNCTION Joy1FireReleased AS BYTE() STATIC SHARED
    RETURN ((Prev1 AND JOY_FIRE) = 0) AND ((Value1 AND JOY_FIRE) > 0)
END FUNCTION

' Subroutine to wait for joystick button click (down+up)
SUB Joy1WaitClick() STATIC SHARED
    DO
        CALL JoyUpdate()
    LOOP UNTIL Joy1FirePressed()
    DO
        CALL JoyUpdate()
    LOOP UNTIL Joy1FireReleased()
END SUB

' Convenience funtions that can be used to change coordinates
FUNCTION Joy1XAxis AS INT() STATIC SHARED
    IF (Value1 AND JOY_LEFT) = 0 THEN RETURN -1
    IF (Value1 AND JOY_RIGHT) = 0 THEN RETURN 1
    RETURN 0
END FUNCTION

FUNCTION Joy1YAxis AS INT() STATIC SHARED
    IF (Value1 AND JOY_UP) = 0 THEN RETURN -1
    IF (Value1 AND JOY_DOWN) = 0 THEN RETURN 1
    RETURN 0
END FUNCTION


REM **********************
REM *    JOYSTICK 2      *
REM **********************

' Similar functions for joystick 2
FUNCTION Joy2Up AS BYTE() STATIC SHARED
    RETURN (Value2 AND JOY_UP) = 0
END FUNCTION

FUNCTION Joy2Down AS BYTE() STATIC SHARED
    RETURN (Value2 AND JOY_DOWN) = 0
END FUNCTION

FUNCTION Joy2Right AS BYTE() STATIC SHARED
    RETURN (Value2 AND JOY_RIGHT) = 0
END FUNCTION

FUNCTION Joy2Left AS BYTE() STATIC SHARED
    RETURN (Value2 AND JOY_LEFT) = 0
END FUNCTION

FUNCTION Joy2Fire AS BYTE() STATIC SHARED
    RETURN (Value2 AND JOY_FIRE) = 0
END FUNCTION

FUNCTION Joy2FirePressed AS BYTE() STATIC SHARED
    RETURN ((Prev2 AND JOY_FIRE) > 0) AND ((Value2 AND JOY_FIRE) = 0)
END FUNCTION

FUNCTION Joy2FireReleased AS BYTE() STATIC SHARED
    RETURN ((Prev2 AND JOY_FIRE) = 0) AND ((Value2 AND JOY_FIRE) > 0)
END FUNCTION

SUB Joy2WaitClick() STATIC SHARED
    DO
        CALL JoyUpdate()
    LOOP UNTIL Joy2FirePressed()

    DO
        CALL JoyUpdate()
    LOOP UNTIL Joy2FireReleased()
END SUB

FUNCTION Joy2XAxis AS INT() STATIC SHARED
    IF (Value2 AND JOY_LEFT) = 0 THEN RETURN -1
    IF (Value2 AND JOY_RIGHT) = 0 THEN RETURN 1
    RETURN 0
END FUNCTION

FUNCTION Joy2YAxis AS INT() STATIC SHARED
    IF (Value2 AND JOY_UP) = 0 THEN RETURN -1
    IF (Value2 AND JOY_DOWN) = 0 THEN RETURN 1
    RETURN 0
END FUNCTION
