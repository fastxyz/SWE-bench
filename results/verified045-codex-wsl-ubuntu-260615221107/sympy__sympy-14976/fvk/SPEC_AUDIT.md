# Spec Audit

Status: constructed, not machine-checked.

| Claim | Adequacy Result | Reason |
| --- | --- | --- |
| C1 positive non-integer rational wraps numerator and denominator with mpmath `mpf` | PASS | Directly entails E1-E3: non-integer rationals are wrapped and no longer bare Python `p/q`. |
| C2 negative non-integer rational wraps magnitude and denominator with mpmath `mpf` | PASS | Same obligation as C1 for the negative branch; the public issue is not sign-specific, so all non-integer rationals in the printer domain must be covered. |
| C3 integer-valued rational prints as an integer | PASS | The precision defect is bare rational division. Integer output has no denominator and no Python division. |
| C4 mpmath lambdify reaches `MpmathPrinter` | PASS | Supported by public source path in `lambdify.py`; needed to connect the method proof to the user-visible issue. |
| C5 unqualified `mpf` is in namespace | PASS | Supported by `MODULES["mpmath"]` importing `from mpmath import *`. |
| C6 non-mpmath printers are unchanged | PASS | Public issue names `modules='mpmath'`; no public evidence asks to change other printer backends. |
| C7 surrounding expression preservation | PASS | Needed because the symptom appears inside a larger expression. Existing `CodePrinter`/`StrPrinter` precedence rules are the implementation evidence that wrapping does not alter grouping. |

No claim is supported only by legacy behavior. The pre-fix display `232/3` is marked as a SUSPECT legacy display: it is the reported bug symptom, not an expected output.
