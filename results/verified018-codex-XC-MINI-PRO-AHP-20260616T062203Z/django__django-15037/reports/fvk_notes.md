## FVK Notes

The FVK audit confirmed V1 unchanged. I made no additional production-code edits
because every concrete finding that would require code change is already
resolved by the V1 patch.

F1 in `fvk/FINDINGS.md` is the original issue: `inspectdb` dropped a
non-primary-key target column. It is discharged by O1 in
`fvk/PROOF_OBLIGATIONS.md`: when `rel_column != target_pk`, V1 adds
`extra_params['to_field']` and the field-description assembly emits it.

F2 is the main correctness risk in a simpler patch: `to_field` must be a target
model field name, not necessarily a database column. It is discharged by O3:
`normalize_table_columns()` runs the same `normalize_col_name()` sequence as the
normal model-generation loop, so the target field name used for `to_field`
matches the generated target model.

F3 guards against over-fixing. A relation to a target primary key should still
omit `to_field`, even when the primary-key column is not named `id`. It is
discharged by O2 because V1 compares the relation target with
`get_primary_key_column(rel_table)`.

F4 covers compatibility and unrelated output. It is discharged by O4 and O5:
V1 changes only the non-PK target branch's `extra_params` and does not alter
public command arguments, backend introspection APIs, relation type selection,
model quoting, `models.DO_NOTHING`, or test files.

F5 is accepted residual risk from the benchmark constraints. I did not run
tests, Python, or K tooling. The proof artifacts are therefore constructed, not
machine-checked, and no test-removal recommendation is made.
