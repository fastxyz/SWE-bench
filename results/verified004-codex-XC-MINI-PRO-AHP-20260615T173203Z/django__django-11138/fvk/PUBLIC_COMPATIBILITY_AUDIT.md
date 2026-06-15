# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public or virtual APIs

No public method signature was changed.

The virtual backend operation methods retain their existing signatures:

* `datetime_cast_date_sql(self, field_name, tzname)`
* `datetime_cast_time_sql(self, field_name, tzname)`
* `datetime_extract_sql(self, lookup_type, field_name, tzname)`
* `datetime_trunc_sql(self, lookup_type, field_name, tzname)`

Callers in `django/db/models/functions/datetime.py` continue to pass the same
arguments. PostgreSQL and base backend implementations are untouched.

## Backend override compatibility

MySQL, SQLite, Oracle, and PostgreSQL still implement the same operation method
signatures. V1 changes only the method bodies for MySQL, SQLite, and Oracle.

## SQLite private helper protocol

V1 changes private SQLite UDF arities:

* `django_datetime_cast_date`: 2 -> 3 SQL arguments.
* `django_datetime_cast_time`: 2 -> 3 SQL arguments.
* `django_datetime_extract`: 3 -> 4 SQL arguments.
* `django_datetime_trunc`: 3 -> 4 SQL arguments.

This is an internal producer/consumer protocol. V1 updates both sides:

* SQL producer: `django/db/backends/sqlite3/operations.py`.
* SQLite UDF registration and Python functions:
  `django/db/backends/sqlite3/base.py`.

No public in-repo callsite invokes these private helper functions directly.

## Verdict

No compatibility blocker was found. The private SQLite protocol change is
complete because producer and consumer are updated together.
