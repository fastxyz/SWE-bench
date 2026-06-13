# Baseline notes — django__django-16263

## Issue
`Book.objects.annotate(Count('chapters')).count()` produces a `COUNT(*)` query that
still includes the (unused) `Count('chapters')` annotation. This forces Django to wrap
the count in a subquery and emit a `GROUP BY`, even though the annotation is not
referenced by any filter, ordering, grouping, or other annotation, so it cannot change
the number of matched rows. The same waste happens for `exists()`. Annotations that are
not referenced should be stripped so that `count()` collapses to a plain
`SELECT COUNT(*) FROM <table>` (matching `Book.objects.count()`), and `exists()` no
longer emits a pointless `GROUP BY`.

## Root cause
* `QuerySet.count()` → `Query.get_count()` adds a `Count('*')` summary aggregate and
  calls `Query.get_aggregation()`. `get_aggregation()` decides whether a subquery is
  needed based on `existing_annotations` (every annotation except the just-added
  summary). Any leftover annotation makes that list non-empty, which forces the
  subquery branch; an aggregate annotation additionally forces a `GROUP BY` on the PK.
  The code never checks whether those annotations are actually *used*.
* `Query.exists()` unconditionally materialises `group_by is True` into the full list of
  model columns before clearing the SELECT, producing `SELECT 1 ... GROUP BY <all
  columns> LIMIT 1` even when the only reason `group_by` was `True` is an unused
  aggregate annotation.
* Stripping an annotation is not just a matter of removing it from the SELECT mask:
  relational annotations such as `Count('chapters')`/`Count('authors')` introduce JOINs
  (reference-counted via `alias_refcount`). If the annotation is dropped but the JOIN is
  left in place, `COUNT(*)` would count the (multiplied) joined rows and return a wrong
  result. The JOINs must be un-referenced as well.

## Changes (all in `django/db/models/sql/query.py`)

### New helper: `Query._gen_annotation_refs(exprs, annotations_by_id)`
Recursively yields the aliases of annotations referenced inside a set of expressions.
References are detected three ways: `Ref` (by `.refs`), `F` (by `.name`), and
annotation expressions embedded directly by object identity — which is how a filter on
an annotation stores it (`build_filter`/`solve_lookup_type` put the resolved annotation
object straight into the `WhereNode`). It deliberately stops at those nodes instead of
descending further; the transitive closure is handled by the caller. Because
`Query.get_source_expressions()` (inherited from `BaseExpression`) returns `[]`, the
recursion never descends into nested `Subquery`/`Exists` queries, so it only reports
references in the *outer* query.

