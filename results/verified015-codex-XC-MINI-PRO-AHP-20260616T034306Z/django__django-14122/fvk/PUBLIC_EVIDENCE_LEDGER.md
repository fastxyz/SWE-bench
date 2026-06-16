# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Meta.ordering fields must not be included in GROUP BY clause" | A grouped query must exclude default metadata ordering fields from `GROUP BY`. | Encoded by `GROUPED-META-SUPPRESSED`. |
| E2 | `benchmark/PROBLEM.md` | "commit ... removes ORDER BY when Meta.ordering is used it still does populates GROUP BY with Meta.ordering fields" | The defect is not only final `ORDER BY`; any earlier compiler path that feeds metadata ordering into grouping must be blocked. | Encoded by `GROUPED-META-SUPPRESSED`, including `extraSelectHasMeta == false`. |
| E3 | `repo/django/db/models/sql/query.py` | "`None`: no group by at all ... A tuple of expressions ... `True`: group by all select fields" | `query.group_by is None` is the no-grouping sentinel; tuple and `True` are grouped-query states. | Encoded by the `grouped` state and by the source edits. |
| E4 | `repo/django/db/models/query.py` | "A default ordering doesn't affect GROUP BY queries." | `QuerySet.ordered` should not report default metadata ordering as active for grouped queries. | Encoded by `orderedProperty == false` for grouped metadata-only states. |
| E5 | `repo/django/db/models/sql/compiler.py` | `get_group_by()` adds non-reference `order_by` expressions to grouping. | If metadata ordering remains in `order_by`, `GROUP BY` can contain metadata fields. | Implementation fact used in the mini semantics and Findings F1. |
| E6 | `repo/django/db/models/sql/compiler.py` | `get_extra_select()` adds non-reference ordering expressions for `distinct` queries. | Filtering only at `get_group_by()` is insufficient because hidden selects can still carry metadata ordering into grouping. | Encoded by proof obligation PO-2. |
| E7 | `repo/django/db/models/sql/compiler.py` | `get_order_by()` gives precedence to `extra_order_by` and explicit `query.order_by` before metadata ordering. | The fix must preserve explicit and extra ordering behavior. | Encoded by `GROUPED-EXPLICIT-PRESERVED` and `GROUPED-EXTRA-PRESERVED`. |

No hidden tests, upstream patch, internet source, evaluator result, or benchmark
result was used.
