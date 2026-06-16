# Baseline Notes

## Root cause

Many-to-many serialization for related objects without natural keys only needs
the related object's primary key, so the serializers narrow the related queryset
with `only("pk")`. When the related model's default manager customizes its base
queryset with `select_related("...")`, that select-related state is inherited by
the related manager queryset used during serialization.

Combining the inherited `select_related()` traversal with `only("pk")` defers
the foreign key field being traversed by `select_related()`. Django then raises
`FieldError: Field ... cannot be both deferred and traversed using
select_related at the same time.`

## Files changed

`repo/django/core/serializers/python.py`

- In the non-natural-key many-to-many serialization path, clear inherited
  `select_related` state with `select_related(None)` before applying
  `only("pk")`.
- This keeps the primary-key-only optimization while avoiding traversal of
  fields that serialization does not need.
- JSON, JSONL, and YAML serializers inherit this Python serializer behavior.

`repo/django/core/serializers/xml_serializer.py`

- Applied the same change to XML's separate many-to-many serialization
  implementation so XML serialization has consistent behavior.

## Assumptions and rejected alternatives

- Assumed that serializers should not preserve a related model manager's
  `select_related()` customizations when serializing only many-to-many primary
  key references, because those joins are unnecessary for the serialized output.
- Rejected removing `only("pk")`, because that would undo the existing
  optimization and fetch unneeded columns for m2m references.
- Rejected using `select_related()` without arguments. In this codebase that
  enables unrestricted select-related traversal; `select_related(None)` is the
  API that clears existing select-related state.
- Left the natural-key many-to-many branch unchanged because it may need fields
  beyond the primary key to compute `natural_key()`, and manager-level
  `select_related()` can still be useful there.

## Verification

No tests or project code were run, per the benchmark instructions.
