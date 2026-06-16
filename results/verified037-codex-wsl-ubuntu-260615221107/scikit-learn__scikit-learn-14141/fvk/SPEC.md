# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Target

The audited behavior is the dependency-reporting path:

- `repo/sklearn/utils/_show_versions.py::_get_deps_info()`
- `repo/sklearn/utils/_show_versions.py::show_versions()`

The public issue requires `joblib` to appear in the dependencies listed by
`show_versions()` for this scikit-learn 0.22 task. V1 implements the
`show_versions()` remedy by adding `"joblib"` to `_get_deps_info()`'s static
`deps` list.

## Intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: the issue explicitly requires `joblib` to be added to
  `show_versions()` dependencies or to the issue template.
- E3: this task is version `0.22`, so the issue's `> 0.20` condition applies.
- E4: `setup.py` lists `joblib` in `install_requires`, so it is a runtime
  dependency rather than incidental optional state.
- E5: the issue template already asks scikit-learn `>= 0.20` users to paste
  `sklearn.show_versions()` output.
- E6: `_get_deps_info()` applies generic import/version-or-None behavior to
  each name in the hard-coded dependency list.

## Formal contract

For any abstract installed-module map `INSTALLED`:

- `_get_deps_info()` over the V1 dependency list returns a map containing
  `"joblib"`.
- The `"joblib"` value is `joblib.__version__` when the abstract import succeeds
  and `None` when the abstract import raises `ImportError`, matching the
  existing behavior for every dependency in the list.
- Existing dependency names remain present in the returned map.
- `show_versions()` prints the dependency map it obtains from `_get_deps_info()`;
  therefore its `Python deps` block contains `"joblib"` whenever the returned
  map contains `"joblib"`.

No printed-row ordering obligation is specified because the public issue only
requires inclusion.

## K artifacts

- `fvk/mini-show-versions.k` defines a small K fragment for the dependency list
  loop, abstract module-version lookup, and dependency printing.
- `fvk/show-versions-spec.k` defines the reachability claims:
  `DEPS-INFO-INCLUDES-JOBLIB`, `DEPS-INFO-PRESERVES-EXISTING-DEPS`,
  `SHOW-VERSIONS-PRINTS-DEPS-INFO`, and a diagnostic
  `LEGACY-LIST-OMITS-JOBLIB` claim.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-show-versions.k --backend haskell
kast --backend haskell fvk/show-versions-spec.k
kprove fvk/show-versions-spec.k --backend haskell
```

Expected machine-check outcome, if the mini semantics are accepted: `#Top` for
the current-code claims. This expectation is constructed, not observed.

## Adequacy and compatibility

- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the formal claims.
- `fvk/SPEC_AUDIT.md` compares those claims to the intent spec and marks them
  adequate.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records that V1 changes no signatures,
  call protocols, overrides, or return shapes beyond the intended added key.
