# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Discharge status |
| --- | --- | --- | --- |
| O1 | `_RepeatedSplits.__repr__` delegates to `_build_repr(self)`. | E1, E3, E4, E6 | Discharged by V1 source and claim C1. |
| O2 | `_build_repr` enumerates constructor parameters, excluding `self` and `**kwargs`, preserving the existing sorted convention. | E6, E7, E8 | Discharged by unchanged helper logic and claim C6. |
| O3 | Parameter value resolution uses direct attribute first, then `cvargs`, then `None`. | E5, E9 | Discharged by V1 sentinel fallback and claims C2-C5. |
| O4 | Deprecated-parameter filtering remains unchanged. | Existing `_build_repr` code | Discharged by inspection: V1 changed only the value lookup default and fallback. |
| O5 | Default `RepeatedKFold` repr contains class name and actual values for `n_repeats`, `n_splits`, and `random_state`. | E1, E2, E5, E9 | Discharged by C2. |
| O6 | Default `RepeatedStratifiedKFold` repr contains class name and actual values for the same parameters. | E1, E2, E5, E9 | Discharged by C3. |
| O7 | Existing direct-attribute splitters are not regressed by the new fallback. | E6, E7, E8 | Discharged by C4-C5 and compatibility audit. |
| O8 | No public API signature, splitter behavior, or test files are changed. | E10, compatibility audit | Discharged by source inspection. |

No additional source edit is required for V2 because every open obligation is
already discharged by the V1 patch under the intent specification in
`fvk/INTENT_SPEC.md`.

