# XC-Basic3 UI Library

## Installation Instructions

1. Copy the lib_ui.bas file to your project folder.
2. Add the following line to your main program:
```basic
    INCLUDE "lib_ui.bas"
```
3. Modify the configuration parameters in lib_ui.bas to suit your needs.

Configuration Parameters
Configure the following parameters in the lib_ui.bas file:

```basic
    REM *********************************
    REM     CONFIGURATION PARAMETERS
    REM *********************************

    ' THE SIZE OF THE SCREEN CACHE.
    ' THIS IS USED TO SAVE THE SCREEN BEHIND PANELS
    ' REQUIRED SIZE IS THE SUM OF SIMULTANEOUSLY
    ' OPEN PANELS: 2 * WIDTH * HEIGHT
    ' CAN BE 0, IF ALL PANELS ARE INITIALIZED WITH
    '   SaveBg=FALSE
    CONST UI_CACHE_SIZE         = 1024

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

    ' THE JOYSTICK TO USE: JOY1 OR JOY2
    Joystick                    = JOY2

    ' THE DELAY BETWEEN JOYSTICK REPETITIONS (FRAMES)
    UiDelay                     = 10

    ' COLOR CODES
    BorderFocusColor            = $0c
    BorderNoFocusColor          = $0b
    ClientAreaColor             = $0f
```
Adjust the values as needed for your specific project requirements.

## API Documentation

Below is the detailed documentation for each subroutine provided by the XCB3-GFX library.

### UiLattice
#### UiLattice(X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SC0 AS BYTE, SC1 AS BYTE, C0 AS BYTE, C1 AS BYTE)

Draws a fancy lattice pattern with alternating characters.

**Parameters**
- **X**: The X-coordinate of the top-left corner of the lattice.
- **Y**: The Y-coordinate of the top-left corner of the lattice.
- **Width**: The width of the lattice.
- **Height**: The height of the lattice.
- **SC0**: Screen code for character 0.
- **SC1**: Screen code for character 1.
- **C0**: Color for character 0.
- **C1**: Color for character 1.

### UiPetsciiToScreenCode
#### UiPetsciiToScreenCode AS BYTE(Petscii AS BYTE)
Converts a PETSCII character to a screen code.

**Parameters**
- **Petscii**: The PETSCII character to be converted.

**Returns**
- BYTE screen code value

### UiPanel.Dispose
#### UiPanel.Dispose()

Disposes of the panel and restores the screen behind it if SaveBg is set to TRUE.

### UiPanel.SetEvents
#### UiPanel.SetEvents(Up AS BYTE, Down AS BYTE, Left AS BYTE, Right AS BYTE, Fire AS BYTE)

Specifies the events that can trigger in WaitEvent().

**Parameters**
- **Up**: Defines what happens when user navigates up from the top row
  - **TRUE**: EVENT_UP is triggered
  - **FALSE**: focus wraps to the bottom

- **Down**: Defines what happens when user navigates down from the last row
  - **TRUE**: EVENT_DOWN is triggered
  - **FALSE**: focus wraps to the top

- **Left**: Defines what happens when user navigates left
  - **TRUE**: EVENT_LEFT is triggered
  - **FALSE**: EVENT_LEFT is not triggered

- **Right**: Defines what happens when user navigates right
  - **TRUE**: EVENT_RIGHT is triggered
  - **FALSE**: EVENT_RIGHT is not triggered

- **Fire**: Defines what happens when user presses the fire button
  - **TRUE**: EVENT_FIRE is triggered
  - **FALSE**: EVENT_FIRE is not triggered

### UiPanel.SetFocus
#### UiPanel.SetFocus(Focus AS BYTE)

Sets or removes the focus from the panel by redrawing the border.

**Parameters**
- **Focus**: Boolean value.

### UiPanel.Init
#### Init(Title AS String*20, X AS BYTE, Y AS BYTE, Width AS BYTE, Height AS BYTE, SaveBg AS BYTE)
Initializes a panel with the specified parameters.

**Parameters**
- **Title**: The title of the panel (max length is 20 characters).
- **X**: The X-coordinate of the top-left border.
- **Y**: The Y-coordinate of the top-left border.
- **Width**: The width of the panel, including the borders.
- **Height**: The height of the panel, including the borders.
- **SaveBg**: If TRUE, the background is restored when panel is disposed.

### WaitEvent
#### WaitEvent(AllowRepeat AS BYTE)

Waits for the user to trigger an event.

**Parameters**
- **AllowRepeat**:
  - **TRUE**: The previous event can repeat by holding the joystick position
  - **FALSE**: The previous event cannot repeat without releasing the joystick

