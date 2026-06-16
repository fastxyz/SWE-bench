# Iteration Guidance

Status: V1 confirmed by FVK audit; no V2 source edit is justified.

## Decision

Keep the V1 source change:

```python
elif getattr(self, field.attname) in field.empty_values:
```

instead of the pre-fix:

```python
elif getattr(self, field.attname) is None:
```

## Why V1 Stands

- F1 and O1 show the public issue requires treating `""` as unset in this
  save-preparation reconciliation path.
- F2 and O2 show the `obj.pk is None` guard remains before the broadened empty
  check.
- F3 and O3 show non-empty mismatched local values still clear the cache rather
  than being overwritten.
- O4 and F4 show the per-field proof composes over the concrete-field loop.
- O5 shows both `save()` and `bulk_create()` use the repaired function.
- O6 shows manual local FK changes still clear the relation cache before save
  preparation can refresh from a cached object.

## Rejected Next Changes

Changing `ForwardManyToOneDescriptor.__set__()` to avoid copying empty target
values at assignment time was rejected. The descriptor's current job is to
mirror the related object's current target value and cache the object. The
public issue points to save preparation failing to reconcile that cached object
after the related object gains its primary key.

Changing public APIs or call signatures was rejected. The source repair needs
only a local predicate change in `_prepare_related_fields_for_save()`.

## Suggested Tests For A Future Test Suite

- Save path: assign `Product()` to `Order.product`, set `sku`, save product,
  save order, assert `order.product_id == "foo"`.
- Bulk path: same object graph, save product first, then pass order through
  `bulk_create()` and assert the stored FK value is `"foo"`.
- Guard path: cached related object with `obj.pk is None` still raises the
  existing `ValueError`.

No tests were run or modified in this session.
