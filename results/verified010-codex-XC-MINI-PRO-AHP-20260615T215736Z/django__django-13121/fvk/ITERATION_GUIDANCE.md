# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 should not stand unchanged. FVK finding F2 and proof obligation PO3 showed
that temporal subtraction is a duration-producing expression in Django, but V1
did not count it as duration output for duration-only arithmetic.

V2 keeps the V1 numeric microsecond branch and adds temporal subtraction
classification in `has_duration_output()`.

## Recommended next actions

1. Keep the V2 source change.
2. Do not modify tests in this benchmark task.
3. When an execution environment is available, add or run coverage for:
   `DurationField + timedelta`, `timedelta + DurationField`,
   `DurationField + DurationField`, `DurationField + (DateTimeField -
   DateTimeField)`, and `DateTimeField + DurationField`.
4. If K tooling is available, run the commands in `fvk/PROOF.md`. Treat test
   removal as conditional on `kprove` returning `#Top`; until then, keep tests.

## Open risks

- The mini-K semantics abstracts SQL strings and backend execution. It is
  property-complete for the branch decision but not a full Django/Python/SQL
  semantics.
- Native-duration backends are intentionally outside the changed branch.
- This audit proves partial correctness of compilation branch selection, not
  database runtime behavior.
