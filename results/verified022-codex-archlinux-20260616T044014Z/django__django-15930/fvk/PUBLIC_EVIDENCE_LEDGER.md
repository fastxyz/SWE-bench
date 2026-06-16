# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "Case() crashes with ~Q(pk__in=[])." | A `Case` with a full negated empty `IN` condition is in scope. | Encoded in O1/O4. |
| E2 | prompt | Generated SQL: `CASE WHEN THEN True ELSE False END` | Empty `WHEN` condition SQL is the defect, not a behavior to preserve. | Encoded in O1. |
| E3 | prompt | "I expected behavior to annotate all rows with the value True since they all match." | Full predicate selects the `then` branch for every row. | Encoded in O4. |
| E4 | prompt | "~Q(pkin=[]) is a sentinel value that is sometimes returned by application code." | The behavior should follow the general full-predicate sentinel path, not a one-off model-specific special case. | Encoded in O1/O2. |
| E5 | code comment | `WhereNode.as_sql()` says `Return '', [] if this node matches everything`. | Empty condition SQL from a `WhereNode` is the full-result sentinel. | Encoded in O1. |
| E6 | code | `Case.as_sql()` catches `EmptyResultSet` from a compiled `When` and skips that case. | Impossible predicates remain false/fall-through. | Encoded in O3. |
| E7 | public test | `test_annotate_with_empty_when` expects `When(pk__in=[])` to use the default. | The fix must not convert impossible predicates to true. | Encoded in O3. |
| E8 | code comment | `Case` is a searched CASE expression and `When.template` is `WHEN %(condition)s THEN %(result)s`. | A `When` condition position needs a valid predicate SQL fragment. | Encoded in O1/O2. |
| E9 | code precedent | `Exists.as_sql()` uses `1=1` for a negated empty result when boolean select support is absent. | `1=1` is an accepted always-true predicate form in expression SQL. | Encoded in O1. |
