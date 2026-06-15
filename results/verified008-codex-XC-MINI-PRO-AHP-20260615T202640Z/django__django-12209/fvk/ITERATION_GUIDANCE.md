# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

Reason: the FVK proof obligations that correspond to the selected public compromise are discharged by the constructed transition proof:

- PO1: raw existing fixture rows update instead of inserting.
- PO2: raw missing fixture rows still fall back to insert.
- PO3: non-raw generated-default object creation keeps the insert-only optimization.
- PO5: public call signatures and serializer dispatch remain compatible.

## Code Changes

No additional source changes are recommended for V2.

The existing V1 change in `repo/django/db/models/base.py` remains the whole production patch:

```python
if (
    not raw and
    not force_insert and
    self._state.adding and
    self._meta.pk.default and
    self._meta.pk.default is not NOT_PROVIDED
):
    force_insert = True
```

## Residual Limitation

Finding F3 remains: normal non-raw explicit-pk saves for models with primary-key defaults can still force INSERT. This is not treated as a V2 code bug because the public issue discussion explicitly accepts preserving the optimization and using `force_update` as the workaround for the direct pattern.

If a future product decision requires restoring full Django 2.2 behavior for direct non-raw explicit-pk saves, the next iteration should not use a `pk_set` condition alone. It would need a deliberate design for tracking whether the primary key value came from a field default or from user assignment, including positional constructor arguments, `id=...`, `pk=...`, post-construction `pk` assignment, direct attname assignment, deferred loading, and model inheritance.

## Suggested Tests for a Future Test-Enabled Environment

Do not modify tests in this benchmark. In a normal development environment, add or keep tests for:

- Loading the same fixture twice for a model with a UUID primary key default updates the existing row instead of inserting a duplicate.
- Loading a fixture once for such a model still inserts missing rows.
- Ordinary `PrimaryKeyWithDefault().save()` remains one query.
- `Sample(pk=existing_pk).save()` documents or asserts the accepted limitation, depending on the project decision.

## Machine Check Follow-Up

When K tooling is available, run:

```sh
kompile fvk/mini-django-save.k --backend haskell
kast --backend haskell fvk/save-table-spec.k
kprove fvk/save-table-spec.k
```

Keep all tests until the proof is actually machine-checked and the integration surface remains covered.
