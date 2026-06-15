# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-13128`, specifically
`CombinedExpression._resolve_output_field()` in
`repo/django/db/models/expressions.py` and its interaction with the existing
`CombinedExpression.as_sql()` temporal-subtraction branch.

No loops or recursive functions are present in the changed unit. The proof is a
finite case analysis over connector and field-type combinations.

## Public Intent Ledger

The public evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`; the controlling
entries are mirrored here:

- E1: the issue asks to make temporal subtraction work without
  `ExpressionWrapper`, imposing a duration output-field obligation on
  same-type temporal subtraction.
- E2: the reported nested expression must type as `DurationField + DurationField`.
- E3: the mixed-type `DateTimeField, DurationField` error is a symptom to remove.
- E4/E5: existing SQL compilation already recognizes same-type temporal
  subtraction as `TemporalSubtraction`, whose output is `DurationField`.
- E7: non-special combinations must keep the generic inference behavior.

## Formal Model

The formal files are:

- `fvk/mini-django-expressions.k`: a finite K model of the relevant
  `CombinedExpression` type resolver and SQL branch discriminator.
- `fvk/temporal-subtraction-spec.k`: K claims for the issue expression, temporal
  field family, generic fallback, and SQL alignment.

The model abstracts each operand to the result of
`output_field.get_internal_type()`. This is sufficient for the audited property:
the defect and the fix both depend only on connector value and internal field
type, not on SQL text, database rows, or expression tree identity.

## Specification

S1. Same-type temporal subtraction output

For `T` in `{DateField, DateTimeField, TimeField}`:

```text
resolveOutput(SUB, T, T) = DurationField
```

S2. Reported nested expression output

```text
resolveOutput(ADD, resolveOutput(SUB, DateTimeField, DateTimeField), DurationField)
= DurationField
```

S3. Generic fallback preservation

For non-special cases, `resolveOutput()` delegates to generic inference:

- same non-temporal field type resolves to that field type;
- mixed known field types resolve to `FieldError`;
- unknown/`None` field sources are ignored in the same way the base resolver
  ignores `None` source fields.

S4. SQL alignment

The SQL branch discriminator for same-type temporal subtraction remains
`TemporalSubtractionSQL`, and that SQL branch has output type `DurationField`.
The V1 fix changes output-field inference only; it does not change SQL rendering.

## Compatibility Conditions

C1. No public signature changes.

`CombinedExpression.__init__()`, `resolve_expression()`, `as_sql()`,
`DurationExpression`, and `TemporalSubtraction` keep their signatures.

C2. No test changes.

The public and hidden suites remain fixed. This FVK pass did not modify any test
files.

## Conclusion

V1 satisfies the stated spec. The audit did not justify additional production
code changes.
