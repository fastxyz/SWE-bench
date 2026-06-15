# Findings

Status: constructed from public evidence and source inspection; no tests,
Python, or K tooling were run.

## F1: Reported Crash Path Is Real and V2 Fixes It

- Classification: code bug, resolved.
- Input shape: `order_by('relation')` where the related model has
  `Meta.ordering = (OrderBy(F('name')), )` or `Meta.ordering = (Lower('name'), )`.
- Observed before fix: recursive related ordering expansion passed the
  expression item to `get_order_dir()`, which indexes `field[0]`; expressions
  are not strings, producing the reported non-subscriptable crash.
- Expected: expression ordering item is converted to an `OrderBy` expression
  and returned as an ordering pair.
- Evidence: E1-E3.
- Proof obligations: PO1, PO2.
- V2 status: satisfied by the early expression branch in `find_ordering_name()`.

## F2: V1 Assumed Every Non-F Child Was a Copyable Expression Tree

- Classification: code robustness issue, resolved by V2.
- Input shape: an expression tree whose `get_source_expressions()` includes a
  non-expression child node such as a conditional `Q` node.
- Observed in V1 by inspection: `_resolve_ordering_expression()` fell through
  to `expr.copy()` and `expr.get_source_expressions()` for every non-plain-F
  source. A non-expression child does not necessarily provide those methods.
- Expected: the helper should only recursively rewrite normal expression
  subtrees; other child nodes should be delegated unchanged to their own
  resolver.
- Evidence: E9.
- Proof obligations: PO6.
- V2 status: fixed by returning nodes without `get_source_expressions()`
  unchanged.

## F3: Conditional Q Lookup Strings Remain Outside the Proven Domain

- Classification: proof boundary / recommended follow-up.
- Input shape: related model `Meta.ordering` containing a conditional
  expression such as `Case(When(name='x', then=Value(0)), default=Value(1))`.
- Observed by source reasoning: V2 avoids a helper-level copy crash on the `Q`
  child, but it does not rewrite the `Q` lookup string to the related alias.
- Expected if full expression-family support is required: conditional lookup
  strings should resolve relative to the related model context, analogously to
  plain `F()` leaves.
- Evidence: broad expression API evidence E4-E7, but no public issue example
  specifically requires conditional `Q` ordering.
- Proof obligations: PO8.
- Recommendation: add an explicit public regression test before deepening the
  query API for alias-relative `Q` resolution in related default ordering.

## F4: Verification and Runtime Execution Were Not Performed

- Classification: honesty gate.
- Input shape: all claims and source changes.
- Observed: task instructions forbid running tests, Python, or K tooling.
- Expected: artifacts provide exact commands and constructed proof reasoning
  only; no machine-checked result is claimed.
- Proof obligations: all.
- Recommendation: when an execution environment is available, run the emitted
  `kompile`/`kprove` commands and the relevant Django ORM/admin regression
  tests.
