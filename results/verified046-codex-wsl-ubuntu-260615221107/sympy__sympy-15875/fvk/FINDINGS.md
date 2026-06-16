# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## F1: Legacy Add imaginary boolean was unsound

Input class: `Add` with zero real part and multiple definitely imaginary
addends that may cancel. Concrete public example:
`-2*I + (1 + I)**2`.

Observed before the fix: the handler collapsed "there is at least one
imaginary addend" to a boolean and returned `False`.

Expected from public intent: `is_zero` must not return a wrong boolean. If the
handler cannot decide cancellation quickly, it should return `None`.

Classification: code bug.

Status: fixed. V2 stores imaginary addends as real coefficients and returns
`None` when multi-term cancellation is possible and not locally disproved.

Related proof obligations: PO1, PO2, PO4.

## F2: V1 delegated a multi-term `False` to coefficient-sum `is_zero`

Input class: a zero-real-part Add with more than one definitely imaginary term
whose coefficient sum is not locally same-sign and whose coefficient-sum
`is_zero` subquery returns `False`.

Observed in V1: V1 returned that `False` directly.

Expected from the FVK spec: a multi-term imaginary group should produce
`False` only from local facts that rule out cancellation: one term, or
same-sign real coefficients. Otherwise it should return `None` unless the
coefficient sum is known zero, which supports `True`.

Classification: proof-derived robustness finding. This is not a known concrete
failure from public tests; it is a proof-base reduction that avoids using an
arbitrary recursive `False` as the Add-level nonzero certificate.

Status: fixed in V2. The code now uses the coefficient-sum subquery only for
`True`; multi-term `False` requires singleton or same-sign evidence.

Related proof obligations: PO3, PO4, PO5.

## F3: Single imaginary nonzero compatibility must be preserved

Input class: `zero + I`, represented by zero real part and exactly one
definitely imaginary addend.

Observed public behavior: existing source tests assert `(a + I).is_zero is
False` for `a` known zero.

Expected from public intent and assumptions docs: since `0` is not imaginary,
a single definitely imaginary addend is nonzero.

Classification: compatibility obligation.

Status: preserved. V2 returns `False` for exactly one definitely imaginary
addend when the real part is zero and there is no imaginary-or-zero term.

Related proof obligations: PO6.

## F4: Imaginary-or-zero terms must stay unknown when real part is zero

Input class: `zero + r*I` for a real symbol `r` of unknown zero status.

Observed public behavior: existing source tests assert `(a + r*I).is_zero is
None` for `a` known zero and `r` unknown real.

Expected: the term may be zero, so the Add handler must not classify the
result as definitely nonzero.

Classification: compatibility obligation.

Status: preserved. V2 still uses `im_or_z` for `(I*a).is_real` terms that are
not definitely imaginary, and returns `None` when the real part is zero.

Related proof obligations: PO7.

## F5: Residual trusted base

Input class: all Add inputs whose classification depends on lower-level SymPy
assumptions.

Observed in this FVK pass: the local proof needs soundness of lower-level
queries (`is_real`, `is_imaginary`, `is_zero`, and sign predicates). FVK did
not verify the entire assumptions lattice.

Expected: this is acceptable for a local proof if it is explicit and the code
does not add a new unsound inference on top of those subqueries.

Classification: proof capability boundary.

Status: open as trusted base, not a code bug in this task.

Related proof obligations: PO8.
