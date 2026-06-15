# Baseline Notes

## Root Cause

`Aggregate.__init__()` rejects `distinct=True` unless the aggregate class sets
`allow_distinct = True`. `Count` already opts in, but `Avg` and `Sum` inherited
the default `allow_distinct = False`, so constructing `Avg(..., distinct=True)`
or `Sum(..., distinct=True)` raised `TypeError` before SQL generation.

The SQL rendering path already supports distinct aggregates through
`Aggregate.template` and `Aggregate.as_sql()`, which emits `DISTINCT ` when
`self.distinct` is true. The missing piece was the class-level opt-in for the
aggregate classes that should allow the argument.

## Changed Files

`repo/django/db/models/aggregates.py`

Added `allow_distinct = True` to `Avg` and `Sum`. This makes both classes accept
`distinct=True` and reuse the existing aggregate SQL generation behavior.

## Assumptions and Alternatives

The issue title specifically requests DISTINCT support for `Avg` and `Sum`, so
the implementation is limited to those classes.

The issue text mentions that the same setting could be applied to `Min` and
`Max`, but also calls it pointless. I treated that as an optional extension and
left those aggregates unchanged to avoid expanding the behavioral surface beyond
the described fix.

No tests or project code were run, per the benchmark instructions.
