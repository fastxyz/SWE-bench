# Baseline notes — django__django-16263

## Issue

`Book.objects.annotate(Count('chapters')).count()` produces SQL that still
computes `Count('chapters')` (and therefore needs a join, a `GROUP BY`, and a
wrapping subquery), even though the annotation is never referenced by a filter,
another annotation, or ordering. The same waste happens for `exists()`. The
ticket asks Django to *strip annotations that are not referenced anywhere except
the SELECT clause* from `count()`/`exists()` (and, by extension, `aggregate()`)
queries, the way `select_related()` is already ignored for those queries.

## Root cause

`Query.get_aggregation()` (used by both `count()` and `aggregate()`) decides
whether to wrap the query in a subquery by inspecting `existing_annotations`,
which is simply *every* annotation that isn't one of the freshly added
aggregates:

```python
existing_annotations = [
    annotation
    for alias, annotation in self.annotations.items()
    if alias not in added_aggregate_names
]
```

Any existing annotation — referenced or not — forces the subquery + `GROUP BY`
path. The annotation also leaves its joins in `alias_map` (with a non-zero
refcount), so they are emitted in the `FROM` clause. There was no mechanism to
notice that an annotation is *only selected* and can be dropped. `Query.exists()`
had the analogous problem: it merely masks the annotations out of the `SELECT`
(via `clear_select_clause()`) but keeps their joins and the `GROUP BY`.

## Fix

All changes are in `django/db/models/sql/query.py` (no test files touched).

Added helper methods on `Query`:

- `_gen_referenced_annotations(summary_aliases)` — returns the set of annotation
  aliases that actually influence which/how many rows the query operates on:
  those referenced by the `WHERE`/`HAVING` clause, an explicit `GROUP BY`,
  ordering, the summary aggregates being computed, or (transitively) by another
  referenced annotation. References are detected both by `Ref(alias)` and by an
  expression holding the resolved annotation object directly (which is what
  filtering on an annotation, or referencing it from another annotation, does).
  Recursion naturally handles transitivity and is stopped at nested `Query`
  objects (subqueries reference the outer query through resolved columns, not
  annotation aliases).

- `_referenced_table_aliases(exprs)` — the set of table aliases referenced by the
  columns inside `exprs`, walked up to the base table via `parent_alias`. Uses
  `_gen_cols(..., include_external=True)` so `Subquery`/`Exists` annotations
  contribute the *outer* columns they reference (via `get_external_cols()`)
  rather than their inner-query columns. Including ancestors guarantees we never
  drop a parent join while keeping a child.

- `_aliases_contain_multivalued_join(aliases)` — whether any of those aliases is
  a multivalued (`one_to_many`/`many_to_many`) join, i.e. one that multiplies the
  number of base rows.

- `_has_extra_where()` — detects `ExtraWhere` (raw SQL added via `extra(where=)`)
  anywhere in the `WHERE` tree.

