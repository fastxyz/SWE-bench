# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Adequacy of the Real-Window Spectrum Contract

The formal contract must encode the public intent that PSD spectrum scaling
with `scale_by_freq=False` uses the coherent-gain denominator
`sum(window)**2` for real-valued windows.

Linked findings: F1.

## PO2: Local Source Obligation for V1

In `_spectral_helper`, after the PSD cross-periodogram and one-sided scaling
are computed, the `scale_by_freq=False` branch must divide by
`window.sum()**2`, not by `np.abs(window).sum()**2`.

Linked findings: F1.

## PO3: Negative-Coefficient Discriminator

The proof must distinguish a passing and failing negative-window instance.
For `[3, -1]`, the expected V1 denominator is `4`; the pre-fix denominator is
`16`.

Linked findings: F1 and F4.

## PO4: Density-Branch Frame Condition

The `scale_by_freq=True` PSD branch must continue to divide by `Fs` and by
`(np.abs(window)**2).sum()`. For real windows this is `Fs * sum(window**2)`.

Linked findings: F2.

## PO5: Positive-Window Compatibility

For windows with all coefficients nonnegative, the V1 denominator equals the
legacy denominator because `sum(abs(w)) == sum(w)`.

Linked findings: F1 and F4.

## PO6: Complex-Window Scope Boundary

The proof must not use complex-valued windows to justify V1 as complete.
Complex windows are recorded as underspecified public intent.

Linked findings: F3.

## PO7: Public API and Callsite Compatibility

The fix must not change public signatures, argument defaults, return shapes, or
wrapper dispatch through `Axes` and `pyplot`.

Linked findings: F4.