### New helper: `Query._get_referenced_annotation_aliases(extra_exprs=())`
Returns the set of annotation aliases referenced by `extra_exprs`, the WHERE/HAVING
clause (`self.where`), the GROUP BY (when it is a tuple), the ordering (string names and
expressions), or — transitively — by other referenced annotations (fixed-point loop).
This is the precise definition of "used" annotations from the ticket ("not referenced by
filters, other annotations or ordering").

### New helper: `Query._unref_annotation_joins(annotation)`
Decrements `alias_refcount` for every JOIN an annotation introduced, by walking each of
its `Col`s up the `parent_alias` chain to (but excluding) the base table. Each `Col`
corresponds to exactly one `setup_joins()` call which reffed every join along that
column's path exactly once, so walking each column's chain undoes precisely this
annotation's contribution. Joins shared with kept clauses keep their own references and
survive; joins used only by the stripped annotation drop to refcount 0 and are omitted
from the FROM clause by the compiler (`get_from_clause` skips refcount‑0 aliases). The
base table is intentionally never un-reffed.

### New helper: `Query._strip_unused_annotations(exclude)`
Computes the referenced set (seeding with the source expressions of the annotations in
`exclude` — e.g. the count's `__count` aggregate — and of any *unselected* annotations,
which are always kept, so their references must be preserved). It then deletes every
*selected* annotation that is neither in `exclude` nor referenced, un-refs its joins, and
updates the annotation mask. It is a no-op when there are no annotations or when a
combinator (UNION/INTERSECT/…) is present.

### `Query.get_count()`
After adding the `Count('*')` summary, calls `obj._strip_unused_annotations({"__count"})`
before `get_aggregation()`. With the unused annotations (and their joins) gone,
`get_aggregation()`'s `existing_annotations` is empty for the headline case, so it takes
the non-subquery branch and emits `SELECT COUNT(*) FROM book`.

### `Query.exists()`
When `group_by is True`, it now expands the GROUP BY (previous behaviour) only if a
combinator is present or if a *referenced* annotation is an aggregate (i.e. a HAVING
needs the grouping). Otherwise it sets `group_by = None`, dropping the unnecessary
`GROUP BY`. Existence of a result set is invariant under grouping, so this is always
correct.

## Key design decisions / scope
* **Stripping is scoped to `count()` (`get_count`), not to general `aggregate()`.**
  `get_aggregation()` is shared by `QuerySet.aggregate()`, whose results can legitimately
  depend on the current (even multiplying) join behaviour of unreferenced annotations;
  many existing tests rely on it. Doing the stripping inside `get_count` (deleting the
  unused annotations from the cloned query *before* calling `get_aggregation`) keeps
  `aggregate()` behaviour byte-for-byte identical while still fixing `count()`.
  `get_aggregation()` itself was left unchanged.
* **Only *selected* annotations are stripped.** Unselected annotations (e.g. those masked
  out by `values()` or added via `alias()`) are preserved, matching current behaviour and
  avoiding having to reason about their grouping/multiplication semantics.
* **JOIN removal is required for correctness, not just optimisation** — confirmed by
  existing tests such as `aggregation_regress.test_more`
  (`Book.objects.annotate(num_authors=Count("authors")).count() == 6`). Leaving the M2M
  join would multiply the count.

## Alternatives considered and rejected
* **Strip inside `get_aggregation()` (affecting `aggregate()` too).** First attempt;
  rejected because it changes `aggregate()` results for unreferenced multi-valued
  annotations (the classic multi-join multiplication), risking many existing
  `annotate(...).aggregate(...)` tests.
* **Only mask the annotation out of the SELECT (no JOIN un-reffing).** Rejected: leaves
  the relational JOIN in place, so `SELECT COUNT(*) FROM book LEFT JOIN ...` counts
  multiplied rows and returns the wrong number.
* **Keep the subquery but drop only the GROUP BY (PR 11062 style).** Already present in
  this codebase for non-aggregate annotations; it is "good enough" for some cases but the
  ticket explicitly asks to eliminate unneeded annotations entirely, and it does not help
  the aggregate-with-join case the issue cites.
* **Track references by `Ref` name only.** Rejected: filters embed the resolved
  annotation object directly (not a `Ref`), so identity-based detection is also required.

## Assumptions
* Within `get_count`/`exists` the query has only been `clone()`d (shallow annotation copy;
  `WhereNode.clone()` does not clone leaf `Lookup`s), so an annotation object in the WHERE
  clause is identical (by `id`) to the one in `self.annotations` — making identity-based
  reference detection reliable at this point.
* `OuterRef` resolves to a `ResolvedOuterRef` without creating a JOIN in the outer query
  at annotation time, so a pure `Subquery`/`Exists` annotation owns no outer joins; thus
  it is safe that `_gen_cols` reports none for it (verified against
  `aggregation.tests` `test_aggregation_subquery_annotation_*`,
  `Author.objects.annotate(Subquery(...)).annotate(Count("book")).count() ==
  Author.objects.count()`).
* `combinator` queries are left untouched (conservative) since SELECT-column alignment
  across combined queries makes annotation pruning unsafe and is outside the ticket's
  scope.
