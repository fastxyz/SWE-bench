# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Source timezone selection

For MySQL, SQLite, and Oracle with `USE_TZ=True`, the source timezone for
datetime SQL/helper conversion must be `connection.timezone_name`. This follows
from ledger E2 and E5.

Discharged by V1:

* MySQL reads `self.connection.timezone_name`.
* Oracle reads `self.connection.timezone_name`.
* SQLite SQL generation passes `self.connection.timezone_name` into datetime
  helper calls.

## PO2: No-op conversion when source equals target

If source timezone equals target timezone, conversion must leave the field/wall
clock unchanged. This follows from ledger E3.

Discharged by V1:

* MySQL skips `CONVERT_TZ()` when names match.
* Oracle returns the field unchanged when names match.
* SQLite parser skips source-to-target conversion when names match.

## PO3: MySQL non-no-op conversion shape

If `USE_TZ=True` and source and target differ, MySQL must emit
`CONVERT_TZ(field, source, target)`, with `source == connection.timezone_name`.

Discharged by V1 in `django/db/backends/mysql/operations.py`.

## PO4: Oracle non-no-op conversion shape

If `USE_TZ=True` and source and target differ, Oracle must wrap the field as a
timestamp in the source timezone and convert it to the target timezone.

Discharged by V1 in `django/db/backends/oracle/operations.py`. The existing UTC
source spelling `0:00` is preserved for the default UTC source.

## PO5: SQLite producer/consumer arity

SQLite SQL generation and `create_function()` registration must agree on helper
argument counts and order.

Discharged by V1:

* cast date/time: SQL passes `(value, source, target)` and registration arity is
  3;
* extract/trunc: SQL passes `(lookup_type, value, source, target)` and
  registration arity is 4.

## PO6: SQLite source interpretation

SQLite stored naive datetime values must be interpreted as wall-clock values in
the connection timezone before conversion to the target timezone.

Discharged by V1 in `_sqlite_datetime_parse()` by stripping the UTC tzinfo that
`typecast_timestamp()` attaches and making the wall time aware in
`conn_tzname` before `timezone.localtime(..., tzname)`.

## PO7: Family coverage

The fix must cover the family of datetime cast, extraction, and truncation paths,
not only the single `__date` example, because public docs establish conversion
before filtering/extracting/truncating for all of them.

Discharged by V1 because all affected backend `datetime_cast_date_sql()`,
`datetime_cast_time_sql()`, `datetime_extract_sql()`, and
`datetime_trunc_sql()` paths call the corrected conversion helper or pass the
same source/target pair.

## PO8: Public compatibility

The fix must not break public operation call signatures or backend override
dispatch.

Discharged by V1 because `datetime_*_sql()` signatures are unchanged. The only
arity change is a private SQLite UDF protocol whose producer and consumer were
updated together.

## PO9: Proof capability boundary

The proof must not pretend to verify civil-time arithmetic, database timezone
tables, or SQL execution. Those are external semantics.

Discharged by this FVK run by modeling timezone conversion as `local(Wall,
Source, Target)` and recording the boundary in `FINDINGS.md`.
