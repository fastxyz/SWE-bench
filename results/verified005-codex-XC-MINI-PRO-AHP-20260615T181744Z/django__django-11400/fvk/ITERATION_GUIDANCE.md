# ITERATION_GUIDANCE

Status: constructed for FVK audit; not machine-checked.

## Decision

Do not leave V1 exactly unchanged. Apply the small V2 refinement from Finding F1:

```python
if ordering is not None and ordering != ():
    return ordering
```

This aligns the filter helper with `ModelAdmin.get_field_queryset()` and avoids making truthiness, rather than Django's local "specified ordering" predicate, part of the contract.

The rest of V1 stands:

- keep the helper shared by both related filter variants;
- keep fallback to `field.remote_field.model._meta.ordering`;
- keep `RelatedOnlyFieldListFilter` passing both `limit_choices_to` and `ordering`;
- do not modify `Field.get_choices()`.

## Follow-up Verification Commands

Record only; do not run in this benchmark session:

```sh
kompile fvk/mini-admin-ordering.k --backend haskell
kast --backend haskell fvk/admin-filter-ordering-spec.k
kprove fvk/admin-filter-ordering-spec.k
```

## Recommended Tests for a Normal Development Environment

Do not add or edit tests in this benchmark session. In a normal Django development workflow, add or keep tests covering:

1. `RelatedFieldListFilter` falls back to related model `Meta.ordering` when no related admin ordering is specified.
2. `RelatedFieldListFilter` uses related `ModelAdmin.ordering` when configured.
3. `RelatedOnlyFieldListFilter` uses related `ModelAdmin.ordering`.
4. `RelatedOnlyFieldListFilter` falls back to related model `Meta.ordering`.
5. `RelatedOnlyFieldListFilter` still restricts choices to related objects present in the changelist queryset.

## Tests to Keep

Keep integration and backend tests around admin changelist rendering and ORM ordering until the K proof is machine-checked and those tests are explicitly shown redundant. The constructed proof does not cover SQL collation, database backend differences, HTML rendering, or full admin request integration.

## Next Intent Question if More Precision Is Needed

Should a custom `ModelAdmin.get_ordering()` override that returns an empty list be treated as an explicit request to clear ordering? V2 follows the adjacent Django admin predicate and preserves it as specified ordering, but the issue text only explicitly identifies `()` as the problematic no-ordering sentinel.
