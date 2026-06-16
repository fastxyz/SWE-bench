# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Unit Under Audit

Primary source unit:

`repo/django/db/models/expressions.py`, `Exists.as_sql()`

Supporting source unit:

`repo/django/db/models/sql/where.py`, `WhereNode.as_sql()`

The formal model intentionally abstracts the full Django compiler to the
boundary relevant to the issue: a subquery either compiles normally or raises
`EmptyResultSet`, and `Exists.as_sql()` either returns SQL or propagates the
empty-result signal. This abstraction preserves the property under test:
whether `~Exists(empty_queryset)` reaches `WhereNode` as a true SQL predicate
or as `EmptyResultSet`.

## Public Intent Ledger

The full public ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-001: the issue reports that `~Exists(empty_queryset)` in a filter removes
  the whole WHERE block.
- E-002: the displayed `EmptyResultSet` is the buggy legacy symptom, not an
  expected result.
- E-003: the public hint says `Exists.as_sql()` should catch
  `EmptyResultSet` from `super().as_sql()` when negated and return an
  always-true predicate.
- E-004: `Exists.__invert__()` stores negation inside `Exists.negated`.
- E-006: `WhereNode.as_sql()` treats a child `EmptyResultSet` in an `AND` as a
  reason to raise `EmptyResultSet` for the whole node.
- E-007: selected boolean expressions need a SQL predicate so
  `select_format()` can wrap them where needed.

## Formal Domain

The formal input domain is the Cartesian product:

- `negated`: `true` or `false`.
- `subqueryEmpty`: `true` when compiling the `query.exists(...)` subquery
  raises `EmptyResultSet`, otherwise `false`.

The WHERE interaction model covers the reported `AND` case with one
`Exists`-derived child and one ordinary SQL predicate such as `name='test'`.

## Required Claims

1. `NEGATED-EMPTY-EXISTS`: `existsAsSql(true, true)` reaches
   `ok(TRUEPRED)`.
2. `POSITIVE-EMPTY-EXISTS`: `existsAsSql(false, true)` reaches
   `emptyResult`.
3. `POSITIVE-NONEMPTY-EXISTS`: `existsAsSql(false, false)` reaches
   `ok(EXISTSPRED)`.
4. `NEGATED-NONEMPTY-EXISTS`: `existsAsSql(true, false)` reaches
   `ok(NOTEXISTSPRED)`.
5. `AND-PRESERVE-TRUE-EXISTS`: `andWhere2(ok(TRUEPRED), ok(NAMEPRED))`
   reaches `whereSql(ANDPRED(TRUEPRED, NAMEPRED))`.
6. `AND-EMPTY-EXISTS-COLLAPSES`: `andWhere2(emptyResult, ok(NAMEPRED))`
   reaches `whereEmpty`.

These claims are encoded in `exists-spec.k`.

## Implementation Mapping

`TRUEPRED` maps to the V1 source return `'%s = %s', (1, 1)`.

`emptyResult` maps to propagating `EmptyResultSet`.

`EXISTSPRED` maps to the SQL returned by `Subquery.as_sql()` through the
`EXISTS(%(subquery)s)` template.

`NOTEXISTSPRED` maps to applying `sql = 'NOT {}'.format(sql)` after normal
subquery compilation.

`whereSql(ANDPRED(TRUEPRED, NAMEPRED))` maps to `WhereNode.as_sql()` joining
both child SQL strings for an `AND`, so the ordinary `name='test'` filter is
not removed.

## Adequacy Result

`SPEC_AUDIT.md` marks every formal obligation as passing against
`INTENT_SPEC.md`. No required behavior is ambiguous, and no ordered or frame
condition is justified solely by V1 behavior.
