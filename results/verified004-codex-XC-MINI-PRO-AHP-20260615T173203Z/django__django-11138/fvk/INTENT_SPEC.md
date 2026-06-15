# Intent Spec

Scope: Django datetime SQL generation for MySQL, SQLite, and Oracle backends
that do not support timezone-aware datetime storage. This intent spec is
derived from the public issue, Django settings docs, query lookup docs, and
public in-repo docs/tests. The current V1 implementation is treated as a
candidate to check, not as the source of truth.

## Required behavior

1. When `USE_TZ` is true and a backend does not support timezone-aware
   datetimes, the database connection timezone is the timezone of naive
   datetimes stored in that database. If `DATABASES[alias]['TIME_ZONE']` is set,
   it supplies that source timezone; otherwise the source timezone is UTC.

2. Date/time extraction, truncation, and cast-to-date/time operations on
   `DateTimeField` values must convert from the stored database timezone to the
   requested Django timezone before extracting or truncating.

3. For `__date`, `__time`, and default `Extract`/`Trunc` calls, the requested
   timezone is the current Django timezone when `USE_TZ` is true.

4. For APIs that accept an explicit `tzinfo`, that timezone is the requested
   timezone for extraction/truncation.

5. If source timezone and requested timezone are equal, timezone conversion is a
   no-op and backend SQL/helper logic must not require database timezone tables
   merely to convert a value to the same timezone.

6. When `USE_TZ` is false, datetime SQL generation must not add timezone
   conversion.

7. PostgreSQL is outside this repair scope because it supports timezone-aware
   datetime storage and Django rejects per-database `TIME_ZONE` for such
   backends.

## Boundary conditions

* Valid timezone names are assumed as Django settings/API inputs. Backend- or
  pytz-specific validation remains delegated to existing Django and database
  behavior.
* Actual civil-time arithmetic, DST ambiguity handling, and SQL execution are
  external semantics. The FVK model proves that Django passes the correct source
  and target timezone names and skips no-op conversion; it does not machine-check
  pytz, MySQL, Oracle, or SQLite execution.
* No test files may be changed in this task.
