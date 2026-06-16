# Iteration Guidance

## Decision

V1 stands unchanged.

The FVK audit found that the current predicate:

```python
not field.null or self.effective_default(field) is not None or field.unique
```

is exactly the smallest branch condition needed to satisfy the public intent
and preserve the unrelated fast path.

## Code Guidance

No additional source edits are recommended.

Do not replace the generic `field.unique` predicate with a
`OneToOneField`-specific check. Finding F-002 and PO-003 show that the issue is
caused by the unique constraint, not by the Python field class name.

Do not change `BaseDatabaseSchemaEditor` for this issue. Finding F-001 and
PO-002 localize the unsupported SQL to SQLite's use of the shared base
add-column path; PO-006 keeps the fix backend-local.

Do not force table remake for every nullable field. Finding F-003 and PO-005
preserve the safe nullable, no-default, non-unique path.

## Verification Guidance

In an execution-capable environment, run the K commands recorded in
`fvk/PROOF.md`, then run Django's SQLite schema tests and a focused regression
test for nullable `OneToOneField` addition.

No test files were edited in this workspace.

## Residual Risk

The proof is constructed, not machine-checked. It verifies the branch predicate
and SQL-shape hazard, not the full operational behavior of SQLite table
remaking. That residual is acceptable for this audit because `_remake_table()`
is an existing SQLite backend path already used for non-null/default add-field
cases, and V1 only expands the set of fields routed to it by one documented
SQLite restriction.
