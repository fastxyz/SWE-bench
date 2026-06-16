# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F-001: Resolved code bug - wrong table entry for digit `1`

- Classification: code bug, resolved by V1.
- Evidence: IE-1 and IE-2 in `fvk/SPEC.md`.
- Pre-V1 observed behavior by static data-flow: `morse_char` contained
  `"----": "1"`, so the derived `char_morse` would encode `"1"` as `----`.
- Expected behavior: `.----` maps to `"1"`, so default encoding of `"1"` is
  `.----` and default decoding of `.----` is `"1"`.
- Current status: V1 changed the source table to `".----": "1"`. PO-1, PO-3,
  and PO-4 discharge the intended behavior.

## F-002: No separate `char_morse` edit is required

- Classification: implementation audit, resolved/confirmed.
- Evidence: IE-3 in `fvk/SPEC.md`; PO-2 in `fvk/PROOF_OBLIGATIONS.md`.
- Observed data-flow: `char_morse` is constructed as `{v: k for k, v in
  morse_char.items()}` at module initialization.
- Expected behavior: once `morse_char[".----"] == "1"`, the derived reverse map
  has `char_morse["1"] == ".----"`.
- Current status: V1's single table edit is sufficient for default encoding.

## F-003: Public test gap for digit `1`

- Classification: test gap.
- Evidence: IE-4 in `fvk/SPEC.md`.
- Observed public tests: Morse tests cover letters, whitespace, punctuation, and
  an invalid decode input, but no assertion for `encode_morse("1")` or
  `decode_morse(".----")`.
- Expected coverage: a future public test should cover the reported digit in
  both encode and decode directions.
- Current status: no test files were edited, per task constraints.

## F-004: Digit-family completeness checked statically

- Classification: table-family audit, confirmed.
- Evidence: IE-5 in `fvk/SPEC.md`; PO-5 in `fvk/PROOF_OBLIGATIONS.md`.
- Observed current table: the digit entries are
  `0=-----`, `1=.----`, `2=..---`, `3=...--`, `4=....-`, `5=.....`,
  `6=-....`, `7=--...`, `8=---..`, and `9=----.`.
- Expected behavior: the digit family matches standard Morse and contains no
  duplicate digit code for `"1"`.
- Current status: no additional source edits are justified.

## F-005: Proof artifact is constructed, not machine-checked

- Classification: proof capability / honesty gate.
- Evidence: FVK `verify.md` honesty gate.
- Observed process: K commands were written into `fvk/PROOF.md`; they were not
  executed because this task forbids running K tooling.
- Expected outcome if executed later: `kprove fvk/morse-spec.k` should reduce the
  claims to `#Top`.
- Current status: this is not a source-code bug. Test deletion or confidence
  claims remain conditional on a future machine check.

