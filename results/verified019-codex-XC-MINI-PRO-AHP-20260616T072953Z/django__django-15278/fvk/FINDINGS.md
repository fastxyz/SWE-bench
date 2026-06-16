# FVK Findings

Status: no unresolved source-code findings requiring changes beyond V1.

## F-001 - Resolved SQLite UNIQUE add-column crash

Input: SQLite `DatabaseSchemaEditor.add_field()` with a concrete field where
`field.null is True`, `effective_default(field) is None`, and
`field.unique is True`.

Observed before V1: the branch delegated to the base schema editor, whose column
SQL includes inline `UNIQUE`; SQLite rejects the resulting
`ALTER TABLE ... ADD COLUMN ... UNIQUE ...` statement with
`OperationalError: Cannot add a UNIQUE column`.

Expected: route to `_remake_table(model, create_field=field)` so the unique
constraint is created as part of the rebuilt table instead of via SQLite
`ADD COLUMN`.

Status: resolved by V1. See PO-001 and PO-002.

## F-002 - OneToOneField is correctly covered by the generic unique predicate

Input: `models.OneToOneField(blank=True, null=True, on_delete=SET_NULL, ...)`.

Observed in source: `OneToOneField.__init__()` forces `unique=True`; the base
column SQL generator emits inline `UNIQUE` for `field.unique`.

Expected: the fix should not special-case `OneToOneField`; it should handle any
unique field that would otherwise produce the same unsupported SQLite SQL.

Status: confirmed by V1. See PO-003.

## F-003 - Existing non-unique fast path is preserved

Input: SQLite `add_field()` with `field.null is True`,
`effective_default(field) is None`, and `field.unique is False`.

Observed in V1: the field still delegates to `super().add_field()`.

Expected: keep the supported base add-column path for this case; the issue does
not justify remaking every table for every nullable field.

Status: confirmed by V1. See PO-005.

## F-004 - Public compatibility has no unresolved issue

Input: public callers and subclasses of the SQLite schema editor.

Observed in V1: no method signature, return value, public class, or generic base
schema behavior changed.

Expected: a backend-specific branch predicate change only.

Status: confirmed by V1. See PO-006.

## F-005 - Proof is constructed, not machine-checked

Input: FVK proof artifacts in this workspace.

Observed: no K toolchain was run, by task instruction.

Expected: keep all proof claims and test-removal recommendations conditional on
future `kompile`/`kprove` execution in a real environment.

Status: residual verification caveat, not a source-code bug. See PO-007.
