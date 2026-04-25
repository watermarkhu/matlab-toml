# Invalid Control Characters

Parser should reject TOML containing forbidden control characters, but it accepts them and returns `{}`.

## invalid/control/only-ff

```
FAIL invalid/control/only-ff
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ <0x0C>  (form-feed, U+000C)

     output from parser-cmd (stdout):
        1 │ {}

     want:
       Exit code 1
```

## invalid/control/only-vt

```
FAIL invalid/control/only-vt
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ <0x0B>  (vertical tab, U+000B)

     output from parser-cmd (stdout):
        1 │ {}

     want:
       Exit code 1
```

## Notes

The input for these two tests is a single non-printable control character (FF and VT respectively). The parser silently returns an empty table `{}` instead of rejecting them with exit code 1. Per the TOML spec, control characters other than tab (U+0009) are not permitted in TOML documents outside of string values.
