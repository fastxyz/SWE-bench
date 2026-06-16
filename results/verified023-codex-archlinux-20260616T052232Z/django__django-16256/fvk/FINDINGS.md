# FVK Findings

Status: constructed, not machine-checked.

## Resolved findings

F1. Reverse many-to-one async dispatch bypassed relation-specific sync behavior
before V1.

- Input: `parent.children.acreate(**kwargs)`,
  `parent.children.aget_or_create(**kwargs)`, or
  `parent.children.aupdate_or_create(**kwargs)`.
- Pre-fix observed behavior by source reasoning: the inherited manager proxy
  from `BaseManager._get_queryset_methods()` called
  `self.get_queryset().<async method>(...)`, so the queryset method was used.
- Expected behavior: dispatch to the reverse related manager sync method, which
  checks the FK value, injects `self.instance` into the FK field, and chooses
  the write database with the bound instance.
- V1 status: fixed by local async wrappers in
  `repo/django/db/models/fields/related_descriptors.py`.
- Proof obligation: PO1.

F2. Many-to-many async dispatch bypassed relation linking and
`through_defaults` before V1.

- Input: `obj.m2m.acreate(..., through_defaults=T)`,
  `obj.m2m.aget_or_create(..., through_defaults=T)`, or
  `obj.m2m.aupdate_or_create(..., through_defaults=T)`.
- Pre-fix observed behavior by source reasoning: inherited async manager proxy
  dispatched to the queryset path, which does not perform the related
  manager's `add()` step.
- Expected behavior: dispatch to the many-to-many related manager sync method,
  adding newly created objects to the relation and forwarding the same
  `through_defaults` value.
- V1 status: fixed by local async wrappers in
  `repo/django/db/models/fields/related_descriptors.py`.
- Proof obligation: PO2.

F3. Generic related managers had the same async dispatch bypass.

- Input: `obj.tags.acreate(**kwargs)`,
  `obj.tags.aget_or_create(**kwargs)`, or
  `obj.tags.aupdate_or_create(**kwargs)` for a `GenericRelation` manager.
- Pre-fix observed behavior by source reasoning: the generated generic related
  manager had sync relation-specific methods but no local async wrappers, so
  copied queryset proxy dispatch could bypass content type and object id
  population.
- Expected behavior: dispatch to the generic related manager sync method.
- V1 status: fixed by local async wrappers in
  `repo/django/contrib/contenttypes/fields.py`.
- Proof obligation: PO3.

F4. A global `BaseManager` change would be over-broad.

- Input: normal manager/queryset async calls such as `Model.objects.acreate()`.
- Observed public intent: the issue is specific to related managers, while
  public async queryset tests cover normal manager/queryset async methods.
- Expected behavior: leave normal manager/queryset async dispatch unchanged.
- V1 status: satisfied; V1 adds local related-manager overrides and does not
  edit `BaseManager`, `Manager`, or `QuerySet`.
- Proof obligation: PO4.

## Open findings

None. The audit did not surface a source change beyond V1.

## Proof-derived caveats

The proof is constructed over an abstract dispatch semantics and was not
machine-checked with K tooling. It establishes the intended dispatch shape
under the model, not database execution, transaction behavior, or termination.
Those behaviors are intentionally delegated to the existing synchronous related
manager methods.

