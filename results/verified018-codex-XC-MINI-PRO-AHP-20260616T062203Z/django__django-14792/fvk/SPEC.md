# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were executed.

## Scope

The audited observable is the timezone name passed from `TimezoneMixin.get_tzname()` into backend datetime conversion SQL or SQLite's equivalent Python-side datetime conversion. The formalized units are:

- `BaseDatabaseOperations._split_tzname_delta()`
- PostgreSQL `_prepare_tzname_delta()`
- MySQL `_prepare_tzname_delta()`
- Oracle `_prepare_tzname_delta()`
- SQLite `_sqlite_datetime_parse()` only for its timezone-name classification and fixed-offset adjustment branch

## Contract

1. `split(tzname)` returns a delta only when `tzname` is a fixed-offset string matching `^(UTC)?[+-]\d{2}(?::?\d{2})?$`. The returned components are `(prefix, sign, offset)`, where `prefix` is either `""` or `"UTC"`.

2. For any timezone name that does not match that fixed-offset family, including `Etc/GMT-10` and `Etc/GMT+10`, `split(tzname)` returns no delta.

3. PostgreSQL preparation:
   - If `split(tzname)` returns no delta, return `tzname` unchanged.
   - If it returns `(prefix, +, offset)`, return `prefix + "-" + offset`.
   - If it returns `(prefix, -, offset)`, return `prefix + "+" + offset`.

4. MySQL and Oracle preparation:
   - If `split(tzname)` returns no delta, return `tzname` unchanged.
   - If it returns `(_, sign, offset)`, return `sign + offset`.

5. SQLite parsing:
   - If `tzname` matches a fixed-offset string, apply the signed offset and then localize as `UTC`.
   - If `tzname` does not match, do not split or offset-adjust it; pass it to timezone-name localization unchanged.

## Public intent ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | `Etc/GMT-10` became `Etc/GMT+10` in PostgreSQL SQL. | Signed IANA names must not be rewritten as numeric offsets. | Encoded in claims and code. |
| E2 | `benchmark/PROBLEM.md` | Numeric `+10` became PostgreSQL `-10` in prior correct behavior. | Preserve numeric-offset sign reversal for PostgreSQL. | Encoded in claims and code. |
| E3 | `benchmark/PROBLEM.md` | MySQL saw `Etc/GMT-10` as `-10`. | Do not truncate signed names at their sign. | Encoded in claims and code. |
| E4 | Existing backend conversion code | Other named zones are passed through as names. | Signed names should follow the named-zone path. | Frame condition. |
| E5 | SQLite parser source | SQLite had the same broad sign search. | Apply the same name-vs-offset distinction in SQLite. | Encoded in claims and code. |

## Adequacy note

The formal model abstracts actual database execution. This is adequate for the reported defect because the defect occurs before database execution: Django constructs the wrong timezone string. The model preserves the discriminating axis, namely whether a signed string is treated as a timezone name or a numeric offset.
