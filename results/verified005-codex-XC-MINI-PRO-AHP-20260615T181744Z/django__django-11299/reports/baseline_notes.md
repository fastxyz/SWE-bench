# Baseline Notes

## Root cause

`CheckConstraint._get_check_sql()` builds its SQL through `Query.build_where()`.
That path passes `simple_col=True` so column references render as bare column
names through `SimpleCol`, which is required for check constraints during table
creation and table rebuilds.

`Query._add_q()` honored `simple_col` only for direct lookup children. When a
`Q` object contained a nested `Q` node, the recursive `_add_q()` call omitted the
`simple_col` argument and fell back to `False`. Nested clauses therefore used
regular `Col` objects, producing table-qualified column references such as
`"new__app_testconstraint"."field_1"`. In mixed `OR`/`AND` constraints, this
made one branch qualified while another branch used bare columns, causing invalid
SQLite schema SQL after the temporary table was renamed.

## Files changed

`repo/django/db/models/sql/query.py`

The recursive `_add_q()` call now passes through the current `simple_col` value.
This keeps column rendering consistent for all levels of a `Q` tree built by
`build_where()`, so check-constraint SQL uses bare column names in nested
clauses as well as top-level clauses.

## Assumptions

The issue is about SQL generated from `build_where()` for schema-level
predicates, where bare column names are already the intended behavior. Preserving
`simple_col=True` through nested `Q` nodes matches that existing intent instead
of adding backend-specific SQL cleanup.

The same path is also used for conditional unique constraints. I treated that as
another schema predicate that should receive consistent `SimpleCol` behavior,
not as a reason to special-case `CheckConstraint`.

## Alternatives considered and rejected

Changing `CheckConstraint._get_check_sql()` to strip table aliases from the final
SQL was rejected because it would be fragile string manipulation after SQL
compilation and could affect quoted values or backend-specific syntax.

Changing `Col.as_sql()` or backend schema editors was rejected because ordinary
query compilation still needs table-qualified columns. The problem is limited to
the `build_where(simple_col=True)` path losing the flag during recursion.
