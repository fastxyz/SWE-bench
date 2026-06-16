# SPEC: RenameIndex unnamed-index reversibility

Status: constructed, not machine-checked.

## Unit under audit

`django.db.migrations.operations.models.RenameIndex.database_backwards()`
when `self.old_fields` is set.

The audited operation is the `old_fields` form of `RenameIndex`, which converts
an unnamed `index_together` index into a named `Index` in state and in the
database.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | problem | "RenameIndex() should restore the old auto-generated name when an unnamed index ... is moving backward." | Backwards database application for an unnamed old index must restore the generated old database name. | Encoded by PO1 and claim `reverse-old-fields-restores-generated-name`. |
| I2 | problem | "Now re-applying RenameIndex() crashes ... relation \"new_pony_test_idx\" already exists" | A forwards, backwards, forwards sequence must not leave the database in a state where the second forwards renames `new_name` to itself. | Encoded by PO2 and claim `round-trip-reapply-safe`. |
| I3 | public hint | "We should be able to find the old name with SchemaEditor._create_index_name()." | The restored old name is the schema editor's deterministic generated index name, not an introspected leftover name. | Encoded by PO1. |
| I4 | docs/source | `old_fields` is documented as corresponding to `Options.index_together`; `state_forwards()` removes `AlterIndexTogether.option_name`. | The `old_fields` contract is scoped to unnamed `index_together` indexes and uses the `"_idx"` suffix. | Encoded by PO1 and PO5. |
| I5 | source | `database_forwards()` respects `allow_migrate_model()` before doing database work. | Backwards must also be a no-op when migration is not allowed for the model. | Encoded by PO3. |
| I6 | source | `schema_editor.rename_index()` abstracts rename-capable and drop/recreate backends. | The fix should use the existing schema-editor operation rather than backend-specific SQL. | Encoded by PO4. |
| I7 | public test in repo | Current public test says "Reverse is a no-op." | This is SUSPECT legacy evidence because it encodes the behavior the issue reports as buggy. | Recorded as F2; not encoded as desired behavior. |
| I8 | problem wording | The prose mentions `unique_together`. | Ambiguous against the operation's docs and state transition, which target `index_together`; do not broaden `RenameIndex` to unique constraints without separate intent/API evidence. | Recorded as F3. |

## Intended contract

For a `RenameIndex(model_name, new_name=NEW, old_fields=FIELDS)` operation:

1. Forward database application starts from a table with exactly one matching
   unnamed index over `FIELDS` and renames that index to `NEW`.
2. Backward database application starts from the post-forward state where the
   current database index over `FIELDS` is named `NEW`.
3. If migration is allowed for the target model, backward application renames
   that current `NEW` index to the deterministic generated index name:
   `schema_editor._create_index_name(table_name, columns, suffix="_idx")`.
4. If migration is not allowed for the target model, backward application makes
   no database change.
5. The named-index branch (`old_name` set, `old_fields` unset) is outside this
   change and keeps the existing swap-and-forward behavior.

## Preconditions and domain

- `old_fields` names fields present on the target-state model.
- The operation is the `index_together` conversion represented by
  `RenameIndex.old_fields`, not unique constraint renaming.
- The generated old name and `new_name` are distinct. If they are equal, the
  migration is semantically redundant and outside the reported crash path.
- The table does not contain an independent object already named `new_name` at
  the moment forwards is applied. This is the usual database uniqueness
  precondition for index names and is already required by `RenameIndex`.

## Observable postcondition

Let:

- `TABLE = to_state.apps.get_model(app_label, model_name)._meta.db_table`
- `COLUMNS = [target_model._meta.get_field(field).column for field in old_fields]`
- `GENERATED = schema_editor._create_index_name(TABLE, COLUMNS, suffix="_idx")`

Then:

- Before V1: `database_backwards()` left the database index name as `NEW`.
- Required behavior: after `database_backwards()`, the database index name is
  `GENERATED`.
- Re-applying `database_forwards()` then sees a non-`NEW` current name and
  renames `GENERATED` to `NEW`, avoiding the rename-to-self failure.

## Adequacy summary

The formal claims in `fvk/rename-index-spec.k` model the database-observable
name transition rather than the full Django runtime. This abstraction is
adequate for the issue because the reported failure is entirely about which
index name exists before the second forward rename. The model keeps the
discriminating property: `NEW` and `GENERATED` are distinct names, and the
database state records which one exists.
