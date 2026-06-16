# Baseline Notes

## Root Cause

`mlab._spectral_helper` applies two different PSD normalization paths. The
`scale_by_freq=True` path divides by the sum of squared window magnitudes,
which is appropriate for a spectral density. The `scale_by_freq=False` path is
for a power spectrum and should divide by the square of the window coherent
gain.

That non-density path instead used `np.abs(window).sum()**2`. For windows with
negative coefficients, such as a flattop window, summing the absolute
coefficients makes the denominator larger than the coherent gain denominator.
This under-scales the returned spectrum compared with the expected spectrum
normalization.

## Changed Files

`repo/lib/matplotlib/mlab.py`

Changed the `mode == "psd"` and `scale_by_freq=False` window correction from
`np.abs(window).sum()**2` to `window.sum()**2`. This keeps positive-only windows
unchanged while correctly handling real-valued windows with negative
coefficients. The adjacent comment now names the coherent-gain normalization so
the reason for preserving the signed sum is explicit.

## Assumptions and Alternatives

I assumed the intended behavior is the real-window spectrum normalization
described in the issue discussion: use the signed window sum for
`scale_by_freq=False`, while keeping the existing squared-magnitude window norm
for `scale_by_freq=True`.

I considered changing the denominator to `np.abs(window.sum())**2`, which would
also fix real-valued negative-coefficient windows and would be more conservative
for hypothetical complex windows. I rejected that for this targeted fix because
the existing code path and the issue discussion point to matching the
non-density spectrum correction used for real windows by dropping the
coefficient-wise absolute value. Complex window semantics are not clarified by
the issue and changing them more broadly would be beyond the reported bug.

I did not modify any tests, and I did not run tests or project code because the
task instructions explicitly prohibit doing so in this session.
