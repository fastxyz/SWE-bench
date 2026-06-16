# Spec Audit

Status: adequacy check comparing `FORMAL_SPEC_ENGLISH.md` to
`INTENT_SPEC.md`.

| Formal clause | Intent clauses | Result | Notes |
| --- | --- | --- | --- |
| FSE1 | I1, I4, D1, D2 | Pass | Directly captures the core public issue: arbitrary `.values` objects are preserved. |
| FSE2 | I2, I1 | Pass | Covers the reported scalar assignment path. |
| FSE3 | I3, I1 | Pass | Covers the public hint's scalar construction path. |
| FSE4 | I5 | Pass | Preserves explicit container unwrapping for DataArray/pandas types. |
| FSE5 | I6, I7 | Pass | Preserves existing earlier branches for `Variable`, `pd.Index`/adapter-like inputs, and supported array types. |
| FSE6 | E2, E7, E9 | Pass as negative evidence | The claim is intentionally labeled as the pre-V1 defect and is not used to justify legacy behavior. |
| FSE7 | D3 | Pass | Correctly limits proof confidence to constructed partial correctness. |

No formal clause is weaker than the public intent for the audited behavior. No
formal clause preserves the reported pre-fix output as desired behavior.
