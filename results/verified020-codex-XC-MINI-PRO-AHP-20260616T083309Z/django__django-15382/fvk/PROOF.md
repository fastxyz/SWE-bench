# Constructed Proof

Status: constructed, not machine-checked. The commands below were written as
artifacts only and were not executed.

## Claims Proved by Construction

The formal claims are in `exists-spec.k`:

- `NEGATED-EMPTY-EXISTS`
- `POSITIVE-EMPTY-EXISTS`
- `POSITIVE-NONEMPTY-EXISTS`
- `NEGATED-NONEMPTY-EXISTS`
- `AND-PRESERVE-TRUE-EXISTS`
- `AND-EMPTY-EXISTS-COLLAPSES`

## Proof Sketch

`mini-exists.k` is a finite, straight-line semantics. Each
`existsAsSql(NEGATED, SUBQUERY_EMPTY)` state matches exactly one rule.

For `existsAsSql(true, true)`, the first rule rewrites to `ok(TRUEPRED)`.
This corresponds to V1 catching `EmptyResultSet` and returning
`'%s = %s', (1, 1)` when `self.negated` is true.

For `existsAsSql(false, true)`, the second rule rewrites to `emptyResult`.
This corresponds to V1 re-raising `EmptyResultSet` for positive
`Exists(empty_queryset)`.

For the two non-empty cases, the third and fourth rules preserve the existing
normal return and normal `NOT` wrapping behavior.

For `andWhere2(ok(TRUEPRED), ok(NAMEPRED))`, the SQL/SQL `AND` rule rewrites
to `whereSql(ANDPRED(TRUEPRED, NAMEPRED))`. This models the important
post-fix interaction with `WhereNode.as_sql()`: since the negated empty
`Exists` no longer raises, the normal `name='test'` predicate is joined into
the WHERE SQL instead of the WHERE block becoming empty.

For `andWhere2(emptyResult, ok(NAMEPRED))`, the empty-child `AND` rule rewrites
to `whereEmpty`, preserving positive empty `Exists` behavior.

No loops or recursion are present, so no circularity claim is required.

## Verification Conditions

There are no arithmetic, map extensionality, loop invariant, or termination
verification conditions. The proof obligations are finite case coverage over
two boolean inputs plus the relevant two-child `AND` interaction.

## Expected Machine-Check Commands

From the workspace root:

```sh
cd fvk
kompile mini-exists.k --backend haskell
kast --backend haskell exists-spec.k
kprove exists-spec.k
```

Expected result after machine-checking: `#Top` for all claims.

## Test Redundancy Recommendation

No tests were inspected for removal and no tests were modified. If a test in a
normal development workflow asserts that `~Exists(Model.objects.none())`
combined with another filter behaves like the filter without the `Exists`
expression, that test is subsumed by PO-001 and PO-005 only after the K
commands above are machine-checked. Until then, keep all tests.

## Residual Risk

The proof is only as adequate as the mini semantics. `SPEC_AUDIT.md` records
why the abstraction preserves the bug's observable property. The result is
partial correctness for expression-compilation behavior and does not prove
database execution, query planning, or performance.
