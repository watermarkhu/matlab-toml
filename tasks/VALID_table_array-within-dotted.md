# Valid Table - Array Within Dotted Key Table

Parser should accept defining an array of tables under a key that was established via dotted key notation, but it crashes with exit code 1.

## valid/table/array-within-dotted

```
FAIL valid/table/array-within-dotted
     Exit 1

     input sent to parser-cmd:
        1 │ [fruit]
        2 │ apple.color = "red"
        3 │
        4 │ [[fruit.apple.seeds]]
        5 │ size = 2

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

Under `[fruit]`, the dotted key `apple.color = "red"` implicitly creates `fruit.apple` as a table. The `[[fruit.apple.seeds]]` then opens an array of tables at `fruit.apple.seeds`, which is a new key under the already-implicit `fruit.apple` table. This is valid TOML.

The parser rejects this, likely because it treats `fruit.apple` as "fully defined" by the dotted key and disallows any further additions via array-of-table headers.

This is closely related to `VALID_spec-1.0.0_table.md` (table-9) where the same dotted-key-then-subtable pattern is rejected.

Expected output:
```json
{
  "fruit": {
    "apple": {
      "color": {"type": "string", "value": "red"},
      "seeds": [
        {"size": {"type": "integer", "value": "2"}}
      ]
    }
  }
}
```
