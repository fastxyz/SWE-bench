# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict | Notes |
| --- | --- | --- | --- |
| C1 SHORT-VERBOSE | I1, I2 | Pass | Directly encodes parity between `-v` and no-value `--verbose`. |
| C2 SHORT-VERBOSE-AFTER-FILE | I1, I4 | Pass | Matches the reported command shape `pylint mytest.py -v` by preserving the file arg and consuming only `-v`. |
| C3 SHORT-VERBOSE-VALUE-ERROR | I2 | Pass | Keeps verbose as a no-value flag and mirrors existing long-option no-value behavior. |
| C4 SEPARATOR-FRAME | I4, I5 | Pass | Prevents the V1 single-dash scan from consuming `-v` after the standard command-line separator. |
| C5 VERBOSE-NARGS-ZERO | I3 | Pass | Directly addresses help/parser metadata advertising `VERBOSE`. |

No claim is derived solely from legacy behavior. The pre-fix error text is treated as SUSPECT evidence because the issue identifies it as the bug.
