# Invalid Encoding / Unicode

Parser should reject TOML with invalid Unicode codepoints or forbidden whitespace characters.

## invalid/encoding/bad-codepoint

```
FAIL invalid/encoding/bad-codepoint
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ # Invalid codepoint U+D800 : ���

     output from parser-cmd (stdout):
        1 │ {}

     want:
       Exit code 1
```

## invalid/encoding/ideographic-space

```
FAIL invalid/encoding/ideographic-space
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ # First on next line is U+3000 IDEOGRAPHIC SPACE
        2 │ 　foo = "bar"

     output from parser-cmd (stdout):
        1 │ {
        2 │   "foo": {"type": "string", "value": "bar"}
        3 │ }

     want:
       Exit code 1
```

## Notes

Two distinct issues:

1. **bad-codepoint**: The file contains a surrogate codepoint (U+D800), which is not valid in UTF-8. The parser should reject the document, but instead returns `{}`.

2. **ideographic-space**: U+3000 (IDEOGRAPHIC SPACE) is not valid whitespace in TOML. Only U+0009 (tab) and U+0020 (space) are allowed as whitespace outside strings. The parser treats it as whitespace and successfully parses `foo = "bar"` from the following content.
