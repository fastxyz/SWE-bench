# Public Compatibility Audit

Status: constructed, not machine-checked.

| Symbol or protocol | Public compatibility question | Audit result |
|---|---|---|
| `xarray.core.computation.where(cond, x, y, keep_attrs=None)` | Did the signature change? | No. |
| `xr.where(..., keep_attrs=True)` | Did accepted input classes change? | No. Scalar, array, Variable, DataArray, and Dataset remain accepted by the documented API. |
| `apply_ufunc(..., keep_attrs=...)` call from `where` | Did the producer/consumer protocol change? | No. `where` still passes a bool/string/callable accepted by `apply_ufunc`; V1 only changes the callable implementation for `True`. |
| DataArray/Dataset `where` methods | Were method signatures or virtual dispatch changed? | No. V1 edits only top-level `xr.where`; method implementations remain untouched. |
| Public tests | Were test files modified? | No. The task forbids test edits; none were made. |

No public compatibility blocker was found.
