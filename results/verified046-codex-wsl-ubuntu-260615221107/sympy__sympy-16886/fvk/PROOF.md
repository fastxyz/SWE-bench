# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims Proved

- PO-1: `morse_char[".----"] == "1"` and the legacy `"----": "1"` mapping is
  absent.
- PO-2: the derived reverse table has `char_morse["1"] == ".----"`.
- PO-3: `encode_morse("1") == ".----"` with default mapping and separator.
- PO-4: `decode_morse(".----") == "1"` with default mapping and separator.
- PO-5: the surrounding digit-family table is unchanged and standard.
- PO-6: no public API shape changed.

## Symbolic Execution Sketch

### Table construction

The current `morse_char` literal contains the binding `".----": "1"` and no
binding `"----": "1"`. The digit-family entries are unique for the ten digit
characters, so reversing the finite map assigns `"1"` to exactly `.----`.

### Default `encode_morse("1")`

1. The default mapping is `char_morse`.
2. With separator `"|"`, the word separator is `"||"`.
3. The input has no whitespace to normalize and no unmapped character to omit.
4. The single word contains the single character `"1"`.
5. The lookup `char_morse["1"]` rewrites to `.----` by PO-2.
6. Joining a one-element Morse word with `"|"` returns `.----`.

Therefore `encode_morse("1")` reaches `.----`.

### Default `decode_morse(".----")`

1. The default mapping is `morse_char`.
2. With separator `"|"`, the word separator is `"||"`.
3. Stripping and splitting produces one word containing one token, `.----`.
4. The lookup `morse_char[".----"]` rewrites to `"1"` by PO-1.
5. Joining a one-character word returns `"1"`.

Therefore `decode_morse(".----")` reaches `"1"`.

## Adequacy and Completeness Check

The formal claims cover the full public issue intent: the source mapping,
default encoding, and default decoding for digit `1`. The table-family audit also
checks the surrounding digit entries so the repair is not a one-off that leaves a
known sibling digit wrong. No claim relies on the pre-V1 behavior as expected
behavior.

## Exact Commands To Machine-Check Later

These commands are intentionally not executed in this task:

```sh
cd /home/patrickmao/.swe-fvk-runs/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-16886/fvk
kompile mini-python.k --backend haskell
kast --backend haskell morse-spec.k
kprove morse-spec.k
```

Expected machine-check result after a future run: `#Top` for all claims.

## Test Redundancy

No tests were deleted or modified. Existing public Morse tests do not cover digit
`1`, so no current test is recommended for removal. Future tests for
`encode_morse("1") == ".----"` and `decode_morse(".----") == "1"` would be
subsumed only after the K proof is actually machine-checked.
