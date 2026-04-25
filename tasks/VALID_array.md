# Valid Array - open-parent-table

Parser should accept defining the parent table of an array of tables after the array entries, but it crashes with exit code 1.

## valid/array/open-parent-table

```
FAIL valid/array/open-parent-table
     Exit 1

     input sent to parser-cmd:
        1 │ [[parent-table.arr]]
        2 │ [[parent-table.arr]]
        3 │ [parent-table]
        4 │ not-arr = 1

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

The test defines two entries of `[[parent-table.arr]]` before explicitly opening `[parent-table]` to add another key (`not-arr`). This is valid TOML — a parent table can be defined after its array-of-tables children. The parser rejects this with an error instead of accepting it.

Expected output (inferred):
```json
{
  "parent-table": {
    "arr": [{}, {}],
    "not-arr": {"type": "integer", "value": "1"}
  }
}
```
