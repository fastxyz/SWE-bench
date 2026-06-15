# PROOF

Status: constructed, not machine-checked.

## Formal Artifacts

- Semantics fragment: `fvk/mini-admin-ordering.k`
- Claim file: `fvk/admin-filter-ordering-spec.k`

Exact commands to run later, not executed in this benchmark session:

```sh
kompile fvk/mini-admin-ordering.k --backend haskell
kast --backend haskell fvk/admin-filter-ordering-spec.k
kprove fvk/admin-filter-ordering-spec.k
```

Expected machine-check result after installing K and running the commands: `#Top` for the claims in `admin-filter-ordering-spec.k`.

## Proof Shape

There are no loops or recursion in the audited code, so no circularity is required. The proof is straight symbolic rewriting over the ordering-resolution helper and the two `field_choices()` call shapes.

The mini semantics has three relevant rewrite groups:

1. `specifiedOrdering()` classifies admin ordering values.
2. `resolveOrdering()` chooses either the specified admin ordering or the model meta ordering.
3. `relatedFieldChoices()` and `relatedOnlyFieldChoices()` lower to `getChoices(...)` calls with the selected ordering.

## Claim Proofs

### RF-unregistered

Claim:

```k
relatedFieldChoices(unregistered, M) => getChoices(related, noLimit, M)
```

Symbolic steps:

1. `relatedFieldChoices(unregistered, M)` rewrites to `getChoices(related, noLimit, resolveOrdering(unregistered, M))`.
2. `resolveOrdering(unregistered, M)` rewrites to `M`.
3. By transitivity, the result is `getChoices(related, noLimit, M)`.

Discharges: PO2.

### RF-empty-tuple

Claim:

```k
relatedFieldChoices(registered(emptyTuple), M) => getChoices(related, noLimit, M)
```

Symbolic steps:

1. `relatedFieldChoices(registered(emptyTuple), M)` rewrites to `getChoices(related, noLimit, resolveOrdering(registered(emptyTuple), M))`.
2. `specifiedOrdering(emptyTuple)` rewrites to `false`.
3. `resolveOrdering(registered(emptyTuple), M)` takes the fallback rule and rewrites to `M`.
4. By transitivity, the result is `getChoices(related, noLimit, M)`.

Discharges: PO2 and the reported empty-tuple bug mechanism.

### RF-none

Claim:

```k
relatedFieldChoices(registered(none), M) => getChoices(related, noLimit, M)
```

Symbolic steps:

1. `relatedFieldChoices(registered(none), M)` rewrites to `getChoices(related, noLimit, resolveOrdering(registered(none), M))`.
2. `specifiedOrdering(none)` rewrites to `false`.
3. `resolveOrdering(registered(none), M)` takes the fallback rule and rewrites to `M`.
4. By transitivity, the result is `getChoices(related, noLimit, M)`.

Discharges: PO2.

### RF-admin-specified

Claim:

```k
relatedFieldChoices(registered(O), M) => getChoices(related, noLimit, O)
requires specifiedOrdering(O)
```

Symbolic steps:

1. `relatedFieldChoices(registered(O), M)` rewrites to `getChoices(related, noLimit, resolveOrdering(registered(O), M))`.
2. The precondition `specifiedOrdering(O)` enables the admin-ordering rule.
3. `resolveOrdering(registered(O), M)` rewrites to `O`.
4. By transitivity, the result is `getChoices(related, noLimit, O)`.

Discharges: PO1 and PO4.

### RO-admin-specified

Claim:

```k
relatedOnlyFieldChoices(registered(O), M) => getChoices(relatedOnly, pkInLimit, O)
requires specifiedOrdering(O)
```

Symbolic steps:

1. `relatedOnlyFieldChoices(registered(O), M)` rewrites to `getChoices(relatedOnly, pkInLimit, resolveOrdering(registered(O), M))`.
2. The precondition `specifiedOrdering(O)` enables the admin-ordering rule.
3. `resolveOrdering(registered(O), M)` rewrites to `O`.
4. The result preserves `pkInLimit`.

Discharges: PO3 and PO5.

### RO-unregistered, RO-empty-tuple, and RO-none

Claims:

```k
relatedOnlyFieldChoices(unregistered, M) => getChoices(relatedOnly, pkInLimit, M)
relatedOnlyFieldChoices(registered(emptyTuple), M) => getChoices(relatedOnly, pkInLimit, M)
relatedOnlyFieldChoices(registered(none), M) => getChoices(relatedOnly, pkInLimit, M)
```

These follow the same fallback derivation as RF-unregistered, RF-empty-tuple, and RF-none, with the related-only frame condition that `pkInLimit` is unchanged.

Discharges: PO3 and PO5.

## Source Correspondence

The final source implements `resolveOrdering()` as:

```python
def field_admin_ordering(self, field, request, model_admin):
    related_admin = model_admin.admin_site._registry.get(field.remote_field.model)
    if related_admin is not None:
        ordering = related_admin.get_ordering(request)
        if ordering is not None and ordering != ():
            return ordering
    return field.remote_field.model._meta.ordering
```

`RelatedFieldListFilter.field_choices()` passes the helper result as `ordering=`.

`RelatedOnlyFieldListFilter.field_choices()` passes the helper result as `ordering=` and preserves `limit_choices_to={'pk__in': pk_qs}`.

## Residual Risk

This is a partial, constructed proof over a mini semantics. It proves the ordering-selection logic modeled by the claims, not full Django ORM or SQL behavior.

Keep tests that exercise:

- rendered admin list filters;
- queryset ordering against actual database backends;
- interactions with custom `ModelAdmin.get_ordering()` overrides;
- integration behavior of `RelatedOnlyFieldListFilter`.

Do not remove any tests unless the K commands are run successfully and the tests are shown to be subsumed by the machine-checked claims.
