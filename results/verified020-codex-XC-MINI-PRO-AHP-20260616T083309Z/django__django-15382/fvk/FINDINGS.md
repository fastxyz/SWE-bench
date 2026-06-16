# FVK Findings

Status: constructed, not machine-checked. No code, tests, Python, or K tooling
were executed.

## F-001: Resolved Code Bug - Negated Empty Exists Escaped as EmptyResultSet

Input/state:

`existsAsSql(negated=True, subqueryEmpty=True)` inside an `AND` filter with a
normal predicate such as `name='test'`.

Pre-V1 observed behavior:

The empty subquery raised `EmptyResultSet`, `Exists.as_sql()` did not catch it,
and `WhereNode.as_sql()` treated the child as always false. The whole WHERE
block collapsed to `EmptyResultSet`.

Expected behavior:

`~Exists(empty_queryset)` is always true. It should compile to a true SQL
predicate, allowing the other `AND` child to remain in the WHERE clause.

Status:

Resolved by V1. Traced to proof obligations PO-001 and PO-005.

## F-002: Frame Condition - Positive Empty Exists Must Remain Always False

Input/state:

`existsAsSql(negated=False, subqueryEmpty=True)`.

Expected behavior:

Positive `Exists(empty_queryset)` remains always false, represented by
propagating `EmptyResultSet`.

Status:

Confirmed by V1. The new `except EmptyResultSet` block re-raises when
`self.negated` is false. Traced to PO-002.

## F-003: Frame Condition - Always-True Replacement Must Be SQL, Not Empty Text

Input/state:

`~Exists(empty_queryset)` compiled outside the simplifying assumptions of a
WHERE child, such as a selected or annotated expression.

Expected behavior:

The expression still has a concrete boolean SQL predicate so downstream
formatting, including `select_format()`, has SQL to wrap.

Status:

Confirmed by V1. Returning `'%s = %s', (1, 1)` satisfies this better than
returning `('', [])`. Traced to PO-001 and PO-006.

## F-004: No Open Code Finding from the FVK Audit

Input/state:

All four combinations of `negated` and empty/non-empty subquery compilation,
plus the reported two-child `AND` interaction.

Expected behavior:

Each combination satisfies the intent and frame obligations.

Status:

No additional source edit is justified. Traced to PO-001 through PO-006.

## F-005: Proof Honesty Gate

Input/state:

The K artifacts `mini-exists.k` and `exists-spec.k`.

Observed limitation:

The proof is constructed in markdown and K claims, but `kompile`, `kast`, and
`kprove` were not executed.

Expected handling:

Keep the proof labeled "constructed, not machine-checked" and do not remove
tests based on it.

Status:

Open verification-process limitation only; not a source-code bug. Traced to
PO-007.
