# Valid Key - Quoted Unicode Keys

Parser should accept quoted keys containing Unicode characters (both via escape sequences and literal multibyte), but it crashes with exit code 1.

## valid/key/quoted-unicode

```
FAIL valid/key/quoted-unicode
     Exit 1

     input sent to parser-cmd:
        1 │
        2 │ "\u0000" = "null"
        3 │ '\u0000' = "different key"
        4 │ "\u0008 \u000c \U00000041 \u007f \u0080 \u00ff \ud7ff \ue000 \uffff \U00010000 \U0010ffff" = "escaped key"
        5 │
        6 │ "~  ÿ ퟿  ￿ 𐀀 􏿿" = "basic key"
        7 │ 'l ~  ÿ ퟿  ￿ 𐀀 􏿿' = "literal key"

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

This test exercises several aspects of quoted keys:

1. `"\u0000"` — a basic quoted key with a Unicode escape (NUL character), distinct from `'\u0000'` (literal key with the 6 chars `\u0000`)
2. A key with a long sequence of `\uXXXX` and `\UXXXXXXXX` escapes spanning control characters and multi-plane codepoints
3. Literal multibyte Unicode in both basic (`"..."`) and literal (`'...'`) quoted keys

The parser crashes on this input, suggesting it cannot handle Unicode in key positions (either the escape processing or the multibyte literal handling).
