# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "order_by('?') unexpectedly breaking queryset aggregation" | Random ordering must not change aggregate cardinality. | Encoded in `DROP-RANDOM` claim. |
| E2 | prompt issue | `GROUP BY "thing"."id", RANDOM()` is shown as the broken SQL. | `Random()` must be absent from added order-by grouping expressions. | Encoded in `DROP-RANDOM` claim and source patch. |
| E3 | prompt issue | `order_by('related')` is expected to split the grouped result. | Column-dependent orderings must remain grouped. | Encoded in `KEEP-COLUMN` claim. |
| E4 | prompt hint | "skip all expressions that have no cols as source expressions" | Column-free order expressions are excluded from order-by grouping. | Encoded in `DROP-RANDOM`. |
| E5 | prompt hint | "plus, we need to include any raw sql" | Raw SQL is retained despite lack of metadata. | Encoded in `KEEP-RAWSQL`. |
| E6 | compiler comment | References to selected expressions are already represented by the select clause. | `is_ref` entries are skipped. | Encoded in `DROP-REF`. |
| E7 | source implementation | `Subquery.get_group_by_cols()` can return `[self]` when external cols are possibly multivalued. | Expressions with non-empty external columns must be retained. | V1 failed; V2 encoded in `KEEP-EXTERNAL-COLS`. |
