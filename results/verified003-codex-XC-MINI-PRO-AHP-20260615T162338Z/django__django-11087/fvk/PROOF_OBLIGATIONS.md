# Proof Obligations

Status: constructed, not machine-checked. These obligations are reasoned about
statically and are not discharged by running `kprove`.

## PO1: Required field set is complete for collector reads

Claim:

For any model `M`, `_delete_fields(M, collect_related, keep_parents)` includes
every concrete field value that `Collector.collect()` may read from instances of
`M` while building the deletion graph under those flags.

Required evidence:

- `PK(M)` is included for hashing/equality, delete batches, field updates, and
  instance identity.
- Parent concrete fields are included when `keep_parents` is false because
  `collect()` materializes parent objects through parent-link descriptors.
- Reverse relation target fields are included when `collect_related` is true
  because `related_objects()` filters with `related.field.name__in=batch`, and
  object-instance filtering needs `related.field.foreign_related_fields`,
  including `ForeignKey(to_field=...)` targets.

Status: discharged by static inspection of `deletion.py` and related field
metadata.

Related findings: F2.

## PO2: Required field set excludes non-required concrete fields

Claim:

If a concrete field attname is not the primary key, not a needed parent concrete
field, and not a reverse-relation foreign target under the current collection
mode, it is absent from `_delete_fields()`.

Required evidence:

- `_delete_fields()` accumulates only those three categories.
- It returns only attnames present in `opts.concrete_fields`.

Status: discharged by static inspection.

Related findings: F3, F4 for residual paths outside this claim.

## PO3: `only()` enforces immediate-load projection for concrete fields

Claim:

For a Django queryset `qs`, `qs.only(*fields)` causes concrete model fields not
listed in `fields` to be deferred, while preserving access through Django's
normal deferred-field machinery.

Required evidence:

- `QuerySet.only()` calls `query.add_immediate_loading(fields)`.
- `Options.get_field()` maps both field names and attnames for concrete fields.
- The SQL compiler's deferred-loading path computes selected columns from the
  immediate-loading field set.

Status: discharged by static inspection of `query.py`, `query.sql`, and
`options.py`.

Related findings: F4, F5 for values outside concrete field projection.

## PO4: Optimization is applied before queryset truthiness evaluation

Claim:

For unevaluated querysets entering `collect()` or produced by
`related_objects()`, the projection is applied before `bool(qs)` or iteration
can fetch rows.

Required evidence:

- `collect()` calls `_optimize_delete_queryset()` before `self.add(objs, ...)`
  when `objs` is an unevaluated queryset.
- `related_objects()` calls `_optimize_delete_queryset()` immediately after
  constructing the filtered queryset and before returning it to the branch that
  evaluates `elif sub_objs:`.
- Already evaluated querysets are explicitly framed unchanged by the
  `_result_cache is None` guard.

Status: discharged by static inspection.

Related findings: none.

## PO5: Signal-listener opt-out preserves full instances

Claim:

If `pre_delete`, `post_delete`, or `m2m_changed` has listeners for a model, the
new optimization is not applied to querysets for that model.

Required evidence:

- `_has_signal_listeners()` checks the same three signal predicates previously
  embedded in `can_fast_delete()`.
- `_can_optimize_delete_queryset()` returns `False` when
  `_has_signal_listeners(queryset.model)` is true.
- `_optimize_delete_queryset()` returns the original queryset when
  `_can_optimize_delete_queryset()` is false.

Status: discharged by static inspection.

Related findings: none.

## PO6: Related queryset mode matches on_delete behavior

Claim:

`Collector.related_objects()` uses the recursive cascade field set only when the
relation's `on_delete` handler is `CASCADE`; otherwise it uses the primary-key
only field set.

Required evidence:

- The CASCADE branch calls `_optimize_delete_queryset(qs, collect_related=True,
  keep_parents=False)`.
- The non-CASCADE branch calls `_optimize_delete_queryset(qs,
  collect_related=False, keep_parents=True)`.
- Built-in non-CASCADE handlers used by the collector (`PROTECT`, `SET_NULL`,
  `SET_DEFAULT`, `SET(...)`) only require truthiness/class identity and primary
  keys for protected-object reporting or update batches.

Status: discharged for built-in handlers by static inspection; custom callable
query-count behavior remains a boundary.

Related findings: F5.

## PO7: Field projection order is deterministic

Claim:

The field list passed to `only()` is deterministic and follows model concrete
field order.

Required evidence:

- `_delete_fields()` returns a list comprehension over `opts.concrete_fields`
  filtered by membership in the required set.

Status: discharged by static inspection.

Related findings: F2.

## PO8: Admin `NestedObjects` opts out of projection

Claim:

The admin display collector never receives the new `only()` projection from the
base collector.

Required evidence:

- `NestedObjects._can_optimize_delete_queryset()` returns `False`.
- `Collector._optimize_delete_queryset()` consults dynamic dispatch through
  `self._can_optimize_delete_queryset(queryset)`.
- `NestedObjects.related_objects()` can therefore call `super().related_objects()`
  and then `select_related()` without a projection conflict.

Status: discharged by static inspection.

Related findings: F1.

## PO9: Frame conditions are preserved

Claim:

The patch does not change behavior outside the selected-field projection
decision.

Required evidence:

- `can_fast_delete()` uses the same signal predicate as before, now via a helper.
- Fast-delete querysets are returned before projection is applied in `collect()`.
- Delete ordering, dependency tracking, field updates, signal sending, raw
  deletes, and `bulk_related_objects()` traversal are unchanged by the diff.

Status: discharged by static diff inspection.

Related findings: F3, F4, F5.

## PO10: Constructed K commands

The FVK proof was not machine-checked. If the abstract K model were written out
as standalone files, the expected commands would be:

```sh
kompile fvk/mini-delete.k --backend haskell
kast --backend haskell fvk/delete-collector-spec.k
kprove fvk/delete-collector-spec.k
```

Expected result after completing the standalone K files: `#Top`.
