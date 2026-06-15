# Intent Spec

Status: constructed from public evidence, not machine-checked.

I-1. A distinct aggregate must render `DISTINCT` as a separate SQL token before the aggregate expression.

Evidence: `benchmark/PROBLEM.md` says a Count annotation with a `Case` condition and `distinct=True` produces `COUNT(DISTINCTCASE WHEN ...)` and that "A space is missing".

I-2. The required behavior applies to `Count(..., distinct=True)` when the aggregate expression is a `Case` expression, including backend paths that represent conditional aggregation as `CASE WHEN ...`.

Evidence: `benchmark/PROBLEM.md` names a `Count` annotation containing both a `Case` condition and `distinct=True`, and says the error occurs "whatever the db backend".

I-3. Existing non-distinct aggregate rendering is out of the bug's change intent and should be preserved.

Evidence: the issue only identifies malformed SQL when `distinct=True`; no public evidence requests a changed shape for non-distinct aggregates.

I-4. Public API compatibility must be preserved.

Evidence: the bug is in SQL rendering, not in constructor signatures, `as_sql()` call signatures, return type shape, or parameter semantics.
