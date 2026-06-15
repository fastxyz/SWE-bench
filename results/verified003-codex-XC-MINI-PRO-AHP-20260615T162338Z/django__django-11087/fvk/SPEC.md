# FVK Specification: delete() Required-Field Collection

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is Django's deletion collector behavior when it must
materialize objects to build a deletion graph. The observable under proof is the
set of concrete model fields requested for immediate loading from each queryset.

Functions and methods in scope:

- `Collector._has_signal_listeners()`
- `Collector._delete_fields()`
- `Collector._can_optimize_delete_queryset()`
- `Collector._optimize_delete_queryset()`
- `Collector.can_fast_delete()`, only for the shared signal-listener predicate
- `Collector.collect()`, only for the point where an unevaluated queryset is
  materialized
- `Collector.related_objects()`
- `NestedObjects._can_optimize_delete_queryset()`

Out of scope, but framed as unchanged: delete ordering, batching, SQL `DELETE`
execution, field-update execution, `bulk_related_objects()` hooks, signal
emission, and querysets that are already evaluated or are not querysets.

## Public Intent Ledger

E1. Source: `benchmark/PROBLEM.md`

Quoted evidence: "Optimize .delete() to use only required fields."

Semantic obligation: A delete traversal should not fetch unrelated concrete
model fields when the collector only needs identifiers and relation keys.

Status: encoded in O1, C1, C2.

E2. Source: `benchmark/PROBLEM.md`

Quoted evidence: "the UnicodeDecodeError is occurring for a field
(`text_log_error.line`) that is not actually needed for the .delete() ... Django
shouldn't be fetching that field regardless when making the text_log_error
SELECT query"

Semantic obligation: For related objects traversed only to cascade deletion,
non-referenced concrete fields must be deferred so corrupt unrelated data is not
decoded.

Status: encoded in O1 and C2.

E3. Source: `benchmark/PROBLEM.md`

Quoted evidence: "additional fields being selected were from a model different
to the one on which the .delete() was being called"

Semantic obligation: The optimization must apply to nested related querysets,
not only the root queryset.

Status: encoded in O2 and C4.

E4. Source: `benchmark/PROBLEM.md`

Quoted evidence: "Group.objects.all().delete() SELECT
`auth_group`.`id`, `auth_group`.`name` ... Oops, all fields selected" and
"Group.objects.only('id').delete() SELECT `auth_group`.`id` ... Yay!"

Semantic obligation: The root queryset should be projected to the required field
set by default when this is safe.

Status: encoded in O2 and C3.

E5. Source: `benchmark/PROBLEM.md`

Quoted evidence: "Non-primary key references (aka ForeignKey(to_field)) works
appropriately."

Semantic obligation: A source model's required field set must include any
non-primary key target fields needed to query reverse relations.

Status: encoded in O3 and C1.

E6. Source: `benchmark/PROBLEM.md`

Quoted evidence: "The optimization is disabled when receivers are connected for
deletion signals" and the discussion that signal receivers prevent safe
introspection.

Semantic obligation: If delete-related listeners may inspect arbitrary instance
fields, the collector must not add a new projection for that model.

Status: encoded in O4 and C5.

E7. Source: `repo/django/contrib/admin/utils.py`

Quoted evidence: `NestedObjects.can_fast_delete()` says "We always want to load
the objects into memory so that we can display them to the user in confirm
page."

Semantic obligation: Admin deletion preview must not receive the narrowed
querysets intended for production delete traversal.

Status: encoded in O5 and C6.

## Intent-Only Obligations

O1. For a model `M` with no relevant signal listeners, if delete collection must
materialize an unevaluated queryset of `M`, all concrete fields outside the
collector-required set are deferred.

O2. The optimization applies both to the initial queryset entering
`Collector.collect()` and to querysets produced by `Collector.related_objects()`
before truthiness can evaluate them.

O3. The collector-required set for recursive cascade collection is:

- `M`'s primary key attname;
- concrete parent fields when parent instances must be materialized for
  multi-table inheritance;
- for each reverse candidate relation that is not `DO_NOTHING`, every
  `foreign_related_field.attname` used to filter related objects, including
  `ForeignKey(to_field=...)` targets.

O4. If a model has relevant signal listeners, the collector leaves the queryset
projection unchanged.

O5. Admin `NestedObjects` is a display collector, not the production delete
collector; it must opt out of the required-field optimization.

O6. Fast-delete behavior, already evaluated querysets, list inputs, generic
relation hooks, deletion order, and signal/field-update side effects are framed
unchanged.

## Formal Model

The mini-model abstracts Django metadata and querysets to the minimum property
axis under audit: immediate field projection.

Definitions:

- `Concrete(M)` is the ordered list of concrete field attnames for model `M`.
- `PK(M)` is the primary-key attname of `M`.
- `Parents(M)` is the set of concrete parent fields needed to materialize parent
  objects for multi-table inheritance.
- `Refs(M)` is the set of `foreign_related_fields` for all non-`DO_NOTHING`
  reverse candidate relations of `M`.
- `Signals(M)` is true when `pre_delete`, `post_delete`, or `m2m_changed` has a
  listener for `M`.
- `Required(M, collect_related, keep_parents)` is the `Concrete(M)`-ordered
  projection of:

```text
{PK(M)}
union (Parents(M) if not keep_parents else empty)
union (Refs(M) if collect_related else empty)
```

- `CanOptimize(collector, M)` is false for `NestedObjects`, false when
  `Signals(M)` is true, and true otherwise.

Constructed K-style claims, paraphrased:

C1. Required-field construction:

```k
claim Required(M, CR, KP)
  => orderedConcreteFilter(Concrete(M), PK(M) union parentFields(M, KP) union refFields(M, CR))
```

C2. Queryset optimization:

```k
claim optimize(QS(M, Unevaluated), CR, KP, Collector)
  => QSOnly(M, Required(M, CR, KP))
  requires CanOptimize(Collector, M)
```

C3. Optimization opt-out:

```k
claim optimize(QS(M, State), CR, KP, Collector)
  => QS(M, State)
  requires notBool CanOptimize(Collector, M)
```

C4. `collect()` materialization:

```k
claim collect(QS(M, Unevaluated), CR, KP, Collector)
  => collect(add(evaluate(QSOnly(M, Required(M, CR, KP)))), CR, KP, Collector)
  requires CanOptimize(Collector, M)
```

C5. Related queryset projection:

```k
claim relatedObjects(Rel(onDelete: CASCADE, child: C), Parents, Collector)
  => QSOnly(C, Required(C, true, false))
  requires CanOptimize(Collector, C)

claim relatedObjects(Rel(onDelete: NonCascade, child: C), Parents, Collector)
  => QSOnly(C, Required(C, false, true))
  requires CanOptimize(Collector, C)
```

C6. Admin display collector:

```k
claim CanOptimize(NestedObjects, M) => false
```

These claims are constructed, not machine-checked. The exact `kompile` and
`kprove` commands are recorded in `fvk/PROOF.md`.

## Adequacy Audit

The formal model preserves the property under test because a passing instance
and a failing instance differ in the model:

- Passing instance: `TextLogError` has concrete fields `[id, step_id, line,
  line_number]`, no signal listeners, no child cascade refs, and is reached by a
  `CASCADE`; `Required(TextLogError, true, false) = [id]`, so `line` is not
  immediately loaded.
- Failing legacy instance: the same model is materialized without `QSOnly`, so
  all concrete fields, including `line`, are immediately loaded.

The model deliberately does not prove SQL execution, database decoding, or
termination. It proves the collector-side projection decision that prevents
unneeded field decoding.
