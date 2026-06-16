# FVK Iteration Guidance

Status: V2 applied. Constructed, not machine-checked.

## Source Decision

V1 did not fully preserve the legacy direct `Float(...)` conversion path for `_imp_` results that are not sympified as numeric SymPy expressions. Finding F-002 and PO-005 justify the V2 source change.

V2 keeps the V1 recursive numeric-expression behavior required by F-001, PO-001, and PO-002.

V2 keeps the `is_number` guard required by F-003 and PO-004, so implemented functions do not become symbolic rewrite rules for free-symbol expressions.

## Current Patch Shape

In `repo/sympy/core/function.py`, the `_imp_` fallback now:

1. calls `_imp_(*self.args)` once;
2. tries to `sympify` the result;
3. recursively evaluates the result with `_evalf(prec)` only if it is numeric;
4. returns that recursive result only if no `AppliedUndef` remains;
5. otherwise tries legacy `Float(imp_result, prec_to_dps(prec))`;
6. returns `None` on the existing caught failure classes.

## Recommended Tests for a Normal Development Environment

Do not add or edit tests in this benchmark.

When execution is available, add or confirm coverage for:

- `f = implemented_function('f', lambda x: x**2)`, `g = implemented_function('g', lambda x: 2*x)`, `f(g(2)).evalf() == 16`.
- Existing behavior: `implemented_function(Function('f'), lambda x: x + 1)(x).evalf() == f(x)`.
- A direct raw numeric `_imp_` return still evaluates through the fallback.
- Precision-sensitive numeric `_imp_` results receive the requested evalf precision.

## Machine-Check Commands

Recorded only; not run here:

```sh
kompile fvk/mini-sympy-evalf.k --backend haskell
kast --backend haskell fvk/function-evalf-spec.k
kprove fvk/function-evalf-spec.k
```

## Next Iteration

If a later real test or K run fails, inspect whether the failure is in:

- the abstraction boundary from Finding F-004;
- a Python object-return case not represented by `numericExpr`, `symbolicExpr`, `rawFloatable`, or failure;
- broader evalf option plumbing outside `Function._eval_evalf`.

No further source change is justified by the current public evidence after V2.
