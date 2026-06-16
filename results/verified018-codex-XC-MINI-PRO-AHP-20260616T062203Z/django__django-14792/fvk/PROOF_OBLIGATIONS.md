# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Fixed-offset classifier is exact for the intended family

For any `tzname`, `_split_tzname_delta(tzname)` returns `(prefix, sign, offset)` only if `tzname` matches `^(UTC)?[+-]\d{2}(?::?\d{2})?$`; otherwise it returns `(None, None, None)`.

- Evidence: E1, E2, E3
- Formal claims: `SPLIT-NAMED-SIGNED`, `SPLIT-OFFSET-UTC`, `SPLIT-OFFSET-BARE`
- Status: discharged by V2 source shape.

## PO2: Signed IANA timezone names are preserved as names

For any non-offset timezone name, including `Etc/GMT-10`, PostgreSQL, MySQL, and Oracle preparation returns the original string.

- Evidence: E1, E3, E4
- Formal claims: `PG-NAMED-PRESERVE`, `MYSQL-NAMED-PRESERVE`, `ORACLE-NAMED-PRESERVE`
- Status: discharged by V2 source shape.

## PO3: PostgreSQL fixed-offset preparation is preserved

For any fixed-offset string classified by PO1, PostgreSQL returns the same prefix and offset with the sign reversed.

- Evidence: E2
- Formal claim: `PG-OFFSET-REVERSE`
- Status: discharged by V2 source shape.

## PO4: MySQL and Oracle fixed-offset preparation is preserved

For any fixed-offset string classified by PO1, MySQL and Oracle return the sign plus offset, omitting an optional `UTC` prefix.

- Evidence: E2, E3
- Formal claims: `MYSQL-ORACLE-OFFSET-STRIP-UTC`
- Status: discharged by V2 source shape.

## PO5: SQLite only offset-adjusts numeric fixed offsets

For any `tzname` not matching the fixed-offset regex, `_sqlite_datetime_parse()` does not split the string or apply a numeric offset. For matching fixed offsets, it applies the offset and uses `UTC` as the localization timezone.

- Evidence: E5
- Formal claims: `SQLITE-NAMED-NO-OFFSET`, `SQLITE-OFFSET-APPLY`
- Status: discharged by V2 source shape.

## PO6: V1 over-approximation is removed

Inputs like `+BAD` and `UTC+BAD` must not satisfy the fixed-offset classifier.

- Evidence: F2
- Formal claims: covered by PO1
- Status: discharged by V2 regex, not by V1.

## PO7: Compatibility and frame conditions

No public API signatures, model function APIs, or test files are changed. Existing backend gates around `settings.USE_TZ` and connection timezone comparison remain unchanged.

- Evidence: source diff and public compatibility audit
- Formal claim: frame condition in `SPEC.md`
- Status: discharged by source diff inspection.
