# FVK Spec

Status: constructed, not machine-checked.

## Unit Under Audit

Primary production code:

- `repo/django/db/backends/base/schema.py`
- `BaseDatabaseSchemaEditor.alter_unique_together()`
- `BaseDatabaseSchemaEditor._delete_composed_index()`

The modeled observable is the schema editor's deletion decision for each
deleted `unique_together` field tuple: it either executes deletion for one
constraint name or raises `ValueError`.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2/E3 require the migration not to fail when a primary key and generated
  single-field `unique_together` constraint both cover the same column.
- E4/E5/E6 require non-primary duplicate unique constraints to be
  disambiguated by Django's generated `_uniq` name for `unique_together`.
- E8 requires existing protection for explicit `Meta.constraints` and
  `Meta.indexes`.
- E9 requires avoiding unnecessary helper signature/API churn.

## Contract

O1. When `alter_unique_together()` deletes an old tuple, it calls
`_delete_composed_index()` with `unique=True` and `primary_key=False`. Therefore
primary keys are not candidate constraints for deletion.

O2. `_delete_composed_index()` first obtains candidates using the existing
column, uniqueness, primary-key, index, and exclusion filters.

O3. If the deletion is for a unique constraint and more than one candidate
remains, `_delete_composed_index()` computes the deterministic Django-generated
unique name:

```text
identifier_converter(_create_index_name(model._meta.db_table, columns, suffix="_uniq"))
```

If that generated name is present among the candidates, it becomes the sole
candidate.

O4. If exactly one candidate remains after O1-O3, that candidate is passed to
`_delete_constraint_sql()` and executed.

O5. If zero candidates remain, or multiple candidates remain and the generated
`_uniq` name is not one of them, `_delete_composed_index()` preserves the
existing `ValueError` behavior.

O6. Explicit names in `model._meta.constraints` and `model._meta.indexes` remain
excluded from implicit composed-index deletion.

O7. The `_delete_composed_index(model, fields, constraint_kwargs, sql)` argument
list remains unchanged in V2; the `_uniq` suffix preference is derived inside
the helper for unique deletions.

## Domain

The spec covers deletion of `unique_together` entries through
`alter_unique_together()` and the subsequent candidate-name selection inside
`_delete_composed_index()`. It assumes `_constraint_names()` faithfully returns
the backend-introspected names matching its filter arguments.

The spec does not claim to resolve creation of a redundant single-field
`unique_together` after `unique=True`; see Finding F-003.

## Formal Core

- `fvk/mini-schema-editor.k` models candidate selection.
- `fvk/schema-editor-spec.k` states reachability claims over that model.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim.
- `fvk/SPEC_AUDIT.md` checks adequacy against `fvk/INTENT_SPEC.md`.
