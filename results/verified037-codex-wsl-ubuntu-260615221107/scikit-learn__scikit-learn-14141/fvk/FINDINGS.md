# FVK Findings

Status: static FVK audit, constructed and not machine-checked.

## F1 - Root cause confirmed: static dependency list omitted joblib

- Evidence: E1-E4 and OBL-1.
- Input/environment: scikit-learn 0.22 with any installed-module map where
  `joblib` may be installed or absent.
- Pre-V1 observed behavior by static reasoning: `_get_deps_info()` iterated a
  list containing `pip`, `setuptools`, `sklearn`, `numpy`, `scipy`, `Cython`,
  `pandas`, and `matplotlib`, but not `joblib`; the resulting dependency map
  therefore had no `joblib` key.
- Expected behavior: the dependency map and `show_versions()` dependency output
  include a `joblib` entry.
- Classification: code bug in pre-V1; localized to the static `deps` list.

## F2 - V1 satisfies the show_versions remedy

- Evidence: OBL-1, OBL-2, OBL-3.
- V1 behavior by static reasoning: `"joblib"` is now in the `deps` list, so the
  existing loop applies the same import/version-or-None behavior used for other
  dependencies and `show_versions()` prints the resulting dependency map.
- Expected behavior: `show_versions()` dependency output contains `joblib`.
- Classification: confirmed fixed for the public issue intent.

## F3 - No issue-template edit is required

- Evidence: E2, E5, OBL-4.
- Observed behavior: `ISSUE_TEMPLATE.md` already instructs scikit-learn
  `>= 0.20` users to call `import sklearn; sklearn.show_versions()`.
- Expected behavior: either the template asks for `joblib` directly or
  `show_versions()` reports it.
- Classification: no code/docs change needed; V1 chooses the `show_versions()`
  branch of the issue's alternatives.

## F4 - No compatibility blocker found

- Evidence: OBL-5 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Observed behavior: no function signature, public call protocol, subclass
  override, or return shape is changed except that the returned dependency map
  has one additional key.
- Expected behavior: existing dependency reporting continues while adding
  `joblib`.
- Classification: compatibility pass.

## F5 - Residual verification caveat

- Evidence: OBL-6.
- Observed behavior: K commands were written but not executed, per benchmark
  constraints.
- Expected behavior: machine verification would require running the emitted
  `kompile`, `kast`, and `kprove` commands and receiving `#Top`.
- Classification: proof status caveat, not a code bug.

## Test guidance

No tests were modified. A direct unit assertion that `_get_deps_info()` contains
`"joblib"` would be useful when test edits are allowed, but any test removal
would be conditioned on actual machine-checking, which was not performed.
