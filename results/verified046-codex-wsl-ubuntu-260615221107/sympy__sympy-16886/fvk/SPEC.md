# FVK Specification: Morse digit `1`

Status: constructed, not machine-checked.

## Scope

The audited unit is the Morse-code table and the default `encode_morse` /
`decode_morse` behavior in `repo/sympy/crypto/crypto.py`. There are no loops or
recursive functions in the relevant path. The proof models the table literal,
the derived reverse table `char_morse`, and one-character default encode/decode
lookups.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| IE-1 | prompt | "Morse encoding for \"1\" is not correct" | Default encoding of the plaintext character `"1"` must produce the intended Morse token. | Encoded by PO-3. |
| IE-2 | prompt | "incorrect mapping of `\"----\": \"1\"`; The correct mapping is `\".----\": \"1\"`" | The default decode table must map `.----` to `"1"` and must not map `----` to `"1"`. | Encoded by PO-1 and PO-4. |
| IE-3 | code/docstring | `encode_morse` encodes plaintext into "popular Morse Code"; `decode_morse` decodes Morse code; `char_morse = {v: k for k, v in morse_char.items()}` | The default encode table is the inverse of `morse_char`; correcting the source table should correct both directions. | Encoded by PO-2. |
| IE-4 | public tests | Existing tests cover letters, whitespace, punctuation, and invalid decode input, but not digit `1`. | Preserve existing API behavior and do not infer a legacy digit mapping from absent tests. | Encoded by PO-6; recorded as F-003 test gap. |
| IE-5 | default-domain assumption | Standard Morse-code digit family: `0=-----`, `1=.----`, `2=..---`, `3=...--`, `4=....-`, `5=.....`, `6=-....`, `7=--...`, `8=---..`, `9=----.` | Audit the whole digit family rather than only the reported member. | Encoded by PO-5. |

## Intended Contract

For default mappings:

1. `morse_char[".----"] == "1"`.
2. `morse_char` does not contain the legacy entry `"----": "1"`.
3. `char_morse["1"] == ".----"` because `char_morse` is the reverse of
   `morse_char`.
4. `encode_morse("1") == ".----"` when using the default separator and default
   mapping.
5. `decode_morse(".----") == "1"` when using the default separator and default
   mapping.
6. The digit-family entries remain the standard Morse entries listed in IE-5.

## Frame Conditions

- Public function names, signatures, default separator behavior, whitespace
  normalization, custom mapping behavior, and existing tests' non-digit examples
  are outside the reported defect and are preserved.
- No test files are modified.

## Formal Artifacts

- `fvk/mini-python.k`: minimal table/lookup semantics for the relevant Python
  fragment.
- `fvk/morse-spec.k`: K claims for the table entry, inverse-map behavior, default
  encode/decode of `"1"`, and the digit-family frame.

