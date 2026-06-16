# Formal Spec English

Status: English paraphrase of the constructed K claims in
`show-versions-spec.k`; not machine-checked.

## Claim DEPS-INFO-INCLUDES-JOBLIB

For any abstract installed-module map, evaluating `_get_deps_info()` with the
current dependency list returns a dependency-info map that contains the key
`"joblib"`. The value for that key is the same generic result used for every
dependency: the installed module version if import succeeds, otherwise `None`.

## Claim DEPS-INFO-PRESERVES-EXISTING-DEPS

For any abstract installed-module map, evaluating `_get_deps_info()` with the
current dependency list still returns entries for `pip`, `setuptools`,
`sklearn`, `numpy`, `scipy`, `Cython`, `pandas`, and `matplotlib`.

## Claim SHOW-VERSIONS-PRINTS-DEPS-INFO

If `_get_deps_info()` returns a map containing `"joblib"`, then
`show_versions()` reaches its `Python deps` printing phase with that map and
therefore emits a dependency line for `"joblib"` along with the other map
entries.

## Claim LEGACY-LIST-OMITS-JOBLIB

The pre-V1 dependency list, which is the same list with `"joblib"` removed,
cannot produce a dependency-info map containing `"joblib"` through the generic
loop alone. This localizes the reported issue to the static dependency list.

## Side conditions

- No ordering claim is made for printed rows.
- No new exception behavior is introduced for `joblib`; the existing
  `ImportError -> None` behavior is reused.
- The proof is partial correctness only: if the modeled functions return, the
  stated map/output properties hold.
