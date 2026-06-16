# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent match | Audit |
| --- | --- | --- |
| C-DECIMAL-PRESERVE | Pass | Matches I-1 and I-2: Decimal input is in-domain and must not be converted through `float`. |
| C-ISSUE-DECIMAL-20 | Pass | Matches I-2 and ledger E-2: the concrete issue point has a specific expected output. |
| C-NONDECIMAL-FRAME | Pass | Matches I-3, I-4, N-1, and ledger E-7: the issue does not require broad non-Decimal conversion changes. |
| C-INVALID-ARG-DECIMAL-DISPLAY | Pass with note | Public evidence does not require preserving Python `repr(Decimal(...))` on invalid arguments. User-visible numeric display is consistent with the docs' numeric-output framing, but this behavior is not part of the core proof. |

No claim is derived solely from V1 behavior. The only implementation-derived
piece is the existing rounding/localization implementation, which is framed as
a trusted external contributor rather than used as evidence that the conversion
bug is fixed.
