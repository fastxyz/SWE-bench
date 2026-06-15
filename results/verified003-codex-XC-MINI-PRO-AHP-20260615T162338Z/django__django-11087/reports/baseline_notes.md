# Baseline Notes

## Root cause

`Collector.collect()` evaluated the root queryset and each cascade queryset
without restricting selected columns. During `.delete()`, the collector only
needs enough data to identify each object, build the cascade graph, apply field
updates, and preserve multi-table inheritance parent collection. Selecting every
concrete field meant unrelated text/blob fields were decoded even when the
delete algorithm never used them, which caused the reported `UnicodeDecodeError`
and unnecessary work.

## Changed files

`repo/django/db/models/deletion.py`

- Added a shared `_has_signal_listeners()` helper and reused it from
  `can_fast_delete()`.
- Added `_delete_fields()` to compute the model field attnames required for
  deletion collection: the primary key, parent concrete fields needed to
  materialize multi-table inheritance parents, and referenced fields used by
  reverse relations, including non-primary-key `to_field` references.
- Added `_optimize_delete_queryset()` to apply `QuerySet.only()` when a queryset
  can be safely materialized with a narrowed field set.
- Applied the optimization to unevaluated querysets entering `collect()` and to
  querysets produced by `related_objects()` before their truthiness can force
  evaluation.
- Kept full delete-collection projections for `CASCADE` relations and narrowed
  non-`CASCADE` relation querysets to the primary key fields needed for
  `PROTECT` and field-update handlers.

## Assumptions and alternatives

- I assumed delete signal receivers may inspect arbitrary fields, so queryset
  narrowing is skipped when the model has relevant signal listeners. This keeps
  signal-visible instances consistent with the preexisting behavior.
- I treated `m2m_changed` listeners the same way as existing
  `can_fast_delete()` logic, even though the optimization primarily concerns
  delete collection. This is conservative and avoids diverging from the existing
  fast-delete safety check.
- I included parent concrete fields for multi-table inheritance. An alternative
  would be to construct parent instances manually with only their own required
  fields, but that would be a broader change to the collector's object
  materialization behavior.
- I treated non-`CASCADE` related querysets as not being recursively deleted by
  the collector, so only their primary key is required unless signal-listener
  checks opt out of narrowing.
- I left `bulk_related_objects()` paths, such as generic relations, unchanged
  because they are field-specific hooks and the collector cannot infer a safe
  projection for arbitrary implementations.
- I did not add or modify tests and did not run code, per the benchmark
  instructions.
