# Findings

Status: constructed, not machine-checked.

## F1: Pre-V1 Temporal Subtraction Was Inferred Too Late

- Classification: code bug fixed by V1.
- Evidence: E1, E2, E3; PO1 and PO2.
- Input: `resolveOutput(ADD, resolveOutput(SUB, DateTimeField, DateTimeField), DurationField)`.
- Observed before V1: the inner subtraction inherited the generic same-type
  result `DateTimeField`; the outer expression saw
  `DateTimeField + DurationField` and raised the reported mixed-type
  `FieldError`.
- Expected: the inner same-type temporal subtraction resolves to
  `DurationField`, so the outer expression sees
  `DurationField + DurationField`.
- V1 status: resolved by `CombinedExpression._resolve_output_field()`.

## F2: Output Inference Must Stay Aligned With SQL Temporal Subtraction

- Classification: proof obligation, satisfied by V1.
- Evidence: E4, E5; PO3.
- Input: `resolveOutput(SUB, T, T)` for `T` in the temporal field family.
- Risk: if type inference used a different temporal predicate than SQL
  rendering, a future expression could infer one type but render through a
  different branch.
- Expected: same temporal predicate as `CombinedExpression.as_sql()`.
- V1 status: satisfied. The temporal set is the same as the existing SQL branch:
  `DateField`, `DateTimeField`, and `TimeField`.

## F3: The Fix Must Not Broaden Unrelated Mixed Arithmetic

- Classification: frame condition, satisfied by V1.
- Evidence: E7; PO4.
- Input: direct `resolveOutput(ADD, DateTimeField, DurationField)`.
- Expected: still a generic mixed-type `FieldError`; the issue only requires the
  inner temporal subtraction to become `DurationField`.
- V1 status: satisfied. `_resolve_output_field()` delegates to
  `super()._resolve_output_field()` outside same-type temporal subtraction.

## F4: Compatibility Audit Found No Blocking API Changes

- Classification: compatibility, satisfied by V1.
- Evidence: PO5 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Input: public callers and subclasses of `CombinedExpression`.
- Expected: no signature or dispatch shape changes.
- V1 status: satisfied. V1 adds an override only and leaves existing signatures
  and SQL methods unchanged.

## Residual Caveat

The proof is constructed from a finite K model and source inspection, not
machine-checked. The emitted commands in `fvk/PROOF.md` should be run in an
environment with K installed before treating proof-based test-redundancy
recommendations as actionable. This caveat does not change the code decision:
the FVK audit did not surface a justified source edit beyond V1.
