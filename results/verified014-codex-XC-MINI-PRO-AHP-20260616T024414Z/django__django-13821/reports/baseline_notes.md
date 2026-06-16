# Baseline Notes

## Root Cause

The SQLite backend still enforced the previous minimum supported SQLite version,
3.8.3, in `django/db/backends/sqlite3/base.py`. That allowed Django to import
and run against SQLite 3.8.x releases even though the issue calls for dropping
support for all SQLite versions older than 3.9.0. A nearby SQLite introspection
comment also described compatibility with pre-3.8.9 `PRAGMA index_list()` output,
which is no longer a supported runtime case once the minimum is 3.9.0.

## Changed Files

`repo/django/db/backends/sqlite3/base.py`

Updated `check_sqlite_version()` to reject `Database.sqlite_version_info` values
older than `(3, 9, 0)` and changed the `ImproperlyConfigured` message to say
that SQLite 3.9.0 or later is required.

`repo/django/db/backends/sqlite3/introspection.py`

Updated the `PRAGMA index_list()` comment so it no longer documents behavior for
now-unsupported SQLite versions. The code continues to read the first three
fields from the pragma result, which keeps the existing behavior while avoiding
unneeded assumptions about extra pragma columns.

## Assumptions and Alternatives Considered

I treated the required behavioral change as the backend support floor, not a new
feature implementation. This checkout's generic `Index` API does not expose
expression indexes, so there was no SQLite expression-index feature flag to
enable in this branch.

I left the JSON1 runtime feature probe intact. SQLite 3.9.0 introduced JSON1,
but the extension can still depend on how SQLite was compiled, so Django still
needs to check whether JSON functions are actually available.

I did not modify tests or run the test suite, per the task constraints. I also
kept documentation updates out of the patch because the requested fix was for
non-test source code under `repo/`.
