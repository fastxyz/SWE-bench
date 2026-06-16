# Spec Audit

Status: constructed for audit; not machine-checked.

| Formal item | Intent item | Verdict | Reason |
| --- | --- | --- | --- |
| DEFAULT-IMPLICIT | I5 | Pass | Public deconstruction guidance allows omitting default values when unnecessary to reconstruct field state. |
| DIRECT-DEFAULT | I5 | Pass | Direct `default_storage` is equivalent to the default storage value for the deconstruction omission rule. |
| DIRECT-OTHER | I6 | Pass | Non-default direct storage must be serialized to reconstruct field state. |
| CALLABLE-DEFAULT | I3, I4 | Pass | The issue explicitly requires including the callable when the callable returns `default_storage`. |
| CALLABLE-OTHER | I3, I6 | Pass | Public test evidence and issue context require callable storage deconstruction to return the callable, not the evaluated storage. |
| Frame conditions | I7 | Pass | V1 changes only the local deconstruction comparison/assignment source and does not change signatures or test files. |

No formal-English obligation is broader than public intent. The only domain
assumption is that a callable storage argument and a storage object are
distinct public input forms, matching the docs phrase "A storage object, or a
callable which returns a storage object."
