# Invalid Inline Table - Spec 1.0.0

Parser should reject extension of an inline table outside of its definition, but it merges the extra key.

## invalid/spec-1.0.0/inline-table-2-0

```
FAIL invalid/spec-1.0.0/inline-table-2-0
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ [product]
        2 │ type = { name = "Nail" }
        3 │ type.edible = false  # INVALID

     output from parser-cmd (stdout):
        1 │ {
        2 │   "product": {
        3 │     "type": {
        4 │       "edible": {"type": "bool", "value": "false"},
        5 │       "name":   {"type": "string", "value": "Nail"}
        6 │     }
        7 │   }
        8 │ }

     want:
       Exit code 1
```

## Notes

Per TOML 1.0.0 spec (section on inline tables): *"Inline tables are fully self-contained and define all keys and sub-tables within them. New keys and sub-tables cannot be added to an already-defined inline table."*

The parser sees `type = { name = "Nail" }` defining `type` as an inline table, then `type.edible = false` attempts to add a new key to that already-closed inline table. Instead of rejecting this, the parser merges `edible` into the `type` table.

This is related to `INVALID_inline-table.md` (overwrite-07, overwrite-08) — the same immutability rule applies.
