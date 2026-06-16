# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## Claims Proved by Construction

The proof targets `repo/lib/matplotlib/mlab.py::_spectral_helper` on the
domain in `SPEC.md`.

1. For `mode == "psd"` and `scale_by_freq=False`, the V1 source divides the
   pre-normalization PSD bin by `window.sum()**2`.
2. For a negative-coefficient real window, this differs from the legacy
   coefficient-wise absolute denominator and matches the public intent.
3. For `scale_by_freq=True`, the density branch remains unchanged.
4. Public wrappers continue to delegate to `mlab` with the same signatures and
   return shapes.

## Symbolic Execution Sketch

Let `RAW` denote the PSD cross-periodogram bin after window multiplication,
FFT, cross multiplication, and one-sided scaling. Those operations are framed:
the issue does not report an FFT or one-sided scaling fault.

In V1, the relevant source branch is:

```python
if scale_by_freq:
    result /= Fs
    result /= (np.abs(window)**2).sum()
else:
    result /= window.sum()**2
```

For the audited branch, the path condition is:

```text
mode == "psd" and scale_by_freq == False
```

Symbolic execution takes the `else` branch and rewrites:

```text
RAW -> RAW / (sum(window) ** 2)
```

For real `window = [3, -1]`:

```text
sum(window) ** 2 == (3 + -1) ** 2 == 4
sum(abs(window)) ** 2 == (3 + 1) ** 2 == 16
```

Thus the V1 expression satisfies PO2 and PO3, while the pre-fix expression
violates them. For any real window with all entries nonnegative,
`sum(abs(window)) == sum(window)`, so V1 preserves the legacy result and
satisfies PO5.

For the density branch, symbolic execution under `scale_by_freq=True` reaches
the untouched source expression:

```text
RAW -> RAW / Fs / sum(abs(window) ** 2)
```

This satisfies PO4.

## K Artifacts

The K model is deliberately minimal:

- `fvk/mini-spectral.k` defines a tiny spectral-normalization language over an
  opaque raw bin and a list of integer coefficients.
- `fvk/spectral-helper-spec.k` states claims for V1 normalization, legacy
  normalization, the negative-window discriminator, and the density frame.

The model abstracts real-valued windows to exact integer coefficients for the
proof discriminator. This is adequate for the bug because the defect is the
placement of `abs` relative to summation, and integer windows with a negative
coefficient preserve that distinction.

## Reproduce the Machine Check Later

These commands are emitted for later use only:

```sh
cd fvk
kompile mini-spectral.k --backend haskell
kast --backend haskell spectral-helper-spec.k
kprove spectral-helper-spec.k
```

Expected result after a real machine check: `#Top` for the stated claims.

## Test Redundancy Recommendation

No test deletion is recommended. The proof is constructed, not machine-checked,
and the visible Hann-window test exercises a positive-window frame condition.

Recommended additional test, without editing tests in this task: compare
`mlab.psd(..., scale_by_freq=False, window=<negative-coefficient real window>)`
against the coherent-gain spectrum normalization or an independent reference.

## Residual Risk

The proof is partial correctness over the normalization expression, not a full
formalization of NumPy arrays, FFT, detrending, plotting, or termination.
Complex-valued windows remain outside the proven domain because the public
intent is ambiguous.

