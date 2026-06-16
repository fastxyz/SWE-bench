# Baseline Notes

## Root cause

`QuerySet.query` can be pickled and later assigned to a fresh `QuerySet` to re-run a query. For `values()` and `values_list()`, the SQL-level `Query` retains the selected columns, but the Python result-shaping state lives on the `QuerySet` in `_iterable_class` and `_fields`. Assigning an unpickled values query to `MyModel.objects.all()` therefore left the fresh queryset using `ModelIterable`, so rows selected for dictionaries or tuples were interpreted as model rows.

## Files changed

`repo/django/db/models/query.py`

- Updated the `QuerySet.query` setter to restore `_iterable_class` and `_fields` when the assigned query has explicit selected fields. If the query came from a current `values()` or `values_list()` queryset, the exact iterable class is restored. If the query lacks that metadata, the setter falls back to `ValuesIterable`, which avoids treating selected values rows as model instances.
- Updated `_values()`, `values()`, and `values_list()` so the underlying `Query` records the queryset fields and iterable class needed to reconstruct the result shape after pickling and reassignment.

## Assumptions and alternatives

- I assumed the documented `query` pickling pattern should preserve the observable result shape of `values()` and `values_list()`, not only the SQL.
- I treated `values_list(flat=True)` and `values_list(named=True)` as part of the same issue because the `Query` alone cannot infer those variants after unpickling.
- I rejected a documentation-only change because the docs already describe pickling `QuerySet.query` as supported, and the failure produces broken model instances rather than a clear limitation.
- I rejected detecting only `query.values_select` because annotation-only or extra-select values queries can have no `values_select` entries while still requiring a values iterable.
- I did not modify tests or run code, in accordance with the task constraints.
