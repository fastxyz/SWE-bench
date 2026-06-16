# FVK Notes

## Decisions

1. V1 stands unchanged. F-001 identifies the root bug as a unique field reaching
   SQLite's base add-column path, and PO-001/PO-002 require all unique fields to
   route to `_remake_table()`. V1 does exactly that by adding `field.unique` to
   the existing remake predicate.

2. I did not add a `OneToOneField` special case. F-002 and PO-003 show that
   `OneToOneField` is covered because it forces `unique=True`; the root cause is
   the generated inline `UNIQUE`, not the field class name.

3. I did not modify `BaseDatabaseSchemaEditor` or add a separate
   add-column-then-create-index path. F-001 localizes the failure to SQLite's
   inability to add a unique column, and PO-006 keeps the fix backend-local with
   no public API or generic backend behavior change.

4. I did not broaden the fix to remake all nullable fields. F-003 and PO-005
   preserve the existing safe path for nullable, non-unique fields with no
   effective default.

5. I did not run tests, Python, or K tooling. F-005 and PO-007 record the
   honesty gate: the proof and commands are constructed only, and no test
   removal is recommended.

## Artifacts

The requested FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional formal-core files were written for the constructed proof:

- `fvk/mini-django-schema.k`
- `fvk/sqlite-add-field-spec.k`
