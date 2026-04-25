# Invalid Datetime Values

Parser should reject datetimes with invalid calendar dates or malformed timezone offsets, but it accepts them verbatim.

## invalid/datetime/feb-29

```
FAIL invalid/datetime/feb-29
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ "not a leap year" = 2100-02-29T15:15:15Z

     output from parser-cmd (stdout):
        1 │ {
        2 │   "not a leap year": {"type": "datetime", "value": "2100-02-29T15:15:15Z"}
        3 │ }

     want:
       Exit code 1
```

## invalid/datetime/feb-30

```
FAIL invalid/datetime/feb-30
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ "only 28 or 29 days in february" = 1988-02-30T15:15:15Z

     output from parser-cmd (stdout):
        1 │ {
        2 │   "only 28 or 29 days in february": {"type": "datetime", "value": "1988-02-30T15:15:15Z"}
        3 │ }

     want:
       Exit code 1
```

## invalid/datetime/offset-minus-minute-1digit

```
FAIL invalid/datetime/offset-minus-minute-1digit
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ foo = 1997-09-09T09:09:09.09+09:9

     output from parser-cmd (stdout):
        1 │ {
        2 │   "foo": {"type": "datetime", "value": "1997-09-09T09:09:09.09+09:9"}
        3 │ }

     want:
       Exit code 1
```

## invalid/datetime/offset-overflow-hour

```
FAIL invalid/datetime/offset-overflow-hour
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ # Hour must be 00-24
        2 │ d = 1985-06-18 17:04:07+25:00

     output from parser-cmd (stdout):
        1 │ {
        2 │   "d": {"type": "datetime", "value": "1985-06-18T17:04:07+25:00"}
        3 │ }

     want:
       Exit code 1
```

## invalid/datetime/offset-overflow-minute

```
FAIL invalid/datetime/offset-overflow-minute
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ d = 1985-06-18 17:04:07+12:60

     output from parser-cmd (stdout):
        1 │ {
        2 │   "d": {"type": "datetime", "value": "1985-06-18T17:04:07+12:60"}
        3 │ }

     want:
       Exit code 1
```

## invalid/datetime/offset-plus-minute-1digit

```
FAIL invalid/datetime/offset-plus-minute-1digit
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ foo = 1997-09-09T09:09:09.09+09:9

     output from parser-cmd (stdout):
        1 │ {
        2 │   "foo": {"type": "datetime", "value": "1997-09-09T09:09:09.09+09:9"}
        3 │ }

     want:
       Exit code 1
```

## Notes

Two distinct issues:

1. **Calendar validation** (`feb-29`, `feb-30`): The parser does not validate that the date portion of an offset datetime is a real calendar date. `2100-02-29` is not a leap year (2100 is divisible by 100 but not 400), and `1988-02-30` never exists.

2. **Timezone offset format** (`offset-*`): The parser does not validate the format or range of timezone offsets. Offsets must be `±HH:MM` with two digits for each part and values within `00`–`23` for hours and `00`–`59` for minutes.
