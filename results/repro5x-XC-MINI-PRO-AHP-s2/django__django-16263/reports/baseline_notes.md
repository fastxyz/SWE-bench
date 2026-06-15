# Baseline notes — django__django-16263

## Issue

`Book.objects.annotate(Count('chapters')).count()` builds SQL that still computes
the `Count('chapters')` annotation (a subquery with a `GROUP BY`) even though the
annotation is not referenced by any filter, ordering, grouping or other
annotation. It returns the same value as `Book.objects.count()` but is far more
expensive. Django should strip annotations that don't affect the result of
`count()` / `aggregate()`, just like it already ignores `select_related()` there.

## Root cause

`Query.get_aggregation()` (`django/db/models/sql/query.py`) is the shared code
path for both `QuerySet.count()` (via `get_count()`) and `QuerySet.aggregate()`.
It computes `existing_annotations` from **every** annotation in
`self.annotations` and, if any exist, wraps the query in a subquery and forces a
`GROUP BY`. It made no attempt to discard annotations that are irrelevant to the
aggregate being computed, so any `annotate()` produced a needless subquery,
`GROUP BY`, and the join(s) required only by that annotation.

Two facts about the query internals make a correct fix non-trivial:

1. **Joins are not pruned by the compiler.** A table/join is emitted in the
   `FROM` clause purely based on `alias_refcount > 0`
   (`SQLCompiler.get_from_clause`). The join introduced when an annotation is
   resolved keeps `refcount == 1` regardless of whether the annotation is still
   selected. So merely dropping an annotation from the `SELECT` (or from
   `self.annotations`) leaves its join in place.
2. **Removing an aggregate annotation removes its `GROUP BY`.** For an aggregate
   over a (left-outer-joined) relation, the row multiplication caused by the
   join is collapsed back to one row per object by the `GROUP BY pk`. If the
   annotation is dropped but its join is left behind, the rows are no longer
   collapsed and `COUNT(*)` would count *join pairs* instead of objects — a wrong
   result. Therefore the join must be removed together with the annotation.

   In contrast, a **non-aggregate** multi-valued annotation (e.g.
   `annotate(title=F('chapters__title'))`) has *no* `GROUP BY`; its join
   multiplication is part of the existing `count()` result, so its join must be
   *kept* to preserve behaviour.

## Fix

File changed: `django/db/models/sql/query.py`.

- `get_aggregation()` now calls a new helper `self._prune_unused_annotations(
  added_aggregate_names)` immediately after the early `return {}` guard and
  before `existing_annotations` is computed, so the rest of the method naturally
  produces simpler (often subquery- and `GROUP BY`-free) SQL.

- New method `Query._prune_unused_annotations(kept_aliases)`:
  1. **Bails out** for constructs that are unsafe/opaque to analyse: set
     operations (`combinator`), `extra()` select/tables/order-by, raw
     `ExtraWhere` nodes in the `WHERE` clause, and filtered relations. In those
     cases behaviour is left exactly as before.
  2. **Computes the referenced annotations.** Starting from the aggregates being
     computed (`kept_aliases`) plus everything referenced by the `WHERE`/`HAVING`
     clause, the ordering and the explicit `GROUP BY`, it transitively keeps any
     annotation referenced by another referenced annotation. References are
     detected three ways, matching how Django stores them: by name (ordering
     strings and `F()`), by alias (`Ref.refs`), and by object identity (filters
     and inter-annotation references hold the annotation object itself — this is
     why an `id()`→alias map is used).
  3. **Drops the unreferenced annotations** from `self.annotations` and updates
     the annotation select mask (intersecting it with the kept set, preserving
     the unselected status of `alias()`-style annotations).
  4. **Releases joins** used *only* by pruned **aggregate** annotations. Using
     `_gen_cols` + the `parent_alias` chain it gathers the join aliases of those
     annotations (`removable`) and, separately, the join aliases still required
     by everything that remains (`needed`: `WHERE`, kept annotations, explicit
     `GROUP BY`, `SELECT`, expression ordering, plus the base table). It then
     `unref_alias()`es the joins in `removable - needed` down to 0 so they leave
     the `FROM` clause. Joins of pruned non-aggregate annotations are
     deliberately left in place.

Why the join removal is safe for aggregate annotations: aggregate annotation
joins are never row-filtering (multi-valued relations are nullable and become
`LEFT OUTER` joins; single-valued non-null FKs are `INNER` but match every row),
and any row multiplication they introduce is collapsed by the `GROUP BY`. So
removing the annotation, its `GROUP BY` contribution and its exclusive joins
together leaves the number of aggregated rows unchanged. Shared joins are handled
correctly because reachability (`removable - needed`) is intersection-based and
only ever lowers a refcount that nothing else needs.

## Worked examples (verified by tracing)

- `Book.objects.annotate(Count('chapters')).count()` → `SELECT COUNT(*) FROM book`
  (no subquery, no `GROUP BY`, chapters join dropped) — matches `…count()`.
- `…annotate(full_name=Concat(...)).count()` → `SELECT COUNT(*) FROM person`.
- `…annotate(c=Count('chapters')).filter(c__gt=5).count()` → unchanged: `c` is
  referenced by the filter, kept, and the subquery + `HAVING` remain (correct).
- `…values('cat').annotate(c=Count(...)).count()` → subquery kept (explicit
  `GROUP BY cat`), but the now-unused `c`/its join are dropped; result unchanged.
- `…annotate(title=F('chapters__title')).count()` → annotation dropped from the
  SELECT but the multiplying chapters join is **kept**, preserving the existing
  (book×chapter) count.

## Assumptions / alternatives considered and rejected

- **Only mask the annotation out of the inner SELECT (keep it in
  `self.annotations`).** Rejected: `existing_annotations` would stay non-empty,
  so the subquery + `GROUP BY` + join would remain — it does not achieve the
  issue's `SELECT COUNT(*)` goal.
- **Remove the annotation but leave its join.** Rejected: for aggregate
  annotations this drops the `GROUP BY` while keeping the multiplying join,
  producing a wrong count.
- **Exact refcount accounting (unref each join by the amount the annotation
  contributed).** Rejected as fragile (shared/duplicated joins make the exact
  contribution hard to compute). Reachability + `removable - needed` only
  requires truthiness of the refcount, which is all `get_from_clause` checks.
- **`exists()` (mentioned in the hints as "same can be done").** Left out of
  scope. `exists()` is a separate code path (`Query.exists()`), already returns
  correct results, and changing it interacts with its distinct/slice/union
  handling; this fix keeps the change minimal and targeted at the
  `count()`/`aggregate()` path described by the ticket.
