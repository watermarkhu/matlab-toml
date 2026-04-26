# Fix: File reader for supplementary-plane Unicode characters

## Affected tests
- `valid/comment/nonascii`
- `valid/string/multibyte`
- `valid/string/quoted-unicode`
- `invalid/encoding/bad-codepoint`

## Problem
`read.m` uses `fopen(filename, 'r', 'n', 'UTF-8') + fread(fid, [1 inf], '*char')`.
In MATLAB R2020b+, `fread` with `'*char'` on a UTF-8 file performs UTF-8 → UTF-16 decoding, producing **surrogate pairs** (two `char` values in range U+D800–U+DFFF) for supplementary-plane characters (U+10000+). MATLAB string built-ins (`startsWith`, `strjoin`, `regexp`, etc.) throw exceptions when given char arrays containing surrogate values.

Additionally, the reader silently accepts invalid UTF-8 byte sequences such as CESU-8 encoded surrogates (`0xED 0xA0 0x80` for U+D800), which should be rejected per the TOML spec.

## Fix required

### `+toml/read.m`
Replace the current MATLAB read path with one that:
1. Reads the file as **raw bytes** (`fread(fid, [1 inf], '*uint8')`).
2. Validates that the bytes are well-formed UTF-8 — reject any sequence that encodes a surrogate codepoint (U+D800–U+DFFF), overlong encoding, or codepoint > U+10FFFF.
3. Decodes the validated UTF-8 bytes to a MATLAB `char` array using proper UTF-16 surrogate pairs for supplementary-plane chars (codepoint ≥ U+10000 → two `char` values: high surrogate + low surrogate).

The Octave path (`read_utf8`) can remain unchanged or be unified with the new path.
