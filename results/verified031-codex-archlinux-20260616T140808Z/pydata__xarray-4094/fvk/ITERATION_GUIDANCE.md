# Iteration Guidance

Status: derived from `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## Code decision

V1 should not stand unchanged because F2 violates PO4. V2 repairs F2 by
replacing unrestricted `.squeeze(drop=True)` with targeted squeezing. The V1
coordinate drop from F1 remains, because PO3 and PO7 require consumed stacked
metadata to be removed before dataset construction.

## Recommended validation when an execution environment exists

Do not modify tests in this benchmark, but future validation should include:

- Issue roundtrip: two variables with only sample dimension `x`, `x` length
  greater than one.
- Length-one sample-dimension roundtrip: same as the issue family, but `x`
  length one, proving PO4.
- Mixed-dimensional roundtrip: one variable with a real remaining level and one
  variable missing it, proving PO5 and PO6.
- Non-MultiIndex guard: existing `ValueError` case, proving PO1.

## Test redundancy

No tests are recommended for removal. The proof is constructed, not
machine-checked, and this task forbids running the Python suite.

## Residual questions

The public issue and local tests justify the issue family and one-real-level
mixed-dimensional behavior. Arbitrary hand-built MultiIndex shapes and broader
multi-level unstacking remain outside this constructed proof and should be
covered by separate intent and tests before any further refactor.
