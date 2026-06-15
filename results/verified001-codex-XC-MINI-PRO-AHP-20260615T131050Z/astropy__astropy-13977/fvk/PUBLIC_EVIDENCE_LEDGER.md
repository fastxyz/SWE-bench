# Public Evidence Ledger

See `fvk/SPEC.md` for the mirrored ledger entries E1-E8. This separate file is
included to satisfy the FVK adequacy contract.

Summary:

- E1-E2 identify the user-visible bug: `ValueError` from converter application
  where `NotImplemented` should allow reflected dispatch.
- E3-E6 establish the intended boundary: only recognized classes are handled by
  Quantity; merely having `.unit` is insufficient, and `__array__` coercion is
  not the desired solution.
- E7-E8 establish implementation facts used by the model: table Columns are
  ndarray subclasses, and the converter helper's documented domain is Quantity
  or ndarray subclasses.

