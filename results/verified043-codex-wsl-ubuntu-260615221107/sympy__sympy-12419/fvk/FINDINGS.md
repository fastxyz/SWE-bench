# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and proof construction only.

## F1: V1 fixed the entry-level root cause

Input: `Identity(n)[i, j]` where `i` and `j` are symbolic integer indices and equality is undecidable.

Pre-V1 observed behavior: `Identity._entry` used `if i == j: ... else: S.Zero`, so structurally different symbols were treated as definitely off-diagonal.

Expected behavior: preserve the equality condition as `KroneckerDelta(i, j)`.

Trace: E3-E5, PO1-PO3.

Resolution: V1 changed `Identity._entry` to return `KroneckerDelta(i, j)`. This finding is closed.

## F2: V1 did not fully discharge the nested-sum output form

Input: `Sum(Sum(e[i, j], (i, 0, n - 1)), (j, 0, n - 1)).doit()` where `e` is an identity matrix and `n` is a positive integer symbol.

V1 behavior by static construction: the inner sum can become `Piecewise((1, Interval(0, n - 1).as_relational(j)), (0, True))`. The existing `eval_sum` code folded Piecewise only when conditions did not depend on the summation variable, so the outer sum could remain partially unevaluated instead of becoming `n`.

Expected behavior: the total sum over the same finite identity-matrix interval is `n`.

Trace: E3, E7, PO4-PO5.

Resolution: V2 adds a narrow `eval_sum` branch for the exact-interval, zero-fallback Piecewise form. This finding is closed by source edit.

## F3: `Piecewise(Eq(i, j))` was rejected for the identity entry

Input: symbolic `Identity(n)[i, j]` used inside nested sums.

Observed risk: a direct `Piecewise((1, Eq(i, j)), (0, True))` can preserve the condition locally, but the public discussion records worse nested-sum behavior than `KroneckerDelta`.

Expected behavior: use the canonical delta representation that existing summation code recognizes.

Trace: E5, PO3-PO4.

Resolution: keep `KroneckerDelta(i, j)` in `Identity._entry`.

## F4: Broader Piecewise implication simplification remains out of scope

Input: a Piecewise condition logically equivalent to, but not syntactically equal to, `Interval(a, b).as_relational(i)`.

Observed behavior after V2: the new `eval_sum` branch does not fire unless the condition is the exact interval relation used by `deltasummation`.

Expected behavior for this issue: only the exact interval relation produced by summing a `KroneckerDelta` must be collapsed.

Trace: PO5, PO7.

Resolution: no further code change. A general logical implication engine for arbitrary Piecewise conditions is outside the issue scope and would need separate specification.

## F5: Proof and test-removal claims are not machine-checked

Input: all proof obligations in this FVK run.

Observed limitation: no K, Python, or test commands were run.

Expected process: label the proof as constructed, not machine-checked, and keep test files unchanged.

Trace: PO8.

Resolution: artifacts include exact commands that could be run later; no tests were modified.

