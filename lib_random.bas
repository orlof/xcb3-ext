RANDOMIZE TI()

FUNCTION rnd8 AS BYTE(min AS BYTE, max AS BYTE) SHARED STATIC
    STATIC range AS BYTE: range = max - min

    STATIC mask AS BYTE: mask = 1
    DO
        if range < mask THEN EXIT DO
        mask = SHL(mask, 1)
    LOOP UNTIL mask = 0

    mask = mask - 1

    DO
        rnd8 = RNDB() AND mask
    LOOP UNTIL rnd8 <= range
    rnd8 = rnd8 + min
END FUNCTION

FUNCTION rnd16 AS WORD(min AS WORD, max AS WORD) SHARED STATIC
    STATIC range AS WORD: range = max - min

    STATIC mask AS WORD: mask = 1
    DO
        if range < mask THEN EXIT DO
        mask = SHL(mask, 1)
    LOOP UNTIL mask = 0

    mask = mask - 1

    DO
        rnd16 = RNDW() AND mask
    LOOP UNTIL rnd16 <= range
    rnd16 = rnd16 + min
END FUNCTION
