# Intent Spec

Status: constructed from public evidence only; current implementation behavior is treated as a candidate to check.

## Required behavior

1. For `Model.objects.all().delete()` on a fast-delete model, the SQL shape must be a direct single-table delete: `DELETE FROM <base_table>`, optionally with a base-table-only `WHERE` for filtered single-table cases.
2. The delete compiler must not introduce a self-subquery for a delete that uses only the base table. The issue identifies `DELETE ... WHERE pk IN (SELECT pk FROM same_table)` as the regression.
3. The fix must apply at the compiler decision point, not only to MySQL, because the public hint says the regression affects other backends as well.
4. Multi-table delete queries must continue to use the existing fallback path: a primary-key subquery on backends that can self-select, or the backend-specific multi-table delete path such as MySQL's `DELETE alias FROM ...`.
5. A query with explicit `extra(tables=...)` has additional table contributors outside `alias_map`; it is not safely representable by the direct `_as_sql()` branch, which only emits `DELETE FROM base_table` plus `WHERE`.
6. No public API, method signature, return shape, or test files should change.

## Domain

The formalized unit is `SQLDeleteCompiler.single_alias` plus the branch in `SQLDeleteCompiler.as_sql()` that consumes it. The domain is delete query states characterized by:

- the number of active aliases in `query.alias_map`;
- whether no aliases are active before compiler setup;
- whether `query.extra_tables` is empty.

This abstracts away quoting, table names, parameters, and the exact backend fallback SQL because those are not the disputed observable. The disputed observable is whether a single-table delete is direct or routed through a self-subquery/fallback.
