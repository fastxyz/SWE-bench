# Baseline notes — django__django-16263

## Issue

> **Strip unused annotations from count queries**
>
> `Book.objects.annotate(Count('chapters')).count()` produces SQL that includes
> the `Count('chapters')` annotation (and the join + GROUP BY it implies) even
> though it isn't used by any filter, ordering or other annotation. The result
> is identical to `Book.objects.count()`, so the annotation should be stripped.
> The same optimisation should apply to `exists()`.

## Root cause

`QuerySet.count()` → `Query.get_count()` → `Query.get_aggregation()` and
`QuerySet.exists()` → `Query.exists()` never removed annotations that have no
effect on the result.

* In `get_aggregation()` the presence of *any* existing annotation
  (`existing_annotations`) forces the aggregation into a wrapped subquery, and an
  aggregate annotation additionally injects a `GROUP BY`. For an unused
  annotation this is pure overhead (`SELECT COUNT(*) FROM (SELECT … FROM book
  LEFT OUTER JOIN chapter GROUP BY book.id)` instead of `SELECT COUNT(*) FROM
  book`).
* In `exists()` an aggregate annotation leaves `group_by` set to `True`, which
  forces a `GROUP BY` over every concrete column even though the annotation is
  masked out of the SELECT.

Simply masking the annotation out of the SELECT is not enough: the annotation is
still in `self.annotations` (so the subquery/GROUP BY is still produced) and, more
importantly, the *join* it introduced is still reference-counted, so it stays in
the `FROM` clause. Removing an annotation therefore also requires removing the
join it brought in — otherwise a one-to-many `LEFT OUTER JOIN` (e.g. to
`chapter`) would multiply rows and make `SELECT COUNT(*)` wrong.

## Fix

All changes are in `django/db/models/sql/query.py` (non-test source only).

Three new private `Query` helpers were added:

1. **`_referenced_annotations(roots=())`** — returns the set of annotation
   aliases that actually influence the result: those referenced by the `WHERE`
   clause, an explicit `GROUP BY` (from `values()`), the `ORDER BY` clause, the
   `roots` annotations (the aggregations being computed), or transitively by
   another referenced annotation.

   Detection covers the three ways an annotation can be referenced:
   * by identity — filters and inter-annotation references inline the *same*
     resolved expression object (`resolve_ref(..., summarize=False)` returns the
     annotation itself), so references are matched via `id(expr)`;
   * via `Ref` — aggregations over an existing annotation
     (`resolve_ref(..., summarize=True)`) and `values()`-driven `GROUP BY`
     entries use `Ref(alias, …)`;
   * via `F` — `order_by(F('alias'))` / `order_by('alias')` stay unresolved until
     compile time.

2. **`_trim_unused_joins()`** — after annotations are removed, drops the
   `LEFT OUTER` joins that are no longer referenced by any remaining part of the
   query (annotations, `WHERE`, `SELECT`, explicit `GROUP BY`), keeping the join
   chain (`parent_alias`) needed to reach used aliases and never touching the
   base table. Only `LOUTER` joins are trimmed because they can only *multiply*
   (never *filter*) result rows, so removing an unreferenced one is always safe
   for a count/exists/aggregate query even if the reference scan is conservative.
   This is what turns `FROM book LEFT OUTER JOIN chapter` back into `FROM book`.

3. **`_prune_unused_annotations(keep=())`** — orchestrates the above: computes
   the keep set, additionally keeps every *selected* annotation when the query is
   `distinct` (DISTINCT deduplicates over the SELECT list), deletes the rest from
   `self.annotations` (and the annotation mask), resets `group_by` from `True` to
   `None` when no aggregation remains (so the now-removed join isn't grouped
   over), and finally trims the orphaned joins. It is a no-op (returns `False`)
   when there are no annotations or when set operations are involved
   (`self.combinator`), to leave union/intersection counts untouched.

Wiring:

* `get_aggregation()` calls `self._prune_unused_annotations(added_aggregate_names)`
  right after the early `if not self.annotation_select` return and before
  `existing_annotations` is computed, so both `count()` and `aggregate()` benefit.
* `exists()` calls `q._prune_unused_annotations()` right after the clone, before
  the existing `group_by`/select-clearing logic (so the `group_by` reset lets it
  skip the unnecessary GROUP BY).

