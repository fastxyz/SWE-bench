# INTENT_SPEC.md

This file records intent before accepting candidate behavior as expected.

## Required Behaviors

1. `kahane_simplify()` simplifies contracted gamma-matrix products by removing
   contracted gamma matrices according to Kahane identities.
2. Leading gamma matrices that are not part of any contraction are unaffected by
   that simplification.
3. "Unaffected" includes preserving left-to-right order.
4. Both public examples must simplify to the same ordered result:
   `4*G(rho)*G(sigma)`.
5. The issue specifically identifies the restoration loop direction as the
   mechanism to audit.

## Domain Assumptions

- The audited source path is for a `TensMul` product whose factors are all
  `GammaMatrix` tensors.
- At least one Lorentz dummy pair exists, otherwise the function returns the
  original expression before the audited restoration loop.
- The proof is partial correctness for the restoration behavior; termination of
  the surrounding algorithm is not proved.

## Frame Conditions

- Do not change the public function signature or call protocol.
- Do not change contraction coefficients or branch construction computed before
  the prefix restoration loop.
- Do not modify tests in this benchmark.
