# Valid String - Multibyte and Unicode Escapes

Parser should handle multibyte UTF-8 characters in string values (both literal and via `\uXXXX`/`\UXXXXXXXX` escapes), but it crashes with exit code 1 on all three test cases.

## valid/string/multibyte

```
FAIL valid/string/multibyte
     Exit 1

     input sent to parser-cmd:
        1 │ # Test each multibyte length: 2, 3, and 4 bytes:
        2 │ # ɑ € 𐫱
        3 │
        4 │ basic    = "ɑ € 𐫱 ɑ€𐫱"
        5 │ raw      = 'ɑ € 𐫱 ɑ€𐫱'
        6 │ ml-basic = """ɑ € 𐫱 ɑ€𐫱"""
        7 │ ml-raw   = '''ɑ € 𐫱 ɑ€𐫱'''

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## valid/string/multibyte-escape

```
FAIL valid/string/multibyte-escape
     Exit 1

     input sent to parser-cmd:
        1 │ # Test each multibyte length: 2, 3, and 4 bytes:
        2 │ # ɑ € 𐫱
        3 │
        4 │ basic-1    = "\u0251 \u20ac \U00010AF1 \u0251\u20ac\U00010AF1"
        5 │ ml-basic-1 = """\u0251 \u20ac \U00010AF1 \u0251\u20ac\U00010AF1"""
        6 │
        7 │ # Again, but only using \U
        8 │ basic-2    = "\U00000251 \U000020ac \U00010AF1 \U00000251\U000020ac\U00010AF1"
        9 │ ml-basic-2 = """\U00000251 \U000020ac \U00010AF1 \U00000251\U000020ac\U00010AF1"""

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## valid/string/quoted-unicode

```
FAIL valid/string/quoted-unicode
     Exit 1

     input sent to parser-cmd:
        1 │
        2 │ escaped_string = "\u0000 \u0008 \u000c \U00000041 \u007f \u0080 \u00ff \ud7ff \ue000 \uffff \U00010000 \U0010ffff"
        3 │ not_escaped_string = '\u0000 \u0008 \u000c \U00000041 \u007f \u0080 \u00ff \ud7ff \ue000 \uffff \U00010000 \U0010ffff'
        4 │
        5 │ basic_string = "~  ÿ ퟿  ￿ 𐀀 􏿿"
        6 │ literal_string = '~  ÿ ퟿  ￿ 𐀀 􏿿'

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

Three related but distinct string Unicode issues:

1. **multibyte** (literal): Strings containing direct multibyte UTF-8 characters (`ɑ` = 2-byte, `€` = 3-byte, `𐫱` = 4-byte) in all four string types (basic, raw, multiline basic, multiline raw). The parser crashes, suggesting the lexer/reader cannot handle multibyte sequences in string content.

2. **multibyte-escape** (`\uXXXX`/`\UXXXXXXXX`): Unicode escape sequences that produce multibyte characters when decoded. Both 4-digit and 8-digit forms are tested. The parser crashes even though the input is pure ASCII (the characters are encoded as escapes).

3. **quoted-unicode**: Mix of escape sequences (including NUL, control characters, and supplementary plane codepoints) in basic strings, and the same characters as literal text in literal strings. Also tests that `'\u0000'` in a literal string is kept as-is (not decoded).
