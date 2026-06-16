# Findings

Status: constructed, not machine-checked.

## F1: Metadata ordering could still reach GROUP BY in V0

Input:

`extra_order_by = false`, `query.order_by = false`, `default_ordering = true`,
model `Meta.ordering = true`, `query.group_by` active.

Observed before the compiler fix:

`get_order_by()` selected metadata ordering. `pre_sql_setup()` then passed that
ordering to `get_group_by()`, whose implementation adds non-reference ordering
expressions to the grouping list. Final `as_sql()` could suppress the rendered
`ORDER BY`, but that happened after grouping was already populated.

Expected:

Metadata ordering must be absent before `get_extra_select()` and
`get_group_by()` run, so `GROUP BY` cannot contain fields that came only from
`Meta.ordering`.

Classification:

Code bug, resolved by `repo/django/db/models/sql/compiler.py`.

Trace:

Proof obligations PO-1 and PO-2.

## F2: V1 left `QuerySet.ordered` on a weaker grouped-query sentinel

Input:

`extra_order_by = false`, `query.order_by = false`, `default_ordering = true`,
model `Meta.ordering = true`, and `query.group_by = ()`.

Observed in V1:

`SQLCompiler.get_order_by()` used `query.group_by is None`, so it treated the
empty tuple as a grouped-query state and did not select metadata ordering.
`QuerySet.ordered` still used `not self.query.group_by`, so it would report this
state as ordered.

Expected:

`Query.group_by` documents `None` as "no group by at all" and a tuple as a
grouped state. The public `ordered` property comment says default ordering does
not affect grouped queries, so it should use the same sentinel.

Classification:

Consistency bug surfaced by FVK, resolved by
`repo/django/db/models/query.py`.

Trace:

Proof obligation PO-5.

## F3: Constructed proof only

Input:

All formal claims in `fvk/django-14122-spec.k`.

Observed:

The proof was constructed by source and symbolic reasoning only. Per task
constraints, no `kompile`, `kast`, `kprove`, Python, or Django tests were run.

Expected before treating this as machine-verified:

Run the emitted K commands and require `kprove` to return `#Top`.

Classification:

Proof status caveat, not a code bug.

Trace:

Proof obligation PO-6 and `fvk/PROOF.md`.
