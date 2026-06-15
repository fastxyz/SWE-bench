# Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue title | "Migration crashes deleting an index_together if there is a unique_together on the same fields" | The operation that removes an `index_together` entry must not fail merely because a same-field `unique_together` remains. | Encoded in SPEC-C1 and SPEC-C2. |
| E2 | prompt reproduction | "add 2 same fields to unique_together and to index_together" then "Delete index_together -> Fail" | Domain includes a model with one same-column unique constraint and one same-column non-unique index. | Encoded in SPEC-C1 and SPEC-C2. |
| E3 | prompt failure localization | "will find two constraints, the _uniq and the _idx one" | Candidate lookup must distinguish unique and non-unique objects when dropping the index. | Encoded in SPEC-C0, SPEC-C1, SPEC-C2. |
| E4 | prompt desired behavior | "The deletion of index_together should be possible alone or made coherent ... with unique_together" | The same-field unique constraint must remain outside the deletion candidate set for `index_together`. | Discharged by PO1 and PO2. |
| E5 | source creation path | `table_sql()` calls `_create_unique_sql()` for `unique_together`; `_model_indexes_sql()` calls `_create_index_sql(... suffix="_idx")` for `index_together`. | `index_together` corresponds to a non-unique index; filtering with `unique=False` matches the object Django created. | Used as implementation evidence for PO1. |
| E6 | source introspection path | Oracle marks unique constraints with `'index': unique`; MySQL updates index entries from `SHOW INDEX`; SQLite records unique indexes with `index=True`. | A unique object may also satisfy `index=True`, so `index=True` alone is insufficient. | Used as implementation evidence for F1 and PO1. |
| E7 | prompt secondary concern | "Moving the declaration of an index should not result in an index re-creation" | Potential migration optimizer/state requirement. | Recorded as unresolved design Finding F2 and PO5. |
| E8 | source API shape | `alter_index_together()` calls `_delete_composed_index()`; method signatures are unchanged by V1. | Compatibility frame condition for existing callers and backend overrides. | Discharged by PO4. |
