# Baseline Notes

## Root cause

`Model.objects.all().delete()` can reach `SQLDeleteCompiler.as_sql()` through the fast-delete path with an empty `alias_map`. The compiler's `single_alias` check treated that as not being a single-table query, so it used the multi-table fallback: an outer `DELETE` constrained by a primary-key subquery selecting from the same table. For an unfiltered queryset, initializing the base table alias first reveals that the query only touches the base table and can be emitted as a direct `DELETE FROM <table>`.

## Files changed

`repo/django/db/models/sql/compiler.py`

The `SQLDeleteCompiler.single_alias` property now initializes the query's base table alias when no aliases have been created yet. This lets unfiltered fast deletes take the existing direct-delete branch while leaving queries with active joins on the existing subquery or backend-specific multi-table delete paths.

## Assumptions and alternatives

I assumed the reported regression is in SQL generation, not in collection or cascade behavior, because the problematic SQL is produced by the fast-delete path after `QuerySet.delete()` delegates to `_raw_delete()`.

I considered changing `QuerySet.delete()` or `QuerySet._raw_delete()` to special-case `all()`, but rejected that because the compiler already owns the single-table versus multi-table SQL decision and has the `single_alias` abstraction for this purpose.

I also considered bypassing the fallback whenever the queryset has no `WHERE` clause, but rejected that as too broad. The minimal condition is whether the delete query has only the base table alias after normal alias initialization.
