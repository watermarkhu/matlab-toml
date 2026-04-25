# Valid Comment - Non-ASCII Characters

Parser should accept TOML files where comments contain non-ASCII Unicode characters, but it crashes with exit code 1.

## valid/comment/nonascii

```
FAIL valid/comment/nonascii
     Exit 1

     input sent to parser-cmd:
        1 │ # ~  ÿ ퟿  ￿ 𐀀 􏿿

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

The input is a single comment line containing a range of Unicode characters spanning multiple code planes:
- `~` (U+007E, last ASCII printable)
- `ÿ` (U+00FF, Latin Extended-A)
- `퟿` (U+D7FF, last valid codepoint before surrogates)
- `￿` (U+FFFF, BMP boundary)
- `𐀀` (U+10000, first supplementary plane)
- `􏿿` (U+10FFFF, last valid Unicode codepoint)

Per the TOML spec, comments may contain any Unicode scalar value except U+0000–U+0008, U+000A–U+001F, and U+007F. All characters in this test are valid. The parser should produce an empty document `{}` but instead crashes.
