# FVK Spec

Status: constructed, not machine-checked.

## Target

Audit V1 for `django__django-16256`: async `acreate()`,
`aget_or_create()`, and `aupdate_or_create()` on related managers must dispatch
to the related manager's synchronous methods instead of to copied queryset proxy
methods.

Primary source files under audit:

- `repo/django/db/models/manager.py`
- `repo/django/db/models/query.py`
- `repo/django/db/models/fields/related_descriptors.py`
- `repo/django/contrib/contenttypes/fields.py`

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical
entries are:

- E1-E2: the issue requires proper async methods on related managers and
  specifically rejects queryset-proxy dispatch.
- E4: `BaseManager._get_queryset_methods()` explains the pre-fix bypass:
  copied manager methods call `self.get_queryset()`.
- E5-E7: reverse FK and many-to-many sync related methods define the
  relation-specific behavior that async must preserve.
- E8: generic related managers have the same relation-specific sync method
  shape and public tests for that behavior.
- E9: normal queryset/manager async methods must remain unchanged.
- E10: new mutating async methods should be marked `alters_data = True`.

## Domain and preconditions

For each related manager family:

- reverse many-to-one managers from `create_reverse_many_to_one_manager()`;
- many-to-many managers from `create_forward_many_to_many_manager()`;
- generic relation managers from `create_generic_related_manager()`;

and each operation:

- `acreate()`;
- `aget_or_create()`;
- `aupdate_or_create()`;

the intended input domain is any argument set accepted by the corresponding
synchronous related-manager method. The async wrapper must preserve the sync
method's existing preconditions, exceptions, router decisions, database writes,
and return shape.

## Postconditions

P1. Reverse many-to-one async methods delegate to
`sync_to_async(self.create)`, `sync_to_async(self.get_or_create)`, and
`sync_to_async(self.update_or_create)` respectively. The observable effect is
the reverse related manager sync effect, including foreign-key injection.

P2. Many-to-many async methods delegate to the many-to-many related manager
sync methods. The observable effect includes relation linking through `add()`.
For all three methods, `through_defaults` is forwarded unchanged.

P3. Generic relation async methods delegate to the generic related manager sync
methods. The observable effect includes content type and object id population.

P4. Plain manager/queryset async behavior remains on the existing queryset
proxy path. V1 must not depend on a global rewrite of
`BaseManager._get_queryset_methods()`.

P5. New related-manager async methods are marked with `alters_data = True`.

## Formal core

The K semantics fragment is `fvk/mini-related-manager.k`; the claims are in
`fvk/related-manager-async-spec.k`.

The model intentionally abstracts database internals into observable effects:
`reverseFkEffect`, `manyToManyEffect`, and `genericEffect`. This abstraction is
property-complete for the issue because it distinguishes the failing pre-fix
path (`querysetProxyEffect`) from the required related-manager sync path, and
it preserves the many-to-many `through_defaults` value as part of the
observable result.

## Adequacy

Intent-only obligations are in `fvk/INTENT_SPEC.md`; the formal English
paraphrase is in `fvk/FORMAL_SPEC_ENGLISH.md`; the adequacy comparison is in
`fvk/SPEC_AUDIT.md`; compatibility is in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

All formal claims pass the adequacy audit. No source edit beyond V1 is required
by this FVK pass.

