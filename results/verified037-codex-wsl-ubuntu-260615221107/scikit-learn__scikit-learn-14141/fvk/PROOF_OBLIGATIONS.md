# FVK Proof Obligations

Status: constructed obligations; no proof tooling executed.

## OBL-1 - Intent coverage for joblib

`_get_deps_info()` must return a dependency-info map containing the key
`"joblib"` for this scikit-learn 0.22 task. This obligation is intent-derived
from E1-E4.

## OBL-2 - Generic dependency semantics for joblib

The `"joblib"` entry must use the same semantics as other entries in the
dependency list: import the module and read `__version__`; if import raises
`ImportError`, record `None`. This obligation is implementation-derived from
E6 but publicly justified by E4, because `joblib` is a required dependency and
should not need a special reporting path.

## OBL-3 - show_versions prints the dependency map

`show_versions()` must include the `joblib` entry in its user-visible
`Python deps` block when `_get_deps_info()` returns a map containing `joblib`.
This is intent-derived from E1 and implementation-derived from the printing
loop in `show_versions()`.

## OBL-4 - Issue-template alternative is discharged

No issue-template edit is required if OBL-1 through OBL-3 hold, because E2
allows adding `joblib` to `show_versions()` dependencies as an alternative to
template changes, and E5 shows the template already routes version reporting
through `show_versions()` for scikit-learn `>= 0.20`.

## OBL-5 - Frame and compatibility

Adding `joblib` must not remove existing reported dependency entries or change
the public call signature of `show_versions()` or `_get_deps_info()`. No printed
row ordering is obligated.

## OBL-6 - Honesty gate

All proof claims remain "constructed, not machine-checked." The exact commands
to run later are:

```sh
kompile fvk/mini-show-versions.k --backend haskell
kast --backend haskell fvk/show-versions-spec.k
kprove fvk/show-versions-spec.k --backend haskell
```

No test deletion or machine-checked confidence is justified until those
commands successfully discharge the claims.
