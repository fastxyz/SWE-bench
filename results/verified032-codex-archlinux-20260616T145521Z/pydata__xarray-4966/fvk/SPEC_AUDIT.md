# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Audit result | Notes |
| --- | --- | --- | --- |
| CLAIM-ABSENT-UNSIGNED | E6 | Pass | `_Unsigned` handling should only run when the attr is present. |
| CLAIM-SIGNED-STRING-TRUE | E1, E8 | Pass | Preserves the existing netCDF convention path. |
| CLAIM-SIGNED-BOOL-TRUE | E3, E6, E9 | Pass | Decode accepts explicit boolean markers symmetrically; encode remains unchanged. |
| CLAIM-UNSIGNED-STRING-FALSE | E2, E4, E8 | Pass | This is the main OPeNDAP/pydap issue path. |
| CLAIM-UNSIGNED-BOOL-FALSE | E2, E3, E4 | Pass | This closes the V1 gap from the issue's `unsigned == False` wording. |
| CLAIM-INTEGER-NOOP | E1, E2, E6 | Pass | Integer data is accepted; conversion occurs only when marker requests opposite signedness. |
| CLAIM-NONINTEGER-WARN | E6 and existing warning behavior | Pass | The issue warning should disappear for unsigned integer data, not for non-integer data. |
| Cast functions | E4 | Pass | The example values require modulo byte reinterpretation. |
| Frame conditions | E5, E7, E10 | Pass | No public API or backend protocol change is needed. |

No claim is supported only by candidate behavior. The V1 string-only assumption
failed the adequacy audit because it omitted E3; that gap is recorded as Finding
F1 and repaired in V2.
