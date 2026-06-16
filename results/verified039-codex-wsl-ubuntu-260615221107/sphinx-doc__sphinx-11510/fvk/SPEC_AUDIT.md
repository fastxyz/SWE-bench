# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| CLAIM-MANAGED-INCLUDE | Matches I1-I3 and evidence E1-E7: include insertion must use `source-read` replacement text. | PASS |
| CLAIM-MANAGED-INCLUDE-FALLBACK-DOC | Matches I7. The issue demonstrates a source-suffix include, but Sphinx also supports non-source include files; using current docname is the least surprising event argument when no docname exists. | PASS with default-domain assumption |
| CLAIM-STANDARD-INCLUDE-FRAME | Matches I5 and E8. | PASS |
| CLAIM-DIRECT-FILEINPUT-COVERAGE | Addresses proof obstacle F-001: the source tree does not prove docutils' internal import style. | PASS after V2 change |
| CLAIM-DURATION-FIRST-SOURCE-READ | Matches I8 and E10; this is compatibility fallout from the event-firing change. | PASS after V2 change |

No formal claim preserves the buggy legacy behavior in which the included source
is read raw and inserted without the handler's `source[0]` replacement.
