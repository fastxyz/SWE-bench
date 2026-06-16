# Spec Audit

Status: adequacy gate for the constructed claims.

| Formal claim | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `GLFP-SCRIPT-REGION-LOWER` | E1, E2, E3 | Pass | Directly covers `/en-latn-us/`, which the issue says should return 200. |
| `GLFP-SCRIPT-REGION-BCP47` | E2, E3, E5 | Pass | Directly covers the configured BCP 47 case spelling shown in the issue. |
| `GLFP-SCRIPT-REGION-CASE-INSENSITIVE` | E2, E5 | Pass | Language tags are case-insensitive; the resolver must tolerate case normalization. |
| `GLFP-NO-ARBITRARY-THREE-PART` | E4 | Pass | Encodes the public hint against regex-only broadening. |
| `LOCALE-MATCH-BCP47-CASE` | E2, E5 | Pass | Needed because activation normalizes language tags through `to_language()`. |
| `LOCALE-MATCH-DEFAULT-EMPTY` | E6, compatibility C2 | Pass | Confirms the case-insensitive comparison keeps empty-prefix matching behavior. |

No claim is candidate-only. The exact configured-language branch is justified
by E3/E4 rather than by V1 itself. The case-insensitive resolver claim is
justified by E2/E5 plus Django's existing normalization behavior, not by a
hidden test or evaluator result.
