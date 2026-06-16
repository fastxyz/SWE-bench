# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run for this audit.

## Target

This FVK run audits the `QuerySet.bulk_create(..., update_conflicts=True, ...)`
path that stores `update_fields` and `unique_fields` on `InsertQuery` and the
`SQLInsertCompiler` path that passes those values to backend
`on_conflict_suffix_sql()` implementations.

The observable under audit is the conflict SQL identifier stream: the conflict
target identifiers and update-assignment identifiers passed to backend quoting
must be database column names.

## Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | `QuerySet.bulk_create() crashes on mixed case columns in unique_fields/update_fields.` | The upsert path must support fields whose Python field names differ from database column names, including case differences. | Encoded by O1-O3. |
| I2 | prompt | Insert SQL uses `"BlacklistID"` but conflict SQL uses `"blacklistid"` and PostgreSQL reports `column "blacklistid" does not exist`. | Conflict target identifiers must be database column names, not model field names. | Encoded by O2-O3. |
| I3 | prompt | Expected SQL: `ON CONFLICT("BlacklistID") DO UPDATE SET "SectorID" = EXCLUDED."SectorID"` | Both `unique_fields` and `update_fields` must be compiled as `Field.column` identifiers. | Encoded by O1-O3. |
| I4 | docs | `Field.db_column`: "The name of the database column to use for this field. If this isn't given, Django will use the field's name." | `Field.column` is the correct normalized database identifier source for a model field. | Encoded by O1-O3. |
| I5 | source | `Field.get_attname_column()` returns `self.db_column or attname`; `set_attributes_from_name()` stores this as `self.column`. | Resolving names to `Field` objects before SQL compilation is sufficient to recover the real database columns. | Encoded by O1-O2. |
| I6 | docs | `update_conflicts=True` updates `update_fields` on conflicts and PostgreSQL/SQLite require `unique_fields`. | The new conversion is required for the upsert path, not for unrelated non-upsert insert paths. | Encoded by O4. |
| I7 | source/API compatibility | Backend `on_conflict_suffix_sql()` methods quote iterable identifier strings using `quote_name`. | Backend hooks should continue receiving identifier strings, not `Field` objects. | Encoded by O3 and O5. |

## Contract

For every `bulk_create()` call that reaches `OnConflict.UPDATE`:

1. Every name in `update_fields` is resolved through `opts.get_field(name)` to a
   `Field`.
2. Every normalized name in `unique_fields` is resolved through
   `opts.get_field(name)` to a `Field`; the existing `"pk"` alias is normalized
   to `opts.pk.name` before resolution.
3. `SQLInsertCompiler` passes `[field.column for field in update_fields]` and
   `[field.column for field in unique_fields]` to
   `connection.ops.on_conflict_suffix_sql()`.
4. Built-in backend `on_conflict_suffix_sql()` implementations quote those
   column strings when forming conflict target and update assignment SQL.

Frame conditions:

1. Calls that do not reach `OnConflict.UPDATE` do not newly resolve or validate
   otherwise unused conflict options during SQL compilation.
2. The existing validation behavior in `_check_bulk_create_options()` remains
   unchanged: invalid `update_fields` or `unique_fields` are rejected when
   `update_conflicts=True`; primary keys remain forbidden in `update_fields`;
   primary key aliasing remains allowed in `unique_fields`.
3. Insert column generation remains unchanged and already uses `f.column`.

## Scope Boundaries

The constructed proof models the option and identifier flow, not the full ORM,
transaction management, database execution, or backend SQL parser. It is a
partial-correctness proof: if compilation reaches the modeled backend hook, the
identifier values supplied to that hook satisfy the column-name contract.

No public tests are modified or removed. Existing and hidden tests remain the
execution-level check because this FVK proof is constructed but not
machine-checked.
