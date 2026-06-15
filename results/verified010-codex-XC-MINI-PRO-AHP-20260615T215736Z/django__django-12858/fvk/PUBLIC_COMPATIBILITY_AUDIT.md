# PUBLIC_COMPATIBILITY_AUDIT.md

Status: constructed, not machine-checked.

## Changed Symbol

- `django.db.models.base.Model._check_ordering`

## Compatibility Review

- Signature: unchanged.
- Return type: unchanged; still returns a list of `checks.Error` objects.
- Error ID for invalid ordering: unchanged; still `models.E015`.
- Error message template for invalid ordering: unchanged.
- Public callers: the check framework invokes model check classmethods and consumes returned check messages; V1 does not alter that protocol.
- Subclass/override risk: no new virtual dispatch or keyword argument was introduced.

## Verdict

No compatibility issue found. This supports PO-5 and F-004.
