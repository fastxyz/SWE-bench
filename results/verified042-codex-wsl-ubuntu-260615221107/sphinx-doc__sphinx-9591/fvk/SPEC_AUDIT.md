# Spec Audit

Constructed, not machine-checked.

| Formal claim | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| PROPERTY-TYPE-XREF | Intent 1, Intent 2, E-001, E-002 | pass | The claim directly captures the issue's expected behavior: property type names become cross-reference-capable nodes. |
| PROPERTY-NO-TYPE-FRAME | Intent 4 | pass | The issue does not request changes for properties without type annotations; preserving them is required frame behavior. |
| PROPERTY-SUPER-FRAME | Intent 4 | pass | The fix should not affect the base signature name/prefix or return tuple; V1 leaves the super call and return unchanged. |
| PROPERTY-COMPATIBILITY | Intent 4, E-007 | pass | V1 does not change the method signature, directive option name, directive registration, or consumer protocol. |

No formal claim is based solely on legacy behavior. The pre-fix property path
that appended `": " + typ` as plain text is marked as the observed defect, not
as a preserved requirement.
