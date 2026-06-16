# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Resolve output_field when combining numeric expressions with MOD operator." | MOD must participate in `CombinedExpression.output_field` inference for numeric expressions. | Encoded in `SPEC.md`, `combined-expression-spec.k`, PO-001, PO-003. |
| E2 | `benchmark/PROBLEM.md` | "if the types of the query are different (Decimal and Integer), it doesn't resolve the result to a Decimal type" | Decimal/Integer modulo must infer `DecimalField` instead of raising `FieldError`. | Encoded in claims `resolve(mod, decimal, integer)` and `resolve(mod, integer, decimal)`. |
| E3 | `benchmark/PROBLEM.md` | "No, this issue is for mixed numeric types, e.g. DecimalField and IntegerField." | Same-type modulo coverage is insufficient; mixed numeric rows are in scope. | Encoded as the mixed numeric MOD proof obligations. |
| E4 | `repo/django/db/models/expressions.py` | "Numeric operations - operands of different type." | The mixed numeric result table is the local implementation contract for cross-type arithmetic promotion. | Used as implementation evidence supporting the table-family fix. |
| E5 | `repo/django/db/models/expressions.py` | Existing mixed rows map Integer/Decimal to Decimal and Integer/Float to Float for add/sub/mul/div. | Adding MOD to the connector family should register all existing mixed numeric rows for MOD. | Encoded in PO-002, PO-005, and Finding F-002. |
| E6 | `repo/django/db/models/expressions.py` | "Missing items will result in FieldError, by design." | Do not add unrelated unsupported combinations, including mixed numeric POW or Decimal/Float rows absent from the table. | Encoded in PO-006 and Finding F-003. |
| E7 | `repo/django/db/models/expressions.py` | `_resolve_combined_type()` checks `issubclass(lhs_type, combinator_lhs_type)` and same for RHS. | Integer subclasses must be covered by the integer-family rows once MOD is registered. | Encoded in the `integerSub` claim and PO-004. |
| E8 | `repo/django/db/models/expressions.py` | `CombinedExpression._resolve_output_field()` raises only when `_resolve_combined_type()` returns `None`. | A non-`None` combined type is sufficient to avoid the reported `FieldError`. | Encoded in PO-004. |
