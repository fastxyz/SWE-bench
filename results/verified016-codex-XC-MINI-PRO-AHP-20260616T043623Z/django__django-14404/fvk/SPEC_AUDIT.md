# SPEC AUDIT

Status: adequacy audit, constructed and not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| CLAIM-REDIRECT | I1, I2, C1, C2, C3 | pass | Redirect target is `PATH + "/"`; resolver result is modeled as coming from `PATHINFO + "/"`. |
| CLAIM-FORCE-SCRIPT-NAME-WITNESS | I1, I2, I3 | pass | Concrete witness distinguishes script-prefixed `PATH` from script-stripped `PATHINFO`. |
| CLAIM-NO-REDIRECT-APPEND-FALSE | Required Behavior 6 | pass | Preserves existing non-redirect behavior. |
| CLAIM-NO-REDIRECT-URL-SLASH | Required Behavior 6 | pass | Preserves existing non-redirect behavior. |
| CLAIM-NO-REDIRECT-RESOLVER404 | Required Behavior 6 | pass | Preserves existing non-redirect behavior. |
| CLAIM-NO-REDIRECT-SHOULD-NOT-APPEND | Required Behavior 6 and C3 | pass | Preserves `should_append_slash` opt-out. |

## Rejected Claims

- `redirect(PATHINFO + "/")`: fail. This is legacy-derived and exactly contradicts I2.
- `resolve(PATH + "/")`: fail. This changes URLconf lookup semantics and is not supported by the issue.
- `redirect(get_full_path_with_slash)`: ambiguous as an improvement and not required here. The public issue specifies `request.path`, not full path with query string.
