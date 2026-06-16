# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 should not stand completely unchanged. It correctly fixed `Identity._entry`, but the FVK audit found that the original nested-sum output form also needs the exact interval `Piecewise` produced by `deltasummation` to collapse over the same summation bounds.

V2 therefore keeps the V1 `KroneckerDelta(i, j)` entry representation and adds a narrow `eval_sum` simplification for exact-interval, zero-fallback Piecewise expressions.

## Follow-Up Checks To Run Later

When an execution environment is available, run focused SymPy tests or equivalent assertions for:

- `Identity(n)[i, j] == KroneckerDelta(i, j)` for symbolic integer indices.
- Concrete entries such as `Identity(3)[0, 0] == 1` and `Identity(3)[0, 1] == 0`.
- `Sum(Sum(Identity(n)[i, j], (i, 0, n - 1)), (j, 0, n - 1)).doit() == n` for positive integer `n`.
- `Sum(Identity(n)[0, i], (i, 0, n - 1)).doit() == 1`.
- The exact-interval Piecewise helper shape in `eval_sum`.

When K is available, run the commands recorded in `fvk/PROOF.md`.

## Residual Risks

The new `eval_sum` branch is intentionally syntactic. It does not simplify conditions merely implied by the limits or conditions equivalent after boolean algebra. That wider simplifier is not needed for this issue and would require a separate specification.

The proof is partial correctness only and constructed by source inspection. It is not machine-checked.

