# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Required behavior

1. For a grouped ORM query, default model `Meta.ordering` must not contribute
   fields to the SQL `GROUP BY` clause.

2. Suppressing default `Meta.ordering` for grouped queries must happen before
   downstream SQL construction steps that consume `order_by`, including hidden
   `extra_select` columns for `DISTINCT` and the `get_group_by()` ordering
   contributor.

3. Explicit user ordering must remain effective. `extra(order_by=...)` and
   `order_by(...)` are not default metadata ordering and may still be selected
   by `get_order_by()`.

4. Default `Meta.ordering` must remain effective for ordinary, non-grouped
   queries.

5. Public introspection through `QuerySet.ordered` must agree with the same
   grouped-query rule: default ordering does not affect queries whose
   `query.group_by` state is active.

## Domain

The audited domain is Django ORM query compilation states distinguished by:

- whether `extra_order_by` is present;
- whether `query.order_by` is present;
- whether `default_ordering` is enabled;
- whether the model has `Meta.ordering`;
- whether `query.group_by` is `None` or active;
- whether `distinct` can request hidden ordering selects.

The proof is partial correctness over this compiler decision. It does not prove
SQL execution semantics, database optimizer behavior, or termination.
