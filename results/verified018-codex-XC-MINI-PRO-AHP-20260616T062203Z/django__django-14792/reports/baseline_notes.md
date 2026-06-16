# Baseline Notes

## Root cause

`TimezoneMixin.get_tzname()` now returns the string form of a `tzinfo`, so IANA names such as `Etc/GMT-10` reach the database backends unchanged. Several backend helpers treated any `+` or `-` anywhere in that string as a fixed UTC offset marker. As a result, `Etc/GMT-10` was rewritten as if it were an offset rather than a timezone name: PostgreSQL inverted it to `Etc/GMT+10`, while MySQL and Oracle truncated it to `-10`. SQLite had the same assumption in its Python datetime parser and attempted to split the name as an offset.

The fix is to apply offset-specific rewriting only to strings that look like fixed-offset timezone names, such as `+0500`, `-05:00`, or `UTC+05:00`. Timezone database names that contain signs, including `Etc/GMT-10`, now pass through as names.

## Changed files

`repo/django/db/backends/base/operations.py`

Added `_split_tzname_delta()` as a shared helper for detecting offset-like timezone strings. This keeps the backend-specific sign handling centralized and prevents the old substring search from matching signs inside IANA timezone names.

`repo/django/db/backends/postgresql/operations.py`

Updated `_prepare_tzname_delta()` to invert signs only when `_split_tzname_delta()` identifies a fixed-offset string. PostgreSQL still receives the previous reversed sign for fixed offsets, but `Etc/GMT-10` remains `Etc/GMT-10`.

`repo/django/db/backends/mysql/operations.py`

Updated `_prepare_tzname_delta()` to strip only an offset-like `UTC` prefix. Named timezones containing signs are no longer truncated before being passed to `CONVERT_TZ()`.

`repo/django/db/backends/oracle/operations.py`

Applied the same offset-only detection used by MySQL. Oracle still receives bare offset values for fixed offsets, while signed IANA timezone names remain intact.

`repo/django/db/backends/sqlite3/base.py`

Replaced the broad sign search in `_sqlite_datetime_parse()` with an anchored regex for fixed-offset strings. SQLite still handles `UTC+HH:MM`, `+HHMM`, and related fixed offsets, but it no longer tries to split `Etc/GMT-10` as an offset.

## Assumptions and alternatives

I assumed the correct behavior for `Etc/GMT-10` and similar values is to preserve the timezone database name rather than convert it to a numeric offset. This matches how the existing backend code already treats other named zones such as `Australia/Melbourne`.

I considered changing `timezone._get_timezone_name()` to return a numeric offset for `Etc/GMT-10`, matching older behavior for pytz in Django 3.1. I rejected that because it would be a broader change outside the database function path and would not naturally cover zoneinfo names without potentially changing timezone display behavior elsewhere.

I also considered adding backend-specific special cases for `Etc/GMT` names. I rejected that because the broader bug is the sign-detection heuristic: any valid timezone name containing `+` or `-` could be misclassified. Detecting actual fixed-offset strings is narrower and more general.

Per task instruction, I did not run tests or project code.
