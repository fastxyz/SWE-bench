# Spec Audit

Status: constructed for FVK audit, not machine-checked.

| Formal claim | Intent entries | Audit result | Notes |
| --- | --- | --- | --- |
| `MERGE-ATTRS-OVERRIDE-COPY` | I1, I2, I3, E1-E5 | Pass | This is the core issue: same first-input contents, distinct result mapping. |
| `MERGE-ATTRS-DROP` | I5 | Pass | Existing helper behavior; no source aliasing. |
| `MERGE-ATTRS-EMPTY` | I5 | Pass | Existing helper behavior; no source attrs mapping exists to alias. |
| `MERGE-ATTRS-NO-CONFLICTS` | I5, E4 | Pass | Sibling branch already uses a shallow copy; no V2 change needed. |
| `MERGE-ATTRS-IDENTICAL` | I5, E4 | Pass | Sibling branch already uses a shallow copy; no V2 change needed. |
| `MERGE-ATTRS-BAD-MODE` | I5 | Pass | Existing error behavior preserved. |
| Shallow-copy frame condition | I4, E4 | Pass | Deep-copying attr values is not entailed by public intent. |
| Public signature frame condition | I6 | Pass | V1 does not alter signatures or accepted option names. |

No formal-English claim is weaker than the public intent for the reported override bug. No claim relies on the pre-fix aliasing display as desired behavior; that display is treated as the bug symptom.
