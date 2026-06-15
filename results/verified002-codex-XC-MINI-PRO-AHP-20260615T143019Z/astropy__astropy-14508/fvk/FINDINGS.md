# FVK Findings

Status: constructed for FVK audit; not machine-checked.

## F1 - Closed code bug: short float token was not preferred

- Evidence: E4, E5.
- Input: `floatView("0.009125", "0.009124999999999999")`.
- V0 observed behavior: `_format_float` selected the legacy `.16G` token
  `0.009124999999999999`.
- Expected behavior: select `str(value)`, yielding `0.009125`, because it fits in
  20 characters.
- V1 status: closed by PO1 and PO4.

## F2 - Closed compatibility risk: lowercase exponent from `str(value)`

- Evidence: E7.
- Input: a short `str(value)` token such as `5.0022221e-07`.
- Risk: raw `str(value)` would use lowercase `e`, while existing FITS standard
  verification expects uppercase exponent markers.
- Expected behavior: normalize lowercase `e` to uppercase `E` before standard
  verification sees the serialized card.
- V1 status: closed by PO2.

## F3 - Closed compatibility risk: overlong `str(value)` tokens

- Evidence: E5, E8.
- Input class: floats whose Python `str(value)` token is longer than 20
  characters.
- Risk: using raw `str(value)` for every float would disturb the helper's
  existing 20-character value-token budget and can change long scientific
  notation formatting more than the issue requires.
- Expected behavior: use `str(value)` only when it fits; otherwise use the
  existing compact `.16G` fallback and capping path.
- V1 status: closed by PO3.

## F4 - Frame condition confirmed: parsed value strings

- Evidence: E9.
- Input class: unmodified cards parsed from existing FITS headers with
  `_valuestring` already set.
- Observed code path: `Card._format_value()` returns the preserved `_valuestring`
  for float and complex values when `_valuemodified` is false.
- Expected behavior: V1 must not reformat these cards while fixing newly
  constructed card values.
- V1 status: confirmed by PO5.

## F5 - Residual proof/tooling caveat

- Evidence: FVK honesty gate.
- Finding: the proof artifacts are constructed but not machine-checked in this
  environment. This is not a source-code defect, but test removal and final
  proof confidence remain conditioned on running the emitted `kompile`/`kprove`
  commands elsewhere.
- V1 status: no code change justified.

## Open code findings

None. The FVK audit did not surface a source-code change beyond V1.
