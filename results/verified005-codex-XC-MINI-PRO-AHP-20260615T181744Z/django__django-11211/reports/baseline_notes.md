# Baseline Notes

## Root cause

`GenericForeignKey.get_prefetch_queryset()` matches prefetched related objects back to source instances with a key made from the target model's primary key value and model class. The related object side uses the loaded object's `pk`, while the source instance side calls `model._meta.pk.get_prep_value()` on the generic object id field.

For a generic object id stored in a `CharField` and a target model whose primary key is a `UUIDField`, the generic object id is a string. Before this change, `UUIDField` inherited `Field.get_prep_value()`, which returned that string unchanged. Related objects loaded from a `UUIDField` primary key have `uuid.UUID` primary key values, so the prefetch join compared a string key with a `uuid.UUID` key and missed, leaving the `GenericForeignKey` cache populated as `None`.

## Changed files

`repo/django/db/models/fields/__init__.py`

Added `UUIDField.get_prep_value()` so UUID values are normalized with `to_python()` during preliminary value preparation. This makes callers that use primary key `get_prep_value()` for Python-side matching, including `GenericForeignKey.get_prefetch_queryset()`, receive a `uuid.UUID` object for valid UUID strings.

## Assumptions and alternatives considered

I assumed the intended behavior is that `GenericForeignKey` prefetch should work when the generic object id field stores a textual representation of a UUID primary key, matching the existing support for textual object ids pointing at integer primary keys.

I considered changing `GenericForeignKey.get_prefetch_queryset()` to call `to_python()` directly when building its source-instance match key. I rejected that as too local and less consistent with the existing generic relation code, which already delegates normalization to the target primary key field through `get_prep_value()`.

I also considered changing both sides of the `GenericForeignKey` prefetch match key to use a new shared conversion helper. I rejected that because the mismatch is caused by `UUIDField` not preparing values like other typed fields; adding the missing field-level preparation is smaller and avoids altering the generic prefetch algorithm.

Tests were not run because the task explicitly forbids running tests or project code in this workspace.
