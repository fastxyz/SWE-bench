# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Required behavior

- For the benchmarked scikit-learn version (`0.22`), the dependency
  information surfaced by `sklearn.show_versions()` must include `joblib`.
- `joblib` should be treated like the other dependencies reported by
  `_get_deps_info()`: if importable, report its `__version__`; if not importable,
  report `None`.
- Existing dependency entries (`pip`, `setuptools`, `sklearn`, `numpy`,
  `scipy`, `Cython`, `pandas`, `matplotlib`) must remain reported.
- The issue template need not be changed if `show_versions()` itself reports
  `joblib`, because the template already instructs users on scikit-learn
  `>= 0.20` to paste `sklearn.show_versions()` output.

## Out of scope

- Exact row ordering in the printed dependency block is not part of the public
  issue text.
- BLAS/system reporting is unchanged and not implicated by the issue.
- Machine verification is out of scope for this benchmark run; commands are
  recorded but not executed.
