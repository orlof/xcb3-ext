SHARED CONST TRUE = $ff
SHARED CONST FALSE = 0

SHARED CONST COLOR_BLACK       = $0
SHARED CONST COLOR_WHITE       = $1
SHARED CONST COLOR_RED         = $2
SHARED CONST COLOR_CYAN        = $3
SHARED CONST COLOR_PURPLE      = $4
SHARED CONST COLOR_GREEN       = $5
SHARED CONST COLOR_BLUE        = $6
SHARED CONST COLOR_YELLOW      = $7
SHARED CONST COLOR_ORANGE      = $8
SHARED CONST COLOR_BROWN       = $9
SHARED CONST COLOR_LIGHTRED    = $a
SHARED CONST COLOR_DARKGRAY    = $b
SHARED CONST COLOR_MIDDLEGRAY  = $c
SHARED CONST COLOR_LIGHTGREEN  = $d
SHARED CONST COLOR_LIGHTBLUE   = $e
SHARED CONST COLOR_LIGHTGRAY   = $f

INCLUDE "../libs/lib_sysinfo.bas"
INCLUDE "../libs/lib_sfx.bas"
INCLUDE "../libs/lib_joy.bas"
INCLUDE "../libs/lib_ui.bas"

DIM Attack(15) AS STRING*5 @_ATTACK
DIM Decay(15) AS STRING*5 @_DECAY
DIM Release(15) AS STRING*5 @_RELEASE
DIM WaveformName(4) AS STRING*8 @_WAVEFORM_NAME
DIM WaveformName2(4) AS STRING*8 @_WAVEFORM_NAME2
DIM WaveformValue(4) AS BYTE @_WAVEFORM_VALUE
DIM Percentage(15) AS STRING*4 @_PERCENTAGE

DIM SHARED Effect AS SFX
    Effect.Duration = 70
    Effect.Waveform = TRIANGLE
    Effect.AttackDecay = $71
    Effect.SustainRelease = $a9
    Effect.Frequency = $0764
    Effect.FrequencySlide = 63
    Effect.Bounce = 0
    Effect.Pulse = 0

DIM Waveform AS BYTE
Waveform = 3

DIM MainPanel AS UiPanel

BORDER COLOR_BLACK
BACKGROUND COLOR_BLACK
POKE 53272,23   ' Set character set to lowercase

CALL SfxInstall(sysinfo_pal())

SUB PrintValues() STATIC
    CALL MainPanel.Right(17, 1, "  " + STR$(Effect.Duration), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 2, WaveformName(Waveform), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 3, Attack(SHR(Effect.AttackDecay, 4)), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 4, Decay(Effect.AttackDecay AND $0f), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 5, Percentage(SHR(Effect.SustainRelease,4)), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 6, Release(Effect.SustainRelease AND $0f), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 7, "    " + STR$(Effect.Frequency), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 9, "    " + STR$(Effect.FrequencySlide), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 11, "  " + STR$(Effect.Bounce), COLOR_LIGHTGRAY, TRUE)
    CALL MainPanel.Right(17, 12, "    " + STR$(CWORD(Effect.Pulse) / 40950), COLOR_LIGHTGRAY, TRUE)
END SUB

