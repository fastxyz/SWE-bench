# FVK Specification

Status: constructed, not machine-checked.

## Unit Under Audit

`repo/django/db/models/base.py::_prepare_related_fields_for_save()`.

The audited behavior is the relation-field iteration for a cached
`ForeignKey` or `OneToOneField` on the instance being saved. The issue's
observable failure is a single relation field, so the K core models one
independent field iteration. The finite Python `for field in
self._meta.concrete_fields` loop is covered by proof obligation O4 as induction
over independent field iterations.

## Contract

For each concrete relation field `field` cached on `self`:

1. If the cached object is falsey, preparation leaves the local relation value
   and cache state unchanged.
2. If `obj.pk is None`, preparation raises the existing `ValueError` before
   any stale foreign-key value can be persisted.
3. If `obj.pk is not None` and `getattr(self, field.attname)` is in
   `field.empty_values`, preparation sets `field.attname` to `obj.pk`.
4. After the refresh opportunity, if
   `getattr(obj, field.target_field.attname) != getattr(self, field.attname)`,
   the owner-side relation cache is cleared.
5. If the field isn't cached, this function has no relation object to reconcile
   and leaves the field untouched.

For the public issue trace, `field.attname` starts as `""`, `obj.pk` becomes
`"foo"` after `order.product.sku = "foo"` and `order.product.save()`, and the
required post-state before database write is `order.product_id == "foo"`.

## Public Intent Ledger

The standalone ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E4 provide the issue-derived stale-empty-string failure and required
  `"foo"` post-state.
- E5 identifies `_prepare_related_fields_for_save()` and `empty_values` as the
  public repair direction.
- E6-E7 explain why `""` appears before the user assigns the `CharField`
  primary key.
- E8-E9 preserve the existing unsaved-object and cache-invalidation behavior.
- E10 shows the shared caller surface: `save()` and `bulk_create()`.

## Domain And Assumptions

- The formalized field is a cached forward relation field with one target
  field, matching `ForeignKey` and `OneToOneField` behavior in this codebase.
- `field.empty_values` includes `None` and `""` through Django's base
  `Field.empty_values`.
- The issue's concrete primary key is a `CharField`, so `""` is the required
  non-`None` empty value.
- Manual assignment to `field.attname` that changes the value clears the cache
  through `ForeignKeyDeferredAttribute.__set__()`, so the refresh rule is only
  applied when the cached relation is still authoritative.
- No termination proof is attempted; the concrete-field collection is finite in
  Django model metadata.

## Formal Artifacts

- `mini-django-save.k` defines a mini relation-save transition semantics.
- `django-save-spec.k` defines reachability claims C1-C3 with provenance.
- `FORMAL_SPEC_ENGLISH.md` paraphrases those claims.
- `SPEC_AUDIT.md` checks the formal claims against this intent spec.
- `PUBLIC_COMPATIBILITY_AUDIT.md` checks the changed public surface.
