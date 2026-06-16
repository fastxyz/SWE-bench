# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Semantic obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Cannot use aggregate over window functions since 4.2" and PostgreSQL reports "aggregate function calls cannot contain window function calls". | The ORM must avoid aggregate-over-window SQL for the reported public usage. |
| E2 | `benchmark/PROBLEM.md` | The example annotates `cumul_DJR=Coalesce(Window(...), 0.0)` and aggregates `cumul_DJR_total=Sum("cumul_DJR")`. | The concrete in-domain path is aggregation over a selected annotation alias containing a window expression. |
| E3 | `repo/docs/topics/db/aggregation.txt:622-624` | "the aggregates you provide can reference any alias defined as part of an annotate() clause". | Aggregate-over-annotation alias is documented public behavior. |
| E4 | `repo/docs/ref/models/expressions.txt:777-780` | Window expressions in Django ORM are equivalent to expressions in `QuerySet.annotate()` and are selected columns. | A selected window annotation is a valid inner-query projection boundary. |
| E5 | `repo/django/db/models/expressions.py:1206-1207` | `Ref.as_sql()` returns the quoted alias name. | Preserving a `Ref` in the outer aggregate yields alias SQL, not inline window SQL. |
| E6 | `repo/django/db/models/sql/query.py:455-464` | The aggregate wrapper condition lists existing triggers. | V1 must add the window-ref trigger without deleting previous triggers. |
| E7 | `repo/django/db/models/sql/query.py:541-547` | The direct branch replaces annotation `Ref`s with annotation expressions. | The direct branch is the mechanism that produced the invalid nested SQL shape for window annotations. |
