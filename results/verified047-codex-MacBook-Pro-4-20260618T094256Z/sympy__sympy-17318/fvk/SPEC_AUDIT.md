# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item(s) | Result | Notes |
|---|---|---|---|
| C1: `_sqrt_match(4 + I) -> noMatch` | O1, O2, O3 | pass | Directly matches the public `4 + I` failure mechanism. |
| C2: `split_surds(4 + I) -> (1, 0, 4 + I)` | O4 | pass | Prevents empty `_split_gcd` call while preserving 3-tuple shape. |
| C3: `rad_rationalize(1, 4 + I) -> (1, 4 + I)` | O5 | pass | No square-root component exists, so no-op behavior is intent-compatible. |
| C4: `rad_rationalize(1, 1 + cbrt(2)) -> unchanged` | O6 | pass | Stops the non-progressing recursive path identified in the public issue. |
| C5: `rad_rationalize(1, sqrt(2) + I) -> (sqrt(2)-I, 3)` | O7 | pass | Confirms V1's no-surd guard does not block the supported sqrt path. |
| C6: documented `split_surds` example remains supported | O7 | pass | Regular positive square-root grouping is preserved. |
| F1-F2: signatures and return shapes unchanged | O9 | pass | Confirmed by source diff and callsite audit. |
| S1: non-empty surds before `_split_gcd` | O4 | pass | This is exactly the missing precondition in the traceback. |
| S2: positive rational squares before `_sqrt_match` shortcut | O3 | pass | Excludes `I` without weakening regular real-surd inputs. |
| S3: `rad_rationalize` recursion requires square-root progress | O6 | pass | V1's `if not a: return num, den` discharges it. |

## Adequacy Result

The formal English matches the public intent for the audited public examples and
directly changed helper branches. No fail or ambiguous item blocks the decision
to keep V1 unchanged.

## Residual Boundary

Full SymPy algebra, expression canonicalization, and all possible denesting
paths are not represented in this finite mini-semantics. That boundary does not
produce a concrete counterexample against V1, so the revision discipline favors
leaving V1 unchanged.