- `_strip_unused_annotations(summary_aliases, preserve_row_count)` — removes the
  unreferenced annotations from `self.annotations`/the annotation mask and zeroes
  the refcount of the joins used *exclusively* by them (computed as
  `referenced_table_aliases(removed) - referenced_table_aliases(kept)`, filtered
  to actual `Join`s so base tables are never dropped). It bails out for query
  features whose interaction with dropped joins is hard to reason about or that
  may reference joins via raw SQL (`is_sliced`, `distinct`, `combinator`,
  `select_for_update`, `extra`, `extra_tables`, `extra_order_by`, `ExtraWhere`).

  When `preserve_row_count` is `True` (the `count()`/`aggregate()` case) it only
  strips if the simplified query provably returns the same number of rows:
  - if the result is still grouped (an explicit `GROUP BY` tuple, or a *kept*
    aggregate annotation that keeps the subquery's `GROUP BY pk`), stripping is
    safe;
  - else, if `group_by is True` (the query collapses join-multiplied rows to one
    per object), it's safe only when no multivalued join survives after dropping
    the removed ones;
  - else (`group_by is None`, no grouping at all), it's safe only when none of
    the dropped joins is multivalued (dropping a multivalued join would change
    the multiplied row count).

  `exists()` passes `preserve_row_count=False` because existence is unaffected by
  join multiplication or grouping.

Wiring:

- `get_aggregation()` calls `_strip_unused_annotations(set(added_aggregate_names),
  preserve_row_count=True)` right after the early `annotation_select` check (only
  when `added_aggregate_names` is non-empty, so the degenerate `annotate(...)
  .aggregate()` with no requested aggregates keeps its original behavior instead
  of being reduced to an empty `SELECT`), then recomputes `existing_annotations`. For the headline case this empties
  `existing_annotations`, so the no-subquery branch runs and (because `group_by`
  is `True` but no non-aggregate column is selected) `get_group_by()` returns
  `[]`, yielding `SELECT COUNT(*) FROM book`.

- `exists()` calls `_strip_unused_annotations(set(), preserve_row_count=False)`
  and, when no aggregate annotation remains, resets `group_by = None` so the
  concrete-field `GROUP BY` it would otherwise add is skipped, yielding
  `SELECT 1 FROM book LIMIT 1`.

A stale comment in `get_aggregation()` ("we aren't smart enough to remove the
existing annotations") was updated.

## Why this is correct

- Annotations referenced by filters/HAVING, grouping, ordering, the computed
  aggregates, or other referenced annotations are kept, so queries like
  `values('publisher').annotate(cnt=Count('isbn')).filter(cnt__gt=1)` and
  `aggregate(Max('num_authors'))` are unchanged (the strip is a no-op there).
- An annotation referenced by an aggregate's `filter=Q(...)` is detected because
  `Aggregate.get_source_expressions()` includes `self.filter`
  (e.g. `Count('pk', filter=Q(ceo_salary__gt=20))` keeps `ceo_salary`).
- Joins are only dropped when used exclusively by removed annotations, and only
  when row count is provably preserved, so cases such as
  `annotate(Count('authors')).filter(authors__age__gt=30).count()` (a multivalued
  filter join that the original `GROUP BY` was de-duplicating) fall back to the
  existing subquery behavior instead of being incorrectly simplified.

## Assumptions and rejected alternatives

- **Assumption:** `group_by is True` is only ever set by annotating with an
  aggregate (verified: only `QuerySet._annotate()` sets it, and only for
  aggregate annotations), so it always means "one row per base object". This
  justifies the `exists()` `group_by = None` reset and the row-count reasoning.
- **Assumption:** annotation-induced joins never *remove* base rows (aggregate
  joins are `LEFT OUTER`; forward-FK joins match exactly one row), so dropping
  them is safe for `exists()` and for the row-count analysis.
- **Rejected — mask only (don't touch joins/GROUP BY):** removing the annotation
  from the `SELECT` mask alone leaves the join in the `FROM` clause; for a
  multivalued join that makes `COUNT(*)` count join-multiplied rows (wrong), and
  it doesn't deliver the requested simplification. So joins must be dropped too.
- **Rejected — refactor `get_aggregation` to take `aggregate_exprs` and resolve
  internally (the shape later Django versions use):** larger, riskier change to
  the public-ish call path (`QuerySet.aggregate`) than needed; the existing
  `added_aggregate_names` contract is sufficient.
- **Rejected — unref each annotation column once instead of the closure
  diff:** column references don't include intermediate joins (e.g.
  `Count('a__b')` only yields a column on `b`), and an exact decrement is fragile
  because `get_from_clause()` keeps a join unless its refcount is *exactly* 0. The
  closure-difference approach (with ancestors) is robust against shared and
  intermediate joins.
- **Rejected — stripping unconditionally for `count()`/`aggregate()`:** would
  change results for queries with multivalued filter joins or ungrouped
  multivalued annotations; hence the `preserve_row_count` guard.
- **Interpretation choice:** annotations referenced *only* by ordering are kept,
  matching the ticket's wording ("not referenced by filters, other annotations or
  ordering"), even though `count()`/`exists()` clear ordering. This is
  conservative (at worst a missed optimization, never a wrong result).
