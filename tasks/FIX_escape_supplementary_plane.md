# Fix: \UXXXXXXXX escape handler for supplementary-plane codepoints

## Affected tests
- `valid/string/multibyte-escape`
- `valid/string/quoted-unicode`

## Problem
In `+toml/private/consume_basic_string.m`, the `\U` (8-digit Unicode escape) handler for codepoints > U+FFFF currently does:

```matlab
pieces{end+1} = char([bitshift(code_point, -16), bitand(uint32(0xFFFF), code_point)]);
```

For e.g. `\U00010AF1` (code_point = 0x10AF1), this produces `char([1, 0x0AF1])` — not a valid UTF-16 surrogate pair and not a valid Unicode char. Downstream operations crash or produce wrong output.

## Fix required

### `+toml/private/consume_basic_string.m`
Replace the supplementary-plane branch to produce a proper UTF-16 surrogate pair:

```matlab
u  = code_point - uint32(0x10000);
w1 = bitor(uint32(0xD800), bitshift(u, -10));
w2 = bitor(uint32(0xDC00), bitand(u, uint32(0x3FF)));
pieces{end+1} = char([w1, w2]);
```

### `test/+toml/+testing/jsonify.m` — `escape_str`
The current `c > 0xffff` branch never triggers because supplementary-plane chars are stored as two surrogate `char` values (each < 0xFFFF). Add surrogate-pair detection:

```matlab
elseif c >= 0xD800 && c <= 0xDBFF
    % high surrogate — consume paired low surrogate
    low = str(idx + 1);  % must advance idx
    out = [out '\u' sprintf('%04X', c) '\u' sprintf('%04X', low)];
    idx = idx + 1;  % skip low surrogate
```

Note: since MATLAB's `for idx = 1:numel(str)` does not support mutating `idx`, the loop in `escape_str` will need to be rewritten as a `while` loop to allow skipping the low surrogate.
