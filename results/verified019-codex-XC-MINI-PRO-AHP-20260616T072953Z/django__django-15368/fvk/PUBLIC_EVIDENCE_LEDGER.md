# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`bulk_update()` does not work with plain `F('...')` expressions." | Plain `F()` assigned to a model field is an intended `bulk_update()` input. | Encoded by `BULK-UPDATE-SPEC` claim 1 and PO-1. |
| E2 | `benchmark/PROBLEM.md` | "`o.c8 = F('name')` ... `bulk_update([o], ['c8'])`" | The issue's concrete witness is one object, one char field, and one same-row field reference. | Encoded by the `Resolvable(FRef(NAME))` claim. |
| E3 | `benchmark/PROBLEM.md` | "The created SQL contains the string repr of `F()`, instead of resolving to the column name." | Expected observable is a column reference, not a literal parameter containing `F(name)`. | Encoded by `Column(NAME)` postcondition and finding F-001. |
| E4 | `benchmark/PROBLEM.md` public hint | "we should check `resolve_expression` like elsewhere." | Expression detection should use Django's expression protocol, not `Expression` subclass membership. | Encoded by V1 source predicate and PO-2. |
| E5 | `repo/django/db/models/expressions.py` | `_parse_expressions()` keeps args with `resolve_expression`; otherwise wraps strings as `F()` and other values as `Value()`. | The expression protocol is an established local convention. | Supports PO-2 and PO-4. |
| E6 | `repo/django/db/models/sql/subqueries.py` | `add_update_fields()` resolves values with `resolve_expression(..., allow_joins=False, for_save=True)`. | Downstream update compilation will resolve the preserved `F()` expression. | Supports PO-3 and PO-4. |
| E7 | `repo/django/db/models/query.py` | Existing validation, batching, `Case` construction, optional `Cast`, transaction, and `update()` call are unchanged by V1. | Non-target behavior must be framed unchanged. | Encoded by PO-5. |
| E8 | `reports/baseline_notes.md` | V1 changed the predicate and removed an unused import. | Audit must decide whether V1 stands or needs more source edits. | Resolved by findings F-002 and F-003. |
