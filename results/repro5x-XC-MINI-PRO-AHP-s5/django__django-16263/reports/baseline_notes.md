# Baseline notes — django__django-16263

## Issue

> Strip unused annotations from count queries

`Book.objects.annotate(Count('chapters')).count()` produces SQL that includes the
`Count('chapters')` annotation even though it is not referenced by any filter, ordering,
or other annotation. Because a *selected* annotation forces `get_aggregation()` down its
subquery path (and an aggregate annotation additionally forces a `GROUP BY`), the count
becomes a needlessly expensive

```sql
SELECT COUNT(*) FROM (
  SELECT book.id, COUNT(chapter.id) AS ... FROM book LEFT JOIN chapter GROUP BY book.id
) subquery
```

instead of the trivial `SELECT COUNT(*) FROM book`. Django should drop annotations that
do not affect the result, the same way `select_related()` is ignored by `count()`.

## Root cause

`django/db/models/sql/query.py`, `Query.get_aggregation()`:

```python
existing_annotations = [
    annotation
    for alias, annotation in self.annotations.items()
    if alias not in added_aggregate_names
]
...
if (isinstance(self.group_by, tuple) or self.is_sliced or existing_annotations
        or self.distinct or self.combinator):
    # build wrapping subquery (with GROUP BY pk when an aggregate exists)
else:
    # fast path: SELECT COUNT(*) ... directly
```

Any pre-existing annotation makes `existing_annotations` truthy, forcing the subquery
branch — even when the annotation is never referenced and cannot influence the result.
There was no mechanism to remove such annotations (the old comment literally said "we
aren't smart enough to remove the existing annotations from the query").

A subtlety that makes naive stripping incorrect:

* A `count()` must equal `len(list(qs))`. An annotation that introduces a **multivalued
  join** without an aggregate (e.g. `annotate(t=F('chapters__title'))`) multiplies rows,
  so its removal would change the count. It must be kept.
* An **aggregate** annotation (`Count('chapters')`) only exists because of the `GROUP BY`
  on the primary key (`group_by is True`), which collapses the multivalued join back to
  one row per main row. Removing it is safe *provided* the GROUP-BY-pk semantics are kept
  when any multivalued join still survives (e.g. when a filter such as
  `filter(chapters__title='x')` independently joins the same multivalued relation —
  current Django returns *distinct* matching books there, and that must not change).
* Joins are only emitted when their `alias_refcount > 0`; deleting an annotation does not
  decrement those refcounts, so its join would still be emitted (and, on the fast path,
  multiply the `COUNT(*)`) unless the refcount is explicitly cleared.

## Changes (all in `django/db/models/sql/query.py`)

### `Query.get_aggregation()`
1. Capture `has_existing_aggregate_annotations` from the **pre-strip** annotations. This
   preserves the GROUP-BY-pk decision even after the aggregate that required it is removed.
2. When it is safe (not `is_sliced`, `distinct`, `distinct_fields`, `combinator`,
   `select_for_update`, and `group_by` is not an explicit tuple — i.e. the cases where the
   selected annotations participate in deciding which/how many rows are returned), call the
   new `_strip_unused_annotations()` and recompute `existing_annotations`.
3. Add `joins_remain` and the extra subquery condition
   `(self.group_by is True and joins_remain)`. This forces the GROUP-BY-pk subquery when an
   aggregate annotation was stripped but a multivalued join (from a filter or a kept
   annotation) still survives, so the result keeps counting distinct main rows. When no
   joins survive, the fast `SELECT COUNT(*)` path is taken.
4. Use the captured `has_existing_aggregate_annotations` inside the subquery branch instead
   of recomputing it from the (now possibly reduced) `existing_annotations`.

### New helper methods
* `_referenced_annotation_aliases(roots, candidates)` — returns the candidate annotation
  aliases referenced (directly or transitively) by the root expressions. Uses an `id()`
  identity walk over `get_source_expressions()` because filters and inter-annotation
  references embed the annotation **object**, and a `Ref`'s `source` is the annotation
  object too, so the same walk catches `Ref`-by-alias references. Order-by **strings** are
  matched by alias name.
* `_annotation_contains_join(annotation)` — True if any of the annotation's columns sit on a
  joined table (`alias_map[alias]` is a `Join`).
* `_strip_unused_annotations(added_aggregate_names)` — removes each unreferenced candidate
  annotation that is either an aggregate (collapsed by GROUP BY pk) or references no join
  (cannot multiply rows). Updates `annotations`, the annotation-select mask / cache, then
  calls `_trim_unused_aliases()`. Roots considered: the aggregates being computed,
  `self.where`, an explicit `group_by` tuple, and `self.order_by`.
* `_trim_unused_aliases()` — recomputes the joins still referenced by the remaining
  annotations, `where`, explicit group_by and select (plus each referenced join's parent
  chain) and sets `alias_refcount` to 0 for the joins no longer needed, so they are dropped
  from the FROM clause. The base table (a `BaseTable`, not a `Join`) is never zeroed.

## Worked outcomes (traced, not executed)

* `annotate(Count('chapters')).count()` → strip the aggregate, trim its join → fast path →
  `SELECT COUNT(*) FROM book`.
* `annotate(full_name=Concat('first','last')).count()` → strip (no join) → `SELECT COUNT(*) FROM person`.
* `annotate(t=F('chapters__title')).count()` → kept (non-aggregate, multivalued join) →
  unchanged (counts pairs, matching `len(list)`).
* `filter(chapters__title='x').annotate(Count('chapters')).count()` → aggregate stripped but
  the filter's multivalued join survives → forced GROUP-BY-pk subquery → still counts
  distinct books (unchanged).
* `annotate(c=Count('chapters')).aggregate(Sum('price'))` → `c` unreferenced/aggregate →
  stripped → `SELECT SUM(price) FROM book` (`aggregate(Sum('c'))` keeps `c` via the Ref walk).

## Assumptions
* `get_aggregation`'s `added_aggregate_names` is iterable of aliases and supports `in`
  (a list from `get_count`, a dict from `QuerySet.aggregate`); both work with the new code.
* Annotation joins are LEFT OUTER (or otherwise non-row-filtering), so they only matter for
  row *multiplication*, captured by the aggregate / `_annotation_contains_join` test.
* `clone()` keeps annotation objects shared by identity between `annotations`, `where`,
  `group_by` and `order_by`, so identity-based reference detection is reliable.

## Alternatives considered and rejected
* **Only mask the annotation out of the SELECT (keep the subquery + join + GROUP BY).**
  Correct but does not produce the `SELECT COUNT(*)` the ticket asks for; the join and
  GROUP BY (the actual performance killers) remain.
* **Surgically `unref_alias()` each stripped annotation's columns.** Fragile: multi-hop
  joins and annotations that *reference* other annotations' columns lead to under/over
  decrementing. Recomputing the needed aliases from the surviving clauses and zeroing the
  rest avoids that double-counting entirely.
* **Detect single- vs multi-valued joins per join to also strip single-valued FK
  annotations.** Django stores no reliable per-join multivalued flag (`Col.possibly_multivalued`
  is incomplete, per its own FIXME). Treating "any surviving join" as cardinality-affecting
  is conservative: it may keep a strictly-unnecessary subquery for single-valued-FK
  annotations, but is always correct.
* **Also strip annotations from `Query.exists()`.** The hints note "Same can be done for
  exists()", but the ticket is about `count()`/`aggregate()`; `exists()` already
  short-circuits with `LIMIT 1` and its `group_by`/`distinct`/`combinator` handling is
  delicate, so changing it carries regression risk disproportionate to the benefit. Left
  unchanged and out of scope.
