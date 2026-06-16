# Public Evidence Ledger

## E1: Reported PostgreSQL regression

- Source: `benchmark/PROBLEM.md`
- Evidence: `TimezoneMixin method get_tzname() returns "Etc/GMT-10"` and PostgreSQL incorrectly produces `AT TIME ZONE 'Etc/GMT+10'`.
- Obligation: `Etc/GMT-10` must not be classified as a numeric offset by backend preparation.
- Status: encoded in `SPEC.md`, `tzname-spec.k` claims `PG-NAMED-PRESERVE` and `SPLIT-NAMED-SIGNED`.

## E2: Prior numeric-offset behavior

- Source: `benchmark/PROBLEM.md`
- Evidence: older behavior returned `+10`, which PostgreSQL prepared as `-10`, described as the time zone 10 hours east from UTC.
- Obligation: numeric fixed offsets still need backend-specific preparation; PostgreSQL sign reversal for offset literals is preserved.
- Status: encoded in proof obligations `PO3` and K claim `PG-OFFSET-REVERSE`.

## E3: MySQL hint

- Source: `benchmark/PROBLEM.md`
- Evidence: "This problem is also affecting MySQL, the timezone `Etc/GMT-10` is returning `-10` instead of `-10:00`."
- Obligation: MySQL must not blindly take the suffix beginning at the sign inside `Etc/GMT-10`; offset parsing must be distinguished from timezone names.
- Status: encoded in proof obligations `PO4` and K claim `MYSQL-NAMED-PRESERVE`.

## E4: Existing named-zone path

- Source: source code under `repo/django/db/backends/*/operations.py`
- Evidence: named zones without signs, e.g. `Australia/Melbourne`, are already passed through to backend timezone conversion functions.
- Obligation: signed IANA names should follow the same named-zone path unless they are actual fixed-offset strings.
- Status: encoded as a frame condition in `SPEC.md` and compatibility audit.

## E5: SQLite same-root parser heuristic

- Source: `repo/django/db/backends/sqlite3/base.py`
- Evidence: `_sqlite_datetime_parse()` used to search for any `+` or `-` in `tzname`.
- Obligation: SQLite must only perform numeric-offset adjustment for offset-like strings and must leave `Etc/GMT-10` for timezone-name localization.
- Status: encoded in proof obligation `PO5` and K claim `SQLITE-NAMED-NO-OFFSET`.
