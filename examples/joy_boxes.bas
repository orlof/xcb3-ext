
INCLUDE "../libs/lib_joy.bas"

MEMSET 16320, 64, 255

DIM X(2) AS WORD
DIM Y(2) AS BYTE

X(0) = 100
Y(0) = 100
X(1) = 200
Y(1) = 100

PRINT "Press joy2 fire to start"
CALL JoyWaitClick(JOY2)

DO
    SPRITE 0 AT X(0),Y(0) SHAPE 255 ON
    SPRITE 1 AT X(1),Y(1) SHAPE 255 ON

    ' Joystick values are updated here
    CALL JoyUpdate()

    ' This is the code that moves the sprite
    ' OPTION A
    IF JoyUp(JOY1) THEN
        Y(0) = Y(0) - 1
    END IF
    IF JoyDown(JOY1) THEN
        Y(0) = Y(0) + 1
    END IF
    IF JoyLeft(JOY1) THEN
        X(0) = X(0) - 1
    END IF
    IF JoyRight(JOY1) THEN
        X(0) = X(0) + 1
    END IF

    ' OPTION B
    X(1) = X(1) + JoyXAxis(JOY2)
    Y(1) = Y(1) + JoyYAxis(JOY2)

    IF JoyFirePressed(JOY1) OR JoyFirePressed(JOY2) THEN
        EXIT DO
    END IF

    ' DELAY
    DO
    LOOP WHILE SCAN() < 256
    DO
    LOOP WHILE SCAN() > 255

LOOP

