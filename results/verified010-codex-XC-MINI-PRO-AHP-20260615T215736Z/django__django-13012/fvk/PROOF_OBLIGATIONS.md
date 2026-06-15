# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Wrapped constants contribute no group-by columns

- Formal claim: `WRAPPED-VALUE-NO-GROUP-BY`.
- Precondition: the child expression is `Value(V)` for any constant `V`; alias
  may be absent or present.
- Expected postcondition: `ExpressionWrapper(Value(V)).get_group_by_cols(alias)`
  returns `[]`.
- Evidence: E-001, E-002, E-007.
- Related findings: F-001.
- V2 status: satisfied because `Value.get_group_by_cols(alias=alias)` is called
  and returns `[]`.

## PO-002: Alias-aware wrapped expressions preserve child grouping semantics

- Formal claim: `WRAPPER-DELEGATES-ALIAS-AWARE`.
- Precondition: the child expression's `get_group_by_cols()` signature accepts
  `alias`.
- Expected postcondition: the wrapper result equals the child result for the
  same alias.
- Evidence: E-003, E-004, E-008.
- Related findings: F-001.
- V2 status: satisfied by the `return self.expression.get_group_by_cols(alias=alias)` branch.

## PO-003: The wrapper itself is not a fallback group-by column

- Formal claim: implied by `WRAPPED-VALUE-NO-GROUP-BY` and
  `WRAPPER-DELEGATES-ALIAS-AWARE`.
- Precondition: `ExpressionWrapper` is asked for group-by columns.
- Expected postcondition: the result is not `[self]` merely because the wrapper
  is non-aggregate; it is derived from the child.
- Evidence: E-001, E-004.
- Related findings: F-001.
- V2 status: satisfied because `ExpressionWrapper` overrides the inherited base
  method.

## PO-004: Legacy missing-alias child overrides remain on the deprecation path

- Formal claim: `WRAPPER-PRESERVES-LEGACY-DEPRECATION`.
- Precondition: the child expression defines `get_group_by_cols(self)` without
  an `alias` parameter.
- Expected postcondition: the wrapper emits `RemovedInDjango40Warning` using the
  existing message shape and calls the child method without `alias`; it does not
  raise `TypeError` solely because `alias` was forwarded.
- Evidence: E-005, E-006.
- Related findings: F-002.
- V2 status: satisfied by `inspect.signature(...)`, `warnings.warn(...)`, and
  `return self.expression.get_group_by_cols()` in the missing-alias branch.

## PO-005: Public API and frame conditions are preserved

- Formal claim: audit frame condition, enforced by the source-diff scope and
  proof write-up rather than a separate `.k` reachability claim.
- Precondition: existing callers use `ExpressionWrapper(...).get_group_by_cols`
  with zero arguments or `alias=...`.
- Expected postcondition: the wrapper method keeps the `alias=None` signature;
  `as_sql()`, source-expression accessors, `Value`, and `BaseExpression` behavior
  are unchanged; no test files are modified.
- Evidence: E-003, E-005.
- Related findings: F-002, F-003.
- V2 status: satisfied by the scoped edit in `expressions.py`.

## PO-006: FVK honesty gate

- Formal claim: proof status annotation rather than a code claim.
- Precondition: no execution environment and no permission to run tests or K
  tools.
- Expected postcondition: proof commands are emitted but not executed; no test
  removal is recommended except conditionally after machine checking.
- Evidence: task instructions and FVK docs.
- Related findings: F-004.
- V2 status: satisfied by artifact labeling.
