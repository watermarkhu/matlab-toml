# Valid Table - Spec 1.0.0 table-9

Parser should accept a table that extends a dotted key defined in a parent table via a sub-table header, but it crashes with exit code 1.

## valid/spec-1.0.0/table-9

```
FAIL valid/spec-1.0.0/table-9
     Exit 1

     input sent to parser-cmd:
        1 │ [fruit]
        2 │ apple.color = "red"
        3 │ apple.taste.sweet = true
        4 │
        5 │ # [fruit.apple]  # INVALID
        6 │ # [fruit.apple.taste]  # INVALID
        7 │
        8 │ [fruit.apple.texture]  # you can add sub-tables
        9 │ smooth = true

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

Under `[fruit]`, dotted keys establish an implicit table at `fruit.apple` and `fruit.apple.taste`. The spec (as of 1.0.0) allows opening `[fruit.apple.texture]` as a new sub-table because `texture` has not previously been defined. However, re-opening `[fruit.apple]` or `[fruit.apple.taste]` would be invalid (shown commented out).

The parser incorrectly rejects `[fruit.apple.texture]` — it appears to treat *any* sub-table of a dotted-key-defined implicit table as invalid, when only *re-opening* an already-fully-defined table should be rejected.

Expected output:
```json
{
  "fruit": {
    "apple": {
      "color": {"type": "string", "value": "red"},
      "taste": {
        "sweet": {"type": "bool", "value": "true"}
      },
      "texture": {
        "smooth": {"type": "bool", "value": "true"}
      }
    }
  }
}
```
