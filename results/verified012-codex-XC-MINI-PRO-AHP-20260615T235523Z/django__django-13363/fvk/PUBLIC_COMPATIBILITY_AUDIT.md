# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`django.db.models.functions.datetime.TruncDate.as_sql(self, compiler, connection)`

- Signature: unchanged.
- Return shape: unchanged, still `(sql, lhs_params)`.
- Backend operation: unchanged, still
  `connection.ops.datetime_cast_date_sql(lhs, tzname)`.
- Compatibility result: PASS.

`django.db.models.functions.datetime.TruncTime.as_sql(self, compiler, connection)`

- Signature: unchanged.
- Return shape: unchanged, still `(sql, lhs_params)`.
- Backend operation: unchanged, still
  `connection.ops.datetime_cast_time_sql(lhs, tzname)`.
- Compatibility result: PASS.

## Public callsites and subclass/override surface

Static source search found public uses of `TruncDate(...)` and `TruncTime(...)`
in docs and tests, and only the two class definitions in production code. No
subclasses overriding these methods were found under `repo/django`.

Existing public tests exercise:

- default `TruncDate('start_datetime')` and `TruncTime('start_datetime')`;
- invalid field combinations and explicit `output_field` attempts;
- null datetime results.

The V1 fix changes only the selected timezone argument. It does not alter
constructor signatures, transform registration, validation, null handling,
compiled params, or backend method signatures.

## Backend operation contracts

All concrete Django backends already define:

- `datetime_cast_date_sql(field_name, tzname)`;
- `datetime_cast_time_sql(field_name, tzname)`.

The fix supplies a different `tzname` value when explicit `tzinfo` is present.
No backend API change is introduced.

