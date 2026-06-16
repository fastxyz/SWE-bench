# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change in
`repo/lib/matplotlib/mlab.py::_spectral_helper`, limited to the PSD
normalization branch:

- `mode == "psd"`;
- `scale_by_freq == False`;
- real-valued window coefficients;
- `len(window) == NFFT`;
- `window.sum() != 0`, because spectrum scaling by coherent gain is undefined
  for a zero coherent gain window.

All detrending, stride-window extraction, FFT computation, one-sided frequency
doubling, averaging, plotting, and wrapper behavior are treated as frame
conditions except where they feed the pre-normalization spectral value.

## Intended Contract

Let `RAW[k, j]` be the cross-periodogram bin produced by `_spectral_helper`
after windowing, FFT, cross multiplication, and one-sided/two-sided frequency
scaling, but before the final PSD window normalization.

For real window coefficients `w[0..NFFT-1]`:

- If `scale_by_freq` is false, the returned spectrum bin is:
  `RAW[k, j] / (sum(w) ** 2)`.
- If `scale_by_freq` is true, the returned density bin remains:
  `RAW[k, j] / (Fs * sum(abs(w) ** 2))`.
- For windows whose coefficients are all nonnegative,
  `sum(abs(w)) == sum(w)`, so V1 preserves the legacy result.
- For real windows containing negative coefficients, the denominator must use
  the signed coherent gain `sum(w)`, not `sum(abs(w))`.

The issue discussion leaves complex-valued window coefficients underspecified.
This specification therefore does not use complex windows to justify either
V1 or a further code change.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt/issue | "Windows correction is not correct in `mlab._spectral_helper`" | Audit the helper's PSD window correction. | Encoded |
| E2 | prompt/issue | "`np.abs` is not needed, and give wrong result for window with negative value, such as `flattop`" | Do not sum absolute window coefficients for spectrum normalization. | Encoded |
| E3 | prompt/issue | "To trigger the bug, you need `mode = 'psd'` and `scale_by_freq = False`" | The required repair is in the non-density PSD branch. | Encoded |
| E4 | prompt/issue | "For real value of window, `np.abs(window)**2 == window**2`, while `np.abs(window).sum()**2 != window.sum()**2`" | Density scaling is not the reported fault for real windows; spectrum scaling is. | Encoded |
| E5 | prompt/issue | "For `spectrum`: `P(f_k) = |X_k / sum w_n|^2`" | The coherent-gain denominator is `(sum(w))**2` for real windows. | Encoded |
| E6 | prompt/issue | "ignore the complex case, and simply drop the `np.abs()`" | Complex windows are not an intent-derived repair target. | Finding F3 |
| E7 | code/docs | `scale_by_freq : bool` controls density vs non-density PSD scaling | Preserve the public keyword and return shape. | Encoded |
| E8 | public tests | Existing test checks the scale relation with a Hann window | Positive-window behavior must remain compatible, but this test is not a negative-window oracle. | Encoded as frame/test gap |

## Formalization Boundary

The K artifact `fvk/mini-spectral.k` models only the arithmetic choice that
distinguishes the bug:

- `signedSum(W) * signedSum(W)` is the V1 denominator.
- `absCoeffSum(W) * absCoeffSum(W)` is the pre-fix denominator.
- `RAW` is opaque, so the proof does not depend on FFT implementation details.

This abstraction is property-complete for the defect because a negative-window
example, `[3, -1]`, maps to different observable denominators:

- coherent-gain denominator: `(3 + -1)^2 == 4`;
- coefficient-wise absolute denominator: `(abs(3) + abs(-1))^2 == 16`.

