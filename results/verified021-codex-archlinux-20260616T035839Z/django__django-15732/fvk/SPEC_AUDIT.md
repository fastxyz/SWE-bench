# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Adequacy | Notes |
| --- | --- | --- | --- |
| K-UT-DEFAULT-FIRST | I1, I2, I3 | pass | Selects the generated `_uniq` constraint instead of raising on duplicate candidates. |
| K-UT-DEFAULT-SECOND | I1, I2, I3 | pass | Candidate order does not affect selection when the generated name is present. |
| K-UT-SINGLE | I1 | pass | Preserves existing behavior when filtering identifies exactly one removable constraint. |
| K-UT-AMBIGUOUS | I1, A2 | pass | Does not guess among multiple non-generated candidates; matches accepted ambiguity for manually renamed constraints. |
| K-NONUNIQUE-AMBIGUOUS | I5 | pass | Avoids extending `_uniq` disambiguation to unrelated non-unique index deletion. |
| K-NONE | I1 | pass | Preserves existing error behavior when no removable constraint exists. |
| Filtering obligation O1 | I2, I3 | pass | Source change adds `primary_key=False` for unique-together deletion. |
| Explicit exclusions O6 | I4 | pass | Existing exclusion logic is unchanged. |
| Creation-path behavior | A1 | ambiguous | Public evidence names it but later says it was not reproduced. No code change is justified without a broader migration-state policy. |
| Manual rename behavior | A2 | pass with residual risk | Public hint accepts relying on generated names; residual risk documented in FINDINGS F-004. |
