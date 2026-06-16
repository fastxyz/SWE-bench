# Public Compatibility Audit

Constructed, not machine-checked.

| ID | Symbol or behavior | Public compatibility check | Status |
| --- | --- | --- | --- |
| C1 | `matplotlib.get_backend()` | Signature and return type stay unchanged. It still returns the backend string from global rcParams access. | Compatible |
| C2 | `RcParams.__getitem__("backend")` on global `rcParams` | Initial lazy resolution still imports pyplot and calls `switch_backend(auto)` when no backend is loaded. Loaded-backend stale-sentinel reads now reuse the loaded backend and do not close figures. | Compatible with intent |
| C3 | `RcParams.__getitem__("backend")` on standalone `RcParams` | The global-only guard remains; standalone `RcParams` instances do not resolve the sentinel. | Compatible |
| C4 | `pyplot.switch_backend()` | Signature and destructive close-on-real-switch behavior are unchanged. | Compatible |
| C5 | `rc_context()` | Signature and generic rc restoration remain unchanged. The repair handles the stale sentinel at backend read time. | Compatible |

## Callsite Notes

Public callsites that read `rcParams["backend"]` receive the same value they
would receive from `get_backend()` in the loaded-backend stale-sentinel state,
without the destructive side effect. Public callsites that explicitly request a
backend switch still route through `pyplot.switch_backend()`.
