# Baseline Notes

## Root cause

`Collector.collect()` stored every fast-delete queryset in `Collector.fast_deletes`
as a separate list entry. `Collector.delete()` later executed `_raw_delete()` once
per entry, so multiple cascade paths to the same related table produced multiple
DELETE round trips even when the querysets were compatible and could be combined
as a single `OR` predicate.

## Changed files

`repo/django/db/models/deletion.py`

Added `Collector.add_fast_delete()` and routed both fast-delete scheduling sites
through it. The helper combines compatible queryset-like fast deletes for the
same model with `QuerySet.__or__`, which preserves the existing raw-delete path
while producing one DELETE with an ORed WHERE clause. It also tracks a conservative
parameter count for relation-batch deletes and avoids combining entries when doing
so would exceed a backend's `max_query_params`.

## Assumptions

The issue concerns queryset-like fast deletes produced by cascade collection,
especially sibling foreign-key or many-to-many-through relations pointing at the
same model/table.

Combining is limited to querysets with the same model because Django's queryset
OR implementation only supports that case. I treated "same table" in the issue
as the normal case where the same model owns the table, rather than adding a
lower-level SQL combiner for proxy or otherwise distinct model classes sharing a
database table.

For related-object fast deletes, `len(batch)` is a suitable parameter-count proxy
because `related_objects()` builds a single `field__in` lookup from that batch.
When the count is unknown, the helper keeps the delete separate on backends with
a query-parameter limit.

## Alternatives considered

Combining all fast deletes by model at execution time was rejected because it can
merge separately batched relation filters into a query that exceeds backend
parameter limits.

Restructuring the related-object collection loop to pre-group all relations by
table was rejected as a larger change than needed. The helper keeps the existing
collection flow and deletion ordering intact while addressing the redundant fast
delete queries.

Adding tests was not done because the task forbids modifying test files. Tests
and project code were not run per the task instructions.
