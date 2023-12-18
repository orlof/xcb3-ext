INCLUDE "lib_random.bas"
INCLUDE "lib_ui.bas"

CONST FALSE                 = 0
CONST TRUE                  = 255

DECLARE SUB MenuPanelHandler() STATIC
DECLARE SUB CheckBoxPanelHandler() STATIC
DECLARE SUB RadioButtonPanelHandler() STATIC
DECLARE SUB DistributorPanelHandler() STATIC
DECLARE SUB InfoPanelHandler(Msg AS STRING*18) STATIC

CALL UiLattice(0, 0, 40, 25, 81, 81+128, 10, 13)

DIM RootPanel AS UiPanel
CALL RootPanel.Init("choose demo", 5, 5, 15, 15, TRUE)
CALL RootPanel.SetEvents(FALSE, FALSE, FALSE, TRUE, TRUE)

RootPanel.Selected = 0
CALL RootPanel.Left(0, "menu", 7, TRUE)
CALL RootPanel.Left(1, "checkbox", 7, TRUE)
CALL RootPanel.Left(2, "radiobutton", 7, TRUE)
CALL RootPanel.Left(3, "distributor", 7, TRUE)
CALL RootPanel.left(5, "exit", 2, TRUE)

DO
    CALL RootPanel.WaitEvent(FALSE)
    CALL RootPanel.SetFocus(FALSE)

    IF RootPanel.Selected = 0 THEN CALL MenuPanelHandler()
    IF RootPanel.Selected = 1 THEN CALL CheckBoxPanelHandler()
    IF RootPanel.Selected = 2 THEN CALL RadioButtonPanelHandler()
    IF RootPanel.Selected = 3 THEN CALL DistributorPanelHandler()
    IF RootPanel.Selected = 5 THEN EXIT DO
    CALL RootPanel.SetFocus(TRUE)
LOOP

CALL RootPanel.Dispose()
END

SUB MenuPanelHandler() STATIC
    DIM Panel AS UiPanel
    CALL Panel.Init("choose info", 10, 10, 15, 10, TRUE)
    CALL Panel.SetEvents(FALSE, FALSE, TRUE, TRUE, TRUE)

    Panel.Selected = 0
    CALL Panel.Left(0, "info 1", 7, TRUE)
    CALL Panel.Left(1, "info 2", 7, TRUE)
    CALL Panel.Left(2, "info 3", 7, TRUE)

    DO
        CALL Panel.WaitEvent(FALSE)

        SELECT CASE Panel.Event
            CASE EVENT_FIRE
                CALL Panel.SetFocus(FALSE)
                CALL InfoPanelHandler("info " + STR$(Panel.Selected + 1))
                CALL Panel.SetFocus(TRUE)
            CASE EVENT_LEFT
                CALL Panel.Dispose()
                EXIT SUB
        END SELECT
    LOOP
END SUB

SUB CheckBoxPanelHandler() STATIC
    DIM Panel AS UiPanel
    DIM Selected(3) AS BYTE
    Selected(0) = 0
    Selected(1) = 0
    Selected(2) = 0

    CALL Panel.Init("choose pet", 10, 5, 14, 5, TRUE)
    CALL Panel.SetEvents(FALSE, FALSE, TRUE, FALSE, TRUE)

    Panel.Selected = 0
    CALL Panel.Left(0, CHR$(119) + " a dog", 7, TRUE)
    CALL Panel.Left(1, CHR$(119) + " a cat", 7, TRUE)
    CALL Panel.Left(2, CHR$(119) + " a fish", 7, TRUE)

    DO
        CALL Panel.WaitEvent(FALSE)

        SELECT CASE Panel.Event
            CASE EVENT_FIRE
                IF Selected(Panel.Selected) THEN
                    CALL Panel.Left(Panel.Selected, CHR$(119), 7, TRUE)
                    Selected(Panel.Selected) = FALSE
                ELSE
                    CALL Panel.Left(Panel.Selected, CHR$(113), 7, TRUE)
                    Selected(Panel.Selected) = TRUE
                END IF
            CASE EVENT_LEFT
                CALL Panel.SetFocus(FALSE)
                CALL InfoPanelHandler(STR$(Selected(0)) + " " + STR$(Selected(1)) + " " + STR$(Selected(2)))
                CALL Panel.Dispose()
                EXIT SUB
        END SELECT
    LOOP
