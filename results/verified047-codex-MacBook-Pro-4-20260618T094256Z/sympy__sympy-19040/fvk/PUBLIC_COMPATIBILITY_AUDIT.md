# Public Compatibility Audit

Status: pass. No source edits beyond V1 are required.

## Changed symbol

`sympy/polys/factortools.py:dmp_ext_factor(f, u, K)`

- Signature unchanged.
- Return shape unchanged: `(coefficient, [(factor, multiplicity), ...])`.
- No new public option, argument, exception type, or domain type.
- No virtual dispatch or subclass override protocol is changed.

## Callers and consumers

| Consumer | Compatibility result |
|---|---|
| `dmp_factor_list(f, u, K0)` | Continues to receive `(coeff, factors)` from `dmp_ext_factor`; no callsite change. |
| `factor_list` / `factor` public APIs | Continue to rebuild public expression factorizations from the same internal return shape. |
| `dmp_trial_division` | Still receives a list of candidate factor polynomials and computes multiplicities exactly as before. |
| `dup_ext_factor` | Unchanged; univariate path is still delegated before V1's multivariate code. |

## Regression scenarios touched by V1

- No main-variable content: `cont` is one, content candidate list is empty, and
  the primitive/norm path remains the source of candidates.
- Main-variable content only: V1 now factors that content and returns through
  the existing trial-division result shape.
- Repeated content factors: V1 supplies one content candidate and relies on
  `dmp_trial_division` to compute multiplicity from the preserved original
  polynomial, matching the existing multiplicity protocol.
- Scalar coefficient in content: V1 multiplies the recursive content
  coefficient into `lc`, preserving reconstruction.

No compatibility finding forces a source edit.
