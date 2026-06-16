# Baseline Notes

## Root cause

`sklearn.show_versions()` gets its Python dependency output from the
hard-coded `deps` list in `sklearn/utils/_show_versions.py`.
`joblib` is a required runtime dependency in this tree, but that list did not
include it, so `show_versions()` could not report the installed `joblib`
version.

## Files changed

- `repo/sklearn/utils/_show_versions.py`: added `joblib` to the dependency
  list used by `_get_deps_info()`, placing it with the required scientific
  runtime dependencies before optional/reporting libraries.
- `reports/baseline_notes.md`: added this required explanation of the fix.

## Assumptions and alternatives considered

- I assumed the intended fix is to make `show_versions()` itself report
  `joblib`, because the issue says `joblib` should be added to the dependencies
  listed in `show_versions` or added to the issue template, and the existing
  issue template already asks users to call `sklearn.show_versions()`.
- I rejected changing `ISSUE_TEMPLATE.md` because it would only document a
  workaround and would not make `show_versions()` more complete for users.
- I rejected adding special-case import logic because `_get_deps_info()` already
  handles missing imports by reporting `None`; adding `joblib` to the existing
  list is enough and follows the local pattern.
- I did not run tests or execute project code, per the task constraints.
