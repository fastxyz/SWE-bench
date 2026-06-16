# Spec Audit

| Formal-English obligation | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| HEAD `TooManyRedirects` followed by GET. | Intent 4, evidence E1-E3 | PASS | Directly matches the issue. |
| GET outcome determines final status after HEAD `TooManyRedirects`. | Intent 5, evidence E1-E3 | PASS | Restores GET-based classification instead of early broken. |
| Successful HEAD does not call GET. | Intent 2, evidence E4 | PASS | Preserves public behavior for HEAD redirects. |
| HEAD HTTPError still calls GET. | Intent 3, evidence E5 | PASS | Preserves public behavior for 405 fallback. |
| GET `TooManyRedirects` remains broken. | Intent 5, default-domain assumption | PASS | The issue requires retrying when HEAD is the redirect-loop operation; if GET also cannot complete, broken remains appropriate. |
| Anchor checks use GET directly and are excluded from the changed branch. | Intent 6 | PASS | Anchor behavior is not weakened by the formal scope. |
| No public API/output shape changes. | Intent 7 | PASS | V1 changes only an imported exception and an internal catch tuple. |

No formal obligation is candidate-derived without public intent support. No
SUSPECT public test was used to preserve the legacy broken behavior.
