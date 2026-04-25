# Valid Multibyte - General Multibyte Throughout

Parser should accept TOML with multibyte Unicode characters used throughout (in table names, keys, string values, and comments), but it crashes with exit code 1.

## valid/multibyte

```
FAIL valid/multibyte
     Exit 1

     input sent to parser-cmd:
        1 │ # Test multibyte throughout
        2 │
        3 │ # Tèƨƭ ƒïℓè ƒôř TÓM£
        4 │ # Óñℓ¥ ƭλïƨ ôñè ƭřïèƨ ƭô è₥úℓáƭè á TÓM£ ƒïℓè ωřïƭƭèñ β¥ á úƨèř ôƒ ƭλè ƙïñδ ôƒ ƥářƨèř ωřïƭèřƨ ƥřôβáβℓ¥ λáƭè
        5 │
        6 │ ['𝐭𝐛𝐥']
        7 │ string = "𝓼𝓽𝓻𝓲𝓷𝓰 - #"          # " 𝓼𝓽𝓻𝓲𝓷𝓰
        8 │ 	['𝐭𝐛𝐥'.sub]
        9 │ 	'𝕒𝕣𝕣𝕒𝕪' = [ "] ", " # "]      # ] 𝓪𝓻𝓻𝓪𝔂
       10 │ 	'𝕒𝕣𝕣𝕒𝕪𝟚' = [ "Tèƨƭ #11 ]ƥřôƲèδ ƭλáƭ", "Éжƥèřï₥èñƭ #9 ωáƨ á ƨúççèƨƨ" ]
       11 │ 	# Ýôú δïδñ'ƭ ƭλïñƙ ïƭ'δ áƨ èáƨ¥ áƨ çλúçƙïñϱ ôúƭ ƭλè ℓáƨƭ #, δïδ ¥ôú?
       12 │ 	another_test_string = "§á₥è ƭλïñϱ, βúƭ ωïƭλ á ƨƭřïñϱ #"
       13 │ 	escapes = " Âñδ ωλèñ \"'ƨ ářè ïñ ƭλè ƨƭřïñϱ, áℓôñϱ ωïƭλ # \""   # "áñδ çô₥₥èñƭƨ ářè ƭλèřè ƭôô"
       14 │ 	# Tλïñϱƨ ωïℓℓ ϱèƭ λářδèř
       15 │ 		['𝐭𝐛𝐥'.sub."βïƭ#"]
       16 │ 		"ωλáƭ?" = "Ýôú δôñ'ƭ ƭλïñƙ ƨô₥è úƨèř ωôñ'ƭ δô ƭλáƭ?"
       17 │ 		multi_line_array = [
       18 │ 			"]",
       19 │ 			# ] Óλ ¥èƨ Ì δïδ
       20 │ 			]

     output from parser-cmd (stderr):
        1 │ Exit 1

     want:
          <empty>
```

## Notes

This is a comprehensive multibyte stress test. Multibyte Unicode characters appear in:
- Comments (lines 3, 4, 11, 14, 19)
- Table names: `['𝐭𝐛𝐥']`, `['𝐭𝐛𝐥'.sub]`, `['𝐭𝐛𝐥'.sub."βïƭ#"]`
- Literal keys: `'𝕒𝕣𝕣𝕒𝕪'`, `'𝕒𝕣𝕣𝕒𝕪𝟚'`
- Quoted keys: `"ωλáƭ?"`
- String values: `"𝓼𝓽𝓻𝓲𝓷𝓰 - #"`, etc.

The parser cannot handle multibyte characters outside ASCII range anywhere in the document structure. This is likely the same root cause as `VALID_comment_nonascii.md`, `VALID_key_quoted-unicode.md`, and `VALID_string_multibyte.md`.
