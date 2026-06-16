# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue text and source inspection only.

## F1: Reported signed-name rewrite is a real code bug, fixed by V1 and preserved in V2

- Classification: code bug
- Evidence: `benchmark/PROBLEM.md` reports `Etc/GMT-10` becoming PostgreSQL `Etc/GMT+10`.
- Input: `tzname = "Etc/GMT-10"`
- Observed in pre-fix source: PostgreSQL `_prepare_tzname_delta()` replaced `-` with `+`; MySQL and Oracle sliced from the embedded `-`; SQLite attempted to parse the embedded sign as an offset.
- Expected: `Etc/GMT-10` remains a timezone name because it is not a numeric fixed-offset string.
- Proof obligations: `PO1`, `PO2`, `PO4`, `PO5`
- V2 status: fixed.

## F2: V1 offset classifier was broader than the intent-derived fixed-offset family

- Classification: proof-derived hardening finding
- Evidence: `reports/baseline_notes.md` described the intended condition as "offset-specific rewriting only to strings that look like fixed-offset timezone names"; V1 used prefix checks rather than numeric validation.
- Input: `tzname = "+BAD"` or `tzname = "UTC+BAD"`
- Observed in V1: `_split_tzname_delta()` classified it as an offset because it started with a sign or `UTC+`.
- Expected: only numeric offset forms such as `+10`, `+1000`, `+10:00`, and `UTC+10:00` classify as offsets.
- Proof obligations: `PO1`, `PO6`
- V2 status: fixed by replacing prefix checks with an anchored numeric regex in `BaseDatabaseOperations`.

## F3: Fixed-offset behavior must remain backend-specific

- Classification: preservation obligation
- Evidence: the issue describes prior PostgreSQL `+10` -> `-10` behavior as correct, and existing backend code already special-cases fixed offsets.
- Input: `tzname = "+10"` or `tzname = "UTC+05:00"`
- Expected: PostgreSQL reverses the numeric sign; MySQL and Oracle strip only the optional `UTC` prefix; SQLite applies the numeric offset.
- Proof obligations: `PO3`, `PO4`, `PO5`
- V2 status: satisfied by the shared split helper and backend-specific preparation.

## F4: Database timezone-table semantics are outside this proof

- Classification: proof capability gap / residual risk
- Evidence: the defect is in Django string preparation, but actual named timezone conversion depends on backend timezone data.
- Input: `tzname = "Etc/GMT-10"` on a database without timezone data.
- Expected: Django should still pass the correct name; database support remains a runtime/backend feature concern.
- Proof obligations: `PO7`
- V2 status: documented residual risk, no code change justified.

## F5: Test guidance, not test edits

- Classification: test gap
- Evidence: the issue names PostgreSQL and MySQL and the source had the same sign-search pattern in SQLite.
- Recommended tests: generated SQL or backend-operation tests for `Etc/GMT-10`, `Etc/GMT+10`, `+10`, `-10`, `UTC+05:00`, and `+0517` across affected backends.
- V2 status: no test files modified per task instruction.
