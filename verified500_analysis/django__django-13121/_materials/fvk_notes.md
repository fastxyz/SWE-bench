# FVK Notes

## Decisions and traceability

1. Kept the V1 stored-microsecond branch for direct duration-only arithmetic.
   This is justified by F1 and proof obligations PO1 and PO2: the reported
   `DurationField + timedelta` case must avoid SQLite `django_format_dtdelta()`
   string output and MySQL `INTERVAL ... MICROSECOND` output when the final
   expression is itself a duration.

2. Revised V1 to also classify same-type temporal subtraction as duration
   output. This change is justified by F2 and PO3. Django's existing
   `CombinedExpression.as_sql()` already compiles `DateField - DateField`,
   `DateTimeField - DateTimeField`, and `TimeField - TimeField` through
   `TemporalSubtraction`, whose output field is `DurationField`. V1 missed that
   duration-producing family when it looked only at the raw expression
   `output_field`.

3. Preserved the mixed date/time duration path. This is justified by F3 and PO4:
   expressions such as `DateTimeField + DurationField` still need backend
   interval formatting, so V2 only takes the numeric branch when both operands
   are duration-producing.

4. Kept the connector guard limited to `+` and `-`. This is justified by F4 and
   PO5. The issue concerns valid duration addition/subtraction, and the SQLite
   backend already treats other timedelta connectors as invalid.

5. Made no backend API, model field, or test-file changes. This is justified by
   F5 and PO6. The source edit is limited to internal expression classification
   and compilation branch selection in `DurationExpression`.

## Files changed in the repair pass

`repo/django/db/models/expressions.py`

- `DurationExpression.compile()` now accepts `duration_only` so
  `DurationValue` literals can be compiled through `Value.as_sql()` only when
  the final expression is duration-only.
- `DurationExpression.has_duration_output()` identifies explicit
  `DurationField` output and, in V2, same-type temporal subtraction as duration
  output.
- `DurationExpression.as_sql()` selects numeric `combine_expression()` for
  duration-only `+` and `-`; otherwise it keeps the existing backend
  `combine_duration_expression()` path.

## Artifacts

The FVK artifacts are in `fvk/`. The requested five are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting artifacts required by the FVK docs were also written:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-duration-expressions.k`
- `fvk/duration-expression-spec.k`

## Verification status

The proof is constructed, not machine-checked. Per task instructions, I did not
run tests, Python, database code, `kompile`, `kast`, or `kprove`.
