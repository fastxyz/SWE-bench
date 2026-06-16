# Baseline Notes

## Root cause

`Exists.as_sql()` delegates to `Subquery.as_sql()`, which can raise
`EmptyResultSet` when the wrapped queryset is known to be empty, such as
`Model.objects.none()`. That exception is correct for a positive
`Exists(empty_queryset)` predicate because it can never match.

For `~Exists(empty_queryset)`, however, the negation is stored inside the
`Exists` expression as `self.negated`; it is not represented as a surrounding
negated `WhereNode`. Because `Exists.as_sql()` did not catch
`EmptyResultSet`, the outer `WhereNode` treated the child as an always-false
predicate before `Exists` had a chance to apply its negation. In an `AND`
filter, that caused the whole WHERE clause to collapse to `EmptyResultSet`
instead of treating `~Exists(empty_queryset)` as always true and preserving the
other filters.

## Changed files

`repo/django/db/models/expressions.py`

Added `EmptyResultSet` handling inside `Exists.as_sql()`. If the wrapped
subquery is empty and the `Exists` expression is negated, the expression now
compiles to an always-true SQL predicate (`%s = %s` with equal parameters).
If the expression is not negated, the original `EmptyResultSet` behavior is
preserved.

`reports/baseline_notes.md`

Added this report describing the root cause, implementation scope, and
assumptions.

## Assumptions

The issue is specifically about `Exists` owning its negation state via
`__invert__()`, so the correct fix belongs in `Exists.as_sql()` rather than in
generic `WhereNode` empty-queryset handling.

The always-true predicate should be expressed as a normal SQL comparison with
parameters instead of returning an empty SQL string, because `Exists` can be
used outside a WHERE clause, such as in annotations or SELECT lists.

## Alternatives considered and rejected

Changing `WhereNode.as_sql()` to reinterpret `EmptyResultSet` from negated
expressions was rejected because `WhereNode` only sees a child compilation
failure; it cannot reliably know whether an expression intended to apply its
own internal negation.

Returning `('', [])` for `~Exists(empty_queryset)` was rejected because that
works as an always-true child in WHERE handling but would produce invalid SQL
when the expression is selected or otherwise compiled outside a WHERE node.

Changing `Subquery.as_sql()` was rejected because positive subqueries and
positive `Exists(empty_queryset)` should continue to propagate
`EmptyResultSet`.
