# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

`django.utils.dateparse.parse_duration(value)`

- Signature: unchanged.
- Return type family: unchanged (`datetime.timedelta` or `None`; existing
  overflow behavior is outside this sign-placement audit).
- Public callers: `django.db.models.fields.DurationField.to_python()` and
  `django.forms.fields.DurationField.to_python()`.
- Compatibility status: pass. Both callers already treat `None` as invalid
  input and accept `datetime.timedelta` as parsed input. The V1 fix only changes
  which standard negative strings are valid and what duration they represent.

## Format families

- Standard positive values: preserved by `STD-NODAYS-POS` and
  `STD-DAYS-PRESERVE`.
- ISO 8601: unchanged source regex and existing `sign` handling are left
  untouched.
- PostgreSQL day-time intervals: unchanged source regex and existing sign
  handling are left untouched. PostgreSQL values with textual day markers do not
  match the standard regex first, so their existing behavior is not shadowed by
  V1.

## Compatibility caveats

Existing public tests that expect standard no-day component-sign behavior are
not compatibility blockers because the public issue identifies that behavior as
the bug.
