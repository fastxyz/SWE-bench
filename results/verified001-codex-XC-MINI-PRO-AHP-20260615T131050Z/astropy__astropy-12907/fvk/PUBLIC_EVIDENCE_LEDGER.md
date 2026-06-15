# Public Evidence Ledger

See `fvk/SPEC.md` for the full table. Critical entries:

- INT-1: The issue states that `Linear1D & Linear1D` has a diagonal
  separability matrix.
- INT-2: The issue states that adding `Pix2Sky_TAN` on the left should still
  leave the linear model inputs and outputs independent.
- INT-3: The issue reports that nesting changes this independence and calls that
  behavior a likely bug.
- INT-4: `separable.py` documents coordinate matrices of shape
  `(n_outputs, n_inputs)`.
- INT-5: `CompoundModel('&')` adds left and right input/output counts, supporting
  block concatenation order.
- INT-6: The pre-fix nested all-True bottom-right output is suspect legacy
  evidence and is rejected as a spec source.
