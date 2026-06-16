# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Formal claim/artifact | V1 audit result |
| --- | --- | --- | --- | --- |
| PO-1 | Bool/bool `_reduce` must return integer 0/1 dot sum. | E3, E4, E5 | `reduceBoolBool(BS, WS) => dot01(BS, WS)` in `weighted-spec.k` | Discharged by `weighted.py` lines 132-135: cast occurs before `dot`. |
| PO-2 | `_sum_of_weights` with boolean weights must use numeric denominator. | E2, E3, E4, E6 | `sumOfWeightsBool(...) => SomeWeight(dot01(...))` | Discharged because `_sum_of_weights` calls `_reduce(mask, weights, ...)`, and mask/boolean weights satisfy PO-1. |
| PO-3 | Reported issue example must produce mean `1.0`. | E1, E2, E4 | `weightedMeanBoolWeights(...) => Ratio(2, 2)` | Discharged: numerator remains `2`; denominator becomes `2`; ratio is `1`. |
| PO-4 | Zero total weight remains invalid/missing. | Existing source behavior and weighted docs | `sumOfWeightsBool(...) => NoWeight` when `dot01 == 0` | Discharged: V1 does not alter `valid_weights = sum_of_weights != 0.0` or `.where(valid_weights)`. |
| PO-5 | Mixed boolean/numeric and numeric paths are unchanged. | Full-intent frame condition | `needsCast` false claims for non-bool/bool combinations | Discharged by conjunctive dtype guard. |
| PO-6 | Public API and dispatch compatibility preserved. | API source inspection | `PUBLIC_COMPATIBILITY_AUDIT.md` | Discharged: no signature, call protocol, or helper class shape changed. |
| PO-7 | FVK proof honesty gate must be explicit. | FVK verify workflow | `PROOF.md` commands and caveat | Discharged: commands are recorded and labeled constructed, not machine-checked. |

## Decision

V1 satisfies all obligations derived from the public issue and source-level API
contract. No source edit is justified by the FVK audit.
