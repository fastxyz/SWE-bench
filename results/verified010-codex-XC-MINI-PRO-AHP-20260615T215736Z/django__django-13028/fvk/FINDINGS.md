# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations.

## F-01: Original collision between user data and expression metadata

Classification: code bug, fixed by V1 and preserved by V2.

Input: a foreign key equality lookup whose RHS is a model instance with a
Boolean field or attribute `filterable=False`, and no `resolve_expression`
method.

Observed before the fix: `check_filterable()` read the RHS `filterable`
attribute and raised `NotSupportedError`, producing the issue traceback.

Expected: the RHS is ordinary lookup data. It must continue to normal lookup and
related-object validation instead of being rejected as a non-filterable
expression.

Evidence: E-01, E-02, E-03.

Related obligations: PO-01, PO-04.

Status: fixed by the early return for objects without `resolve_expression`.

## F-02: V1 still partially treated non-expressions as expression containers

Classification: proof-derived code improvement, fixed by V2.

Input: an ordinary RHS value without `resolve_expression` but with an unrelated
application method named `get_source_expressions`.

Observed in V1 by source inspection: the `filterable` flag was gated by
`resolve_expression`, but the recursive `get_source_expressions()` walk could
still run on that non-expression value.

Expected: expression-container traversal is part of the ORM expression
protocol. Non-expression RHS values should return from `check_filterable()`
before any expression-only metadata or methods are inspected.

Evidence: E-03 and E-05.

Related obligations: PO-01, PO-03.

Status: fixed by V2 changing `check_filterable()` to return immediately when
`resolve_expression` is absent.

## F-03: Non-filterable real expressions must remain rejected

Classification: preservation obligation, satisfied.

Input: a real ORM expression with `resolve_expression` and `filterable=False`,
such as the `Window` expression class.

Observed in V2 by source inspection: after the non-expression early return,
`check_filterable()` still raises `NotSupportedError` when
`getattr(expression, 'filterable', True)` is false.

Expected: the internal `filterable=False` expression contract remains enforced.

Evidence: E-04.

Related obligations: PO-02.

Status: satisfied.

## F-04: Recursive validation of real expression sources must remain intact

Classification: preservation obligation, satisfied.

Input: a filterable expression with source expressions, at least one of which is
a real non-filterable expression.

Observed in V2 by source inspection: once the parent object is known to expose
`resolve_expression`, the existing `get_source_expressions()` loop still
recursively calls `check_filterable()` on each source.

Expected: nested non-filterable expressions remain rejected from filter clauses.

Evidence: E-04.

Related obligations: PO-03.

Status: satisfied.

## F-05: No execution evidence is available

Classification: verification boundary / test gap.

Input: the V2 patch and constructed FVK claims.

Observed: the benchmark forbids executing tests, Python, `kompile`, or
`kprove`.

Expected: the proof and test recommendations must be labeled constructed, not
machine-checked. Existing tests must not be removed based on this run.

Related obligations: PO-06.

Status: open verification boundary, not a code bug.
