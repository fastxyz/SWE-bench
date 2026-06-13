# django__django-15629 — Errors with db_collation: no propagation to foreign keys

## Summary of the issue

When a primary key (or any unique/`to_field` target) declares a database
collation via `db_collation` (a `CharField`/`TextField` option), the foreign
key columns that reference it are **not** given the same collation. On MySQL a
foreign key constraint can only be created when the referencing column and the
referenced column share the same collation, so the generated migration SQL such
as

```sql
ALTER TABLE `b_manage_account` MODIFY `id` varchar(22) COLLATE `utf8_bin`;
ALTER TABLE `b_manage_address` MODIFY `account_id` varchar(22) NOT NULL;
ALTER TABLE `b_manage_address` ADD CONSTRAINT ... FOREIGN KEY (`account_id`) REFERENCES `b_manage_account` (`id`);
```

fails on the `ADD CONSTRAINT` step because `account_id` was modified **without**
`COLLATE utf8_bin`. The desired output applies the collation to the referencing
column as well:

```sql
ALTER TABLE `b_manage_address` MODIFY `account_id` varchar(22) NOT NULL COLLATE `utf8_bin`;
```

## Root cause

Two related gaps:

1. **`ForeignKey.db_parameters()` did not expose a collation.** It returned only
   `{"type", "check"}`. A `ForeignKey`'s on-disk column should mirror the target
   field's type *and* collation, but the collation was dropped. This affects the
   *column-creation* path (`column_sql()` → `_iter_column_sql()` already honors
   `field_db_params["collation"]`, but the value was never present for FKs).

2. **The schema editor never carried the collation when re-typing referencing
   columns.** In `BaseDatabaseSchemaEditor._alter_field()`, when a PK/unique
   field changes, the loop over `rels_to_update` rewrites each referencing FK
   column via `_alter_column_type_sql()`, which only emitted the column *type* —
   never a `COLLATE` clause. Collation alterations were handled by a *separate*
   method (`_alter_column_collation_sql()`) that was only ever invoked for the
   field's own column, not for the referencing columns. Additionally, that
   separate path on MySQL omitted the `NULL`/`NOT NULL` status, so it could not
   be reused for FK columns (MySQL's `MODIFY` resets a column to nullable when
   the clause is omitted).

## Fix

The collation was folded into the *type* alteration so that a single code path
(`_alter_column_type_sql`) handles type **and** collation for both the field's
own column and every referencing FK column. This guarantees the collation
travels with the type wherever a column is (re)typed, and lets MySQL keep its
`NULL`/`NOT NULL` handling (which is part of its type-alter SQL).

### Files changed

- **`django/db/models/fields/related.py`** — `ForeignKey.db_parameters()` now
  proxies the target field's collation:
  `{"type": ..., "check": ..., "collation": target_db_parameters.get("collation")}`.
  This makes both column creation and column alteration aware of the referenced
  field's collation. (`OneToOneField` inherits it.)

- **`django/db/backends/base/schema.py`**
  - `sql_alter_column_type` gained a `%(collation)s` placeholder; the now-unused
    `sql_alter_column_collate` template and the `_alter_column_collation_sql()`
    method were removed.
  - `_alter_column_type_sql()` now takes `old_collation`/`new_collation` and
    appends a `COLLATE` clause (via `_collate_sql`) when the collation changes.
  - `_alter_field()` computes `old_collation`/`new_collation` once, lets a
    collation difference (not just a type difference) trigger `drop_foreign_keys`
    (so a collation-only change on a referenced PK also re-makes the FK columns
    and constraints), merges the old "collation change" / "type change" branches
    into a single `_alter_column_type_sql()` call, and passes the FK's own
    old/new collation in the `rels_to_update` loop.
  - `_collate_sql()` signature extended to `(collation, old_collation=None,
    table_name=None)` and now returns `""` for an empty collation (so backends
    can branch on resetting a collation).

