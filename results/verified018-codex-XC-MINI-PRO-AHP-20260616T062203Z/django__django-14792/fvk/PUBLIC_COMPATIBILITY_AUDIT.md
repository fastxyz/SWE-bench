# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

- `BaseDatabaseOperations._split_tzname_delta(tzname)`
  - New private helper introduced by the fix.
  - Public compatibility risk: low; private backend helper, no public callsites in source outside backend operations.
  - V2 change: tightened implementation from prefix-only detection to anchored numeric offset regex. Return shape is unchanged from V1: `(prefix, sign, offset)` or `(None, None, None)`.

- `DatabaseOperations._prepare_tzname_delta(tzname)` in PostgreSQL, MySQL, and Oracle
  - Signature unchanged.
  - Return type unchanged: string.
  - Callers unchanged: `_convert_field_to_tz()` in each backend.

- SQLite module-level `TIMEZONE_OFFSET_REGEX`
  - New internal regex; no public API.

- SQLite `_sqlite_datetime_parse(dt, tzname=None, conn_tzname=None)`
  - Signature unchanged.
  - Return behavior for non-offset signed names changes from failing or misadjusting to named-timezone localization, matching intent.

## Callsite and override audit

The source search found the changed `_prepare_tzname_delta()` methods are only used by their backend-local `_convert_field_to_tz()` methods. No public method signatures, virtual dispatch arguments, model function APIs, or test files were changed.

## Compatibility conclusion

No public API incompatibility was introduced. The observable change is limited to correcting timezone string preparation for signed names and narrowing offset parsing to numeric fixed-offset strings.
