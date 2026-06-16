# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent item | Result | Notes |
| --- | --- | --- | --- |
| EXPORT-SAFE-NAMED | I1, I2, I3, I4 | Pass | This is the core issue: with matching name-list length, lookup is split-only and cannot use leaf sentinel `-2`. |
| EXPORT-SAFE-GENERIC | I4 | Pass | Preserves documented generic feature labels for split nodes without using leaf sentinels. |
| VISIT-LEAF-NO-LOOKUP | I3 | Pass | Directly matches the public statement that leaves do not split on a feature. |
| VISIT-SPLIT-LOOKUP | I2, I4 | Pass | Split nodes use their valid split feature index. The fitted-tree validity requirement is a domain invariant, not candidate-derived behavior. |
| VISIT-TRUNCATED-NO-LOOKUP | I5 | Pass | The issue does not require naming truncated split nodes; source behavior already reports truncation text without names. |
| Frame conditions F1-F3 | I5 | Pass | V1 does not alter validation, signature, child traversal order, or formatting. |

No formal-English claim is weaker than the public issue intent, and no claim
preserves the reported `IndexError` behavior.