- **`django/db/backends/mysql/schema.py`** — `sql_alter_column_type` gained
  `%(collation)s`; `sql_alter_column_collate` removed; `_alter_column_type_sql()`
  signature updated to forward the collations (it still injects `NULL`/`NOT NULL`
  before delegating, so the result is e.g.
  `MODIFY \`account_id\` varchar(22) NOT NULL COLLATE \`utf8_bin\``, exactly the
  SQL the ticket asks for).

- **`django/db/backends/oracle/schema.py`** — `sql_alter_column_type` gained
  `%(collation)s`; `sql_alter_column_collate` removed; `_alter_column_type_sql()`
  forwards the collations; the old `_alter_column_collation_sql()` override was
  replaced by a `_collate_sql()` override that substitutes the table's default
  collation when a collation is being *removed* (Oracle cannot reset to the
  default implicitly).

- **`django/db/backends/postgresql/schema.py`** — `_alter_column_type_sql()`
  signature updated; the dynamically-built `sql_alter_column_type` gained
  `%(collation)s` (placed before the `USING …` cast, which is valid PostgreSQL),
  the auto-field branch supplies `"collation": ""`, and both `super()` calls
  forward the collations.

- **`django/contrib/gis/db/backends/postgis/schema.py`** —
  `_alter_column_type_sql()` signature updated to forward the collations to
  `super()`; the dimension-change branch supplies `"collation": ""` (geometry
  columns have no collation).

- **`django/db/backends/sqlite3/schema.py`** — `_alter_field()` now rebuilds
  related tables when the referenced field's *collation* changes (in addition to
  its type), so SQLite — which applies column changes by re-making the table and
  regenerating each column via `column_sql()`/`db_parameters()` — picks up the FK
  column collation. `_collate_sql()` signature widened to match the base.

## How the fix resolves the ticket scenario

Changing `Account.id` from `BigAutoField` to a collated `CharField` produces an
`AlterField` only on `Account.id`. When applied, the base schema editor drops
the incoming FK constraints, re-types `Account.id`, then re-types each
referencing column in `rels_to_update`. Because `ForeignKey.db_parameters()` now
carries the target collation and `_alter_column_type_sql()` emits it, the
referencing `account_id` columns are modified **with** `COLLATE utf8_bin`, and
the subsequent `ADD CONSTRAINT` succeeds. On SQLite the related tables are
re-made and the FK columns are regenerated with the collation.

## Assumptions and alternatives considered

- **Chosen: fold collation into `_alter_column_type_sql` (and remove
  `_alter_column_collation_sql`).** The public hint suggested two options: a
  read-only `ForeignKey.db_collation` property, or returning `collation` in
  `db_params` and branching in the schema editor. The property alone only fixes
  *new* models, not alterations (the hint and draft PR discussion note this), so
  the `db_params` route was taken. Folding collation into the type-alter path
  (rather than keeping a separate collation-alter path) was necessary because the
  separate path does not preserve MySQL's `NULL`/`NOT NULL` status, which the FK
  columns require.

- **Rejected: only patch the `rels_to_update` loop and keep
  `_alter_column_collation_sql`.** Reusing the collation-only method for FK
  columns would have produced `MODIFY \`account_id\` varchar(22) COLLATE …`
  *without* `NOT NULL`, silently making non-nullable FK columns nullable on
  MySQL. Routing through the type-alter path avoids that.

- **PostgreSQL `USING` interaction.** Putting `%(collation)s` before the `USING`
  cast keeps `ALTER COLUMN … TYPE varchar(n) COLLATE "x" USING …::varchar(n)`
  valid, so a simultaneous type+collation change on a referencing column still
  casts correctly.

- **Internal signatures.** `_alter_column_type_sql`, `_collate_sql`, and
  `db_parameters` are internal/extension-point methods; no test in the suite
  calls them with the old signatures (verified), and the collation tests assert
  the resulting column collation via introspection rather than exact SQL, so the
  template/signature refactor is safe.

- **Scope.** Only the collation propagation problem was addressed; nullability
  handling on collation-only changes of ordinary (non-FK) columns and unrelated
  schema behavior were intentionally left untouched.
