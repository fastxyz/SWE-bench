# Proof Obligations

Status: constructed, not machine-checked.

## PO-001 - Nullable unique fields do not use SQLite BaseAdd

Claim: for any SQLite add-field operation with
`field.null == True`, `effective_default(field) is None`, and
`field.unique == True`, the branch decision is `Remake`.

Reason: this is the exact class that includes the reported nullable
`OneToOneField` migration and the exact class SQLite rejects if delegated to
`ALTER TABLE ADD COLUMN ... UNIQUE`.

K claim: `addField(field(true, false, true)) => Remake`.

Findings: F-001.

## PO-002 - Every unique field is excluded from BaseAdd

Claim: for any field with `field.unique == True`, the branch decision is
`Remake`, regardless of nullability or default.

Reason: `BaseDatabaseSchemaEditor._iter_column_sql()` emits inline `UNIQUE`
whenever `field.unique` is true. The SQLite backend must not expose that SQL
shape to `ADD COLUMN`.

K claim: `addField(field(NULL, HASDEFAULT, true)) => Remake`.

Findings: F-001.

## PO-003 - OneToOneField reduces to the unique-field obligation

Claim: nullable `OneToOneField` is covered by PO-001 and PO-002 because
`OneToOneField.__init__()` sets `unique=True`.

Reason: the issue's field type is a public spelling of a unique foreign key.
Special-casing `OneToOneField` would underfit the root cause.

Findings: F-002.

## PO-004 - Existing remake cases remain remake cases

Claim: if `field.null == False` or `effective_default(field) is not None`, the
branch decision is `Remake`.

Reason: these were the pre-existing SQLite conditions for table remake and are
unrelated to the regression.

K claims:

- `addField(field(false, HASDEFAULT, UNIQUE)) => Remake`
- `addField(field(NULL, true, UNIQUE)) => Remake`

Findings: F-003.

## PO-005 - Existing safe BaseAdd case remains available

Claim: if `field.null == True`, `effective_default(field) is None`, and
`field.unique == False`, the branch decision is `BaseAdd`.

Reason: the issue only invalidates `ADD COLUMN` for inline `UNIQUE`; preserving
the safe fast path prevents an unnecessarily broad behavioral change.

K claim: `addField(field(true, false, false)) => BaseAdd`.

Findings: F-003.

## PO-006 - Compatibility frame condition

Claim: V1 changes no public signature, call protocol, return shape, or generic
backend behavior.

Reason: the patch changes only the SQLite backend's internal branch predicate
and comment; it still uses existing `_remake_table()` and `super().add_field()`
paths.

Findings: F-004.

## PO-007 - Honesty gate

Claim: proof artifacts are constructed only.

Reason: the task forbids running tests, Python, or K tooling. Any future test
removal or proof confidence upgrade requires the K commands in `PROOF.md` to
return `#Top` in an execution-capable environment.

Findings: F-005.
