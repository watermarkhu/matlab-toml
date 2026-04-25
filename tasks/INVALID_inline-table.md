# Invalid Inline Table

Parser should reject inline tables that duplicate keys or overwrite already-defined structure, but it silently merges them.

## invalid/inline-table/duplicate-key-03

```
FAIL invalid/inline-table/duplicate-key-03
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ tbl = { fruit = { apple.color = "red" }, fruit.apple.texture = { smooth = true } }

     output from parser-cmd (stdout):
        1 │ {
        2 │   "tbl": {
        3 │     "fruit": {
        4 │       "apple": {
        5 │         "color": {"type": "string", "value": "red"},
        6 │         "texture": {
        7 │           "smooth": {"type": "bool", "value": "true"}
        8 │         }
        9 │       }
       10 │     }
       11 │   }
       12 │ }

     want:
       Exit code 1
```

## invalid/inline-table/overwrite-07

```
FAIL invalid/inline-table/overwrite-07
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ tab = { inner.table = [{}], inner.table.val = "bad" }

     output from parser-cmd (stdout):
        1 │ {
        2 │   "tab": {
        3 │     "inner": {"table": [{
        4 │       "val": {"type": "string", "value": "bad"}
        5 │     }]}
        6 │   }
        7 │ }

     want:
       Exit code 1
```

## invalid/inline-table/overwrite-08

```
FAIL invalid/inline-table/overwrite-08
     Expected an error, but no error was reported.

     input sent to parser-cmd:
        1 │ tab = { inner = { dog = "best" }, inner.cat = "worst" }

     output from parser-cmd (stdout):
        1 │ {
        2 │   "tab": {
        3 │     "inner": {
        4 │       "cat": {"type": "string", "value": "worst"},
        5 │       "dog": {"type": "string", "value": "best"}
        6 │     }
        7 │   }
        8 │ }

     want:
       Exit code 1
```

## Notes

Per the TOML spec, inline tables are immutable once defined — you cannot add keys to them after the closing brace, and you cannot define the same key path twice within one. All three cases involve the parser silently merging content instead of rejecting the document:

- **duplicate-key-03**: `fruit` is defined twice within the same inline table — first as `{ apple.color = "red" }`, then extended via `fruit.apple.texture = { ... }`.
- **overwrite-07**: `inner.table` is first set to an array of tables `[{}]`, then a dotted key attempts to add `inner.table.val` into it, which is invalid.
- **overwrite-08**: `inner` is first defined as a complete inline table `{ dog = "best" }`, then a dotted key `inner.cat` tries to add to it.
