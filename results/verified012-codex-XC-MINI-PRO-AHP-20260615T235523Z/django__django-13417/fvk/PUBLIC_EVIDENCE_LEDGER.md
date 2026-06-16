# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "A property should say whether the queryset will be ordered or not." | `QuerySet.ordered` must reflect effective query ordering, not merely configured ordering metadata. | Encoded in PO-1 and `ORDERED-MATCHES-COMPILER`. |
| E2 | `benchmark/PROBLEM.md` | Annotated queryset SQL has `GROUP BY` and no `ORDER BY`, while `qs2.ordered # => True`. | The grouped aggregate/default-ordering case must return `False`. | Encoded in PO-4 and `GROUPED-META-UNORDERED`; fixed by V1. |
| E3 | `benchmark/PROBLEM.md` hints | "Meta.ordering doesn't affect GROUP BY queries..." | Default model ordering is not an effective ordering source for grouped queries. | Encoded in PO-3 and PO-4. |
| E4 | `repo/django/db/models/query.py` docstring | "has an order_by() clause or a default ordering on the model (or is empty)." | Preserve empty queryset and explicit/default non-grouped behavior. | Encoded in PO-2, PO-3, and PO-5. |
| E5 | `repo/django/db/models/sql/compiler.py` | `get_order_by()` sets `_meta_ordering` only when ordering comes from `Meta.ordering`; `as_sql()` sets `order_by = None` when grouping and `_meta_ordering`. | The formal compiler model must distinguish explicit ordering from default meta ordering under grouping. | Encoded in `compilerSource()` and `sourceOrdered()` in `mini-queryset-ordered.k`. |
| E6 | `repo/django/db/models/query.py` | `_annotate()` sets `query.group_by = True` or `set_group_by()` for aggregate annotations. | Aggregate annotation queries are represented by `hasGroupBy = true` in the model. | Encoded in the grouped input class for PO-4. |
| E7 | Source compatibility search under `repo/django` | `ordered` is read as a property; no source override or changed call signature was found. | Keep the property API unchanged. | Encoded in PO-7 and compatibility audit. |
