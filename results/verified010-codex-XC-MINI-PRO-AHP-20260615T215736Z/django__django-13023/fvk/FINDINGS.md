# FINDINGS

Status: constructed, not machine-checked.

## F1 - Resolved code bug: dict input leaked TypeError

- Classification: code bug, resolved by V1.
- Evidence: Public issue E1/E2 says `DecimalField.to_python()` with a dictionary produced `TypeError` instead of `ValidationError`.
- Input: `dictInput`, representing a Python dictionary value passed to `DecimalField.to_python()`.
- Pre-V1 observed behavior: `decimal.Decimal(value)` raises raw `TypeError`, and the method did not catch it.
- Expected behavior: Django `ValidationError` with the existing invalid decimal message, code, and value params.
- V1 behavior: the exception tuple catches `TypeError`, so `dictInput => validationError(dictInput)`.
- Proof obligations: PO5, PO7.
- Status: discharged by constructed proof; not machine-checked.

## F2 - Resolved adjacent conversion gap: ValueError input should not leak

- Classification: needed code guard, resolved by V1.
- Evidence: Base `Field.to_python()` contract E4 and adjacent numeric field behavior E8 treat conversion failures as validation errors.
- Input: `malformedTupleInput`, representing a value for which `decimal.Decimal(value)` raises `ValueError`.
- Pre-V1 observed behavior: raw `ValueError` would bypass the `except decimal.InvalidOperation` guard.
- Expected behavior: Django `ValidationError` for data that cannot be converted to a decimal number.
- V1 behavior: the exception tuple catches `ValueError`, so `malformedTupleInput => validationError(malformedTupleInput)`.
- Proof obligations: PO6, PO7.
- Status: discharged by constructed proof; not machine-checked.

## F3 - Confirmed preservation: valid and existing invalid syntax paths

- Classification: frame condition, confirmed.
- Evidence: Public tests E5/E6/E7 cover valid integer, valid string, context-based float conversion, and invalid string syntax.
- Inputs: `none`, `floatInput(F)`, `validInput(D)`, `invalidSyntaxInput`.
- Expected behavior: unchanged from pre-V1.
- V1 behavior: the source edit is limited to the exception tuple inside the non-float `decimal.Decimal(value)` conversion guard, preserving return paths and the existing `InvalidOperation` validation path.
- Proof obligations: PO1, PO2, PO3, PO4.
- Status: discharged by constructed proof; not machine-checked.

## F4 - Confirmed compatibility: no public API or dispatch break

- Classification: compatibility finding, no defect found.
- Evidence: Public compatibility audit found the method signature unchanged and no new call arguments, return shape, or virtual dispatch.
- Expected behavior: existing callers continue to call `to_python(value)` and receive the same valid conversion results.
- V1 behavior: only additional conversion-failure exceptions are normalized to `ValidationError`.
- Proof obligations: PO8.
- Status: discharged by inspection; not machine-checked.

## F5 - Residual proof caveat

- Classification: proof capability gap.
- Evidence: FVK MVP constructs but does not run `kompile` or `kprove`; benchmark instructions also prohibit running tests or code.
- Input: all formal claims.
- Expected behavior: machine checking would return `#Top` for all claims before treating proof-covered tests as redundant.
- Observed behavior in this session: commands are recorded in `fvk/PROOF.md` but not executed.
- Proof obligations: all.
- Status: open caveat only; not a source-code bug.
