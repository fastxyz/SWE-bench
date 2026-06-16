# Public Evidence Ledger

Status: public evidence only. Hidden tests, evaluator results, internet access, and upstream fixes were not used.

## E1: Issue No-Op Requirement

- Source: `benchmark/PROBLEM.md`
- Evidence: "RenameModel with db_table should be a noop."
- Obligation: If `RenameModel` keeps the same database table because `db_table` is fixed, `database_forwards()` must emit no database schema operations.
- Encoded in: `SPEC.md` S1, `rename-model-spec.k` claim `RENAME-MODEL-NOOP-SAME-TABLE`.

## E2: Concrete Side-Effect Symptoms

- Source: `benchmark/PROBLEM.md`
- Evidence: "In Postgres, it drops and recreates foreign key constraints. In sqlite it recreates the table."
- Obligation: The no-op must prevent relation/M2M schema-editor calls, not only the direct table rename.
- Encoded in: `FINDINGS.md` F-001, `PROOF_OBLIGATIONS.md` PO-1.

## E3: Existing Table-Equivalence Convention

- Source: `repo/django/db/backends/base/schema.py`, lines 468-473
- Evidence: `alter_db_table()` returns when old and new table names are equal, or case-insensitively equal on backends with `ignores_table_name_case`.
- Obligation: The `RenameModel` no-op guard should use the same table-equivalence predicate as table renaming.
- Encoded in: `SPEC.md` S2, `PROOF_OBLIGATIONS.md` PO-1.

## E4: Root-Cause Implementation Shape

- Source: `repo/django/db/migrations/operations/models.py`, lines 319-375
- Evidence: `database_forwards()` gets old and new models, then performs table, related-field, and M2M schema-editor calls. In V1, lines 323-332 return before those calls when the table identity is unchanged.
- Obligation: The proof must show the early return dominates all database-mutating loops on the same-table branch.
- Encoded in: `PROOF.md` proof of PO-1.

## E5: State Rename Remains Required

- Source: `repo/django/db/migrations/state.py`, lines 133-168
- Evidence: `rename_model()` changes model state and repoints state-level references.
- Obligation: The fix must not move or suppress `state_forwards()`.
- Encoded in: `SPEC.md` S3, `PROOF_OBLIGATIONS.md` PO-4.

## E6: Non-No-Op Branch Compatibility

- Source: `repo/tests/migrations/test_operations.py`, lines 600-633 and 768-794
- Evidence: public tests describe and exercise actual table renames, FK repointing, and M2M usability after a model rename.
- Obligation: If table names differ, preserve existing database behavior.
- Encoded in: `rename-model-spec.k` claim `RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`, `PROOF_OBLIGATIONS.md` PO-3.

## E7: Autodetector Same-db_table Shape

- Source: `repo/tests/migrations/test_autodetector.py`, lines 1332-1345
- Evidence: when model name changes but `db_table` stays as-is, the autodetector creates only `RenameModel`, not `AlterModelTable`.
- Obligation: `RenameModel` must handle this case without additional database table work.
- Encoded in: `SPEC.md` S1 and `FINDINGS.md` F-001.
