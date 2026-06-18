# Public Evidence Ledger

| ID | Source | Public evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt / issue title | "Factor with extension=True drops a factor of y-1" | `extension=True`/`extension=[I]` factorization must preserve the `y - 1` factor. | Encoded by `DMP-EXT-FACTOR-SPEC` issue claim. |
| E2 | prompt / issue example | `factor(z)` returns `(x - 1)*(y - 1)` while `factor(z, extension=[I])` returns `x - 1`. | The extension path should not be less complete than rational factorization for this factor family. | Encoded by issue and legacy diagnostic claims. |
| E3 | prompt / public hint | "That happens cause of a typo in ... factortools.py#L1150" | The bug is localized to the algebraic extension factorization path in `factortools.py`. | Used to scope the audit to `dmp_ext_factor`. |
| E4 | `polytools.factor` docstring | "To factor over other domain ... use appropriate options: `extension`, `modulus` or `domain`." | `extension` selects a factorization domain, not a mode that may discard factors. | Mirrored in the no-content frame claim. |
| E5 | `dmp_ext_factor` docstring | "Factor multivariate polynomials over algebraic number fields." | The target helper is expected to factor multivariate polynomials, including lower-variable factors. | Mirrored in the general claim. |
| E6 | `dmp_primitive` docstring | "Returns multivariate content and a primitive polynomial." | Splitting main-variable content is a local, existing abstraction for recovering factors independent of the main variable. | Used in V1 audit and helper obligation `PRIMITIVE-SPLIT`. |
| E7 | `dmp_include` docstring | "Include useless levels in `f`." | Lower-variable content factors can be lifted back into the full variable set without changing their polynomial meaning. | Used in V1 audit and compatibility notes. |
| E8 | `dmp_trial_division` docstring | "Determine multiplicities of factors for a multivariate polynomial using trial division." | Candidate generation need only provide each factor once; multiplicity comes from trial division over the original polynomial. | Encoded by obligation `TRIAL-MULTIPLICITY`. |

SUSPECT legacy behavior: the issue's displayed `factor(z, extension=[I]) -> x - 1`
is explicitly the reported bug and is not used as an expected output.
