# Baseline Notes

## Root cause

For backends that don't store timezone-aware datetimes, Django already adapts
read and written `DateTimeField` values through `connection.timezone`. The SQL
used by datetime date/time extraction and truncation didn't follow that same
rule. MySQL and Oracle always treated stored values as UTC before converting to
the active timezone, and SQLite's custom datetime SQL functions parsed stored
values as UTC. That ignored `DATABASES[alias]['TIME_ZONE']` for `__date` and
related datetime transforms.

## Changed files

* `django/db/backends/mysql/operations.py`: changed datetime SQL conversion to
  convert from `self.connection.timezone_name` to the requested/current
  timezone, and to skip `CONVERT_TZ()` when source and target timezone names
  are the same.
* `django/db/backends/oracle/operations.py`: changed datetime SQL conversion to
  use the connection timezone as the `FROM_TZ()` source, validate both source
  and target timezone names, and skip conversion when both names match.
* `django/db/backends/sqlite3/operations.py`: changed generated SQLite
  datetime function calls to pass both the connection timezone and the requested
  timezone.
* `django/db/backends/sqlite3/base.py`: updated the registered SQLite datetime
  function arities and parsing logic so stored naive values are interpreted in
  the connection timezone before any conversion to the requested timezone.

## Assumptions and alternatives

I assumed the database-level `TIME_ZONE` option is the source timezone for
naive stored datetimes on MySQL, SQLite, and Oracle, matching the existing
adapt/read paths and the settings documentation.

I did not change PostgreSQL because it supports timezone-aware storage and
Django rejects a per-database `TIME_ZONE` setting for such backends.

I applied the fix to all datetime cast, extract, and truncation SQL paths
rather than only the `__date` lookup because they all shared the same incorrect
source-timezone assumption. A narrower `datetime_cast_date_sql()`-only change
would leave the same bug in `Extract`, `Trunc`, and `__time`.

No tests were run, per the task instruction not to execute tests or code in
this workspace.
