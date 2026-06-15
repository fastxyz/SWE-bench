# PROOF_OBLIGATIONS

Status: constructed for FVK audit; not machine-checked.

## PO1: Specified related admin ordering wins

For both related filter variants, if a related admin is registered and `related_admin.get_ordering(request)` is specified, the ordering passed to `field.get_choices()` is that admin ordering.

Specified means `ordering is not None and ordering != ()`, matching `ModelAdmin.get_field_queryset()`.

Evidence: E2, E3, E6.

K claims:

- `relatedFieldChoices(registered(O), M) => getChoices(related, noLimit, O)` when `specifiedOrdering(O)`.
- `relatedOnlyFieldChoices(registered(O), M) => getChoices(relatedOnly, pkInLimit, O)` when `specifiedOrdering(O)`.

## PO2: Missing or empty-tuple admin ordering falls back to Meta.ordering

For `RelatedFieldListFilter`, if there is no related admin, or the related admin ordering is `None` or `()`, the ordering passed to `field.get_choices()` is `field.remote_field.model._meta.ordering`.

Evidence: E1, E2, E5.

K claims:

- `relatedFieldChoices(unregistered, M) => getChoices(related, noLimit, M)`.
- `relatedFieldChoices(registered(emptyTuple), M) => getChoices(related, noLimit, M)`.
- `relatedFieldChoices(registered(none), M) => getChoices(related, noLimit, M)`.

## PO3: Related-only filter uses the same ordering resolution

`RelatedOnlyFieldListFilter.field_choices()` uses the same resolved ordering as `RelatedFieldListFilter`.

Evidence: E3, E4.

K claims:

- `relatedOnlyFieldChoices(registered(O), M) => getChoices(relatedOnly, pkInLimit, O)` when `specifiedOrdering(O)`.
- `relatedOnlyFieldChoices(unregistered, M) => getChoices(relatedOnly, pkInLimit, M)`.
- `relatedOnlyFieldChoices(registered(emptyTuple), M) => getChoices(relatedOnly, pkInLimit, M)`.
- `relatedOnlyFieldChoices(registered(none), M) => getChoices(relatedOnly, pkInLimit, M)`.

## PO4: V2 preserves explicit custom non-tuple-empty ordering values

The source must not collapse every falsy ordering value into the fallback case. It must preserve the adjacent admin predicate, where only `None` and `()` mean "not specified".

Evidence: E6.

Code obligation:

```python
if ordering is not None and ordering != ():
    return ordering
```

Finding trace: F1.

## PO5: Related-only choice restriction is preserved

The patch must not widen `RelatedOnlyFieldListFilter` choices. It must retain the `pk_qs` computation and the `limit_choices_to={'pk__in': pk_qs}` argument.

Evidence: E7.

K observable:

- Related-only claims use `getChoices(relatedOnly, pkInLimit, ...)`.

Finding trace: F3.

## PO6: No public API or override break

The patch must not require callers or subclasses to pass new arguments to existing methods.

Evidence: source compatibility audit in `fvk/SPEC.md`.

Code obligations:

- Keep both `field_choices(self, field, request, model_admin)` signatures unchanged.
- Add only internal helper dispatch.
- Use existing `Field.get_choices(..., ordering=...)` keyword.

## PO7: Formal abstraction is property-complete for this issue

The K model must preserve the property under test: which ordering and limit shape is passed into `get_choices()`.

Evidence: E1-E7.

Discriminator:

- Failing instance: `relatedFieldChoices(registered(emptyTuple), metaOrdering)` would return `getChoices(..., emptyTuple)` in the pre-fix behavior.
- Passing instance: V2 returns `getChoices(..., metaOrdering)`.

Because the abstraction distinguishes those outputs, it is adequate for the reported ordering-selection defect.

## PO8: Honesty gate

The proof remains constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` may be run in this benchmark session.

Required commands to record, not execute:

```sh
kompile fvk/mini-admin-ordering.k --backend haskell
kast --backend haskell fvk/admin-filter-ordering-spec.k
kprove fvk/admin-filter-ordering-spec.k
```
