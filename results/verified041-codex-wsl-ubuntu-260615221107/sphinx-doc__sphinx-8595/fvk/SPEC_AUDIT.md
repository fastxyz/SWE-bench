# Spec Audit

Status: constructed adequacy audit.

| Formal claim | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `NO-ALL-BRANCH` | Intent item 4, evidence E4/E5 | pass | Preserves absent/ignored `__all__` behavior. |
| `EXPLICIT-ALL-BRANCH` | Intent items 1 and 2, evidence E1/E4 | pass | Covers every valid explicit sequence, not only non-empty ones. |
| `EMPTY-ALL-BRANCH` | Intent items 2 and 3, evidence E1/E2/E3 | pass | Specifically prevents the old truthiness conflation. |
| `EMPTY-ALL-FILTER` | Intent item 3, evidence E3 | pass | Establishes the final no-member default output. |
| `EXPLICIT-MEMBERS-FRAME` | Out-of-scope item 1 | pass | Confirms the V1 edit does not affect the non-`want_all` branch. |
| Skip-event compatibility | Intent item 5, evidence E6 | pass | Modeled as a frame condition because the issue reproducer has no event override. |

No required behavior is marked fail or ambiguous.
