# FVK Proof Obligations

Status: constructed, not machine-checked.

## Formal Core

The formal core is split into:

- `fvk/mini-sympy-sets.k`: abstract K semantics for the fuzzy set operations
  used by the audited handlers.
- `fvk/productset-finiteset-spec.k`: reachability claims for the subset and
  equality contracts.

The model is intentionally small. It abstracts SymPy objects to the properties
used by the changed code: product finiteness, product enumeration success or
failure, finite-set membership, fuzzy conjunction, and `tfn` conversion.

## Obligations

| ID | Claim | Informal statement | Finding trace |
|---|---|---|---|
| PO1 | `PSUBSET-NONFINITE` | If `ProductSet.is_finite_set is False` and the target is finite, the subset result is `False`. | F1 |
| PO2 | `PSUBSET-UNKNOWN-FINITE` | If product finiteness is unknown, the specialized handler returns `None` and lets the generic query remain indeterminate. | F1 |
| PO3 | `PSUBSET-FINITE-ENUM` | If product finiteness is `True` and enumeration succeeds, the result is `fuzzy_and(target.contains(x) for x in product)`. | F1 |
| PO4 | `PSUBSET-FINITE-ENUM-FAIL` | If product finiteness is `True` but enumeration raises `TypeError` or `ValueError`, the result is `None`. | F2 |
| PO5 | `PEQ-FSET` / `FSET-PEQ` | Equality between `ProductSet` and `FiniteSet` in either order is `tfn(fuzzy_and([lhs.is_subset(rhs), rhs.is_subset(lhs)]))`. | F3 |

## Commands To Machine-Check Later

These commands are recorded only; they were not executed in this session.

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kast --backend haskell fvk/productset-finiteset-spec.k
kprove fvk/productset-finiteset-spec.k
```

Expected later result: `kprove` discharges all claims to `#Top`.

