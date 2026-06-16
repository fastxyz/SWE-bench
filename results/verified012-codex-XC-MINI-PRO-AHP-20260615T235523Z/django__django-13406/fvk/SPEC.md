# FVK Spec for django__django-13406

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Scope

This FVK pass audits the V1 source change in `repo/django/db/models/query.py` for the documented workflow:

1. Build a `QuerySet` with `values()` or `values_list()`.
2. Pickle and unpickle its `query` attribute.
3. Assign that query to a fresh queryset with `qs.query = query`.
4. Evaluate the fresh queryset.

The verified observable is result shape: dicts for `values()`, tuples/scalars/namedtuples for the `values_list()` variants, and no fallback to `ModelIterable` for selected values rows.

## Public Intent Ledger

E1. Source: issue, `benchmark/PROBLEM.md:3`.
Quote: "Queryset with values()/values_list() crashes when recreated from a pickled query."
Obligation: restoring a pickled selected-values query must not evaluate through `ModelIterable`.
Status: encoded by `ASSIGN-MARKED-SELECT` and `ASSIGN-UNMARKED-SELECT`.

E2. Source: issue, `benchmark/PROBLEM.md:6-7`.
Quote: "pickling query objects (queryset.query) for later re-evaluation" and "the result ... should be a list of dicts".
Obligation: the documented query-pickle workflow must preserve `values()` result form when re-evaluated.
Status: encoded by `VALUES-MARKS` and `ASSIGN-MARKED-SELECT`.

E3. Source: issue reproduction, `benchmark/PROBLEM.md:22-29`.
Quote: `prices = Toy.objects.values('material').annotate(...)`, `prices2.query = pickle.loads(...)`, and `type(prices2[0])` is a model class.
Obligation: a `values().annotate()` query assigned to a fresh queryset must evaluate using `ValuesIterable`.
Status: encoded by the marked-query path and covered by proof obligation PO3.

E4. Source: public hint, `benchmark/PROBLEM.md:51`.
Quote: "`_iterable_class` ... in case of .objects.all() ... ModelIterable, but when .values() is used, it should be ValuesIterable."
Obligation: the fix must restore the queryset iterable class from query state during `query` assignment.
Status: encoded by query-side iterable markers.

E5. Source: public hint, `benchmark/PROBLEM.md:53`.
Quote: "this will not respect values_list() with different classes (NamedValuesListIterable, FlatValuesListIterable, ValuesListIterable)."
Obligation: `values_list()` must preserve all three iterable variants, not collapse them to `ValuesIterable`.
Status: encoded by `VALUES-LIST-MARKS` and `ASSIGN-MARKED-SELECT`.

E6. Source: docs, `repo/docs/ref/models/querysets.txt:94-106`.
Quote: "pickle the `query` attribute" and "qs.query = query" and "safe (and fully supported)".
Obligation: the assignment setter is the public restoration point to repair.
Status: encoded by the setter proof obligations.

E7. Source: implementation, `repo/django/db/models/query.py:94-180`.
Quote: `ValuesIterable`, `ValuesListIterable`, `NamedValuesListIterable`, and `FlatValuesListIterable` define distinct row-shaping behavior.
Obligation: the formal observable must distinguish iterable class, not only SQL selection.
Status: encoded in the `Iterable` sort of `mini-django-query.k`.

## Intent-Only Contract

For any current-version `Query` produced by `QuerySet.values()`:

- the `Query` records that the intended iterable is `ValuesIterable`;
- the `Query` records the queryset fields used by `_fields`;
- assigning that `Query` to a fresh queryset restores `ValuesIterable` and the recorded fields before evaluation.

For any current-version `Query` produced by `QuerySet.values_list()`:

- tuple mode records `ValuesListIterable`;
- `flat=True` records `FlatValuesListIterable`;
- `named=True` records `NamedValuesListIterable`;
- assignment restores the exact recorded iterable and fields.

For a selected `Query` with no V1 metadata marker:

- assignment must not leave a fresh queryset at `ModelIterable`;
- the safe fallback is `ValuesIterable` with the query's selected names.

For a non-selected model `Query`:

- this patch preserves the pre-existing frame behavior: assignment stores the query and leaves iterable/field state unchanged.

## Formal Model

The K artifacts model only the result-shape protocol. SQL compilation, database rows, Python pickling byte layout, and actual iterator execution are abstracted away. This abstraction is property-complete for this issue because the failing and passing cases differ on the preserved observable `Iterable`:

- failing instance: selected query assigned to a fresh queryset leaves `ModelIterable`;
- passing instance: the same assignment yields `ValuesIterable`, `ValuesListIterable`, `FlatValuesListIterable`, or `NamedValuesListIterable` as appropriate.

See `fvk/mini-django-query.k` and `fvk/django-queryset-query-spec.k`.

## Adequacy Summary

The formal claims match the intent:

- They prove marker creation for `values()` and all `values_list()` modes.
- They prove the `query` setter restores exact marked result shape.
- They prove selected unmarked queries fall back to a non-model values iterable.
- They do not claim exact recovery of `values_list(flat=True)` or `values_list(named=True)` from old/unmarked query pickles, because the public evidence and source state provide no way to infer those variants without a marker.

## Public Compatibility Audit

Changed public symbol: `QuerySet.query` setter behavior.

- Signature: unchanged.
- Documented callsite: `qs.query = query` in `repo/docs/ref/models/querysets.txt:99-102`; now selected values queries restore result shape.
- In-tree public-style callsites: `repo/tests/queryset_pickle/tests.py:284` and `:297` assign model queries; no selected-query marker is present on the outer query, so the frame path leaves behavior unchanged.
- Subclass/override audit: no `QuerySet.query` setter override was found in `repo/django` by static search.
- Producer/consumer shape: V1 adds private attributes to `Query` instances created by `values()`/`values_list()`. `Query.clone()` copies `__dict__` at `repo/django/db/models/sql/query.py:295-296`, so the marker survives normal ORM cloning. Python pickle preserves instance attributes by default; no custom `Query.__getstate__` was found.

Conclusion: no additional source edit is justified by public compatibility evidence.

