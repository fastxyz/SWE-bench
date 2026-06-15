# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1 - Resolved Code Bug: Shared Combined Query State

Evidence: `benchmark/PROBLEM.md` shows an ordered `union()` queryset `qs`, then a
derived `qs.order_by().values_list('pk', flat=True)`, then later evaluation of
`qs` failing with "ORDER BY position 4 is not in select list".

Observed in V0 model: `Query.clone()` shallow-copied `combined_queries`, so a
derived combined queryset could share component `Query` objects with the original
combined queryset.

Expected: a queryset derived from `qs` must not mutate `qs` or the component
queries used by `qs`.

Proof obligations: PO1, PO2, PO3, PO4.

Status: resolved by V1. `Query.clone()` now recursively clones each query in
`combined_queries`, giving derived combined querysets independent component
queries.

## F2 - Confirmed Scope: Compiler-Local Cloning Is Not the Central Contract

Evidence: `repo/django/db/models/sql/compiler.py` already clones a branch query
before applying `set_values()` in the limited-select combined-query path.

Observed risk: relying only on that call-site protects one compiler path but does
not make `Query.clone()` satisfy the general queryset derivation ownership
contract for combined query components.

Expected: the clone boundary itself must produce a combined query whose component
queries are owned by the clone.

Proof obligations: PO2, PO3, PO6.

Status: no additional source edit needed beyond V1. V1 fixes the ownership
contract at `Query.clone()`, while the existing compiler-local clone remains a
defensive local copy.

## F3 - Confirmed Compatibility: No Public API Shape Change

Evidence: V1 changes only the body of `Query.clone()` and does not change method
arguments, return type, queryset methods, SQL compiler method signatures, or test
files.

Observed: callers still call `Query.clone()` and `Query.chain()` the same way.

Expected: source fix should preserve public and internal call signatures.

Proof obligations: PO5.

Status: satisfied. No compatibility-driven source change is needed.

## F4 - Proof Boundary: Full SQL Semantics Not Modeled

Evidence: FVK was run under the task constraint that no tests, Python, or K
tooling may execute.

Observed: this proof models component-query ownership, projection mutation, and
order-position validity. It does not model the full Django SQL compiler or every
database backend.

Expected: the proof should be used to justify the ownership fix, while normal
test execution and backend coverage remain necessary outside this no-execution
workspace.

Proof obligations: PO7.

Status: residual verification boundary, not a source-code bug found in V1.

## F5 - No New Code Findings Against V1

Evidence: the adequacy check in `fvk/SPEC.md` maps the issue's failure to shared
component query ownership, and PO1-PO5 discharge that ownership contract for V1.

Observed: no proof obligation required a further production-code edit.

Expected: V1 may stand if clone preservation, clone isolation, mutation framing,
issue postcondition, and compatibility all hold.

Proof obligations: PO1, PO2, PO3, PO4, PO5.

Status: V1 stands unchanged.
