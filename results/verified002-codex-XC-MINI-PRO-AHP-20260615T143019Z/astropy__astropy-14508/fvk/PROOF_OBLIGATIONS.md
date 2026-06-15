# Proof Obligations

Status: constructed for FVK audit; not machine-checked.

## PO1 - Short representation preference

For every float view `floatView(S, Legacy)`, if
`len(normalizeLowerE(S)) <= 20`, then `_format_float` selects `S` after
lowercase-exponent normalization rather than `Legacy`.

- Discharges: F1.
- Evidence: E1, E4, E5, E6.
- K claim: `SHORT-REP-PREFERENCE`.

## PO2 - FITS exponent and decimal normalization

After base-token selection, the helper still ensures a decimal point for plain
non-exponent numeric strings and normalizes exponent output to uppercase `E`.

- Discharges: F2.
- Evidence: E7.
- K claim: `EXPONENT-NORMALIZATION`; helper functions in
  `mini-fits-card-format.k`.

## PO3 - Overlong short-token fallback

For every float view where `len(normalizeLowerE(S)) > 20`, `_format_float`
selects the legacy `.16G` token and then applies the pre-existing cleanup/cap.

- Discharges: F3.
- Evidence: E5, E8.
- K claim: `LEGACY-FALLBACK`.

## PO4 - Reported HIERARCH card preservation

For the reported keyword/comment and value view
`floatView("0.009125", "0.009124999999999999")`, card formatting uses the short
token and the complete comment fits in the 80-character card image.

- Discharges: F1.
- Evidence: E2, E3, E4.
- K claims: `REPORTED-FLOAT`, `REPORTED-HIERARCH-CARD`.

## PO5 - Parsed valuestring frame condition

If a card has `_valuestring` set, `_valuemodified` false, and a float/complex
value, then `Card._format_value()` preserves `_valuestring` and does not call
the newly changed `_format_float` path.

- Discharges: F4.
- Evidence: E9.
- Proof form: source-level frame proof from the `elif` branch in
  `Card._format_value()`.

## PO6 - Public compatibility

The fix must not change public signatures, public return types, or test files.

- Discharges: public compatibility audit.
- Evidence: E10.
- Proof form: source-level compatibility proof; `_format_float` signature and
  return type are unchanged, and no test files were edited.
