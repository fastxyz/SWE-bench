# FINDINGS

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation construction only.

## F-001: Original defect - conflict SQL used field names instead of columns

- Input: a model field declared as `blacklistid = IntegerField(primary_key=True, db_column="BlacklistID")`, with `bulk_create(..., update_conflicts=True, update_fields=["sectorid"], unique_fields=["blacklistid"])`.
- Observed in V0: insert SQL used `"BlacklistID"`, but `ON CONFLICT` used `"blacklistid"` and update assignments used `"sectorid"`.
- Expected: conflict target and update assignments use `"BlacklistID"` and `"SectorID"`.
- Classification: code bug.
- Proof obligations: O1, O2, O3.
- V2 status: resolved by resolving option names to `Field` objects on the upsert path and passing `Field.column` strings to backend SQL generation.

## F-002: V1 widened name resolution outside the upsert path

- Input: a non-upsert `bulk_create()` call with truthy `update_fields` or `unique_fields` values.
- Observed in V1 by source audit: `bulk_create()` resolved those names after object preparation even when `on_conflict` was not `OnConflict.UPDATE`.
- Expected: the issue and docs require column conversion for `update_conflicts=True`; non-upsert calls should not get new name resolution or validation from this fix.
- Classification: public-compatibility risk.
- Proof obligation: O4.
- V2 status: resolved by gating the extra resolution with `on_conflict == OnConflict.UPDATE`.

## F-003: V1 changed the backend hook argument shape to generators

- Input: the call from `SQLInsertCompiler` to `connection.ops.on_conflict_suffix_sql()`.
- Observed in V1 by source audit: the compiler passed generator expressions for `update_fields` and `unique_fields`.
- Expected: backend hooks should receive materialized iterable identifier strings, preserving the previous list-like producer/consumer shape while changing only the values from field names to columns on the update-conflict path.
- Classification: public-compatibility risk for backend overrides.
- Proof obligation: O5.
- V2 status: resolved by materializing column lists before calling the hook when `on_conflict == OnConflict.UPDATE`.

## F-004: No unresolved source bug found in the audited path

- Input class: `bulk_create()` calls that pass valid concrete model field names in `update_fields` and valid concrete model field names or `"pk"` in `unique_fields`, with `update_conflicts=True`.
- Observed in V2 by source audit: names are validated, resolved to `Field` objects, converted to `Field.column`, and then quoted by backend SQL generation.
- Expected: SQL conflict identifiers use database column names.
- Classification: confirmed against constructed proof obligations.
- Proof obligations: O1-O5.
- V2 status: no further code change justified by the FVK audit.

## F-005: Verification and tests were not executed

- Input: the emitted K commands and Django test suite.
- Observed: this session forbids running tests, Python, or K tooling.
- Expected: commands are recorded in `PROOF.md`; tests remain untouched.
- Classification: proof honesty boundary and test gap.
- Proof obligations: all obligations remain constructed, not machine-checked.
- V2 status: unresolved only in the machine-checking sense; no source edit follows from this constraint.
