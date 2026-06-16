# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 Fixes the Reported Real-Window Spectrum Scaling Bug

Evidence: SPEC ledger entries E2, E3, and E5; proof obligations PO1 and PO2.

Input class: real-valued window coefficients with at least one negative value,
`mode == "psd"`, and `scale_by_freq == False`.

Observed before V1: `_spectral_helper` divided by
`np.abs(window).sum()**2`. For a discriminator window `[3, -1]`, that
denominator is `16`.

Expected: divide by the coherent gain denominator `window.sum()**2`. For
`[3, -1]`, that denominator is `4`.

V1 status: fixed. The production code now divides by `window.sum()**2` in the
non-density PSD branch.

## F2: Density Scaling Is a Frame Condition, Not the Reported Fault

Evidence: SPEC ledger entries E3 and E4; proof obligation PO4.

Input class: real-valued windows with `mode == "psd"` and
`scale_by_freq == True`.

Expected: retain normalization by `Fs * sum(abs(window)**2)`.

V1 status: unchanged. The V1 patch does not alter the density branch.

## F3: Complex Window Coefficients Are Underspecified

Evidence: SPEC ledger entry E6; proof obligation PO6.

Input class: complex-valued window coefficients.

Observed: the public issue discusses uncertainty around complex windows and
suggests ignoring them for this repair. A formula in the discussion mentions
`abs(sum(w))**2`, but the concrete requested code direction for this bug is to
drop the coefficient-wise `np.abs()` in the real-window spectrum branch.

Expected: no intent-derived production change in this pass.

V1 status: stands unchanged. Complex-window behavior should be clarified in a
separate issue before changing the denominator to `abs(window.sum())**2` or
dropping support.

## F4: Public Tests Cover Positive Windows but Not the Regressed Case

Evidence: SPEC ledger entry E8; proof obligations PO3 and PO7.

Input class: negative-coefficient real windows such as flattop.

Observed: the visible in-repository test checks a Hann-window scale relation.
Because Hann coefficients are nonnegative, both the old and new denominators
are equal.

Expected: a regression test should use a negative-coefficient real window and
`scale_by_freq=False`.

V1 status: no test files were edited, per task instructions. This is a test
gap, not a production-code blocker.

## Proof-Derived Findings from `/verify`

No proof obligation over the stated real-window domain forced a source change
beyond V1. The only open proof-derived item is F3, which is classified as
underspecified intent rather than a code bug in this task.

