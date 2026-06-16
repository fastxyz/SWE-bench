# Intent Spec

Status: constructed from public issue evidence, not from hidden tests.

## Required behavior

1. A terminal `QuerySet.aggregate()` expression with an aggregate `default` must be valid after the queryset already has annotations.
   Evidence: `Book.objects.annotate(idx=F("id")).aggregate(Sum("id", default=0))` is reported to crash with invalid SQL.

2. The result of a defaulted aggregate in this path must be equivalent to explicitly wrapping the aggregate in `Coalesce`.
   Evidence: the issue states that the long form `aggregate(x=Coalesce(Sum("id"), 0))` works and returns the expected sum.

3. The crash is not limited to aggregating over the annotated field.
   Evidence: public hint says the title is not quite accurate and the crash happens whether or not the aggregate uses the annotated field.

4. The change must remain local to aggregate default resolution.
   Evidence: public hint identifies `Aggregate.default` internally generating `Coalesce` and points to `django/db/models/aggregates.py`.

5. Ordinary, non-terminal aggregate annotations should not be reclassified as terminal aggregate reductions.
   Evidence: `BaseExpression.resolve_expression()` documents `summarize` as "a terminal aggregate clause" and copies it to `is_summary`; `QuerySet.aggregate()` is the public callsite that passes `is_summary=True`.

## Out of scope

No total correctness, database execution, SQL backend parsing, or performance proof is attempted. The FVK model covers the expression-resolution and aggregation-planning state needed to distinguish the reported invalid outer `SELECT` from a valid one.
