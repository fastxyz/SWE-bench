# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Negated Empty Exists Returns True Predicate

Evidence: E-001, E-003, E-004.

Claim: `existsAsSql(true, true) => ok(TRUEPRED)`.

Source mapping: In `Exists.as_sql()`, `super().as_sql(...)` raises
`EmptyResultSet`; because `self.negated` is true, the method returns
`'%s = %s', (1, 1)`.

Status: satisfied by V1.

## PO-002: Positive Empty Exists Propagates EmptyResultSet

Evidence: Intent 2, E-005, E-006.

Claim: `existsAsSql(false, true) => emptyResult`.

Source mapping: In `Exists.as_sql()`, the `except EmptyResultSet` block
re-raises when `self.negated` is false.

Status: satisfied by V1.

## PO-003: Positive Non-Empty Exists Preserves Existing SQL

Evidence: Intent 3.

Claim: `existsAsSql(false, false) => ok(EXISTSPRED)`.

Source mapping: If `super().as_sql(...)` succeeds and `self.negated` is false,
the method returns the original `sql, params`.

Status: satisfied by V1.

## PO-004: Negated Non-Empty Exists Preserves NOT Wrapping

Evidence: Intent 3.

Claim: `existsAsSql(true, false) => ok(NOTEXISTSPRED)`.

Source mapping: If `super().as_sql(...)` succeeds and `self.negated` is true,
the method applies `sql = 'NOT {}'.format(sql)`.

Status: satisfied by V1.

## PO-005: AND Filter Preserves Other Predicate

Evidence: E-001, E-006.

Claim: `andWhere2(ok(TRUEPRED), ok(NAMEPRED)) =>
whereSql(ANDPRED(TRUEPRED, NAMEPRED))`.

Source mapping: Since V1 returns SQL instead of raising, `WhereNode.as_sql()`
follows its normal `else` branch, appends the child SQL to `result`, and joins
it with the other predicate instead of decrementing `empty_needed`.

Status: satisfied by V1.

## PO-006: Public Compatibility and Return Shape

Evidence: E-007 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Claim: The changed path returns the normal expression-compiler tuple shape
`(sql, params)` and does not change public signatures, call sites, or tests.

Source mapping: V1 returns a SQL string and a parameter sequence.

Status: satisfied by V1.

## PO-007: Machine-Checking Honesty Gate

Evidence: FVK README and `commands/verify.md`.

Claim: The proof must remain labeled constructed, not machine-checked, unless
`kompile` and `kprove` are actually executed.

Status: satisfied by these artifacts. No test removal is recommended until
machine-checking is performed.
