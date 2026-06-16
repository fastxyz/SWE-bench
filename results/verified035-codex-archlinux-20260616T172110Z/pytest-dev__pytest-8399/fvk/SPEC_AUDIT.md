# Spec Audit

Constructed, not machine-checked.

| Formal item | Intent entries | Audit | Notes |
| --- | --- | --- | --- |
| C1 | I1, I3, E1, E2 | Pass | Matches the reported unittest `setUpClass` example and the issue's suggested diff. |
| C2 | I1, I2, E5 | Pass | The unittest helper also generates a unittest `setup_method` fixture; E5 requires all generated fixtures, not only the example. |
| C3 | I2, E5 | Pass | Module-level xunit setup is a sibling generated fixture name in `python.py`. |
| C4 | I2, E5 | Pass | Function-level xunit setup is a sibling generated fixture name in `python.py`. |
| C5 | I2, E4, E5 | Pass | Matches the xunit class example from the issue hint. |
| C6 | I2, E5 | Pass | Method-level xunit setup is a sibling generated fixture name in `python.py`. |
| C7 | I3, E3, E6 | Pass | The source listing rule skips underscore names for non-verbose output. |
| C8 | I4, E3 | Pass | The issue allows private fixtures to appear with `-v`; the fixtures remain registered. |
| Frame claim F | I5, E7, E8 | Pass | The source diff changes only `name=` strings; no behavior body or public signature changes are specified. |

No formal item is candidate-derived without public intent support. No item is
marked ambiguous.
