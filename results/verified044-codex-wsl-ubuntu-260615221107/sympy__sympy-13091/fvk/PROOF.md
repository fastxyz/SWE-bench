# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` command was run.

## What is proved

The constructed proof covers the comparison result category for the audited SymPy core comparison methods:

- unsupported `Basic.__eq__` cases return `NotImplemented`
- `Basic.__ne__` and numeric `__ne__` methods preserve `NotImplemented`
- unsupported `Expr` ordering cases return `NotImplemented`
- recognized invalid complex/NaN ordering remains an invalid comparison error
- unsupported core numeric comparison overrides return `NotImplemented`
- numeric singleton equality returns `True` only for the identical singleton, `False` for different known SymPy numbers, and `NotImplemented` for unsupported non-number operands

The proof is partial correctness over straight-line method bodies. There are no loops, recursion, or termination obligations.

## Proof sketch

1. `Basic.__eq__` has two unsupported branches under `type(self) is not type(other)`: `_sympify(other)` failure and post-sympification type mismatch. V2 returns `NotImplemented` in both branches, discharging PO1 and PO2.

2. `Basic.__ne__` stores `eq = self.__eq__(other)` and returns `NotImplemented` exactly when `eq is NotImplemented`; otherwise it returns `not eq`. This discharges PO3 for `Basic`.

3. Python equality dispatch is modeled by `pyEq`. If the left method returns `RNotImplemented`, the right result determines the final boolean; if both return `RNotImplemented`, final equality is `RFalse`. This is the language behavior cited by the issue and discharges PO4.

4. `Expr` ordering methods now return `NotImplemented` in the `except SympifyError` branches. The later checks for complex and NaN operands are reached only after sympification succeeds, and still raise the invalid-comparison category. This discharges PO5 and the ordering part of PO8.

5. Numeric overrides in `numbers.py` now return `NotImplemented` for unsupported sympification failure or unsupported non-number cases, and their `__ne__` methods preserve `NotImplemented`. Supported numeric branches still compute booleans. This discharges PO6 and the numeric part of PO8.

6. FVK found that V1's singleton equality methods used `_sympify(other)` even though the original methods were identity checks. V2 removes that sympification and implements the intended trichotomy: same singleton true, other known `Number` false, unsupported non-number `NotImplemented`. This discharges PO7 and resolves Finding F4.

## Machine-check commands

These commands are emitted for a future environment with K installed. They were not run here.

```sh
kompile fvk/mini-python-richcompare.k --backend haskell
kast --backend haskell fvk/sympy-richcompare-spec.k
kprove fvk/sympy-richcompare-spec.k
```

Expected machine-check result after the model is accepted by K: `#Top` for all claims.

## Residual risk

- The K model is an abstract mini semantics of rich-comparison result categories, not a full Python semantics.
- The proof is constructed, not machine-checked.
- The proof establishes the audited shared-core behavior, not a package-wide cleanup of every specialized comparison method.
- Test removal is not recommended. Existing and hidden tests should be kept unless the K claims are machine-checked and mapped to concrete test coverage.
