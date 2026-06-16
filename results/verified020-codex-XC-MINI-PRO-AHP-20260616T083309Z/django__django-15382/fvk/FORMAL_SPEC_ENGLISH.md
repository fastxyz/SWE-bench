# Formal Spec in English

Status: paraphrase of `exists-spec.k`; constructed, not machine-checked.

## NEGATED-EMPTY-EXISTS

If `Exists.as_sql()` is compiling a negated `Exists` expression and the
subquery compilation raises `EmptyResultSet`, the result is an ordinary
always-true SQL predicate. In the implementation this is represented by
`'%s = %s'` with equal parameters `(1, 1)`.

## POSITIVE-EMPTY-EXISTS

If `Exists.as_sql()` is compiling a non-negated `Exists` expression and the
subquery compilation raises `EmptyResultSet`, the method propagates
`EmptyResultSet`.

## POSITIVE-NONEMPTY-EXISTS

If the subquery compiles normally and the `Exists` expression is not negated,
the method returns the `EXISTS(...)` predicate from normal subquery
compilation.

## NEGATED-NONEMPTY-EXISTS

If the subquery compiles normally and the `Exists` expression is negated, the
method returns the normal predicate prefixed with `NOT`.

## AND-PRESERVE-TRUE-EXISTS

In a two-child `AND` where the first child is the true predicate from
`~Exists(empty_queryset)` and the second child is another SQL predicate such
as `name='test'`, the WHERE result remains a SQL conjunction instead of
becoming `EmptyResultSet`.

## AND-EMPTY-EXISTS-COLLAPSES

In a two-child `AND` where a child is the propagated empty-result signal from
positive `Exists(empty_queryset)`, the WHERE result is empty. This preserves
the existing positive-`Exists` semantics.
