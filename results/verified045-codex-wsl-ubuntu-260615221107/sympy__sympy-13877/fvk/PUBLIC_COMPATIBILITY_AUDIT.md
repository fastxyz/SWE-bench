# Public Compatibility Audit

Changed public method: `MatrixDeterminant.det(self, method="bareiss")`.

- Signature unchanged.
- Accepted method strings unchanged.
- Non-square exception behavior unchanged.
- Return shape remains a SymPy expression, including `S.NaN`.
- No new keyword arguments or virtual dispatch requirements were introduced.

Changed internal helper: local `_find_pivot` inside `_eval_det_bareiss`.

- Not public.
- Return tuple shape unchanged.
- The pivot value may be an expanded equivalent expression, which is necessary
  for correctness and does not change the public API.