END SUB

SUB RadioButtonPanelHandler() STATIC
    DIM Panel AS UiPanel
    DIM Selected AS BYTE
    Selected = 0

    CALL Panel.Init("choose vehicle", 10, 5, 14, 5, TRUE)
    CALL Panel.SetEvents(FALSE, FALSE, TRUE, FALSE, TRUE)

    Panel.Selected = 0
    CALL Panel.Left(0, CHR$(119) + " ferrari", 7, TRUE)
    CALL Panel.Left(1, CHR$(119) + " toyota", 7, TRUE)
    CALL Panel.Left(2, CHR$(119) + " hummer", 7, TRUE)

    DO
        CALL Panel.WaitEvent(FALSE)

        SELECT CASE Panel.Event
            CASE EVENT_FIRE
                CALL Panel.Left(Selected, CHR$(119), 7, TRUE)
                Selected = Panel.Selected
                CALL Panel.Left(Selected, CHR$(113), 7, TRUE)
            CASE EVENT_LEFT
                CALL Panel.SetFocus(FALSE)
                CALL InfoPanelHandler("selected " + STR$(Selected))
                CALL Panel.Dispose()
                EXIT SUB
        END SELECT
    LOOP
END SUB

SUB DistributorPanelHandler() STATIC
    DIM Panel AS UiPanel
    DIM PointsLeft AS BYTE, StrPoints AS BYTE, IntPoints AS BYTE
    PointsLeft = 100
    StrPoints = 0
    IntPoints = 0

    CALL Panel.Init("distribute points", 10, 5, 20, 6, TRUE)
    CALL Panel.SetEvents(FALSE, FALSE, TRUE, TRUE, TRUE)

    Panel.Selected = 2
    CALL Panel.Left(0, "free", 7, FALSE)
    CALL Panel.Left(2, "str", 7, TRUE)
    CALL Panel.Left(3, "int", 7, TRUE)

    DO
        CALL Panel.Right(0, " " + STR$(PointsLeft), 7, FALSE)
        CALL Panel.Right(2, " " + STR$(StrPoints), 7, TRUE)
        CALL Panel.Right(3, " " + STR$(IntPoints), 7, TRUE)
        CALL Panel.WaitEvent(TRUE)

        SELECT CASE Panel.Event
            CASE EVENT_RIGHT
                IF Panel.Selected = 2 THEN
                    IF PointsLeft > 0 THEN
                        PointsLeft = PointsLeft - 1
                        StrPoints = StrPoints + 1
                    END IF
                END IF
                IF Panel.Selected = 3 THEN
                    IF PointsLeft > 0 THEN
                        PointsLeft = PointsLeft - 1
                        IntPoints = IntPoints + 1
                    END IF
                END IF
            CASE EVENT_LEFT
                IF Panel.Selected = 2 THEN
                    IF StrPoints > 0 THEN
                        PointsLeft = PointsLeft + 1
                        StrPoints = StrPoints - 1
                    END IF
                END IF
                IF Panel.Selected = 3 THEN
                    IF IntPoints > 0 THEN
                        PointsLeft = PointsLeft + 1
                        IntPoints = IntPoints - 1
                    END IF
                END IF
            CASE EVENT_FIRE
                CALL Panel.Dispose()
                EXIT SUB
        END SELECT
    LOOP
END SUB

SUB InfoPanelHandler(Msg AS STRING*18) STATIC
    DIM Panel AS UiPanel
    CALL Panel.Init("info", RndByte(0, 19), RndByte(0, 19), 20, 5, TRUE)
    CALL Panel.SetEvents(FALSE, FALSE, FALSE, FALSE, TRUE)

    CALL Panel.Center(1, Msg, 7, FALSE)

    CALL Panel.WaitEvent(FALSE)

    CALL Panel.Dispose()
END SUB

