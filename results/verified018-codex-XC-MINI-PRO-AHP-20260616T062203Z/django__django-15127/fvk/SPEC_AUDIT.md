# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| `update-message-tags` | I1, I3, I4, E1, E3, E5, E7 | Pass | The claim says the receiver refreshes effective tags from active settings on `MESSAGE_TAGS`. |
| `ignore-other-setting` | I5 | Pass | The receiver ignores unrelated settings; this prevents accidental cache churn. |
| `message-level-tag-after-update` | I1, I2, I3, E2, E4, E6 | Pass | The claim directly covers the reported symptom: a configured custom level no longer returns `''`. |
| `message-level-tag-current-map` | I2, E6 | Pass | This matches the public `Message.level_tag` observable. |
| `restore-after-exit` | I4, E7 | Pass | `override_settings().disable()` sends the same signal after restoring settings, so recomputation restores the map. |
| Object identity preserved | I7, E1, E9 | Pass as compatibility strengthening | Public docs do not expose `LEVEL_TAGS`, but the issue names the module constant. In-place refresh is at least as compatible as rebinding for the public observable. |

No formal-English claim is weaker than the intent spec. No claim preserves the
legacy stale-tag behavior.
