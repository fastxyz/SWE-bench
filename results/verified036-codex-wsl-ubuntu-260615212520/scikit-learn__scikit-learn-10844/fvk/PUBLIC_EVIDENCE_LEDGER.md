# PUBLIC EVIDENCE LEDGER

This ledger mirrors the critical entries in `SPEC.md`.

- I1: Problem report names `pk * qk` integer overflow in the return expression.
  Obligation: avoid forming the integer product.
- I2: Problem report expects calculating `tk / np.sqrt(pk * qk)` and returning
  a float. Obligation: preserve the mathematical FMI value.
- I3: Problem report proposes `np.sqrt(tk / pk) * np.sqrt(tk / qk)`.
  Obligation: prove this rewrite equivalent and safe.
- I4: Docstring and user guide define FMI as
  `TP / sqrt((TP + FP) * (TP + FN))`. Obligation: follow the public formula.
- I5: Docs say score ranges from 0 to 1. Obligation: preserve boundedness for
  valid counts.
- I6: Public examples/tests cover general, perfect, zero, symmetric, and
  permutation cases. Obligation: preserve those behaviors.
- I7: Source code computes `tk`, `pk`, and `qk` from a contingency matrix.
  Obligation: use those counts as the arithmetic-kernel inputs and preserve
  existing API compatibility.
