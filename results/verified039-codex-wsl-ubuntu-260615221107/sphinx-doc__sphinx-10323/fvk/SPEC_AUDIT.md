# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| READ-PIPELINE | I1, I3 | pass | The formal order makes dedent apply after content selection and before synthetic lines. |
| DEDENT-WARNING-SCOPE | I2 | pass | The warning source is selected file content only. |
| NO-DEDENT-FRAME | I4 | pass | No-dedent behavior remains the same as the existing public tests require. |
| DIFF-FRAME | I5 | pass | The V1 patch does not alter the `diff` branch. |
| PUBLIC-COMPATIBILITY | I5 | pass | V1 changes no public API, option name, method signature, or return shape. |
| Docutils leading-space recovery | OOS1 | pass | The spec intentionally does not require Sphinx to recover whitespace docutils has discarded. |

No formal claim is candidate-only or legacy-only. The only legacy behavior preserved is limited to public behavior outside the defective `dedent` plus `prepend`/`append` interaction.
