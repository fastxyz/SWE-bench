# FVK Findings

Status: constructed, not machine-checked. Findings were produced by static
intent/code/proof-obligation review only.

## F1: V1 optimized the admin display collector

Classification: code bug in V1, fixed in V2.

Evidence:

- `SPEC.md` E7 records the public code comment in
  `NestedObjects.can_fast_delete()`: admin deletion confirmation wants loaded
  objects for display.
- `NestedObjects.related_objects()` calls `super().related_objects()` and then
  `select_related(related.field.name)`.
- V1 changed `Collector.related_objects()` so `super().related_objects()` could
  return an `only()` queryset.

Concrete input:

`NestedObjects.collect()` over a parent object with a cascading child relation
where the child is displayed in the admin confirmation page.

Observed in V1 by static control flow:

`NestedObjects.related_objects()` received a queryset narrowed by
`Collector.related_objects()` and then added `select_related()` for the parent
relation. That could produce partially loaded display objects and can conflict
with `select_related()` if the relation connector field is deferred.

Expected:

Admin display collection should preserve full object loading, while production
delete collection should still use required-field projection.

Resolution:

Added `Collector._can_optimize_delete_queryset()` and overrode it in
`NestedObjects` to return `False`.

Proof obligations:

PO5 and PO8 in `PROOF_OBLIGATIONS.md`.

## F2: V1 returned required fields from an unordered set

Classification: robustness issue in V1, fixed in V2.

Evidence:

- `SPEC.md` O1/O3 require a field projection, but not an arbitrary output order.
- Django's model metadata has an ordered `opts.concrete_fields` list.

Concrete input:

A model whose required field set contains multiple attnames, such as a model
with a primary key plus a non-primary-key `to_field` reference.

Observed in V1 by static control flow:

`_delete_fields()` accumulated a `set` and passed it to `QuerySet.only()` via
argument expansion.

Expected:

The field set should be stable and deterministic, preferably matching model
concrete field order.

Resolution:

`_delete_fields()` now filters `opts.concrete_fields` by membership in the
required set and returns the ordered list of attnames.

Proof obligations:

PO1 and PO7 in `PROOF_OBLIGATIONS.md`.

## F3: Generic relation hooks remain unoptimized

Classification: residual proof boundary, accepted.

Evidence:

- `Collector.collect()` delegates private fields with `bulk_related_objects()`
  to the field implementation.
- `GenericRelation.bulk_related_objects()` constructs its own queryset.
- `SPEC.md` O6 frames generic relation hooks unchanged.

Concrete input:

A delete traversal through a private field implementing `bulk_related_objects()`
that returns a queryset selecting all model fields.

Observed:

This patch does not inject `only()` into that field-specific hook.

Expected under this spec:

No change. The collector cannot infer a safe field projection for arbitrary
field hook implementations without a separate API or hook-specific audit.

Recommended next iteration:

Audit generic relation hooks separately if public intent expands from normal
reverse FK/O2O delete traversal to arbitrary private relation hooks.

Proof obligations:

PO9 records this frame condition.

## F4: Query annotations and extra select columns are not modeled

Classification: residual scope boundary, not changed.

Evidence:

- The public issue and hints discuss concrete model fields selected during
  deletion traversal.
- `QuerySet.only()` controls concrete model field loading; it does not by
  itself remove user-requested annotation or `extra(select=...)` output.

Concrete input:

An annotated queryset whose annotation expression decodes a corrupt text column
and is then deleted.

Observed:

The V2 patch does not clear annotations or extra select clauses before deletion
collection.

Expected under this spec:

No claim. This is outside the field-projection obligation derived from the
public issue and would require a separate compatibility audit because
annotations may participate in filters or HAVING clauses.

Recommended next iteration:

If public intent is broadened to "delete collection selects no unnecessary SQL
outputs at all," audit annotation masks and `extra(select=...)` handling in
`QuerySet.delete()`.

Proof obligations:

PO9 records this frame condition.

## F5: Custom `on_delete` callables may inspect deferred fields

Classification: residual behavioral boundary, accepted.

Evidence:

- Public intent specifically names cascade graph traversal, `PROTECT`, field
  updates, non-primary-key references, and delete-signal receivers.
- Django allows arbitrary `on_delete` callables.

Concrete input:

A custom non-`CASCADE` `on_delete` callable that reads an unrelated concrete
field from `sub_objs`.

Observed:

V2 may defer that unrelated field for the queryset passed to the callable. If
the callable reads it, Django's deferred-field machinery will issue a lazy load.

Expected under this spec:

The concrete value remains available by normal deferred loading. Query-count
preservation for custom callables is not part of the public issue intent.

Recommended next iteration:

If custom `on_delete` query-count compatibility is required, add public API
documentation and a collector hook for custom handlers to opt out of projection.

Proof obligations:

PO6 and PO9 record the accepted boundary.
