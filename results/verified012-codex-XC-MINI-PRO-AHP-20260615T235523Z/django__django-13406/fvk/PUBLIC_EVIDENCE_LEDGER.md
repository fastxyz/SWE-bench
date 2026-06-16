# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md:3` | "values()/values_list() crashes when recreated from a pickled query" | Cover both `values()` and `values_list()` restoration. |
| E2 | `benchmark/PROBLEM.md:6-7` | Query objects are pickled for later re-evaluation; results should be dicts. | Preserve values result shape through query pickling. |
| E3 | `benchmark/PROBLEM.md:22-29` | `prices2.query = pickle.loads(...)` then `type(prices2[0])` is model. | Setter must restore a non-model iterable. |
| E4 | `benchmark/PROBLEM.md:51` | `_iterable_class` is on queryset, not query. | Persist result-shape metadata on the query. |
| E5 | `benchmark/PROBLEM.md:53` | `ValuesListIterable`, `FlatValuesListIterable`, `NamedValuesListIterable`. | Preserve exact values-list variants. |
| E6 | `repo/docs/ref/models/querysets.txt:94-106` | Query pickling/reassignment is safe and supported. | Source fix belongs in query restoration path. |
| E7 | `repo/django/db/models/query.py:94-180` | Distinct iterable classes define row shape. | Formal model must distinguish iterable class. |

