# Baseline notes — django__django-11138

## Issue

When `USE_TZ = True` and a per-database `TIME_ZONE` is configured in the
`DATABASES` setting (a common setup for legacy databases that store datetimes in
local time), date/time *lookups and transforms* (`__date`, `__time`, `Extract`,
`Trunc`, etc.) on backends that don't support time zones (MySQL, SQLite, Oracle)
ignored the database's `TIME_ZONE`. They always assumed the stored value was in
**UTC** and converted `UTC -> current timezone`.

Two problems followed (per the report):

1. **Wrong source zone.** The conversion must go from the *database* time zone
   (the value stored in `DATABASES[...]['TIME_ZONE']`, call it `tz2`) to the
   *current/active* Django time zone (`tz1`). It was hard-coded to start from
   UTC.
2. **Unnecessary conversion.** When `tz1 == tz2` no conversion is needed at all.
   On MySQL this matters in practice because `CONVERT_TZ()` silently returns
   `NULL` unless the server's time-zone tables have been loaded
   (`mysql_tzinfo_to_sql`), so a `__date` lookup that should have matched
   returned no rows.

## Root cause

Each non-tz backend converts the column to the target zone before truncating
/extracting, but used a fixed `'UTC'` source:

- `django/db/backends/mysql/operations.py` — `_convert_field_to_tz()` emitted
  `CONVERT_TZ(field, 'UTC', tzname)`.
- `django/db/backends/oracle/operations.py` — `_convert_field_to_tz()` emitted
  `FROM_TZ(field, '0:00') AT TIME ZONE tzname` (i.e. source = UTC offset 0).
- `django/db/backends/sqlite3/` — the conversion happens in Python in the
  `django_datetime_*` SQLite functions. `_sqlite_datetime_parse()` ran
  `typecast_timestamp()` (which tags the naive value as **UTC** when `USE_TZ`)
  and then `timezone.localtime(dt, tzname)`, i.e. it always treated the stored
  value as UTC.

The correct "database time zone" is already available on the connection as
`self.connection.timezone_name` (defined in
`django/db/backends/base/base.py`): it returns `'UTC'` when no per-database
`TIME_ZONE` is set, and the configured value otherwise. PostgreSQL needs no
change — it stores `timestamptz`, `connection.timezone` is `None`, and the
session time zone already accounts for the DB `TIME_ZONE`.

## Changes

### `django/db/backends/mysql/operations.py`
`_convert_field_to_tz()` now converts from `self.connection.timezone_name`
instead of `'UTC'`, and skips `CONVERT_TZ` entirely when the connection zone
already equals the target `tzname`:
```python
if settings.USE_TZ and self.connection.timezone_name != tzname:
    field_name = "CONVERT_TZ(%s, '%s', '%s')" % (
        field_name, self.connection.timezone_name, tzname,
    )
```
This fixes both reported problems for MySQL (correct source zone, and no
`CONVERT_TZ`/time-zone-table dependency when `tz1 == tz2`).

### `django/db/backends/oracle/operations.py`
`_convert_field_to_tz()` now uses `self.connection.timezone_name` as the
`FROM_TZ` source (instead of the literal `'0:00'`) and returns the field
unchanged when it already matches `tzname`. The existing `_tzname_re` validation
of the active `tzname` (Oracle crashes when a tz name is bound as a parameter,
so it is interpolated and must be validated) is preserved.

### `django/db/backends/sqlite3/operations.py`
SQLite does the conversion in Python, so the connection zone has to be passed
down to the registered functions. Renamed `_convert_tzname_to_sql()` to
`_convert_tznames_to_sql()`, which now returns a `(tzname, conn_tzname)` pair
(`('NULL', 'NULL')` when `USE_TZ` is off), and updated
`datetime_cast_date_sql`, `datetime_cast_time_sql`, `datetime_extract_sql`, and
`datetime_trunc_sql` to pass both values as extra SQL arguments.

### `django/db/backends/sqlite3/base.py`
- Bumped the `create_function` arities to match the new signatures:
  `django_datetime_cast_date`/`django_datetime_cast_time` 2 -> 3,
  `django_datetime_extract`/`django_datetime_trunc` 3 -> 4.
- `_sqlite_datetime_parse(dt, tzname=None, conn_tzname=None)` now reinterprets
  the parsed value in the connection zone before converting to the target zone:
  ```python
  if conn_tzname:
      dt = dt.replace(tzinfo=pytz.timezone(conn_tzname))
  if tzname is not None and tzname != conn_tzname:
      dt = timezone.localtime(dt, pytz.timezone(tzname))
  ```
- `_sqlite_datetime_cast_date`, `_sqlite_datetime_cast_time`,
  `_sqlite_datetime_extract`, and `_sqlite_datetime_trunc` accept and forward the
  new `conn_tzname` argument.

`_sqlite_date_trunc` / `_sqlite_time_trunc` are untouched — they operate on
`DateField`/`TimeField` values that carry no time-zone semantics.

## Behavior verification (by reasoning)

- **Default config (no per-DB `TIME_ZONE`):** `timezone_name == 'UTC'`. MySQL/
  Oracle still emit a `UTC -> tzname` conversion (only skipped when the active
  zone is also UTC, which was already a no-op conversion). SQLite re-tags as UTC
  (offset 0, no change) then converts UTC -> tzname. Existing behavior is
  preserved.
- **Legacy config from the report (`tz1 == tz2 == 'Europe/Paris'`):** no
  `CONVERT_TZ`/`FROM_TZ` is emitted; SQLite returns the stored wall-clock
  components directly, so `__date` yields `2017-07-06` and matches — without
  needing MySQL's time-zone tables.
- **`tz1 != tz2`:** conversion now correctly goes `tz2 -> tz1`.

## Assumptions & rejected alternatives

- **`tzname` is the target (active) zone; `connection.timezone_name` is the
  source (DB) zone.** Confirmed via
  `django/db/models/functions/datetime.py`, where `tzname` comes from
  `timezone.get_current_timezone_name()`/the requested `tzinfo`.
- **PostgreSQL intentionally left unchanged.** It supports tz-aware storage;
  `connection.timezone` is `None` and the DB `TIME_ZONE` is applied via the
  session time zone, so `AT TIME ZONE tzname` is already correct. The issue
  explicitly scopes the bug to MySQL/SQLite/Oracle.
- **SQLite `dt.replace(tzinfo=...)` vs. `pytz.localize()`.** `replace()` is used
  because the primary fix (and the common legacy case) is `tz1 == tz2`, where the
  conversion branch is skipped and only the wall-clock components matter, so the
  pytz LMT subtlety does not affect the result; it also keeps the change minimal
  and mirrors the pre-existing `localtime` flow for the default UTC case.
- **No extra validation of `connection.timezone_name` on Oracle.** Unlike the
  active `tzname` (which can derive from `timezone.activate(...)` and is already
  regex-validated), `timezone_name` comes from trusted `settings.DATABASES`
  configuration, consistent with how the previous literal source was treated.
- **No documentation change.** `docs/topics/i18n/timezones.txt` already documents
  the per-database `TIME_ZONE` option for local-time databases; this change makes
  the documented behavior actually hold for date lookups, so no doc edit is
  required.
