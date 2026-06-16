# FVK Findings

Status: constructed, not machine-checked.

## F1: Resolved Code Bug - Univariate Non-Canonical Zero

Input class: a univariate dense polynomial whose leading coefficient is not
recognized as zero before denominator clearing, but becomes exact zero after
multiplication by the common denominator.

Observed in the issue before the fix: `clear_denoms()` can produce
`DMP([EX(0)], EX, None)`, so the resulting `Poly` prints as zero but has
`is_zero == False`.

Expected: the dense representation of zero is `[]`.

V1 status: resolved by `dup_clear_denoms` applying `dup_strip(f)` after
denominator multiplication and before returning or converting.

Proof obligations: PO2, PO3, PO6.

## F2: Resolved Completeness Gap - Recursive Dense Polynomials Need Recursive Strip

Input class: a recursive dense polynomial whose inner coefficient polynomial
becomes `[0]` after denominator clearing.

Risk in a weaker fix: applying only top-level `dmp_strip` would not recognize an
inner `[0]` as zero, so a multivariate analogue of the issue could remain.

Expected: inner coefficient polynomials are stripped first, then outer leading
zero polynomial coefficients are stripped.

V1 status: resolved by `dmp_clear_denoms` applying `_rec_strip(f, u)`.

Proof obligations: PO4, PO6.

## F3: Confirmed Non-Issue - Generic Ground Multiplication Was Not Changed

Input class: all callers of `dup_mul_ground` and `dmp_mul_ground`.

Finding: the issue can be repaired in `clear_denoms` without changing generic
ground multiplication. This avoids broadening the behavior change to unrelated
dense arithmetic paths.

V1 status: keep unchanged.

Proof obligations: PO1, PO2, PO7.

## F4: Confirmed Compatibility - API Shape Preserved

Input class: public and internal callsites expecting `(common, dense_result)` or
`(coeff, Poly)`.

Finding: V1 changes no function signatures and no return arities. Existing
callers receive the same tuple shape and a stricter valid dense representation.

V1 status: keep unchanged.

Proof obligations: PO7.

## F5: Honesty Gate - Proof Is Constructed, Not Machine-Checked

Input class: the FVK proof artifacts themselves.

Finding: this benchmark forbids running tests, Python, or K tooling. The proof is
therefore a constructed proof only.

Expected next action outside this benchmark: run the recorded `kompile`, `kast`,
and `kprove` commands, plus the project tests, before treating the proof as
machine checked or removing any tests.

Proof obligations: all.
