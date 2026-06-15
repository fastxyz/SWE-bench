# SPEC

Status: constructed, not machine-checked.

## Target

Audited unit: `repo/django/db/models/fields/__init__.py`, `DecimalField.to_python(self, value)`.

Candidate under audit: V1 changes the `decimal.Decimal(value)` conversion guard from catching only `decimal.InvalidOperation` to catching `(decimal.InvalidOperation, TypeError, ValueError)`.

## Intent-derived contract

For the intended `DecimalField.to_python()` behavior:

- `None` is returned unchanged.
- Floats are converted with `self.context.create_decimal_from_float(value)`.
- Non-float values accepted by `decimal.Decimal(value)` are returned as decimal values.
- Conversion failures from `decimal.Decimal(value)` that mean "this value is not a decimal number" raise Django `ValidationError` with the existing invalid decimal message, `code='invalid'`, and `params={'value': value}`.
- A dictionary value is in scope because the public issue names it explicitly. Its raw `TypeError` is the defect, not behavior to preserve.
- `ValueError` from malformed conversion input is treated as the same conversion-failure class because the base `Field.to_python()` contract says conversion failures raise `ValidationError`, and adjacent numeric fields normalize `TypeError` and `ValueError` in `to_python()`.
- The public signature and valid-input return behavior are frame conditions.

## Public evidence ledger summary

The complete ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

Key entries:

- E1/E2: The issue says dictionary input currently produces `TypeError` instead of `ValidationError`.
- E4: The base `Field.to_python()` docstring says conversion failures raise `django.core.exceptions.ValidationError`.
- E5/E6/E7: Public DecimalField tests preserve valid integer, string, float, and invalid string behavior.
- E8: Adjacent model numeric fields treat `TypeError` and `ValueError` as conversion failures in `to_python()`.
- E9: V1 changes only the local exception tuple around `decimal.Decimal(value)`.

## Formal model

Formal files:

- `fvk/mini-decimal-field.k`
- `fvk/decimal-field-spec.k`

The mini semantics abstracts Python decimal conversion into observable input classes:

- `none`
- `floatInput(F)`
- `validInput(D)`
- `invalidSyntaxInput`, where conversion raises `decimal.InvalidOperation`
- `dictInput`, where conversion raises `TypeError`
- `malformedTupleInput`, where conversion raises `ValueError`
- `otherExceptionInput`, outside the issue's conversion-failure set

This abstraction is property-complete for this issue because it preserves the axis being verified: whether `DecimalField.to_python()` returns a value, raises Django `ValidationError`, or leaks a raw non-validation exception.

## Claims

`decimal-field-spec.k` states these `[all-path]` claims:

- `toPython(none, PREC) => returnNone`
- `toPython(floatInput(F), PREC) => returnDecimal(decimalFromFloat(F, PREC))`
- `toPython(validInput(D), PREC) => returnDecimal(decimal(D))`
- `toPython(invalidSyntaxInput, PREC) => validationError(invalidSyntaxInput)`
- `toPython(dictInput, PREC) => validationError(dictInput)`
- `toPython(malformedTupleInput, PREC) => validationError(malformedTupleInput)`
- `toPython(otherExceptionInput, PREC) => rawException(otherError)`

There are no loops or recursive calls, so there are no circularity claims.

## Adequacy

The formal-English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the intent-only obligations in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` marks all formal items as pass. The compatibility audit in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no unhandled public callsite, override, or signature issue.

Conclusion: the V1 source fix satisfies the FVK spec. No V2 source edit is justified.
