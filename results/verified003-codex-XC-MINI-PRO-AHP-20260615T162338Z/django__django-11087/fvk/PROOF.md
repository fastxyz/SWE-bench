# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What is proved

For the production `Collector`, every unevaluated queryset materialized by the
delete collector is either:

- left unchanged because optimization is unsafe or inapplicable; or
- narrowed with `only()` to the concrete fields required for the collector's
  deletion traversal under the current mode.

For admin `NestedObjects`, the optimization is disabled so display collection
continues to receive full querysets.

This is a partial-correctness proof over field projection decisions. It does not
prove SQL execution, database decoding, delete termination, or query planner
behavior.

## Proof sketch

### Lemma L1: Required fields are complete

From `PROOF_OBLIGATIONS.md` PO1:

`_delete_fields()` starts with the primary key. The collector always needs the
primary key for object identity, set membership, field-update batches, and delete
batches.

If parents are not kept, `_delete_fields()` includes every concrete field from
each concrete parent model reached by the parent link. This is sufficient for
the current parent materialization path, which calls `getattr(obj, ptr.name)`.

If related objects are collected, `_delete_fields()` includes every
`foreign_related_field.attname` for every non-`DO_NOTHING` reverse candidate
relation. These are exactly the fields needed when Django filters related
objects with `related.field.name__in=batch`, including non-primary-key
`to_field` references.

Therefore every field the collector may read from a materialized instance is in
`Required(M, collect_related, keep_parents)`.

### Lemma L2: Non-required concrete fields are excluded

From PO2 and PO7:

The only entries added to the internal required set are primary key, parent
concrete fields, and reverse relation target fields. The return value filters
`opts.concrete_fields` by membership in that set. Therefore any other concrete
field is absent, and the resulting list is deterministic in model field order.

### Lemma L3: `only()` implements the projection

From PO3:

`QuerySet.only(*fields)` records an immediate-loading set. Django's query
compiler converts that set into selected concrete columns and defers other
concrete fields. Since `_delete_fields()` returns attnames that `Options` maps
to concrete fields, the projection is well-formed.

### Lemma L4: Projection happens before fetch

From PO4:

`collect()` checks for an unevaluated queryset before `self.add()` can iterate
it. `related_objects()` applies the projection before returning the queryset to
the `elif sub_objs:` truthiness check. Thus the first fetch of normal root and
nested related querysets uses the narrowed immediate-loading set.

### Lemma L5: Unsafe collectors and signal-visible models are framed unchanged

From PO5 and PO8:

The production collector's `_can_optimize_delete_queryset()` returns false when
there are relevant listeners. `_optimize_delete_queryset()` returns the original
queryset in that case, so signal receivers are not exposed to a new projection.

`NestedObjects` overrides `_can_optimize_delete_queryset()` to return false for
all models. Dynamic dispatch ensures calls from the base collector use this
override. Therefore admin deletion preview is unchanged with respect to field
projection.

### Lemma L6: Related queryset mode matches collector use

From PO6:

For `CASCADE`, related objects may themselves be recursively collected, so the
recursive required-field set is used. For non-`CASCADE`, the collector only
needs primary keys for built-in protected-object handling and field updates, so
`collect_related=False, keep_parents=True` is sufficient.

## Main theorem

For every normal delete-collector path covered by `SPEC.md`:

1. If the queryset can be fast-deleted, `collect()` appends it to
   `fast_deletes` and returns before materialization, preserving prior behavior.
2. If the input is not an unevaluated queryset, the new projection path is not
   taken, preserving prior behavior.
3. If the input is an unevaluated queryset and optimization is disabled, the
   queryset is returned unchanged by `_optimize_delete_queryset()`.
4. If the input is an unevaluated queryset and optimization is enabled, Lemmas
   L1-L4 show that the first materialization loads all collector-required
   fields and defers every non-required concrete field.
5. Lemma L5 preserves signal-visible and admin display behavior.
6. Lemma L6 covers nested related querysets for cascade and non-cascade
   handlers.

Therefore the V2 code satisfies O1-O6 from `SPEC.md`: delete collection fetches
only required concrete fields where safe, handles nested relations and
`to_field` references, disables optimization for signal-visible models, opts
admin display collection out, and preserves framed behavior.

## Proof-derived findings

The proof attempt found two V1 issues:

- F1: admin `NestedObjects` needed an explicit opt-out from the projection.
- F2: `_delete_fields()` should return deterministic model field order.

Both are fixed in V2. Residual boundaries F3-F5 are outside this spec and are
recorded in `FINDINGS.md`.

## Machine-check commands

The benchmark forbids running K tooling. The commands below are recorded for a
future environment where the abstract K files are completed and can be checked:

```sh
kompile fvk/mini-delete.k --backend haskell
kast --backend haskell fvk/delete-collector-spec.k
kprove fvk/delete-collector-spec.k
```

Expected machine-check result: `#Top`.

Until those commands are run successfully, this remains a constructed proof, not
a machine-checked proof. No test deletion is recommended.
