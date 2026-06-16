# Intent Spec

Status: constructed from public issue text and in-repository source, not machine-checked.

## Required behavior

1. A timezone database name containing a sign, such as `Etc/GMT-10`, must remain a timezone name when `Trunc()` and `Extract()` build database timezone conversions. It must not be rewritten to the opposite timezone (`Etc/GMT+10`) and must not be truncated to a suffix such as `-10`.

2. Fixed-offset strings must keep the backend-specific behavior already required by the existing conversion paths:
   - PostgreSQL reverses numeric offset signs for `AT TIME ZONE` offset literals.
   - MySQL and Oracle pass bare numeric offsets to their conversion functions, stripping an optional `UTC` prefix.
   - SQLite applies numeric offsets in its Python-side datetime parser.

3. Offset-specific handling must be limited to fixed-offset string forms. The intended offset family is `+HH`, `-HH`, `+HHMM`, `-HHMM`, `+HH:MM`, `-HH:MM`, and the same forms with an optional `UTC` prefix.

4. Existing public API shape must remain unchanged: no signature changes to backend operation methods, no altered `TimezoneMixin.get_tzname()` contract, and no test-file edits.

## Out of scope

This FVK pass does not prove database engines' own timezone-table correctness. It proves that Django sends named signed timezones as names and only applies numeric-offset rewrites to numeric offsets.
