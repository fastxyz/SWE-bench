# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "order_by() a parent model crash when Meta.ordering contains expressions." | Relation/default ordering expansion must handle expression entries. | Encoded by I1-I4, PO1-PO4. |
| E2 | `benchmark/PROBLEM.md` | "the field is an OrderBy object, not a string, during get_order_dir" | Expressions must not reach string indexing in `get_order_dir()`. | Encoded by PO1. |
| E3 | `benchmark/PROBLEM.md` hints | `ordering = (Lower('name'),)` causes "'Lower' object is not subscriptable" via `get_order_dir()` | Non-`OrderBy` expressions must be wrapped and compiled, not string-indexed. | Encoded by PO2. |
| E4 | `repo/django/db/models/sql/query.py` | `add_ordering()` accepts items with `resolve_expression`; docs mention field names or `OrderBy` expressions. | Expression ordering is a supported ordering input shape. | Encoded by I2-I3. |
| E5 | `repo/django/db/models/sql/compiler.py` | Top-level `get_order_by()` already handles expression items before `get_order_dir()`. | Related default ordering should not be less capable than top-level ordering for the same expression family. | Encoded by PO1-PO4. |
| E6 | `repo/tests/ordering/tests.py` and `repo/tests/ordering/models.py` | "F expressions can be used in Meta.ordering." | `F()`-based ordering expressions are intended public behavior. | Encoded by PO3. |
| E7 | `repo/tests/modeladmin/test_checks.py` | `Upper('name')` and `Upper('band__name').desc()` are valid admin ordering expressions. | Transform/function expression ordering is part of the public expression-ordering family. | Encoded by PO2-PO4. |
| E8 | implementation fact | Existing string path in `find_ordering_name()` uses `_setup_joins(pieces, opts, alias)` and `trim_joins()` to resolve fields from the current related model. | Expression `F()` leaves must use the same alias-relative resolution to satisfy I4. | Encoded by PO3. |
| E9 | implementation fact | Some expression source children such as `Q` are not normal `BaseExpression` trees with `copy()` and `get_source_expressions()`. | The helper must not blindly copy non-expression child nodes. | Encoded by PO6 and Finding F2. |
