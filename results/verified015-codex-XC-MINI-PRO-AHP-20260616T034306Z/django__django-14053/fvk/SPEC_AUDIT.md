# Spec Audit

Status: constructed, not machine-checked.

| Formal English Item | Intent Items | Result | Notes |
| --- | --- | --- | --- |
| POST-PROCESS-SUCCESS emits non-adjustables once and adjustable finals once. | I1, I2, I3, I4 | Pass | This matches the issue's required one-line final output while preserving internal passes. |
| POST-PROCESS-SUCCESS hides intermediate adjustable events. | I3 | Pass | Directly follows the public statement that intermediate files are lower-level implementation details. |
| POST-PROCESS-FIRST-PASS-ERROR yields the exception immediately and stops. | I5 | Pass | Matches collectstatic's exception consumer contract. |
| POST-PROCESS-REPEAT-PASS-ERROR yields the exception immediately and stops. | I5 | Pass | Same tuple-level failure behavior after buffering. |
| POST-PROCESS-MAX-ERROR yields `All` error and does not flush adjustable successes. | I6, I3 | Pass | Preserves the existing error while avoiding successful exposure of internal adjustable pass details. |
| Compatibility claim preserves tuple shape and signature. | I7 | Pass | No signature or tuple shape changes were made. |

No required behavior is marked fail or ambiguous.
