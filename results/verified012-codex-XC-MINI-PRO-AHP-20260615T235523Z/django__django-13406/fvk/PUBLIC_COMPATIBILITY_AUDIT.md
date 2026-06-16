# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol: `QuerySet.query` setter in `repo/django/db/models/query.py`.

## Signature

No signature change.

## Documented workflow

Docs at `repo/docs/ref/models/querysets.txt:94-106` show:

```python
query = pickle.loads(s)
qs = MyModel.objects.all()
qs.query = query
```

V1 improves this documented workflow for selected values queries.

## Internal/public-style callsites

Static search found direct `QuerySet.query` assignment examples in `repo/tests/queryset_pickle/tests.py:284` and `:297`. These assign outer model queries, not selected values result queries, so `has_select_fields` is false on the assigned query and V1 preserves the old iterable/field frame.

## Overrides and subclasses

Static search found no override of the `query` property setter under `repo/django`.

## Query producer/consumer shape

V1 adds private marker attributes to `Query` instances produced by `values()` and `values_list()`. `Query.clone()` copies `__dict__` (`repo/django/db/models/sql/query.py:295-296`), so normal cloning preserves these markers. Default pickling preserves instance attributes because no custom `Query.__getstate__` was found.

Conclusion: no public compatibility blocker was found.

