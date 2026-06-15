# Spec Audit

Status: constructed adequacy gate.

| Formal claim | Intent entry | Result | Notes |
|---|---|---|---|
| `REPLACE-NAMED-TRAILING` | E1, E2 | pass | Matches the public issue's required replacement without a trailing slash. |
| `REPLACE-UNNAMED-TRAILING` | E3 | pass | Matches the public hint requiring the analogous unnamed-group fix. |
| `UNNAMED-OUTERMOST` | E4, E5 | pass | Encodes the helper's plural unnamed-groups contract and existing nested-group behavior. |
| `UNNAMED-RECONSTRUCT` | E4 | pass | Prevents V1's duplicated-prefix behavior for multiple groups. |
| `SIMPLIFY-ISSUE-CASE` | E2, E6 | pass | Proves the public wrapper's issue example after accounting for Django's leading slash behavior. |
| `COMPATIBILITY` | E6 | pass | No public surface change. |

No claim is based solely on legacy behavior. Existing public tests are used only
as preservation evidence where they do not conflict with the issue intent.
