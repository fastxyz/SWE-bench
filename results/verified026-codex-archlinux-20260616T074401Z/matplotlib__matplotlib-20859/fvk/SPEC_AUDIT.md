# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent entries | Audit | Notes |
|---|---|---|---|
| C-001 | I-001, I-002, I-005 | pass | Matches the public requirement that `subfig.legend()` work and produce a subfigure-scoped legend. |
| C-002 | I-003 | pass | Preserves existing axes and concrete figure classifications. |
| C-003 | I-004 | pass | The issue expands only figure-like valid parents; arbitrary parents remain invalid. |
| C-004 | I-005, I-006 | pass | Audits the hinted bbox path by requiring the subfigure bbox to include its owned legend. |
| C-005 | FVK honesty gate | pass | Labels the proof as constructed, not machine-checked, and does not claim renderer-level proof. |

No formal claim is candidate-derived without public-intent support.  No claim
preserves the pre-fix `SubFigure` rejection.
