# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Summary preservation on default wrapper

- Claim: resolving an aggregate with `default` must return a `Coalesce` wrapper whose `is_summary` equals the resolved aggregate's `is_summary`.
- Intent evidence: E1, E3, E5, E6.
- Source evidence: `Aggregate.resolve_expression()` obtains `c` from `super().resolve_expression(..., summarize)`, then wraps it in `Coalesce`.
- V1 discharge: `coalesce.is_summary = c.is_summary`.
- K claim: `TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID` and `NONTERMINAL-DEFAULT-NOT-SUMMARY`.

## PO2: Valid outer aggregate plan after `annotate()`

- Claim: when existing annotations force a subquery and the aggregate expression is terminal, `Query.get_aggregation()` must move the expression to the outer query so the outer select is not empty.
- Intent evidence: E1 and E2.
- Source evidence: `get_aggregation()` moves expressions only under `if expression.is_summary`.
- V1 discharge: PO1 makes the generated wrapper summary in the terminal path.
- K claim: `plan(true, resolve(true, terminal)) => valid`.

## PO3: Non-terminal annotation frame condition

- Claim: resolving a defaulted aggregate as a normal annotation must not mark the generated wrapper as terminal summary.
- Intent evidence: E6 and public compatibility expectations for annotations.
- Source evidence: `BaseExpression.resolve_expression()` uses `summarize` to set `is_summary`; non-terminal annotation resolution passes `False`.
- V1 discharge: copying `c.is_summary` yields `False` for non-terminal annotations.
- K claim: `isSummary(resolve(true, nonTerminal)) => false`.

## PO4: Public compatibility

- Claim: the fix must not change public signatures or expression return families.
- Intent evidence: local bug-fix scope E5.
- Source evidence: no constructor, method signature, subclass, or callsite shape changes.
- V1 discharge: only wrapper metadata is added.
- K claim: represented as a frame condition in `TERMINAL-NO-DEFAULT-VALID`; documented in `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO5: Adequacy and honesty gate

- Claim: the formal model must distinguish the reported failing state from the repaired state and must be labeled constructed, not machine-checked.
- Intent evidence: FVK methodology.
- Discharge: `PREFIX-REGRESSION-SHAPE` models the pre-fix invalid path; `TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID` models V1's valid path; all proof artifacts include the caveat that no tooling was run.
