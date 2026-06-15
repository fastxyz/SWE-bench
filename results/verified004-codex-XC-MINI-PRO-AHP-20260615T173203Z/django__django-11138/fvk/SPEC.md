# FVK Spec

Status: constructed for audit, not machine-checked.

## Scope

This FVK run verifies the V1 fix for the datetime SQL conversion path used by
MySQL, SQLite, and Oracle. The observable under audit is the SQL/helper shape
used for datetime cast, extraction, and truncation:

* whether timezone conversion is omitted when `USE_TZ` is false;
* whether timezone conversion is omitted when source and target timezone names
  are equal;
* whether conversion, when needed, uses the database connection timezone as the
  source rather than hardcoded UTC;
* whether SQLite's generated SQL and registered helper functions agree on the
  source/target timezone argument protocol.

The model does not cover all of Django. It covers the changed backend helper
contract because that is the behavior named by the public issue and the V1
patch.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries mirrored
into the formal claims are:

* E2: conversion goes from database timezone `tz2` to Django requested timezone
  `tz1`.
* E3: if `tz1 == tz2`, conversion is a no-op and MySQL must not require
  timezone tables for `CONVERT_TZ(tz, tz)`.
* E5: for MySQL/SQLite/Oracle with `USE_TZ=True`, database `TIME_ZONE` is the
  timezone of naive stored datetimes.
* E6-E9: `__date`, `__time`, `Extract`, `Trunc`, and `datetimes()` all depend on
  converting datetimes to current/explicit timezone before filtering,
  extracting, or truncating.

## Formal Model

Supporting K files:

* `mini-django-datetime-sql.k`
* `django-datetime-sql-spec.k`

The formal model abstracts SQL strings into structured terms:

* `raw("field")`: unconverted field expression;
* `mysqlConvert(F, Source, Target)`: MySQL `CONVERT_TZ(F, Source, Target)`;
* `oracleConvert(F, Source, Target)`: Oracle `FROM_TZ(F, Source) AT TIME ZONE Target`;
* `sqliteDate(UseTz, Wall, Source, Target)`: SQLite helper date extraction from
  stored wall-clock components.

Actual timezone arithmetic is represented by `local(Wall, Source, Target)`, an
uninterpreted function. This is intentional: the bug is the source/target
selection and no-op conversion, not the correctness of pytz or database timezone
tables.

## Preconditions

* Backend is one of MySQL, SQLite, or Oracle.
* Timezone names are valid Django/database timezone names.
* `Source` is `connection.timezone_name`; `Target` is the current or explicit
  Django timezone name.
* For SQLite, stored datetime values are parsed as wall-clock components before
  source-to-target conversion.

## Postconditions

P1. `USE_TZ=False` implies datetime SQL/helper conversion returns the unconverted
field/wall-clock date.

P2. `USE_TZ=True` and `Source == Target` implies datetime SQL/helper conversion
returns the unconverted field/wall-clock date.

P3. `USE_TZ=True` and `Source != Target` implies MySQL conversion is
`mysqlConvert(Field, Source, Target)`.

P4. `USE_TZ=True` and `Source != Target` implies Oracle conversion is
`oracleConvert(Field, Source, Target)`, with the implementation preserving
Oracle's existing `0:00` spelling for UTC source in emitted SQL.

P5. `USE_TZ=True` and `Source != Target` implies SQLite date casting uses
`datePart(local(Wall, Source, Target))`.

P6. SQLite SQL generation and UDF registration must agree on arity and argument
order: datetime cast helpers receive `(value, Source, Target)` and datetime
extract/trunc helpers receive `(lookup_type, value, Source, Target)`.

P7. The same conversion helper contract must be used by cast-to-date,
cast-to-time, extraction, and truncation paths for each affected backend.

P8. Public backend operation method signatures remain unchanged.

## Out Of Scope

* Running tests or K tools.
* Machine-checking actual SQL execution.
* Proving civil-time conversion rules, DST transition behavior, or timezone name
  database contents.
* PostgreSQL timezone behavior.
