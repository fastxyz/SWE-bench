# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Formal claim | Constructed status |
| --- | --- | --- | --- | --- |
| PO-001 | Every `ChoicesMeta`-created choices class has `do_not_call_in_templates == True`. | E-004, E-007 | `CHOICES-CREATION-MARKS` | Discharged by V1 assignment after class creation. |
| PO-002 | The template callable gate preserves a callable value when the marker is true. | E-005, E-006 | `TEMPLATE-ENUM-MEMBER-LOOKUP` step 2 | Discharged by existing resolver branch in `Variable._resolve_lookup()`. |
| PO-003 | After the callable gate preserves the enum class, dotted lookup reaches the enum member. | E-001, E-002, E-006 | `TEMPLATE-ENUM-MEMBER-LOOKUP` | Discharged by preserving `current` as the class through the gate. |
| PO-004 | Adding the marker does not alter enum members or choices metadata. | E-007, E-008 | `CHOICES-MEMBER-FRAME` | Discharged because V1 assigns the marker after `EnumMeta.__new__()` consumes `classdict._member_names`. |
| PO-005 | No public API or resolver compatibility is broken. | E-005, E-006, E-008 | Compatibility frame | Discharged by no signature/export changes and no edit to template resolver behavior. |

## Rejected Obligations

No obligation was accepted from hidden tests, evaluator output, internet
sources, or the original upstream patch.

## Remaining Open Obligations

None for the issue-scoped proof. Machine checking remains open because K tools
were not run.
