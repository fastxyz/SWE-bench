# Specification

Status: constructed, not machine-checked.

## Scope

This FVK run audits the compiler decision that chooses ordering expressions and
feeds them into `get_extra_select()` and `get_group_by()`.

Concrete code under audit:

- `repo/django/db/models/sql/compiler.py`: `SQLCompiler.get_order_by()`,
  `pre_sql_setup()`, `get_extra_select()`, and `get_group_by()`.
- `repo/django/db/models/query.py`: `QuerySet.ordered`.

The issue is about provenance of ordering fields. The formal model therefore
abstracts an ordering list to one of four sources: `meta`, `explicit`, `extra`,
or `none`. This abstraction is property-complete for the reported defect because
the failing and passing cases differ exactly on whether metadata ordering can
flow into `GROUP BY`.

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | `benchmark/PROBLEM.md`: "Meta.ordering fields must not be included in GROUP BY clause" | Grouped queries with only default metadata ordering must produce no metadata-derived grouping contributor. |
| E2 | `benchmark/PROBLEM.md`: final `ORDER BY` was removed but `GROUP BY` still received metadata ordering fields | The fix must happen before `get_group_by()` consumes `order_by`, not only at final SQL rendering. |
| E3 | `Query.group_by` comment: `None` means "no group by at all"; tuple and `True` are grouped states | The grouped-query guard must use `group_by is None` as the no-grouping sentinel. |
| E4 | `QuerySet.ordered` comment: "A default ordering doesn't affect GROUP BY queries." | Public `ordered` introspection must use the same sentinel rule. |
| E5 | `get_order_by()` precedence gives `extra_order_by` and explicit `query.order_by` before metadata ordering | Explicit ordering behavior is a frame condition and must be preserved. |

## Formal Contract

The formal contract is expressed in `fvk/django-14122-spec.k` over the mini
semantics in `fvk/mini-django-compiler.k`.

The central result shape is:

`result(source, orderByHasMeta, extraSelectHasMeta, groupByHasMeta, orderedProperty)`

Meaning:

- `source`: which ordering source `get_order_by()` selects;
- `orderByHasMeta`: whether the selected ordering came from model metadata;
- `extraSelectHasMeta`: whether `get_extra_select()` can add metadata ordering
  columns;
- `groupByHasMeta`: whether metadata ordering can reach `GROUP BY`;
- `orderedProperty`: whether `QuerySet.ordered` should report the query as
  ordered.

Required claims:

- `GROUPED-META-SUPPRESSED`: with no explicit or extra ordering, default
  ordering enabled, model metadata ordering present, and grouping active, the
  result is `noSource`, with all metadata-flow booleans false and
  `orderedProperty == false`.
- `UNGROUPED-META-PRESERVED`: the same metadata ordering is preserved for a
  non-grouped query.
- `GROUPED-EXPLICIT-PRESERVED`: explicit `query.order_by` remains selected even
  when grouping is active.
- `GROUPED-EXTRA-PRESERVED`: `extra_order_by` remains selected even when
  grouping is active.

## Source-Level Satisfaction

`SQLCompiler.get_order_by()` now selects `Meta.ordering` only when
`self.query.group_by is None`. Since `pre_sql_setup()` calls `get_order_by()`
before `get_extra_select()` and `get_group_by()`, metadata ordering is absent
from both downstream contributors when grouping is active.

`QuerySet.ordered` now uses the same `self.query.group_by is None` sentinel for
the default-ordering branch, matching the documented `Query.group_by` states.
