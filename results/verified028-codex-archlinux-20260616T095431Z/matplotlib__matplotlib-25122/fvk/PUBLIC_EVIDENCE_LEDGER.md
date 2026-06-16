# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
|---|---|---|---|
| E1 | Issue | "Windows correction is not correct in `mlab._spectral_helper`" | Audit `_spectral_helper` normalization. |
| E2 | Issue | "`np.abs` is not needed" | Remove coefficient-wise absolute summation from the affected branch. |
| E3 | Issue | "wrong result for window with negative value, such as `flattop`" | Include negative real coefficients in the intended domain. |
| E4 | Issue | "To trigger the bug, you need `mode = 'psd'` and `scale_by_freq = False`" | Scope the repair to non-density PSD scaling. |
| E5 | Issue | "`np.abs(window)**2 == window**2`, while `np.abs(window).sum()**2 != window.sum()**2`" | Preserve density scaling; change spectrum denominator. |
| E6 | Issue | "`P(f_k) = |X_k / sum w_n|^2`" | Use coherent-gain denominator for real spectrum scaling. |
| E7 | Issue | "ignore the complex case" | Treat complex windows as out of scope/underspecified. |
| E8 | Code/docs | `scale_by_freq : bool` public parameter | Preserve public API and branch meaning. |
| E9 | Public tests | Hann-window scale relation | Positive-window compatibility evidence only. |

