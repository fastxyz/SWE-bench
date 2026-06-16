# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were executed.

## Claims proved by construction

- OBL-1: `_get_deps_info()` returns a map containing `"joblib"`.
- OBL-2: the `"joblib"` value is computed by the existing generic
  import/version-or-None rule.
- OBL-3: `show_versions()` prints the dependency map and therefore emits a
  `joblib` dependency line.
- OBL-5: existing dependency keys and public signatures are preserved.

## Symbolic proof sketch

The mini semantics models `_get_deps_info()` as a loop over a dependency list
with accumulator map `M`. For each dependency name `D`, the loop updates
`M[D]` to `versionOf(D, INSTALLED)`, where `versionOf` abstracts
`importlib.import_module(D).__version__` and the `ImportError -> None` fallback.

For the V1 list, list decomposition reaches the element `"joblib"`. At that
step, the loop rewrites:

```text
M => M["joblib" <- versionOf("joblib", INSTALLED)]
```

Subsequent loop iterations update only later keys (`"Cython"`, `"pandas"`,
`"matplotlib"`) and do not delete the `"joblib"` binding. At loop exit,
`deps_info` is exactly the accumulated map, so `"joblib" in_keys(deps_info)` and
`deps_info["joblib"] == versionOf("joblib", INSTALLED)`.

The same loop also visits every pre-existing dependency key, so V1 preserves
the existing dependency-reporting frame condition. Since `show_versions()`
obtains `deps_info` and then prints the dependency map entries in its
`Python deps` phase, the printed dependency block includes `"joblib"`.

The diagnostic pre-V1 claim uses the same loop over the old list without
`"joblib"`. Because the loop only inserts keys that appear in its list, no
`"joblib"` binding can be produced. That proves the root-cause localization in
F1 and shows why the V1 list change is sufficient.

## Verification conditions

- VC-1: list membership - `"joblib"` occurs in `depsV1()`.
- VC-2: map update preservation - updating keys after `"joblib"` does not remove
  the existing `"joblib"` binding.
- VC-3: version fallback totality - `versionOf("joblib", INSTALLED)` is defined
  as either the installed version or `"None"`.
- VC-4: print propagation - `showVersions(depsV1())` transfers the dependency
  map to `printedDeps`.

All four verification conditions are discharged by the rewrite rules in
`mini-show-versions.k` and the claims in `show-versions-spec.k`, subject to
later machine-checking.

## Commands not executed

```sh
kompile fvk/mini-show-versions.k --backend haskell
kast --backend haskell fvk/show-versions-spec.k
kprove fvk/show-versions-spec.k --backend haskell
```

Expected result if machine-checked successfully: `#Top`.

## Test-redundancy recommendation

No test files were modified. Because this proof is not machine-checked, no
existing test should be removed. If the K claims later discharge, a direct unit
test that only checks `"joblib" in _get_deps_info()` would be subsumed by
OBL-1, but integration tests for the actual printed output and import behavior
should remain useful.

## Residual risk

This is a partial-correctness proof over a small semantics fragment. The trusted
base is the adequacy of the mini semantics, the correctness of the public intent
ledger, and future K tooling. The result justifies keeping V1 unchanged as a
source fix, but not claiming machine-checked verification.
