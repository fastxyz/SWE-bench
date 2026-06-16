# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Do not leave V1 unchanged. FVK finding F-002 identified that V1 preserved the
old inverse remapping formula for `syms` orders longer than a two-symbol swap.
The source should keep V1's `permute` propagation and also reindex canonical
tuples by iterating requested `syms`.

Current code status: the V2 source implements that guidance at
`repo/sympy/solvers/diophantine.py:183-185`.

## Next Verification Step

In an environment with K installed, run the commands listed in `fvk/PROOF.md`.
In an environment where project execution is allowed, run the focused
Diophantine tests for:

- `permute=True` with two `syms` orders on the reported even-power equation;
- at least one three-variable `syms` cycle to confirm the generalized remap.

## Residual Risk

The full Diophantine solver is abstracted as `canonicalSolve(eq, permute)`.
This is appropriate for the branch-level bug, but it means the FVK proof does
not establish algebraic completeness of `diop_solve`, `classify_diop`, or the
permutation generators.

## No Test Deletion

Do not remove tests based on this run. The proof is constructed, not
machine-checked, and PO-6 is an explicit solver abstraction boundary.
