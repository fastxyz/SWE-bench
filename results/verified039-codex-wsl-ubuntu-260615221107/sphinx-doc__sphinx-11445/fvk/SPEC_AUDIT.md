# SPEC AUDIT

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| C-SECTION-PREDICATE | Intent 3, 4, 5; E2, E6 | Pass | The claim captures the local section-title shape needed to avoid splitting headings. |
| C-SCAN-POSITION | Intent 2, 3; E3, E5 | Pass | The scan advances over docinfo only while the current line is not a section title. |
| C-ROLE-TITLE | Intent 3, 4; E1, E2, E3 | Pass | This is the reported bug family. |
| C-DOCINFO-PREFIX | Intent 2; E5, E7 | Pass | Preserves documented metadata behavior. |
| C-NO-DOCINFO | Intent 1; E4, E7 | Pass | Preserves ordinary prolog insertion. |
| C-EMPTY-PROLOG | Intent 6; existing function contract | Pass | The outer guard makes this a frame condition. |
| Public API compatibility | Intent 7 | Pass | No public signature or caller protocol changed. |

No formal claim is implementation-derived without public evidence. The
underlying `docinfo_re` broadness remains an implementation fact, not a desired
semantic rule; the spec instead requires that section titles stop the scan.

