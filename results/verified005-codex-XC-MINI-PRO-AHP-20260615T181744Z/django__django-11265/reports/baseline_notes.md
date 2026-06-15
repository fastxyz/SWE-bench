# Baseline Notes

## Root cause

`exclude()` on an annotated `FilteredRelation` enters `Query.split_exclude()`
because the filtered relation can traverse a multi-valued join. `split_exclude()`
builds a fresh inner `Query(self.model)` for the `NOT IN` subquery, but that
query did not receive the outer query's `_filtered_relations` mapping. As a
result, lookups such as `book_alice__isnull` could not resolve the annotated
filtered relation alias and raised `FieldError`.

Copying the mapping alone is not enough. The inner query initially represents
the filtered relation as a filtered join, but `trim_start()` can simplify the
subquery by turning the joined table into the subquery's base table. When that
happens, the `Join` object is removed and any `FilteredRelation` predicate
stored in the join's `ON` clause would be lost, producing a subquery that
filters on the unfiltered relation.

## Changed files

`repo/django/db/models/sql/query.py`

- `split_exclude()` now copies `_filtered_relations` from the outer query into
  the generated inner query before adding the original filter expression. This
  lets the inner query resolve the annotated filtered relation alias.
- `trim_start()` now preserves a filtered join predicate when the filtered join
  is trimmed into the subquery's base table. If the predicate only references
  aliases that remain after trimming, it is moved into the subquery `WHERE`
  clause. If the predicate references an alias that would be trimmed away, the
  first join is left intact so the predicate can remain in its original `ON`
  clause.

## Assumptions and alternatives

I assumed the correct behavior is that `exclude()` applies both the lookup
being excluded and the `FilteredRelation.condition` to the same related rows,
matching the behavior of `filter()` on the same annotated relation.

I considered only copying `_filtered_relations` into the inner query. That
addresses the `FieldError`, but it still allows `trim_start()` to discard the
filtered join's `ON` condition, which matches the incorrect SQL described in
the issue hints.

I also considered disabling the first-join trim whenever a filtered relation is
present. That preserves correctness, but it unnecessarily keeps an extra join
for the common case where the filtered condition can be safely moved onto the
trimmed related table.
