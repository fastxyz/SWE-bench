# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Source decode table entry for `1`

- Claim: `morse_char[".----"] == "1"` and `morse_char` has no entry
  `"----": "1"`.
- Provenance: IE-2.
- Formal claims: `(MORSE-TABLE-ONE)` proves the positive `.----` lookup;
  `(DIGIT-FAMILY)` gives the exact digit-family table and excludes the legacy
  four-dash key for `"1"`.
- Status: discharged by static inspection of `repo/sympy/crypto/crypto.py` and
  the constructed finite-table claims.

## PO-2: Derived reverse map for `1`

- Claim: if `char_morse = {v: k for k, v in morse_char.items()}` and
  `morse_char[".----"] == "1"`, then `char_morse["1"] == ".----"`.
- Provenance: IE-3.
- Formal claim: `(MORSE-INVERSE-ONE)` in `fvk/morse-spec.k`.
- Status: discharged by the finite-map reverse construction; uniqueness follows
  because no other digit-family entry maps to `"1"`.

## PO-3: Default encode result for `"1"`

- Claim: `encode_morse("1") == ".----"` with default separator and default
  mapping.
- Provenance: IE-1, IE-2, IE-3.
- Formal claim: `(ENCODE-ONE)` in `fvk/morse-spec.k`.
- Status: discharged by one-character symbolic execution: normalize whitespace
  as no-op, keep `"1"` as mapped, lookup `char_morse["1"]`, join one token.

## PO-4: Default decode result for `.----`

- Claim: `decode_morse(".----") == "1"` with default separator and default
  mapping.
- Provenance: IE-2, IE-3.
- Formal claim: `(DECODE-ONE)` in `fvk/morse-spec.k`.
- Status: discharged by one-token symbolic execution: split one word/letter,
  lookup `morse_char[".----"]`, join one character.

## PO-5: Digit-family frame

- Claim: the digit family remains
  `0=-----`, `1=.----`, `2=..---`, `3=...--`, `4=....-`, `5=.....`,
  `6=-....`, `7=--...`, `8=---..`, `9=----.`.
- Provenance: IE-5.
- Formal claim: `(DIGIT-FAMILY)` in `fvk/morse-spec.k`.
- Status: discharged by static table inspection. No other digit-family source
  file or mirrored table was found.

## PO-6: Public compatibility

- Claim: V1 changes only one table literal and does not change public function
  signatures, import names, separator semantics, or test files.
- Provenance: IE-4 and frame conditions in `fvk/SPEC.md`.
- Formal claim: documented in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`; no K claim is
  needed because this is an API-shape/static-diff obligation.
- Status: discharged by static diff: only `repo/sympy/crypto/crypto.py` line
  1523 changed in source, replacing the table key for `"1"`.
