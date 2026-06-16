# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Source Decision

Keep the V1 behavioral fix but reduce its compatibility footprint:

- retain `primary_key=False` for deleting `unique_together`;
- retain generated `_uniq` disambiguation when multiple unique candidates remain;
- restore the original `_delete_composed_index()` signature by deriving `_uniq`
  inside the helper for unique deletions.

This addresses F-001 while preserving the obligations that address F-002.

## Suggested Public Tests For A Future Test-Editing Pass

Do not edit tests in this benchmark session. A normal Django development pass
should add focused schema-editor tests for:

- removing `unique_together = (("id",),)` when the primary key and generated
  `_uniq` constraint both cover `id`;
- removing single-field `unique_together` when a field-level `unique=True`
  constraint also covers the column;
- preserving explicit `Meta.constraints` on the same columns;
- preserving the existing `ValueError` when multiple same-column unique
  constraints remain and none has the generated `_uniq` name;
- checking whether adding single-field `unique_together` after `unique=True` is
  reproducible on supported backends, and deciding the intended policy if it is.

## Next Questions

Q1. Should adding redundant single-field `unique_together` on an already unique
field be a no-op, create a second physical constraint with a different name, or
continue to attempt the historical generated name?

Q2. Is dropping manually renamed single-field `unique_together` in an ambiguous
same-column constraint set supported, or is generated-name matching the intended
boundary?
