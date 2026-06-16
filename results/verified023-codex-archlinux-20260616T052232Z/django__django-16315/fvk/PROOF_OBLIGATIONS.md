# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## O1: Upsert option names resolve to fields

For `on_conflict == OnConflict.UPDATE`, `bulk_create()` must transform every
name in `update_fields` and every normalized name in `unique_fields` into the
corresponding `Field` object via `opts.get_field(name)`.

Evidence: I1, I3, I5. Finding: F-001.

Discharge in V2: `repo/django/db/models/query.py` gates both conversions on
`on_conflict == OnConflict.UPDATE` and uses `opts.get_field(name)`.

## O2: Compiler extracts database columns from resolved fields

For `on_conflict == OnConflict.UPDATE`, `SQLInsertCompiler` must transform the
stored `Field` objects into their `column` values before calling backend conflict
SQL generation.

Evidence: I2, I3, I4, I5. Finding: F-001.

Discharge in V2: `repo/django/db/models/sql/compiler.py` computes
`[f.column for f in self.query.update_fields]` and
`[f.column for f in self.query.unique_fields]`.

## O3: Backend conflict SQL receives and quotes column identifiers

For built-in PostgreSQL, SQLite, and MySQL/MariaDB conflict-update SQL paths,
backend `on_conflict_suffix_sql()` must receive identifier strings that are
database column names and quote them with the backend's `quote_name()`.

Evidence: I2, I3, I7. Finding: F-001.

Discharge in V2: the compiler supplies column strings; existing backend methods
already quote the iterable values and interpolate them into conflict/update SQL.

## O4: Non-upsert calls preserve ignored conflict-option behavior

For `on_conflict != OnConflict.UPDATE`, this fix must not introduce new
resolution or validation of otherwise unused `update_fields` or `unique_fields`
values.

Evidence: I6. Finding: F-002.

Discharge in V2: the new name-to-field conversion in `bulk_create()` is guarded
by `on_conflict == OnConflict.UPDATE`; the compiler forwards existing values
unchanged on non-update-conflict paths.

## O5: Backend hook producer/consumer shape remains list-like

For the update-conflict path, the compiler must pass backend hooks materialized
iterables of identifier strings, not `Field` objects and not one-shot generator
objects.

Evidence: I7. Finding: F-003.

Discharge in V2: the compiler builds materialized Python lists of column names.

## O6: Primary key alias frame condition

When `unique_fields` contains `"pk"`, `bulk_create()` must preserve the existing
normalization to `opts.pk.name` before field resolution, so the compiler later
uses the primary key field's database column.

Evidence: existing source behavior in `bulk_create()` and public tests around
`unique_fields=["pk"]` in `tests/bulk_create/tests.py`.

Discharge in V2: the existing normalization block remains before
`_check_bulk_create_options()` and before the new guarded field resolution.
