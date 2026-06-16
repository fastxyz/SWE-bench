# Spec Audit

| Formal claim | Intent match | Audit |
| --- | --- | --- |
| SQF-COMBINE | Pass | Matches E1, E2, E3, and E4: one factor per multiplicity for univariate `sqf_list()`. |
| SQF-GATED-COMBINE | Pass | Matches E5: square-free helpers are univariate, with a single explicit generator or no ambiguity. |
| FACTOR-LIST-FRAME | Pass | Matches E8: `factor_list()` is an irreducible-factor API and is not part of the reported bug. |
| SHAPE-PRESERVATION | Pass | Matches existing API flags and the narrow public intent; no evidence supports changing coefficients, exponent values, `polys`, or `frac` shape. |
| AMBIGUOUS-MULTIVARIATE-FRAME | Ambiguous but non-blocking | E6 discusses possible `ValueError`, while E7 cautions against changing existing no-generator multivariate behavior. This claim is a frame/compatibility boundary, not proof that the legacy behavior is mathematically ideal. It becomes Finding F-002. |

Conclusion: the formalized claims cover the required univariate grouping intent.
They do not prove or bless the broader ambiguous multivariate behavior; they
only justify leaving it unchanged in this pass.
