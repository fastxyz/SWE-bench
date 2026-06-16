# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent clause | Result | Notes |
| --- | --- | --- | --- |
| TO-ROTATION-MATRIX | Intent 1, 2 | PASS | Uses active Hamilton rotation as the independent reference. |
| MATRIX-APPLIES-HAMILTON-ROTATION | Intent 1, 2 | PASS | Proves matrix equivalence for all nonzero quaternion components. |
| REPORTED-X-AXIS | Intent 3 | PASS | Directly covers the issue reproducer. |
| Z-axis preservation in proof | Intent 4 | PASS | Confirms no convention flip. |
| POINT-ROTATION-ABOUT-V | Intent 5 | PASS | Follows from existing `v - M*v` branch with corrected `M12`. |
| Nonzero side condition | Intent 6 | PASS | Domain is intent/default-domain derived, not copied from the candidate patch. |
| Visible `q=(1,2,3,4)` test expectation | Intent 1-3 | FAIL AS LEGACY | The expected `M12 = 14/15` is candidate/legacy-derived and conflicts with the Hamilton-rotation claim. Recorded as F2. |
