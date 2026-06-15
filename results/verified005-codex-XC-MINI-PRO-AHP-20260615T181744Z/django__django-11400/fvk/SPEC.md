# SPEC

Status: constructed for FVK audit; not machine-checked.

## Scope

Target source:

- `repo/django/contrib/admin/filters.py`

Target methods:

- `RelatedFieldListFilter.field_choices()`
- `RelatedFieldListFilter.field_admin_ordering()`
- `RelatedOnlyFieldListFilter.field_choices()`

The observable under verification is the ordering argument passed to `field.get_choices()` and, for `RelatedOnlyFieldListFilter`, preservation of the existing `limit_choices_to={'pk__in': pk_qs}` restriction.

## Intent Spec

1. `RelatedFieldListFilter` must order related filter choices by the related `ModelAdmin` ordering when that ordering is specified.
2. If no related `ModelAdmin` ordering is specified, `RelatedFieldListFilter` must fall back to the related model's `Meta.ordering`.
3. The empty tuple `()` is the reported no-admin-ordering sentinel and must not be passed through as the final ordering when the related model has `Meta.ordering`.
4. `RelatedOnlyFieldListFilter` must use the same related ordering resolution as `RelatedFieldListFilter`.
5. `RelatedOnlyFieldListFilter` must keep its related-only restriction; the fix is about ordering, not expanding the choice set.
6. The fix must stay local to admin filters and must not change the global behavior of `Field.get_choices()`.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "RelatedFieldListFilter doesn't fall back to the ordering defined in Model._meta.ordering." | Fallback ordering for related filters must be related model `Meta.ordering`. | Encoded by PO1, PO2, K claims RF-unregistered and RF-empty-tuple. |
| E2 | `benchmark/PROBLEM.md` | "unless ordering is defined on the related model's ModelAdmin class it stays an empty tuple" | Specified related `ModelAdmin` ordering takes precedence; empty tuple is not specified ordering. | Encoded by PO1, PO2, K claim RF-admin-specified. |
| E3 | `benchmark/PROBLEM.md` | "RelatedOnlyFieldListFilter doesn't order the related model at all, even if ordering is defined on the related model's ModelAdmin class." | Related-only filters must pass resolved ordering to `get_choices()`. | Encoded by PO3, K claims RO-admin-specified and RO-fallback. |
| E4 | `benchmark/PROBLEM.md` | "the call to field.get_choices ... omits the ordering kwarg entirely" | The code fix must include an explicit `ordering=` argument in related-only choices. | Encoded by PO3. |
| E5 | Source: `django/db/models/fields/__init__.py` | `get_choices(..., ordering=())` calls `.order_by(*ordering)`. | Passing `()` clears default ordering; callers must pass the intended ordering explicitly. | Encoded as bug mechanism and PO2. |
| E6 | Source: `django/contrib/admin/options.py` | `get_field_queryset()` uses `ordering is not None and ordering != ()` to detect specified related admin ordering. | Use the same local predicate for admin-related ordering compatibility. | Encoded by PO4 and V2 refinement. |
| E7 | Source: existing `RelatedOnlyFieldListFilter.field_choices()` | It computed `pk_qs` and passed `limit_choices_to={'pk__in': pk_qs}`. | Preserve related-only choice restriction. | Encoded by PO5 and K `pkInLimit` observable. |

## Formal Spec English

Let `specified(ordering)` mean `ordering is not None and ordering != ()`.

Let `resolved_ordering(field, request, model_admin)` be:

- related admin ordering, if a related admin is registered and `specified(related_admin.get_ordering(request))`;
- otherwise `field.remote_field.model._meta.ordering`.

`RelatedFieldListFilter.field_choices()` must call:

```python
field.get_choices(include_blank=False, ordering=resolved_ordering(...))
```

`RelatedOnlyFieldListFilter.field_choices()` must call:

```python
field.get_choices(
    include_blank=False,
    limit_choices_to={'pk__in': pk_qs},
    ordering=resolved_ordering(...),
)
```

Frame conditions:

- `include_blank=False` remains unchanged.
- `RelatedOnlyFieldListFilter` keeps the `pk_qs` restriction.
- `Field.get_choices()` and `ModelAdmin.get_ordering()` public APIs are unchanged.
- No test files are modified.

## Formal Core

The K fragment is in `fvk/mini-admin-ordering.k`.

The K claims are in `fvk/admin-filter-ordering-spec.k`.

The fragment models only the property under audit: whether each filter path passes `Meta.ordering`, specified related admin ordering, or the related-only limit-preserving call shape into `get_choices()`. It deliberately abstracts away SQL execution and rendered HTML because the issue's root cause is the ordering argument selected before query execution.

## Spec Audit

| Formal clause | Intent coverage | Result |
| --- | --- | --- |
| `registered(O)` with `specifiedOrdering(O)` resolves to `O`. | E2 and E6. | Pass. |
| `unregistered` resolves to model meta ordering. | E1. | Pass. |
| `registered(emptyTuple)` resolves to model meta ordering. | E1, E2, E5. | Pass. |
| `registered(none)` resolves to model meta ordering. | E6 and the source need to avoid passing `None` into `order_by(*ordering)`. | Pass. |
| `RelatedOnlyFieldListFilter` uses the same resolved ordering. | E3, E4. | Pass. |
| `RelatedOnlyFieldListFilter` retains `pkInLimit`. | E7. | Pass. |
| SQL/queryset final ordering is abstracted behind `getChoices`. | Source shows `get_choices()` forwards `ordering` to `order_by(*ordering)`. Full SQL semantics are outside this FVK fragment. | Pass with trusted-base note. |

## Public Compatibility Audit

Changed public or virtual symbols:

- Added `RelatedFieldListFilter.field_admin_ordering()`.
- Changed internal calls to `field.get_choices()` by adding/resolving `ordering=`.

Compatibility results:

- `field_choices()` signatures are unchanged.
- `RelatedOnlyFieldListFilter.field_choices()` remains an override with the same signature.
- No external callsite is required to pass a new argument.
- `field_admin_ordering()` is a new helper, so no existing override can be broken.
- `Field.get_choices()` already accepts `ordering`; this patch uses an existing keyword.

Conclusion: no public API or override incompatibility found.
