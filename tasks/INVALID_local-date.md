# Invalid Local-Date Values

Parser should reject local dates that do not correspond to real calendar dates, but it accepts them verbatim.

## invalid/local-date/feb-29

```
FAIL invalid/local-date/feb-29
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ "not a leap year" = 2100-02-29

     output from parser-cmd (stdout):
        1 │ {
        2 │   "not a leap year": {"type": "date-local", "value": "2100-02-29"}
        3 │ }

     want:
       Exit code 1
```

## invalid/local-date/feb-30

```
FAIL invalid/local-date/feb-30
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ "only 28 or 29 days in february" = 1988-02-30

     output from parser-cmd (stdout):
        1 │ {
        2 │   "only 28 or 29 days in february": {"type": "date-local", "value": "1988-02-30"}
        3 │ }

     want:
       Exit code 1
```

## Notes

The parser does not validate the calendar correctness of local-date values:

- `2100-02-29`: Year 2100 is not a leap year (divisible by 100 but not 400), so February only has 28 days.
- `1988-02-30`: February never has 30 days.

The parser treats dates as opaque strings, passing them through without checking validity.
