# Spec Audit

Status: adequacy gate for constructed claims.

| Formal claim | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `STANDARD-CANONICAL-NAMES` | Intent 1, 2, 3 | Pass | The claim states exactly the replacement requested by the issue. |
| `CANONICAL-OPTIONS-PRECEDENCE` | Intent 5, 6 | Pass | The claim matches documented precedence when canonical option keys are used. |
| `LEGACY-OPTIONS-PASSTHROUGH` | Intent 6 | Pass | This is a frame condition, not a stronger correctness claim. It prevents over-scoping the issue to user-owned driver options. |
| `FRAME-UNCHANGED-BEHAVIOR` | Intent 5 | Pass | The V1 diff touches only the two deprecated standard-setting key names. |

No formal claim depends only on candidate behavior for the issue's requested
replacement. The legacy-options claim is explicitly framed as pass-through
behavior supported by docs, not as evidence that deprecated aliases are
preferred.
