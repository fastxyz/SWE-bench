# SPEC_AUDIT.md

Status: constructed, not machine-checked.

| Formal entry | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| MODE-GETTER | Intent 1, 2 | Pass | Implements the public hint and removes the delegated binary-mode defect. |
| MODE-NO-B | Intent 1, 4 | Pass | Prevents third-party code from selecting bytes writes based on wrapper mode. |
| BUFFER-MODE-PRESERVED | Intent 3 | Pass | Keeps the underlying mode inspectable through `.buffer.mode`. |
| STRIPB-PRESERVES-NON-B | Intent 2 | Pass | Matches `replace("b", "")`, not an over-specific V1-only behavior. |
| WRITE-FRAME | Intent 4 | Pass | The issue concerns advertised mode, not widening `write`. |
| DELEGATION-FRAME | Intent 2, source evidence E-006 | Pass | Intercepts only the buggy `.mode` attribute. |

No fail or ambiguous adequacy entries remain.
