# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify an additional source edit.

## Traceability

`fvk/FINDINGS.md::F1` confirms the root cause: applying `dmp_sqf_part` to the
whole multivariate polynomial can remove factors that depend only on lower
variables. This maps to `fvk/PROOF_OBLIGATIONS.md::PO2-PO4` and `PO8`.

`fvk/FINDINGS.md::F2` confirms that V1 addresses that root cause by splitting
the monic polynomial with `dmp_primitive`, recursively factoring the
lower-variable content, and lifting those factors back with `[g]`. This maps to
`PO3-PO5` and `PO8`.

`fvk/FINDINGS.md::F3` confirms that the primitive part still uses the existing
square-free norm path and recovers multiplicities by trial division against the
original monic polynomial. This maps to `PO6-PO8`.

`fvk/FINDINGS.md::F4` confirms there was no public API compatibility issue:
the edit is body-only and keeps the `(coefficient, factors)` return shape. This
maps to `PO11`.

`fvk/FINDINGS.md::F5` records the proof boundary: the constructed proof relies
on existing helper contracts for dense polynomial operations. This maps to
`PO1`, `PO6`, `PO7`, and `PO10`. It does not call for a code edit because the
boundary is verification scope, not a public-intent mismatch.

`fvk/FINDINGS.md::F6` records regression tests that would be useful in normal
development. No test files were edited because the task forbids modifying
tests.

## Artifacts Added

I added the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added supporting constructed K artifacts required by the FVK methodology:

- `fvk/mini-sympy-factor.k`
- `fvk/dmp-ext-factor-spec.k`

These artifacts include exact `kompile`, `kast`, and `kprove` commands for a
future environment. They were not run in this session.

## Code Changes

No source code was changed during the FVK pass. The existing V1 source edit in
`repo/sympy/polys/factortools.py` remains the proposed fix.

