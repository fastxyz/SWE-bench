# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or SymPy imports were run.

## Formal Artifacts

Constructed K files:

- `fvk/mini-sympy-evalf.k`
- `fvk/function-evalf-spec.k`

Commands to machine-check later, not executed here:

```sh
kompile fvk/mini-sympy-evalf.k --backend haskell
kast --backend haskell fvk/function-evalf-spec.k
kprove fvk/function-evalf-spec.k
```

Expected machine-check outcome after a real K run: `#Top` for all claims. This expectation is constructed from the proof below, not observed.

## Claims Proved in the Constructed Model

1. `IMP-NUMERIC-RECURSES`: numeric sympified `_imp_` results are recursively evaluated with `prec`.
2. `ISSUE-COMPOSITION`: the issue example shape evaluates to `16`.
3. `SYMBOLIC-NONNUMERIC-NO-REWRITE`: nonnumeric symbolic `_imp_` results do not become symbolic rewrites.
4. `RAW-FLOAT-FALLBACK`: raw Float-compatible values still use the legacy Float conversion path.
5. `FAILURE-RETURNS-NONE`: unsupported or raising fallback cases return no value.
6. `UNRESOLVED-NUMERIC-NO-SUCCESS`: recursive numeric evaluation that still contains an applied undefined function is not returned as success.

## Constructed Proof Sketch

### PO-001: Recursive numeric result

Start in the no-mpmath fallback branch. The semantic step for `_imp_(*self.args)` produces an abstract `numericExpr(E)`. The `sympify` abstraction maps it to `E`. The side condition `isNumber(E)` holds. The V2 branch then rewrites to `recEval(E, P)`, matching the code's `result._evalf(prec)`, and returns only if `hasAppliedUndef(recEval(E, P))` is false.

This discharges PO-001 because the formal post-state is exactly the recursive-eval result with the same binary precision variable `P`.

### PO-002: Issue composition

Instantiate PO-001 with `E = square(innerImpExpr(2))`.

Symbolic execution:

1. `recEval(innerImpExpr(2), P)` uses the inner implementation `g(x) = 2*x`, yielding `evaled(4)`.
2. `recEval(square(innerImpExpr(2)), P)` evaluates the base first and then squares it.
3. `square(evaled(4))` simplifies to `evaled(16)`.

The final post-state is `some(evaled(16))`, so the pre-fix `f(g(2))` residual is excluded.

### PO-003: Precision propagation

The numeric-expression branch carries `P` unchanged into `recEval(E, P)`, corresponding to `_evalf(prec)` in source. The raw fallback branch uses `precToDps(P)`, corresponding to `mlib.libmpf.prec_to_dps(prec)` before calling public `Float`.

The proof obligation is a frame/argument-preservation property, not arithmetic over the concrete precision value.

### PO-004: Symbolic nonnumeric result

For `symbolicExpr(symbolExpr)`, `isNumber(symbolExpr)` is false. The recursive rule is blocked. The fallback attempts `Float` conversion in the source; for ordinary symbolic expressions this raises a caught conversion error and returns `None`.

The constructed claim models this as `none`, preserving the public test expectation that `f(x).evalf()` remains `f(x)` at the outer evalf layer.

### PO-005: Raw Float fallback

For `rawFloatable(I)`, the sympified numeric-expression rule is not used in the model. The fallback rule returns `some(floatRaw(I, precToDps(P)))`, matching the V2 source's direct `Float(imp_result, prec_to_dps(prec))`.

This is the proof-derived improvement over V1.

### PO-006: Failure behavior

For `badResult` or `impRaises`, the model reaches `none`. This corresponds to the outer catch of `AttributeError`, `TypeError`, and `ValueError` and preserves the legacy "not evaluable" convention.

### PO-009: Unresolved applied undefined function

For `numericExpr(unresolvedImpExpr(I))`, `isNumber(...)` is true but `recEval(...)` still has an applied undefined function. The recursive success rule is blocked by `notBool hasAppliedUndef(...)`, and the model reaches `none`, matching the source guard before returning a recursive result.

## Adequacy and Completeness Check

The formal English in `SPEC.md` matches the intent spec:

- It covers the reported composition behavior.
- It covers the public precision hint.
- It covers the public existing behavior for free-symbol inputs.
- It covers the compatibility frame created by the old `Float(...)` conversion.
- It covers the fallback behavior when recursive evaluation still cannot resolve an applied undefined function.

The model does not cover full Python object semantics or all possible user `_imp_` callables. That boundary is explicit in Finding F-004 and is not used to claim machine-verified correctness.

## Test Recommendation

Do not modify tests in this benchmark.

Conditioned on future machine-checking, a direct unit assertion for `f(g(2)).evalf() == 16` would be subsumed by PO-001 and PO-002 within the modeled domain. Existing tests around `f(2).evalf() == 3` and `f(x).evalf() == f(x)` should be kept unless the full project suite and real K proof are available, because they also guard integration with SymPy's broader evalf machinery.

## Residual Risk

The proof is partial correctness over an abstract fallback model. It does not prove termination, performance, or full SymPy/Python semantics. The trusted base is the adequacy of the mini model, the matching-logic/K proof system, and any future `kprove` machine check.
