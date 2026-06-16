# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`,
`kast`, or `kprove` were run.

## Claims Proved

The constructed proof covers PO-1 through PO-5 in `PROOF_OBLIGATIONS.md`.
The K files are `mini-sklearn-clone.k` and `clone-params-spec.k`.

## Abstraction Adequacy

The mini semantics models the property axis that matters for this issue:

- whether a value has `get_params`;
- whether that value is a class;
- whether clone/deep-parameter expansion calls the estimator-like path or the
  ordinary-value path.

The abstraction distinguishes a failing pre-fix input from a passing post-fix
input: `classObj(C)` has `get_params` but is not an estimator instance, while
`kernelObj(K, P)` has `get_params` and is a non-class estimator-like value.

The Python loops over parameter dictionaries and named estimator lists are
reduced to per-entry obligations. This preserves the audited property because
the bug is local to the branch decision for each value.

## Proof Sketch

PO-1: For `classObj(C)`, the semantics gives `hasGetParams(classObj(C)) = true`
and `isClass(classObj(C)) = true`. Therefore
`isEstimatorInstance(classObj(C)) = false`. The `CloneParam(O, false)` rule for
non-estimator values applies and rewrites to `ObjResult(deepCopy(classObj(C)))`;
the `deepCopy` rule for classes rewrites that to `ObjResult(classObj(C))`.
No rule on this path calls `get_params` on the class.

PO-2: For `kernelObj(K, P)`, the semantics gives
`hasGetParams(kernelObj(K, P)) = true` and `isClass(kernelObj(K, P)) = false`.
Thus `isEstimatorInstance(kernelObj(K, P)) = true`, and the estimator-clone
rule applies. This discharges the public hint that the fix must not tighten
support to `BaseEstimator` instances only.

PO-3: For `DeepParamEntry(PNAME, classObj(C))`, the same class calculation makes
`isEstimatorInstance(classObj(C)) = false`. The ordinary-include rule applies,
rewriting to `IncludeOnly(PNAME, classObj(C))`. This corresponds to returning
the direct parameter and emitting no nested `PNAME__...` entries.

PO-4: `CompositionEntry(NAME, classObj(C))` follows the same proof as PO-3.
This closes the V1 coverage gap in `_BaseComposition._get_params`.

PO-5: `CloneParam(classObj(C), true)` is a non-estimator safe clone call, so it
rewrites to `TypeError`. The public issue does not require direct top-level
class cloning to succeed.

## Machine Check Commands

These commands are emitted for later reproduction and were not executed:

```sh
kompile fvk/mini-sklearn-clone.k --backend haskell
kast --backend haskell fvk/clone-params-spec.k
kprove fvk/clone-params-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top` for
all claims.

## Residual Risk

This is a partial-correctness proof over a mini semantics. It does not prove
termination, Python object model completeness, or behavior outside the stated
parameter-introspection paths. No test removal is recommended because the proof
has not been machine-checked and the task forbids editing tests.
