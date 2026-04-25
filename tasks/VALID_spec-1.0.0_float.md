# Valid Float - Spec 1.0.0

Parser parses floats but formats them incorrectly: it loses precision for very small exponent values and always uses fixed-point notation instead of preserving the original representation.

## valid/spec-1.0.0/float-0

```
FAIL valid/spec-1.0.0/float-0
     Values for key "flt7" don't match:
       Expected:     6.626e-34
       Your encoder: 0

     input sent to parser-cmd:
        1 │ # fractional
        2 │ flt1 = +1.0
        3 │ flt2 = 3.1415
        4 │ flt3 = -0.01
        5 │
        6 │ # exponent
        7 │ flt4 = 5e+22
        8 │ flt5 = 1e06
        9 │ flt6 = -2E-2
       10 │
       11 │ # both
       12 │ flt7 = 6.626e-34

     output from parser-cmd (stdout):
        1 │ {
        2 │   "flt1": {"type": "float", "value": "1.000000000000000"},
        3 │   "flt2": {"type": "float", "value": "3.141500000000000"},
        4 │   "flt3": {"type": "float", "value": "-0.010000000000000"},
        5 │   "flt4": {"type": "float", "value": "49999999999999995805696.000000000000000"},
        6 │   "flt5": {"type": "float", "value": "1000000.000000000000000"},
        7 │   "flt6": {"type": "float", "value": "-0.020000000000000"},
        8 │   "flt7": {"type": "float", "value": "0.000000000000000"}
        9 │ }

     want:
        1 │ {
        2 │     "flt1": {"type": "float", "value": "1"},
        3 │     "flt2": {"type": "float", "value": "3.1415"},
        4 │     "flt3": {"type": "float", "value": "-0.01"},
        5 │     "flt4": {"type": "float", "value": "5e+22"},
        6 │     "flt5": {"type": "float", "value": "1e+06"},
        7 │     "flt6": {"type": "float", "value": "-0.02"},
        8 │     "flt7": {"type": "float", "value": "6.626e-34"}
        9 │ }
```

## Notes

Two distinct problems visible in the output:

1. **Precision loss for very small/large values**: `flt7 = 6.626e-34` is output as `"0.000000000000000"` — the value is lost entirely due to fixed-point formatting with only 15 decimal places.

2. **Float serialization format**: The toml-test protocol expects the float value string to represent the number faithfully (e.g. `"6.626e-34"`, `"5e+22"`). The parser is using `printf`-style fixed-point formatting (`%.15f`) which loses information for numbers near the floating-point range boundaries.

The output format must preserve the numeric value exactly, preferring scientific notation when needed.
