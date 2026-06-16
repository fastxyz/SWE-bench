# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## Claims proved by construction

The proof targets the claims listed in `fvk/regex-csv-spec.k` and the obligations in `fvk/PROOF_OBLIGATIONS.md`.

## Scanner proof

The scanner loop has state `(patterns, pattern, escaped, in_character_class, open_brace, remaining_input)`.

Loop invariant:

- `patterns` is the ordered list of completed fragments from the already-scanned prefix.
- `pattern` is the exact sequence of non-separator characters since the last separator.
- `escaped`, `in_character_class`, and `open_brace` encode the regex context at the end of the scanned prefix.
- Concatenating emitted fragments, removed separator commas, and the current fragment reconstructs the scanned prefix, modulo boundary stripping and empty-fragment discard at emit points.

Progress:

- Each branch consumes one input character. The remaining suffix length decreases by one. This discharges O1.

Case split on next character:

- If `escaped` is true, append the character, clear `escaped`, and consume it. This preserves escaped commas and discharges the escaped branch of O2/O3/O4.
- If the character is backslash and `escaped` is false, append it, set `escaped`, and consume it. This preserves the escape marker and discharges O2.
- If the character is `[` outside a class, append it and enter character-class mode. If it is `]` inside a class, append it and leave character-class mode. Commas seen while `in_character_class` is true are therefore appended, not emitted. This discharges O2/O3 and the `REGEX-CHARCLASS-COMMA` claim.
- If the character is `{` outside a class, append it and enter brace mode. If it is `}` while brace mode is open outside a class, append it and leave brace mode. Commas seen while `open_brace` is true are therefore appended, not emitted. This discharges O2/O3 and the `REGEX-QUANTIFIER-EXAMPLE` claim.
- If the character is comma and all context flags are false, emit the stripped current fragment if non-empty and reset the current fragment. This discharges O3/O5/O7.
- Otherwise append the character. This discharges O4.

Finalization:

- When the remaining input is empty, emit the stripped current fragment if non-empty. This is the same emit rule used for separator boundaries and discharges O5.

## Transformer proof

`_regexp_csv_transfomer` iterates over the fragments returned by `_split_regex_csv`.

- For every valid fragment, `_regex_transformer(fragment)` returns `re.compile(fragment)`. The loop appends those compiled patterns in iteration order, discharging O8.
- If `_regex_transformer` catches `re.error`, it raises `argparse.ArgumentTypeError`. Because `_regexp_csv_transfomer` delegates every compile through `_regex_transformer`, invalid fragments use the clean error path, discharging O9.

## Adequacy and compatibility

- `fvk/SPEC_AUDIT.md` marks all formal claims as PASS against public intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no changed public API shape.
- `F-001` marks the conflicting public test as SUSPECT legacy behavior, so it does not block the issue-derived spec.

## Machine-check commands

These commands are intentionally not executed in this environment:

```sh
kompile fvk/mini-regex-csv.k --backend haskell
kast --backend haskell fvk/regex-csv-spec.k
kprove fvk/regex-csv-spec.k
```

Expected machine-check outcome for the modeled claims: `#Top`.

## Test-redundancy recommendation

No tests are removed. Because this proof is constructed but not machine-checked, no test deletion is recommended. The existing test for `(foo{1,3})` should be treated as a legacy-behavior conflict to update in a normal test-maintenance pass, but this task forbids modifying tests.
