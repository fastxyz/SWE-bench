# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed implementation symbol:

- `repo/sympy/polys/densetools.py`
  - `dup_clear_denoms(f, K0, K1=None, convert=False)`
  - `dmp_clear_denoms(f, u, K0, K1=None, convert=False)`

Compatibility checks:

| Surface | Status | Notes |
|---|---|---|
| Function signatures | Unchanged | No parameters, defaults, or names changed. |
| Return arity | Unchanged | Both helpers still return `(common, dense_result)`. |
| `convert=False` behavior | Compatible | Algebraic result unchanged; dense result may now be more canonical by removing leading zero terms. |
| `convert=True` behavior | Compatible | Algebraic result unchanged; canonicalization happens before conversion, and existing conversion still handles domain change. |
| Public callsites | Compatible | Callers in `euclidtools`, `factortools`, `rootisolation`, `compatibility`, and wrappers consume the same tuple shape. Canonical zero is a stricter valid dense representation. |
| `Poly.clear_denoms()` wrapper | Improved | Receives canonical dense zero before `DMP.per()` wraps it. |
| Tests | Not modified | The benchmark forbids editing test files. |

Compatibility conclusion: V1 changes representation quality, not API shape. The
only observable behavior intentionally changed is that a denominator-cleared
zero polynomial now reports and behaves as zero through dense-polynomial methods.
