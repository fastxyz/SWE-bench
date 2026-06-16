# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| CLAIM-RECORD-ALIASED-ANNOTATIONS | Intent 2, 3, 4; ledger E1-E8 | Pass | The claim directly encodes the reported alias-preservation requirement for parameter and return annotations. |
| CLAIM-MERGE-PRESERVES-RECORDED-ALIASES | Intent 1, 4, 5; ledger E4, E9 | Pass | Description mode displays recorded strings in fields; the corrected string must survive merge. |
| CLAIM-PREFIX-FAILS-ALIASED-ANNOTATIONS | Ledger E3 SUSPECT legacy output | Pass as negative finding | This claim identifies the rejected behavior and is not used to specify fixed output. |
| CLAIM-NO-DUPLICATE-USER-FIELDS | Intent 5; implementation E9 | Pass | This frame condition preserves existing behavior unrelated to the alias defect. |

No claim is stronger than the public issue requires in a way that affects output
ordering or public API shape. No claim relies on the buggy `Dict[str, Any]` output as
expected behavior.