**Returns**
- Does not return anything, but when this method returns, caller should check
  - **UiPanel.Selected**: Row that originates the event
  - **UiPanel.Event** - event type. one of
    - EVENT_UP
    - EVENT_DOWN
    - EVENT_LEFT
    - EVENT_RIGHT
    - EVENT_FIRE
  - see SetEvents()

### Text Methods

The library provides several methods to add text to panels.

#### Left(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE)
Adds left-aligned text to the panel.

**Parameters**
- **Y**: The Y-coordinate of the text (0 is the first row after the border).
- **Text**: The text to display (max length is 20 characters).
- **TextColor**: The color of the text.
- **Focusable**:
  - **TRUE**: text can be selected
  - **FALSE**: the text is a non-selectable label


#### Left(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE)
Adds left-aligned text to the panel at a specified X and Y coordinate.

**Parameters**
- **X**: The X-coordinate of the first character (0 is the first column after the border).
- **Y**: The Y-coordinate of the text (0 is the first row after the border).
- **Text**: The text to display (max length is 20 characters).
- **TextColor**: The color of the text.
- **Focusable**:
  - **TRUE**: text can be selected
  - **FALSE**: the text is a non-selectable label

#### Right(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE)
Adds right-aligned text to the panel.

**Parameters**
- **Y**: The Y-coordinate of the text (0 is the first row after the border).
- **Text**: The text to display (max length is 20 characters).
- **TextColor**: The color of the text.
- **Focusable**:
  - **TRUE**: text can be selected
  - **FALSE**: the text is a non-selectable label

#### Right(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE)
Adds right-aligned text to the panel at a specified X and Y coordinate.

**Parameters**
- **X**: The X-coordinate of the last character (0 is the first column after the border).
- **Y**: The Y-coordinate of the text (0 is the first row after the border).
- **Text**: The text to display (max length is 20 characters).
- **TextColor**: The color of the text.
- **Focusable**:
  - **TRUE**: text can be selected
  - **FALSE**: the text is a non-selectable label

#### Center(Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE)
Adds centered text to the panel.

**Parameters**
- **Y**: The Y-coordinate of the text (0 is the first row after the border).
- **Text**: The text to display (max length is 20 characters).
- **TextColor**: The color of the text.
- **Focusable**:
  - **TRUE**: text can be selected
  - **FALSE**: the text is a non-selectable label

#### Center(X AS BYTE, Y AS BYTE, Text AS String*20, TextColor AS BYTE, Focusable AS BYTE)
Adds centered text to the panel at a specified X and Y coordinate.

**Parameters**
- **X**: The X-coordinate of the center (0 is the first column after the border).
- **Y**: The Y-coordinate of the text (0 is the first row after the border).
- **Text**: The text to display (max length is 20 characters).
- **TextColor**: The color of the text.
- **Focusable**:
  - **TRUE**: text can be selected
  - **FALSE**: the text is a non-selectable label

## Example

```basic
INCLUDE "lib_ui.bas"

CONST FALSE                 = 0
CONST TRUE                  = 255

DECLARE SUB InfoPanel(Msg AS STRING*18) STATIC

CALL UiLattice(0, 0, 40, 25, 81, 81+128, 10, 13)

DIM RootPanel AS UiPanel
CALL RootPanel.Init("demo", 5, 5, 15, 15, TRUE)
CALL RootPanel.SetEvents(FALSE, FALSE, TRUE, FALSE, TRUE)

RootPanel.Selected = 0
CALL RootPanel.Left(0, "choice 1", 7, TRUE)
CALL RootPanel.Left(1, "choice 2", 7, TRUE)
CALL RootPanel.Left(2, "choice 3", 7, TRUE)

DO
    CALL RootPanel.WaitEvent(FALSE)
    CALL RootPanel.SetFocus(FALSE)

    SELECT CASE RootPanel.Event
        CASE EVENT_FIRE
            CALL InfoPanel("choice " + STR$(RootPanel.Selected))
        CASE EVENT_LEFT
            EXIT DO
    END SELECT
    CALL RootPanel.SetFocus(TRUE)
LOOP

CALL RootPanel.Dispose()
END

SUB InfoPanel(Msg AS STRING*18) STATIC
    DIM Panel AS UiPanel
    CALL Panel.Init("info", 10, 10, 20, 5, TRUE)
    CALL Panel.SetEvents(FALSE, FALSE, FALSE, FALSE, TRUE)

    CALL Panel.Center(1, Msg, 7, FALSE)

    CALL Panel.WaitEvent(FALSE)

    CALL Panel.Dispose()
END SUB
```
