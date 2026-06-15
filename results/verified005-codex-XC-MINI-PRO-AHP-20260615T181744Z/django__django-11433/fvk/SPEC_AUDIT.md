# Spec Audit

| Formal obligation | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| `CI-DERIVED-NONEMPTY-ASSIGNS` | I1, I2 | Pass | Directly captures the issue: omitted payload plus non-empty derived `cleaned_data` overwrites the model default. |
| `CI-DERIVED-FILE-QUEUES` | I2, I6 | Pass | File fields receive the same skip decision but preserve the existing delayed save path. |
| `CI-OMITTED-EMPTY-PRESERVES-DEFAULT` | I3 | Pass | Preserves existing public tests for ordinary omitted optional fields. |
| `CI-SUBMITTED-EMPTY-ASSIGNS` | I4, I5 | Pass | Distinguishes submitted blank values from omitted values. |
| `CI-NONDEFAULT-OMITTED-EMPTY-ASSIGNS` | I1 | Pass | The default-preservation branch is only for fields with defaults. |
| `CI-INELIGIBLE-*` | I1 and existing control flow | Pass | Keeps the pre-existing eligibility filters. |
| Explicit empty cleaned override should assign | A1 | Ambiguous | Public issue wording could be read broadly, but public tests require preserving normal omitted empty values and `cleaned_data` has no provenance marker for "manually re-assigned to same empty value." This is recorded as F-003 and does not justify changing V1. |
| Public API compatibility | I7 | Pass | No signature or hook protocol changes. |

Adequacy conclusion: the K claims prove the intended non-empty derived-value fix
and the documented default-preservation frame conditions. The only ambiguous
point is explicit empty-value override provenance; it is outside the confirmed
public intent and should be handled by a future clarification or targeted design
change, not by widening this patch.
