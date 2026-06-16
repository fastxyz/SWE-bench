# Spec Audit

Status: constructed for FVK audit, not machine-checked.

| Formal Claim | Intent Entry | Result | Notes |
| --- | --- | --- | --- |
| C-001 arbitrary lazy fallback | Intent 1, 2; E-001, E-002 | pass | Directly covers the issue example family `Promise("Y-m-d") -> "Y-m-d"`. |
| C-002 localized module hit | Intent 1, 3; E-001, E-004, E-006 | pass | Covers affected callers beyond the date filter when a custom format module supplies a value. |
| C-003 localized settings fallback | Intent 1, 3; E-001, E-005, E-006 | pass | Lazy registered setting names behave as concrete setting names. |
| C-004 non-localized settings fallback | Intent 1, 3; E-001, E-005, E-006 | pass | Promise normalization is independent of the localization branch. |
| C-005 non-localized arbitrary fallback | Intent 1, 2; E-001, E-002, E-006 | pass | Covers arbitrary lazy format strings when localization is disabled. |
| C-006 cache hit | Intent 1; E-006 | pass | The normalized string is used as the cache key before branch resolution. |
| C-007 out-of-domain non-string frame | Intent 5; E-007 | pass | The formal spec intentionally does not prove support for arbitrary non-string objects. |

No fail or ambiguous entries block the conclusion that V1 satisfies the public
issue intent. The proof remains constructed, not machine-checked.
