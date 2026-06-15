# Control Notes

## Source decision

I kept the V1 source change unchanged:

`repo/django/db/models/sql/query.py`

```python
obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

This decision follows Findings 1, 4, 6, and 7. The reported failure comes from a
derived combined queryset sharing component `Query` objects with the original
combined queryset. `Query.clone()` is the derivation boundary used by
`QuerySet._clone()`, and cloning `combined_queries` there restores queryset
isolation without changing SQL generation rules or public API behavior.

## Decisions not to make further edits

I did not change `SQLCompiler.get_combinator_sql()`. Finding 4 shows that the
compiler already clones a component query before applying `set_values()` for a
limited select list. The missing isolation was at the broader query-cloning
boundary, not in the local compiler branch.

I did not change `QuerySet._combinator_query()` to clone operands at construction
time. Finding 5 explains that this would be a broader semantic change than the
reported issue requires. The reproduction fails after deriving a new queryset
from an existing union, and Finding 1 traces that path through `Query.clone()`,
where V1 applies.

I did not add special handling for empty combined queries, nested combined
queries, or unsupported backend errors. Findings 2 and 3 show those behaviors
continue to use existing code paths, while recursive cloning improves nested
combined-query isolation.

## Verification

No tests or project code were run, as required by the task. Finding 8 documents
that this control pass is based on static review of the relevant source paths.
