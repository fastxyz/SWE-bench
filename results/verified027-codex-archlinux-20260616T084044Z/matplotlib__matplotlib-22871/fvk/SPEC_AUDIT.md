# Specification Audit

Status: adequacy comparison between `INTENT_SPEC.md` and
`FORMAL_SPEC_ENGLISH.md`.

| Claim | Audit | Reason |
| --- | --- | --- |
| C-001 | pass | Matches the issue's expected year offset when January is absent. |
| C-002 | pass | Matches documented zero-format behavior and existing January-visible tests. |
| C-003 | pass | Year-level labels already carry year context; no issue evidence requires changing this. |
| C-004 | pass | Preserves finer-level behavior outside the defect. |
| C-005 | pass | Matches the public `show_offset` parameter contract. |

No required behavior is marked fail or ambiguous for the issue-scoped domain.
Residual assumptions are recorded in F-005 and F-006.

