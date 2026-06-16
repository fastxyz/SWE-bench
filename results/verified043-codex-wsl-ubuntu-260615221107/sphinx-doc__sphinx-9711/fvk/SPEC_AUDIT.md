# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| C-001 | I-001, I-003 | pass | Uses parsed version ordering for documented version strings. |
| C-002 | I-002 | pass | Directly encodes the reported `0.10.0 >= 0.6.0` witness. |
| C-003 | I-006 | pass | Kept as compatibility outside the documented proof domain; not used to justify semantic ordering. |
| C-004 | I-003, I-007 | pass | Preserves existing `None` branch. |
| C-005 | I-004 | pass | Preserves warning-and-continue behavior for missing extensions. |
| C-006 | I-005 | pass | Preserves `unknown version` as too weak. |
| C-007 | I-001 | pass | Old valid versions still fail. |
| C-008 | I-001, I-002 | pass | Newer valid versions now pass. |
| C-009 | I-003, I-004, I-005 | pass | Finite-entry lifting of the per-entry behavior. |
| C-010 | I-007 | pass | V1 adds only a private helper and an import of an existing dependency. |

No claim is supported only by candidate behavior. The fallback claim C-003 is
intentionally marked as compatibility behavior outside the semantic version
domain; it is not used to prove the issue witness.
