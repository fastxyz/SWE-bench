# FVK Specification - django__django-15278

Status: constructed from public issue text and source inspection; not
machine-checked.

## Scope

Target function: `DatabaseSchemaEditor.add_field()` in
`repo/django/db/backends/sqlite3/schema.py`.

Verified observable: the SQLite branch decision between:

- `Remake`: call `_remake_table(model, create_field=field)`.
- `BaseAdd`: delegate to `BaseDatabaseSchemaEditor.add_field()`, which emits
  `ALTER TABLE ... ADD COLUMN ...`.

The model abstracts a field by three booleans relevant to that branch:
`null`, `has_effective_default`, and `unique`.

## Intent Specification

1. Adding a nullable `OneToOneField` on SQLite must not crash with
   `OperationalError: Cannot add a UNIQUE column`.
2. Because `OneToOneField` is implemented as a unique foreign key, the behavior
   applies to any concrete nullable `unique=True` field with no effective
   default.
3. Existing SQLite behavior for non-null fields and fields with effective
   defaults must be preserved: both use `_remake_table()`.
4. Existing SQLite behavior for nullable, non-unique fields with no effective
   default must be preserved: they may still use the base `ADD COLUMN` path.
5. The fix must not change public method signatures or generic backend schema
   generation.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | prompt | "Adding nullable OneToOneField crashes on SQLite." | A nullable one-to-one add field migration is in domain and must not use an SQLite operation that crashes. | Encoded by PO-001. |
| I-002 | prompt | `OperationalError: Cannot add a UNIQUE column` for `ALTER TABLE ... ADD COLUMN ... UNIQUE ...` | SQLite `ADD COLUMN` with inline `UNIQUE` is the forbidden observable. | Encoded by PO-001 and PO-002. |
| I-003 | source | `OneToOneField.__init__()` sets `kwargs['unique'] = True`. | One-to-one fields are covered by the generic `field.unique` predicate. | Encoded by PO-003. |
| I-004 | source | `BaseDatabaseSchemaEditor._iter_column_sql()` yields `UNIQUE` when `field.unique`. | Delegating a unique field to the base add-column path produces the forbidden SQL shape. | Encoded by PO-002. |
| I-005 | source | SQLite `add_field()` already remakes for `not field.null` or non-`None` effective defaults. | The V2 predicate must preserve those remake cases. | Encoded by PO-004. |
| I-006 | source | Base `add_field()` has an existing supported path for nullable fields without defaults. | The V2 predicate must not route every add field through table remake. | Encoded by PO-005. |
| I-007 | compatibility | V1 changed only an internal branch condition and a comment. | No public API, signature, return type, override contract, or producer/consumer shape changes. | Encoded by PO-006. |

## Formal Core

The constructed K artifacts are:

- `fvk/mini-django-schema.k`
- `fvk/sqlite-add-field-spec.k`

They model only the property-carrying decision axis. This is property-complete
for the reported bug because the passing and failing cases differ only on
whether the SQLite base add-column path receives a field whose generated column
definition contains inline `UNIQUE`.

Discriminator examples:

- Failing pre-fix instance: `field(null=true, has_default=false, unique=true)`
  reaches `BaseAdd`, whose SQL has inline `UNIQUE`.
- Passing V1 instance: the same field reaches `Remake`.
- Unrelated fast-path instance: `field(null=true, has_default=false,
  unique=false)` still reaches `BaseAdd`.

## Formal Spec English

1. If `field.unique` is true, SQLite `add_field()` reaches `Remake`.
2. If `field.null` is false, SQLite `add_field()` reaches `Remake`.
3. If `effective_default(field)` is not `None`, SQLite `add_field()` reaches
   `Remake`.
4. If `field.null` is true, `effective_default(field)` is `None`, and
   `field.unique` is false, SQLite `add_field()` reaches `BaseAdd`.
5. `OneToOneField(null=True, default=None)` is in the first case because
   `OneToOneField` forces `unique=True`.

## Spec Audit

All five formal-English obligations pass against the intent specification:

- Obligations 1 and 5 directly discharge the issue's nullable
  `OneToOneField` crash.
- Obligations 2 and 3 preserve existing SQLite remake behavior.
- Obligation 4 preserves the existing non-unique fast path and prevents an
  overbroad "always remake" patch.

No formal obligation is derived solely from V1 behavior. The `unique` obligation
is derived from the prompt's SQLite error and the base schema editor's inline
`UNIQUE` generation.

## Public Compatibility Audit

Changed public symbols: none.

Changed internal symbol: `DatabaseSchemaEditor.add_field()` branch condition.
Its signature, return contract, virtual dispatch shape, and call sites are
unchanged. The method continues to call either `_remake_table()` or
`super().add_field()`, both existing paths.
