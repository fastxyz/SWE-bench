# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## PO1: Reverse restores generated old name

For `RenameIndex(old_fields=FIELDS, new_name=NEW)`, if migration is allowed and
the current database index over `FIELDS` is named `NEW`, then
`database_backwards()` must leave that index named:

`schema_editor._create_index_name(TABLE, COLUMNS, suffix="_idx")`

where `TABLE` and `COLUMNS` come from the target-state model.

Evidence: I1, I3, I4. Finding: F1.

V1 status: discharged by the new `old_fields` branch in
`database_backwards()`.

## PO2: Reapply safety after backwards

For distinct names `NEW != GENERATED`, the sequence:

1. forwards: `GENERATED -> NEW`
2. backwards: `NEW -> GENERATED`
3. forwards: `GENERATED -> NEW`

must not invoke a rename from `NEW` to `NEW` on the third step.

Evidence: I2. Findings: F1, F2.

V1 status: discharged as a consequence of PO1.

## PO3: Migration routing frame condition

If `allow_migrate_model()` is false for the target model, the backwards
operation must leave the database unchanged.

Evidence: I5.

V1 status: discharged by the explicit `allow_migrate_model()` guard in the
`old_fields` branch.

## PO4: Backend abstraction frame condition

The implementation must work through `schema_editor.rename_index()` so
rename-capable backends and drop/recreate backends keep their existing behavior.

Evidence: I6.

V1 status: discharged. V1 constructs `Index` objects for old and new names and
delegates to `schema_editor.rename_index()`.

## PO5: Scope of `old_fields`

The generated name for the reverse target uses the `index_together` suffix
`"_idx"`, not the unique-constraint suffix `"_uniq"`.

Evidence: I4. Finding: F3.

V1 status: discharged. V1 uses `suffix="_idx"`.

## PO6: Do not broaden public operation semantics

The audit must not silently turn `RenameIndex(old_fields=...)` into unique
constraint renaming because the source operation does not update
`unique_together` state and its forward lookup asks for indexes.

Evidence: I4, I8. Finding: F3.

V1 status: discharged by keeping the source change limited to `index_together`
reverse naming.

## PO7: Honesty gate

Because no tests, Python, or K tooling may be executed, proof artifacts must be
reported as constructed, not machine-checked, and tests must not be removed.

Evidence: task constraints. Finding: F4.

V1 status: discharged by artifact labeling and by leaving test files unchanged.
