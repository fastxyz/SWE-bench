# Spec Audit

Status: adequacy audit, constructed and not machine-checked.

| Formal English Item | Intent Coverage | Verdict |
|---|---|---|
| 1. Issue-shaped token prefix does not take E252 missing branch | Matches E-01, E-02, E-03. | Pass |
| 2. RHS `[` after alias assignment is not type parameters | Matches E-02 and directly addresses the root cause. | Pass |
| 3. Actual type-parameter list remains classified as type parameters | Matches E-05 preservation/frame condition. | Pass |
| 4. Nested brackets inside type parameters preserve inner bracket counting | Matches implementation frame condition needed to avoid regressions in existing type-param handling. | Pass |
| 5. Annotated function E252 path remains true | Matches E-04 preservation/frame condition. | Pass |

No item is candidate-derived without public or implementation-frame support. No item attempts to preserve the reported legacy false-positive behavior.
