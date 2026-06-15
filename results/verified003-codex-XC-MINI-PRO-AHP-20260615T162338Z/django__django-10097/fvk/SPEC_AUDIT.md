# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entry | Audit result | Notes |
| --- | --- | --- | --- |
| AUTH-UNCLEAN-REJECTED | E1, E2 | pass | Captures rejection of raw invalid userinfo data. |
| AUTH-FORBIDS-SLASH | E2, E3 | pass | Directly covers `http://foo/bar@example.com` style path delimiter misuse. |
| AUTH-FORBIDS-RAW-AT | E2 | pass | Ensures extra raw `@` cannot be credential data. |
| AUTH-FORBIDS-EXTRA-COLON | E2 | pass | Treats only the first username/password separator as syntax. |
| QUERY-OR-PATH-SMUGGLING-REJECTED | E3, E4 | pass | Extends the same delimiter boundary to query and fragment delimiters. |
| CLEAN-USERINFO-PRESERVED | E5 | pass | Preserves ordinary public valid credential forms. |
| PERCENT-ENCODED-DELIMITERS-PRESERVED | E2, E5 | pass | Encoded delimiters are not raw invalid characters. |
| Visible fixture with raw extra colons | E6 | suspect | Conflicts with prompt/RFC-derived intent and cannot justify preserving V1-incompatible behavior. |

No formal claim is supported only by implementation behavior. The only conflict
is the visible legacy fixture with raw extra colons; it is recorded in
`FINDINGS.md` and does not block confirmation of the source fix.
