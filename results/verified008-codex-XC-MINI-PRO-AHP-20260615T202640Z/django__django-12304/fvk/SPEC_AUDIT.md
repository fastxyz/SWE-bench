# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent source | Audit result | Notes |
| --- | --- | --- | --- |
| `CHOICES-CREATION-MARKS` | E-004 | Pass | The issue explicitly names `do_not_call_in_templates` on choices classes as the fix mechanism. |
| `TEMPLATE-ENUM-MEMBER-LOOKUP` | E-001, E-002, E-005, E-006 | Pass | The claim says the exact issue example can reach the enum member without calling the class. |
| `UNMARKED-ENUM-CLASS-FAILS` | E-003 | Pass as diagnostic | This claim is used only to localize the legacy failure. It is not a V2 postcondition. |
| `CHOICES-MEMBER-FRAME` | E-007, E-008 | Pass | The marker is assigned after enum class creation and does not alter the enum member map. |
| Compatibility frame | E-005, E-006, E-008 | Pass | No public signature, export, or resolver branch was changed. |

## Adequacy Verdict

The formal English matches the intent spec. There are no failed or ambiguous
required behaviors, and no claim relies on hidden tests, evaluator feedback, or
candidate behavior alone.
