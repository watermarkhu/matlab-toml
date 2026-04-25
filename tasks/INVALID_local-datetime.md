# Invalid Local-Datetime Values

Parser should reject local datetimes that do not correspond to real calendar dates, but it accepts them verbatim.

## invalid/local-datetime/feb-29

```
FAIL invalid/local-datetime/feb-29
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ "not a leap year" = 2100-02-29T15:15:15

     output from parser-cmd (stdout):
        1 │ {
        2 │   "not a leap year": {"type": "datetime-local", "value": "2100-02-29T15:15:15"}
        3 │ }

     want:
       Exit code 1
```

## invalid/local-datetime/feb-30

```
FAIL invalid/local-datetime/feb-30
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ "only 28 or 29 days in february" = 1988-02-30T15:15:15

     output from parser-cmd (stdout):
        1 │ {
        2 │   "only 28 or 29 days in february": {"type": "datetime-local", "value": "1988-02-30T15:15:15"}
        3 │ }

     want:
       Exit code 1
```

## Notes

Same root cause as `INVALID_local-date.md` — the parser does not validate the date portion of local-datetime values:

- `2100-02-29T15:15:15`: 2100 is not a leap year.
- `1988-02-30T15:15:15`: February 30 does not exist.

The same fix likely covers both `local-date` and `local-datetime` cases (and the offset `datetime` cases in `INVALID_datetime.md`).