CALL UiLattice(0, 0, 40, 25, 105, 95, COLOR_RED, COLOR_LIGHTRED)
CALL MainPanel.Init("Sound", 1, 1, 20, 23, FALSE)
CALL MainPanel.SetEvents(EVENT_LEFT OR EVENT_RIGHT OR EVENT_FIRE)
CALL MainPanel.Left(0, 1, "Duration", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 2, "Waveform", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 3, "Attack", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 4, "Decay", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 5, "Sustain", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 6, "Release", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 7, "Frequency", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Right(17, 8, "Low", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 9, "Slide", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Right(17, 10, "Low", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 11, "Bounce", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 12, "Pulse", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Right(17, 13, "Low", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 15, "Export", COLOR_LIGHTGRAY, TRUE)
CALL MainPanel.Left(0, 16, "Examples", COLOR_LIGHTGRAY, TRUE)

CALL MainPanel.SetSelected(1)

DIM Repeat AS BYTE
Repeat = TRUE

DO
    CALL PrintValues()
    CALL MainPanel.SetFocus(TRUE)

    CALL MainPanel.WaitEvent(Repeat)

    SELECT CASE MainPanel.Selected
        CASE 1  'Duration
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.Duration = Effect.Duration + 1
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.Duration = Effect.Duration - 1
                    CONTINUE DO
            END SELECT
        CASE 2  'Waveform
            IF MainPanel.Event = EVENT_RIGHT THEN
                DIM WaveformPanel AS UiPanel

                CALL WaveformPanel.Init("Waveform", 22, 2, 14, 6, TRUE)
                CALL WaveformPanel.SetEvents(EVENT_FIRE)

                CALL WaveformPanel.Left(0, "Noise", COLOR_LIGHTGRAY, TRUE)
                CALL WaveformPanel.Left(1, "Pulse", COLOR_LIGHTGRAY, TRUE)
                CALL WaveformPanel.Left(2, "Saw", COLOR_LIGHTGRAY, TRUE)
                CALL WaveformPanel.Left(3, "Triangle", COLOR_LIGHTGRAY, TRUE)
                CALL WaveformPanel.SetSelected(Waveform)

                CALL WaveformPanel.WaitEvent(FALSE)

                Waveform = WaveformPanel.Selected
                Effect.Waveform = WaveformValue(Waveform)
                CALL WaveformPanel.Dispose()
                CALL MainPanel.SetFocus(TRUE)

                CONTINUE DO
            END IF
        CASE 3  'Attack
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.AttackDecay = Effect.AttackDecay + $10
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.AttackDecay = Effect.AttackDecay - $10
                    CONTINUE DO
            END SELECT
        CASE 4  'Decay
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    IF (Effect.AttackDecay AND $0f) = $0f THEN
                        Effect.AttackDecay = Effect.AttackDecay AND $f0
                    ELSE
                        Effect.AttackDecay = Effect.AttackDecay + 1
                    END IF
                    CONTINUE DO
                CASE EVENT_LEFT
                    IF (Effect.AttackDecay AND $0f) = 0 THEN
                        Effect.AttackDecay = Effect.AttackDecay OR $0f
                    ELSE
                        Effect.AttackDecay = Effect.AttackDecay - 1
                    END IF
                    CONTINUE DO
            END SELECT
        CASE 5  'Sustain
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.SustainRelease = Effect.SustainRelease + $10
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.SustainRelease = Effect.SustainRelease - $10
                    CONTINUE DO
            END SELECT
        CASE 6  'Decay
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    IF (Effect.SustainRelease AND $0f) = $0f THEN
                        Effect.SustainRelease = Effect.SustainRelease AND $f0
                    ELSE
                        Effect.SustainRelease = Effect.SustainRelease + 1
                    END IF
                    CONTINUE DO
                CASE EVENT_LEFT
                    IF (Effect.SustainRelease AND $0f) = 0 THEN
                        Effect.SustainRelease = Effect.SustainRelease OR $0f
                    ELSE
                        Effect.SustainRelease = Effect.SustainRelease - 1
                    END IF
                    CONTINUE DO
            END SELECT
        CASE 7  'Frequency
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.Frequency = Effect.Frequency + 100
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.Frequency = Effect.Frequency - 100
                    CONTINUE DO
            END SELECT
        CASE 8  'Frequency
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.Frequency = Effect.Frequency + 1
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.Frequency = Effect.Frequency - 1
                    CONTINUE DO
            END SELECT
        CASE 9  'FrequencySlide
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.FrequencySlide = Effect.FrequencySlide + 100
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.FrequencySlide = Effect.FrequencySlide - 100
                    CONTINUE DO
            END SELECT
        CASE 10  'FrequencySlide
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.FrequencySlide = Effect.FrequencySlide + 1
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.FrequencySlide = Effect.FrequencySlide - 1
                    CONTINUE DO
            END SELECT
        CASE 11  'Bounce
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.Bounce = Effect.Bounce + 1
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.Bounce = Effect.Bounce - 1
                    CONTINUE DO
            END SELECT
        CASE 12  'Pulse
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.Pulse = (Effect.Pulse + 100) AND $0fff
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.Pulse = (Effect.Pulse - 100) AND $0fff
                    CONTINUE DO
            END SELECT
        CASE 13  'Pulse
            Repeat = TRUE
            SELECT CASE MainPanel.Event
                CASE EVENT_RIGHT
                    Effect.Pulse = (Effect.Pulse + 1) AND $0fff
                    CONTINUE DO
                CASE EVENT_LEFT
                    Effect.Pulse = (Effect.Pulse - $1) AND $0fff
                    CONTINUE DO
            END SELECT
        CASE 15  'Export
            IF MainPanel.Event = EVENT_RIGHT THEN
                DIM ExportPanel AS UiPanel

                CALL ExportPanel.Init("SFX", 0, 2, 39, 13, TRUE)
                CALL ExportPanel.SetFocus(TRUE)
                CALL ExportPanel.SetEvents(EVENT_FIRE OR EVENT_LEFT)

                CALL ExportPanel.Left(1,"DIM SHARED SfxName AS SFX", COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(2,"    SfxName.Duration = " + STR$(Effect.Duration), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(3,"    SfxName.Waveform = " + WaveformName2(Waveform), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(4,"    SfxName.AttackDecay = " + STR$(Effect.AttackDecay), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(5,"    SfxName.SustainRelease = " + STR$(Effect.SustainRelease), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(6,"    SfxName.Frequency = " + STR$(Effect.Frequency), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(7,"    SfxName.FrequencySlide = " + STR$(Effect.FrequencySlide), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(8,"    SfxName.Bounce = " + STR$(Effect.Bounce), COLOR_LIGHTGRAY, FALSE)
                CALL ExportPanel.Left(9,"    SfxName.Pulse = " + STR$(Effect.Pulse), COLOR_LIGHTGRAY, FALSE)

                'CALL WaveformPanel.SetSelected(Waveform)

                CALL ExportPanel.WaitEvent(FALSE)

                CALL ExportPanel.Dispose()
                CALL MainPanel.SetFocus(TRUE)

                CONTINUE DO
            END IF
        CASE 16  'Samples
            IF MainPanel.Event = EVENT_RIGHT THEN
                DIM SamplePanel AS UiPanel

                CALL SamplePanel.Init("Samples", 0, 2, 39, 13, TRUE)
                CALL SamplePanel.SetFocus(TRUE)
                CALL SamplePanel.SetEvents(EVENT_FIRE OR EVENT_LEFT)

                CALL SamplePanel.Left(1,"Launch", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(2,"Engine", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(3,"Explosion", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(4,"Shot", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(5,"Gold", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(6,"Fuel", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(7,"Asteroid", COLOR_LIGHTGRAY, TRUE)
                CALL SamplePanel.Left(8,"VergeField", COLOR_LIGHTGRAY, TRUE)

                CALL SamplePanel.SetSelected(1)
                CALL SamplePanel.WaitEvent(FALSE)

                SELECT CASE SamplePanel.Selected
                    CASE 1 'SfxGameStart
                        Effect.Duration = 70
                        Effect.Waveform = TRIANGLE
                        Waveform = 3
                        Effect.AttackDecay = $71
                        Effect.SustainRelease = $a9
                        Effect.Frequency = $0764
                        Effect.FrequencySlide = 63
                        Effect.Bounce = 0
                        Effect.Pulse = 0

                    CASE 2 ' SfxEngine
                        Effect.Duration = 16
                        Effect.Waveform = NOISE
                        Waveform = 0
                        Effect.AttackDecay = $00
                        Effect.SustainRelease = $c4
                        Effect.Frequency = $0264
                        Effect.FrequencySlide = 0
                        Effect.Bounce = 6
                        Effect.Pulse = 0

                    CASE 3 ' SfxExplosion
                        Effect.Duration = 50
                        Effect.Waveform = NOISE
                        Waveform = 0
                        Effect.AttackDecay = $00
                        Effect.SustainRelease = $fc
                        Effect.Frequency = $0664
                        Effect.FrequencySlide = -10
                        Effect.Bounce = 0
                        Effect.Pulse = 0

                    CASE 4 ' SfxShot
                        Effect.Duration = 25
                        Effect.Waveform = NOISE
                        Waveform = 0
                        Effect.AttackDecay = $0a
                        Effect.SustainRelease = $0a
                        Effect.Frequency = $28c8
                        Effect.FrequencySlide = -50
                        Effect.Bounce = 0
                        Effect.Pulse = 0

                    CASE 5 ' SfxGold
                        Effect.Duration = 25
                        Effect.Waveform = TRIANGLE
                        Waveform = 3
                        Effect.AttackDecay = $a6
                        Effect.SustainRelease = $96
                        Effect.Frequency = $0004
                        Effect.FrequencySlide = $3201
                        Effect.Bounce = 3
                        Effect.Pulse = 0

                    CASE 6 ' SfxFuel
                        Effect.Duration = 45
                        Effect.Waveform = TRIANGLE
                        Waveform = 3
                        Effect.AttackDecay = $85
                        Effect.SustainRelease = $76
                        Effect.Frequency = $0004
                        Effect.FrequencySlide = $1201
                        Effect.Bounce = 5
                        Effect.Pulse = 0

                    CASE 7 ' SfxAsteroid
                        Effect.Duration = 12
                        Effect.Waveform = NOISE
                        Waveform = 0
                        Effect.AttackDecay = $04
                        Effect.SustainRelease = $a4
                        Effect.Frequency = 5000
                        Effect.FrequencySlide = -1407
                        Effect.Bounce = 3
                        Effect.Pulse = 0

                    CASE 8 ' VergeField
                        Effect.Duration = 50
                        Effect.Waveform = TRIANGLE
                        Waveform = 3
                        Effect.AttackDecay = $0a
                        Effect.SustainRelease = $f6
                        Effect.Frequency = $28c8
                        Effect.FrequencySlide = 100
                        Effect.Bounce = 25
                        Effect.Pulse = 0
                END SELECT

                CALL SamplePanel.Dispose()
                CALL MainPanel.SetFocus(TRUE)

                CONTINUE DO
            END IF
    END SELECT

    CALL SfxPlay(@Effect)
    Repeat = FALSE
LOOP

_WAVEFORM_NAME:
DATA AS STRING*8 "   Noise", "   Pulse", "     Saw", "Triangle"
_WAVEFORM_NAME2:
DATA AS STRING*8 "NOISE", "PULSE", "SAW", "TRIANGLE"

_WAVEFORM_VALUE:
DATA AS BYTE 128, 64, 32, 16

_ATTACK:
DATA AS STRING*5 "  2ms","  8ms"," 16ms"," 24ms"," 38ms"," 56ms", " 68ms"," 80ms","100ms","250ms","500ms","800ms","   1s","   3s","   5s","   8s"
_DECAY:
_RELEASE:
DATA AS STRING*5 "  6ms"," 24ms"," 48ms"," 72ms","114ms","168ms","204ms","240ms","300ms","750ms"," 1.5s"," 2.4s","   3s","   9s","  15s","  24s"

_PERCENTAGE:
DATA AS STRING*4 "  0%","  7%"," 13%"," 20%"," 27%"," 33%"," 40%"," 47%"," 53%"," 60%"," 67%"," 73%"," 80%"," 87%"," 93%","100%"
