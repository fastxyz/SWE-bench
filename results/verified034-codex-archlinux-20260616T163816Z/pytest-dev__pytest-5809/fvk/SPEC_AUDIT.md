# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| C-001 URL is `https://bpaste.net` | Intent item 1 | Pass | Preserves existing documented service target. |
| C-001 code field is exactly `CONTENTS` | Intent item 4 | Pass | The issue changes classification metadata, not uploaded content. |
| C-001 lexer is exactly `text` | Intent items 2 and 3 | Pass | Directly follows the issue's stated successful alternative and rationale. |
| C-001 expiry is `1week` | Intent item 4 | Pass | Existing behavior preserved; no public evidence asks to change it. |
| C-001 has no Python-version-specific lexer branch | Intent items 2, 3, and 5 | Pass | Python source classification is the reported defect. |
| Public test expecting `python3` or `python` | Intent items 2 and 3 | Fail as spec evidence | Marked SUSPECT in FINDINGS.md because it encodes the legacy bug. |
| External service availability or malformed response behavior | Out-of-scope item | Ambiguous/out of scope | Not used to justify source changes in this audit. |