### Effect

* `Book.objects.annotate(Count('chapters')).count()` now compiles to
  `SELECT COUNT(*) AS "__count" FROM "book"` — byte-for-byte identical to
  `Book.objects.count()` (the join is trimmed, the GROUP BY/subquery elided).
* `Book.objects.annotate(Count('chapters')).exists()` now compiles to
  `SELECT (1) AS "a" FROM "book" LIMIT 1`.
* `aggregate()` strips unused annotations too, e.g.
  `Publisher.objects.annotate(avg_rating=Avg('book__rating')).aggregate(Sum('num_awards'))`
  drops the `book` join and the GROUP BY.

## Why this is correct (annotations that must be kept)

An annotation is removed only when nothing references it. Concretely it is kept
when it is:

* referenced by a filter/`HAVING` (e.g. `annotate(c=Count(...)).filter(c__gt=1)`)
  — needed for the subquery + GROUP BY semantics;
* referenced by the aggregate being computed
  (e.g. `annotate(c=Count(...)).aggregate(Avg('c'))`);
* referenced by another kept annotation (transitive closure);
* part of an explicit `GROUP BY` produced by `values()`
  (`values('x').annotate(c=Count(...))` keeps the grouping; only `c` is dropped,
  and the count stays "number of groups" because the `group_by` tuple is
  preserved);
* referenced by ordering;
* selected while the query is `distinct` (DISTINCT depends on the SELECT list,
  e.g. `annotate(initial=Substr(...)).values('initial').distinct().count()`).

Because the `WHERE` clause is never modified and every annotation it references
is detected (and therefore kept), pruning can never corrupt the filter. Joins
required by kept annotations/filters are detected by the same column scan and so
are never trimmed.

Existing regression tests that already exercise these paths remain green by
construction, e.g. `aggregation_regress`'s “annotations don't get in the way of a
count()”:
`Book.objects.values('publisher').annotate(Count('publisher')).count() == 4` and
`Book.objects.annotate(Count('publisher')).values('publisher').count() == 6`,
`Author.objects.annotate(c=Count('friends__name')).exclude(friends__name='Joe').count()`,
and `annotations`'s `test_annotate_exists`
(`annotate(c=Count('id')).filter(c__gt=1).exists()`).

## Assumptions / alternatives considered & rejected

* **Assumption: `clone()` preserves expression identity.** `Query.clone()`
  shallow-copies the `annotations` dict and `WhereNode.clone()` keeps `Lookup`
  children by reference (lookups have no `clone()` method), so a filtered
  annotation's expression object stays identical to its entry in
  `self.annotations`. This is what makes the `id(expr)` reference detection
  reliable for the cloned query used by `count()`/`exists()`/`aggregate()`.

* **Rejected: only mask unused annotations out of the SELECT (keep the
  subquery/GROUP BY).** This is the pre-existing “good enough” behaviour from PR
  11062; it does not remove the join/subquery and so does not produce
  `SELECT COUNT(*) FROM book`, which the ticket explicitly asks for.

* **Rejected: remove the annotation without removing its join.** A reverse/`*-to-many`
  `LEFT OUTER JOIN` multiplies rows; with the collapsing `GROUP BY` also gone,
  `SELECT COUNT(*)` would count joined rows instead of objects. Hence
  `_trim_unused_joins()`.

* **Rejected: trim *all* unreferenced joins (including INNER).** Restricting
  trimming to `LOUTER` joins is a deliberate safety margin: annotations only ever
  introduce outer joins, while inner joins come from filters (which are always
  detected and kept). A non-null forward-FK annotation may leave a harmless inner
  join, but since the FK always matches it does not change the count.

* **Rejected: changing `get_aggregation`'s signature / the big
  `aggregate_exprs` refactor.** Kept the existing
  `get_aggregation(self, using, added_aggregate_names)` signature and the
  `QuerySet.aggregate()` flow to keep the change minimal and targeted; the
  pruning hooks in without touching callers.

* **Set operations (`union`/`intersection`/`difference`).** Pruning is skipped
  when `self.combinator` is set so that combined-query counts keep their existing
  (correct) behaviour, where the SELECT lists must stay aligned across branches.
