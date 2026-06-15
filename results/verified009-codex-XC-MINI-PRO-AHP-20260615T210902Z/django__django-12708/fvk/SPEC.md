# SPEC

Status: constructed, not machine-checked. No tests, Python, or K commands were
run.

## Scope

The verified unit is the observable decision made by
`BaseDatabaseSchemaEditor.alter_index_together()` when it asks
`_delete_composed_index()` to delete an old `index_together` entry. The model is
property-complete for the reported defect because it preserves the columns,
`index`, `unique`, and exclusion flags used by `_constraint_names()` to select
candidate database objects.

## Public intent ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The core obligations are:

- E1-E4: deleting `index_together` must not crash solely because
  `unique_together` exists on the same fields.
- E3/E6: same-column unique constraints may also be reported as indexes, so
  `index=True` alone is not a sufficient selector.
- E5: `index_together` creation uses non-unique index SQL, so deletion should
  select a non-unique index.
- E8: public signatures and migration operation shapes must not change.

## Formal model

`mini-schema.k` defines a small schema-editor transition system:

- a database object is `constraint(name, columns, index, unique, excluded)`;
- `filterIndexOnly()` models the old `{'index': True}` lookup;
- `filterIndexTogetherDelete()` models V1's
  `{'index': True, 'unique': False}` lookup;
- `deleteOne()` models `_delete_composed_index()` raising the wrong-count error
  unless the filtered list has exactly one name.

`schema-editor-spec.k` contains three all-path claims:

- SPEC-C0: the old index-only lookup reaches `wrongCount("_uniq", "_idx")`;
- SPEC-C1: V1 deletes `_idx` when `_uniq` appears before `_idx`;
- SPEC-C2: V1 deletes `_idx` when `_idx` appears before `_uniq`.

## Preconditions

For each removed `index_together` field tuple:

- the field tuple maps to a concrete column sequence;
- after excluding names declared in `Meta.constraints` and `Meta.indexes`, there
  is exactly one same-column non-unique index created for `index_together`;
- there may also be same-column unique constraints or unique indexes.

If the non-unique candidate set is empty or has more than one member, preserving
the existing `ValueError` behavior is intentional because deletion would be
ambiguous or impossible to identify safely.

## Postcondition

Under the preconditions, deleting `index_together` reaches the SQL deletion path
for the non-unique index and does not count same-column unique objects as
deletion candidates.

## Frame conditions

- `alter_unique_together()` remains unchanged and still deletes using
  `{'unique': True}`.
- `_delete_composed_index()` and `_constraint_names()` signatures remain
  unchanged.
- Backend introspection semantics remain unchanged.

## Machine-check commands

These commands are emitted for a later environment with K installed. They were
not run here.

```sh
cd fvk
kompile mini-schema.k --backend haskell
kast --backend haskell schema-editor-spec.k
kprove schema-editor-spec.k
```
