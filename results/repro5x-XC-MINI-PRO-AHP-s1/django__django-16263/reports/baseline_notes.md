# Baseline notes — django__django-16263

## Issue

`Book.objects.annotate(Count('chapters')).count()` builds a SQL statement that
still computes `Count('chapters')` (inside a subquery with a `GROUP BY`), even
though the annotation is not referenced by any filter, ordering, or other
annotation. The result is identical to `Book.objects.count()`, so the annotation
(and the join/`GROUP BY` it drags in) is pure overhead. The same problem affects
`exists()`. The ticket asks Django to strip annotations that are not referenced
by filters, other annotations, or ordering from `count()`/`exists()` queries,
mirroring how `select_related()` is already ignored for these.

## Root cause

`Query.get_aggregation()` (used by both `count()` and `aggregate()`) decides
whether a subquery + `GROUP BY` is needed based on `existing_annotations` — every
annotation in the query other than the aggregate being computed. The code even
documented that "we aren't smart enough to remove the existing annotations from
the query, so those would force us to use GROUP BY." `Query.exists()` had the
analogous problem: it kept every annotation (and its joins / `GROUP BY`) even
though existence is unaffected by them.

So nothing ever removed annotations that contribute nothing to the result, and
their joins kept multiplying / grouping rows inside the aggregation subquery.

## Fix

Single file changed: `repo/django/db/models/sql/query.py`.

Two new helpers plus call sites:

1. `Query._referenced_aliases(expr, annotation_ids)` (staticmethod) — collects
   the set of annotation aliases referenced by an expression tree. References can
   be:
   - `Ref(alias, …)` instances — produced when aggregating/grouping/ordering
     over an annotation (e.g. `aggregate(Sum('x'))`, GROUP BY refs);
   - the annotation expression embedded **by object identity** — produced when
     *filtering* on an annotation or *annotating over another annotation*
     (`resolve_ref(..., summarize=False)` returns the annotation object itself,
     **not** a `Ref`), so identity matching against `annotation_ids` (a map of
     `id(expr) -> alias`) is required;
   - `OuterRef`/`ResolvedOuterRef` (`F` subclasses) — captured by name, and the
     traversal descends into nested `Query` subqueries so an outer annotation
     referenced only through a kept subquery's `OuterRef` is preserved.

2. `Query._prune_unused_annotations(preserved=())` — computes the transitive
   closure of annotations that must be kept (the `preserved` aggregates being
   computed, plus anything referenced by the `WHERE` clause, ordering, the
   preserved expressions, and other kept annotations), deletes the rest from
   `self.annotations` / the annotation mask, and then prunes joins that became
   unused. It bails out (no change) for queries where stripping could change the
   result: `is_sliced`, `distinct`, `distinct_fields`, `select_for_update`,
   `combinator`, `extra`, or an explicit (`values()`-style) tuple `group_by`.

   Join pruning only runs when `group_by is True` (i.e. an aggregate annotation
   was present and therefore rows were already being collapsed to one row per
   group). In that situation an unreferenced `LEFT OUTER JOIN` can be dropped
   without changing the row count, which lets `annotate(Count('rel')).count()`
   collapse to plain `SELECT COUNT(*) FROM table`. Base tables and `INNER` joins
   are always kept (they can change cardinality), and ancestors of any kept join
   are kept. Finally, if no aggregate annotations remain, `group_by` is reset to
   `None`. When `group_by` is not `True` (e.g. `annotate(Concat(...))`), no joins
   are touched; join-less annotations still reach the simple `SELECT COUNT(*)`
   path, while a non-aggregate annotation over a multi-valued relation keeps its
   (cardinality-affecting) join so the count matches the existing behaviour.

3. `Query.get_aggregation()` now calls `self._prune_unused_annotations(
   added_aggregate_names)` before computing `existing_annotations`, and the stale
   "we aren't smart enough…" comment was updated.

4. `Query.exists()` now calls `q._prune_unused_annotations()` right after cloning,
   so unreferenced annotations (and the joins/`GROUP BY` they require) are
   dropped before the `GROUP BY` materialisation / select-clause clearing. Since
   `Exists.__init__` builds its inner query via `query.exists()`, `Exists()`
   subqueries benefit too.

All mutation happens on a clone (`get_count`/`aggregate` chain or `exists`'s
`q = self.clone()`), and `Query.clone()` preserves the object identity link
between `self.annotations[alias]` and the same expression embedded in
`self.where`, which the identity-based reference detection relies on.

## Why object identity (not just `Ref`) is required

Filtering on an annotation (`.filter(c__gt=1)`) and annotating over another
annotation (`.annotate(b=F('a'))`) both embed the *actual* annotation object in
the `WHERE`/annotation tree rather than a `Ref`. A `Ref`-only scan would wrongly
strip such annotations and break the query (existing tests such as
`tests/annotations` `test_filter_alias_with_double_f`,
`test_filter_alias_agg_with_double_f`, and `test_annotate_exists` cover exactly
this). Aggregates over an annotation (`aggregate(Max('num_authors'))`) *do* use
`Ref`, so both forms are detected.

## Behaviour preserved (spot-checked against existing tests)

- `annotate(num_authors=Count("authors")).count()` → `6`
  (`aggregation_regress.test_more`): annotation + its m2m LEFT OUTER joins are
  stripped, result unchanged.
- `annotate(num_authors=Count("authors")).aggregate(Max("num_authors"))`:
  `num_authors` is referenced by the `Max` (via `Ref`) and kept.
- `values(...).annotate(Count(...)).count()`: tuple `group_by` → pruning bails.
- `Publisher.objects.none().aggregate(...)`: only the computed aggregates exist,
  so pruning is a no-op and the empty-result optimisation still fires.
- Union/`combinator` `count()`/`exists()`: pruning bails on the combinator query.

## Assumptions / alternatives rejected

- **Assumption:** ordering-only joins and `select_related` joins do not exist in
  `alias_map` at this point (they are created at compile time), so clearing
  ordering is unnecessary for join safety and annotations referenced *only* by
  ordering are conservatively kept (matching the ticket wording "…filters, other
  annotations or ordering").
- **Rejected: drop every unreferenced join.** Dropping `INNER` joins or any join
  when there is no `GROUP BY` collapsing could change the counted rows (e.g.
  `annotate(F('m2m__field')).count()` counts duplicated rows today). Restricting
  drops to unreferenced `LEFT OUTER` joins under `group_by is True` keeps results
  identical.
- **Rejected: only mask annotations out of the SELECT.** That leaves the
  annotation in `self.annotations`, so it still forces the subquery/`GROUP BY`
  and (for relation aggregates) the join, so the join would multiply the counted
  rows. Fully removing the annotation and its orphaned joins is required.
- **Rejected: `Ref`-only reference detection.** Insufficient because filters and
  inter-annotation references use object identity (see above).
- **Rejected: changing `get_aggregation`'s signature to add the aggregates
  itself.** Not needed; the already-added aggregates are identified via
  `added_aggregate_names`, keeping the change smaller and the public-ish method
  signature stable.
