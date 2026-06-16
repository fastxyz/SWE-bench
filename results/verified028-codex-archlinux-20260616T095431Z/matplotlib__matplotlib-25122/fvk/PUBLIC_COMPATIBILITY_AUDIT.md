# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

No public function signatures, keyword defaults, return shapes, classes, or
module exports were changed.

## Public Callsites and Wrappers

| Caller | Relationship | Compatibility result |
|---|---|---|
| `matplotlib.mlab.psd` | Calls `csd(..., scale_by_freq=scale_by_freq)` and returns `Pxx.real, freqs` | Compatible |
| `matplotlib.mlab.csd` | Calls `_spectral_helper(..., mode="psd")` | Compatible |
| `matplotlib.mlab.specgram` | Calls `_spectral_helper(..., mode=mode)` | Compatible for PSD mode |
| `Axes.psd` | Delegates to `mlab.psd` | Compatible |
| `Axes.csd` | Delegates to `mlab.csd` | Compatible |
| `Axes.specgram` | Delegates to `mlab.specgram` | Compatible |
| `pyplot.psd/csd/specgram` | Delegates to corresponding `Axes` methods | Compatible |

## Compatibility Conclusion

The fix changes only a numeric denominator in an internal helper branch. It
does not require caller, subclass, or wrapper updates.

