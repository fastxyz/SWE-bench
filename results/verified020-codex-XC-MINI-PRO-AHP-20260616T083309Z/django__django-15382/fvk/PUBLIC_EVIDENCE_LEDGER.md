# Public Evidence Ledger

## E-001

Source: prompt / issue.

Quoted evidence: "filter on exists-subquery with empty queryset removes whole
WHERE block"

Semantic obligation: A filter combining `~Exists(empty_queryset)` with another
predicate must preserve the other predicate instead of becoming
`EmptyResultSet`.

Status: encoded by `SPEC.md` and formal claims
`NEGATED-EMPTY-EXISTS` and `AND-PRESERVE-TRUE-EXISTS`.

## E-002

Source: prompt / issue reproduction.

Quoted evidence: `MyModel.objects.filter(~models.Exists(MyModel.objects.none()), name='test')`
prints `EmptyResultSet`.

Semantic obligation: This displayed `EmptyResultSet` is SUSPECT legacy
behavior: it is the symptom being reported, not behavior to preserve.

Status: recorded as Finding F-001.

## E-003

Source: public hint.

Quoted evidence: "Exists encapsulate its negation logic (see __invert__) it
should catch EmptyResultSet when raised by its super() call in as_sql and
return an always true predicate"

Semantic obligation: The fix belongs in `Exists.as_sql()` around the
`super().as_sql()` call. For a negated empty subquery, the result must be an
always-true SQL predicate.

Status: encoded by proof obligation PO-001.

## E-004

Source: source code.

Quoted evidence: `def __invert__(self): clone = self.copy(); clone.negated = not self.negated`

Semantic obligation: Negation is internal to `Exists`; generic WHERE empty-set
handling sees only the exception, not the intended negation.

Status: supports PO-001 and the rejection of a `WhereNode`-level fix.

## E-005

Source: source code.

Quoted evidence: `NothingNode.as_sql()` raises `EmptyResultSet`.

Semantic obligation: An empty queryset subquery reaches `Exists.as_sql()` as
an exception during subquery compilation.

Status: supports the mini semantics' `subqueryEmpty` case.

## E-006

Source: source code.

Quoted evidence: `WhereNode.as_sql()` treats `EmptyResultSet` in an `AND`
node as a reason to raise `EmptyResultSet` for the whole WHERE clause.

Semantic obligation: The negated empty `Exists` must not leak
`EmptyResultSet` to `WhereNode` when it should mean true.

Status: encoded by PO-005.

## E-007

Source: source code.

Quoted evidence: `select_format()` wraps boolean expressions for backends that
do not support boolean expressions in SELECT or GROUP BY lists.

Semantic obligation: The replacement for a negated empty `Exists` should
remain a boolean SQL predicate that can pass through `select_format()`; an
empty SQL string is not adequate outside WHERE handling.

Status: encoded by PO-006 and Finding F-003.
