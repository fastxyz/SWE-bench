# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entry | Audit result | Notes |
| --- | --- | --- | --- |
| `VARIABLE-FIELD-NO-XREF` | E1-E4, E6 | PASS | It directly encodes that `var`/`ivar`/`cvar` field labels are descriptions and must not auto-link to any same-name object. |
| `VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF` | E7, E10 | PASS | It preserves public documented `vartype` link behavior. |
| `EXPLICIT-REFERENCE-STILL-LINKS` | E5 | PASS | It keeps explicit user-authored roles as the linking mechanism. |
| No resolver-wide change | E3, E5, E9 | PASS | Avoids changing explicit reference resolution and avoids an incomplete fuzzy-only fix. |

No formal claim is legacy-derived. The only implementation facts used are the
mechanism by which field roles create nodes and the V1 fact that the variable
field no longer has `rolename='obj'`.
