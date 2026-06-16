# SPEC

Status: constructed, not machine-checked.

## Target

The audited production target is `RenameModel.database_forwards()` in `repo/django/db/migrations/operations/models.py`.

The observable being specified is database schema-editor side effects. Migration-state mutation by `state_forwards()` is a frame condition: it must still happen, but it is outside the database-forward side-effect proof.

## Public Intent Ledger

S1. Same-table `RenameModel` no-op.

- Source: `benchmark/PROBLEM.md`
- Evidence: "RenameModel with db_table should be a noop."
- Obligation: If the old and new models identify the same database table, `database_forwards()` must add zero schema-editor operations.
- Status: encoded in `RENAME-MODEL-NOOP-SAME-TABLE`.

S2. Same-table predicate.

- Source: `repo/django/db/backends/base/schema.py`, lines 468-473
- Evidence: table rename already no-ops for exact equality and backend case-insensitive equality.
- Obligation: Reuse this equivalence before relation/M2M schema work.
- Status: encoded as the abstract input `SameTable`.

S3. State rename preservation.

- Source: `repo/django/db/migrations/operations/models.py`, lines 316-317; `repo/django/db/migrations/state.py`, lines 133-168
- Evidence: `state_forwards()` delegates to `state.rename_model()`.
- Obligation: V1 must not change `state_forwards()` or state reference repointing.
- Status: checked by source audit; no source edit beyond `database_forwards()`.

S4. Different-table compatibility.

- Source: public in-repo tests at `repo/tests/migrations/test_operations.py`, lines 600-633 and 768-794
- Evidence: actual table renames repoint incoming FKs/M2Ms and leave M2M usage working.
- Obligation: If table names differ, V1 must preserve the existing database branch.
- Status: encoded in `RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`.

S5. API compatibility.

- Source: Django migration operation API shape and call sites in `repo/django/db/migrations/migration.py`, lines 122-125
- Evidence: operations are invoked through `operation.database_forwards(self.app_label, schema_editor, old_state, project_state)`.
- Obligation: no public signature or call protocol change.
- Status: checked in `PUBLIC_COMPATIBILITY_AUDIT.md`.

## Formal Model

The K model abstracts one execution of `database_forwards()` as:

`renameModelForwards(AllowMigrate, SameTable, RelatedCount, M2MCount)`

Inputs:

- `AllowMigrate`: the result of `allow_migrate_model()`.
- `SameTable`: `old_db_table == new_db_table or (ignores_table_name_case and lower(old_db_table) == lower(new_db_table))`.
- `RelatedCount`: number of relation `alter_field()` calls reachable in the non-no-op branch.
- `M2MCount`: number of applicable auto-created M2M entries reachable in the non-no-op branch. Each contributes two schema-editor operations in the existing code: table rename and field alteration.

Observable:

- `<dbops>`: integer count of database schema-editor operations emitted by `database_forwards()`.

Claims:

- `RENAME-MODEL-NOOP-SAME-TABLE`: with `AllowMigrate = true` and `SameTable = true`, `<dbops>` is unchanged for all non-negative `RelatedCount` and `M2MCount`.
- `RENAME-MODEL-NOOP-DISALLOWED`: with `AllowMigrate = false`, `<dbops>` is unchanged.
- `RELATED-COUNT` and `M2M-COUNT`: helper circularities for the finite non-no-op relation/M2M loops.
- `RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`: with `AllowMigrate = true` and `SameTable = false`, `<dbops>` increases by `1 + RelatedCount + 2 * M2MCount`, matching the pre-existing database branch shape.

## Scope and Limits

This proof is partial correctness over the specified side-effect count. It does not machine-check K, run Django tests, prove full Django object semantics, or prove runtime M2M usability after a same-table model rename. The latter is intentionally not used to override the issue's explicit database no-op requirement; see `FINDINGS.md` F-002.
