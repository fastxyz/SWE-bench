# Spec Audit

Status: pass for the FVK-modeled obligations; constructed, not machine-checked.

| Formal obligation | Intent entry | Audit result | Notes |
| --- | --- | --- | --- |
| Cast only on bool/bool reducer operands. | INTENT-1, INTENT-6 | Pass | Public issue requires conversion for boolean dot; mixed cases are not implicated. |
| Bool/bool reduce returns integer 0/1 dot sum. | INTENT-1, INTENT-6 | Pass | Directly matches issue workaround and `_reduce` equivalence comment. |
| Boolean `sum_of_weights` returns numeric count when nonzero. | INTENT-2 | Pass | Matches prompt's `array(2)` denominator. |
| Zero denominator remains missing/invalid. | INTENT-4 | Pass | Existing behavior is independently supported by weighted docstring notes and source comments; V1 does not alter it. |
| Issue mean is `Ratio(2, 2)` = `1.0`. | INTENT-3 | Pass | Numerator and denominator are both externally derived from the issue example. |
| Public API shape unchanged. | INTENT-5 | Pass | V1 changes only an internal branch in `_reduce`; no signatures or call protocol changed. |

No claim is derived solely from the candidate implementation. The only
implementation-derived facts used are control-flow facts needed to localize the
guard and source lines under audit.
