# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the one-line source change discharges the central issue obligation and the broader conversion-failure obligation introduced by `ValueError`.

## Why no V2 source edit is needed

- F1 and PO5 show the reported dictionary/type-error path is fixed by catching `TypeError`.
- F2 and PO6 show the additional `ValueError` catch is justified by public/base API intent, not by hidden tests.
- F3 and PO1-PO4 show valid inputs, float conversion, and existing invalid syntax behavior are preserved.
- F4 and PO8 show there is no public signature, callsite, override, or return-shape compatibility problem.
- PO7 confirms the change remains targeted to `decimal.Decimal(value)` conversion failures rather than catching unrelated exceptions.

## Suggested tests for a normal development environment

Do not add or edit tests in this benchmark task. In a normal Django development pass, useful tests would be:

- `DecimalField(max_digits=4, decimal_places=2).to_python({})` raises `ValidationError` with `code == 'invalid'`.
- `DecimalField(...).clean({}, None)` raises the same `ValidationError`.
- A malformed tuple/value-error input raises `ValidationError` if a stable public example is selected.
- Existing valid integer, string, and float conversion tests continue to pass.

## Machine-check commands to run later

Recorded only, not executed:

```sh
cd fvk
kompile mini-decimal-field.k --backend haskell
kast --backend haskell decimal-field-spec.k
kprove decimal-field-spec.k
```

## Next iteration if a machine check fails

- If the parser rejects the mini K syntax, repair only the formal artifact syntax; the source-code decision still follows from F1/PO5 unless the repaired claims change meaning.
- If the `dictInput` claim does not discharge, inspect whether the `handle(raises(typeError), V)` rule still represents V1's `except (..., TypeError, ...)` branch.
- If adequacy fails, repair the spec before changing source; the public issue and base `Field.to_python()` contract remain the controlling intent evidence.
