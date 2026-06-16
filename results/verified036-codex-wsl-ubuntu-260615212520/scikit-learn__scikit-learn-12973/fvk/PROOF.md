# FVK Proof

Status: constructed, not machine-checked. No Python, tests, `kompile`, `kast`, or `kprove` were run.

## What Is Proved

For the copy-routing slice of `LassoLarsIC.fit`:

1. If the fit-level `copy_X` value is `None`, both `_preprocess_data` and `lars_path` receive `self.copy_X`.
2. If the fit-level `copy_X` value is explicitly `True` or `False`, both `_preprocess_data` and `lars_path` receive that explicit value.
3. Therefore the in-domain fit call cannot route contradictory `copy_X` values internally.

## Symbolic Execution Sketch

The mini-K model abstracts the audited source to:

`fitRoute(self_copy, fit_copy_arg) -> (preprocess_copy, lars_path_copy)`

The pair records the two copy-sensitive downstream calls. This preserves the property under verification because a passing instance and a failing instance map to different observables:

- Passing instance: `fitRoute(False, None) -> (False, False)`.
- Pre-fix failing instance: omitted fit argument with constructor `False` would route `(False, True)`.

### Claim 1: None/default argument

Initial state:

`<k> fitRoute(C, None) </k>`

The `None` rule fires:

`fitRoute(C, None) => (C, C)`

This corresponds to `least_angle.py:1504-1505`, where `copy_X is None` assigns `self.copy_X` into the local `copy_X`, followed by lines 1507-1515, where that same local is passed to both copy-sensitive operations.

Result: PO-1 and the `None` branch of PO-3 discharge.

### Claim 2: explicit boolean argument

Initial state:

`<k> fitRoute(C, F) </k>` where `F` is `True` or `False`.

The explicit boolean rule fires:

`fitRoute(C, F) => (F, F)`

This corresponds to skipping the `copy_X is None` assignment and then using the unchanged local `copy_X` at both downstream calls.

Result: PO-2 and the explicit-boolean branch of PO-3 discharge.

## Adequacy Gate

The English meaning of the K claims is exactly the intent in `SPEC.md`: omitted/`None` uses the constructor value, explicit booleans override consistently, and mixed internal routing is forbidden. The model does not claim anything about numerical LARS correctness, which is outside the issue and outside this proof.

## Compatibility Proof Sketch

The public method still accepts `copy_X` as the third argument. Existing explicit boolean callers continue to bind successfully. Existing omitted-argument callers continue to bind successfully, with the intended behavior change from the public issue. Local source search found no in-repo `LassoLarsIC` subclass or in-repo explicit `LassoLarsIC.fit(..., copy_X=...)` callsite requiring an additional source update.

## Residual Risk

The proof is constructed but not machine-checked. The trusted base is the adequacy of the mini-K abstraction for copy-routing, the source-to-model correspondence, and the K reachability proof system once the commands are run.

Termination and numerical correctness of `lars_path` are not proved here. They are framed because the source diff does not alter that behavior.

## Test Guidance

No tests should be removed. Useful future public tests would cover:

- `LassoLarsIC(copy_X=False).fit(X, y)` routes `False` to both copy-sensitive calls.
- `LassoLarsIC(copy_X=True).fit(X, y, copy_X=False)` routes `False` to both copy-sensitive calls.
- `LassoLarsIC(copy_X=False).fit(X, y, copy_X=None)` routes `False` to both copy-sensitive calls.

These are recommendations only; this task forbids modifying tests.

## Expected Machine Check

Commands to run in an environment with K installed:

```sh
cd fvk
kompile mini-copy-routing.k --backend haskell
kast --backend haskell lasso-lars-ic-copy-x-spec.k
kprove lasso-lars-ic-copy-x-spec.k
```

Expected result if the constructed artifacts are accepted by the toolchain: `kprove` returns `#Top`.
