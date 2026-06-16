# Baseline Notes

## Root Cause

`PTH123` and `S102` both inspect the semantic qualified name of a call target and compare the call path against a literal module segment. They correctly included the empty segment (`""`) for unqualified builtin calls like `open()` and `exec()`, but they used `"builtin"` for explicitly qualified calls. Python's standard-library module is named `builtins`, so `builtins.open()` and `builtins.exec()` were missed while unrelated `builtin.open()` and `builtin.exec()` calls were reported.

## Changed Files

- `repo/crates/ruff_linter/src/rules/flake8_bandit/rules/exec_used.rs`
  - Changed the `S102` qualified-name match from `["" | "builtin", "exec"]` to `["" | "builtins", "exec"]`.
  - This keeps detection for unqualified `exec()` and adds detection for `builtins.exec()`, while avoiding false positives for a non-standard `builtin` module.

- `repo/crates/ruff_linter/src/rules/flake8_use_pathlib/rules/replaceable_by_pathlib.rs`
  - Changed the `PTH123` qualified-name match from `["" | "builtin", "open"]` to `["" | "builtins", "open"]`.
  - This keeps detection for unqualified `open()` and applies the existing pathlib compatibility checks to `builtins.open()`, while avoiding false positives for a non-standard `builtin` module.

## Assumptions and Alternatives

- I assumed the semantic model resolves `import builtins; builtins.open(...)` and `import builtins; builtins.exec(...)` to qualified names beginning with `"builtins"`, matching other Ruff code paths that already use `["" | "builtins", ...]` for builtin references.
- I rejected adding `"builtin"` as an accepted alias because the issue specifically identifies it as the incorrect module name and because keeping it would preserve the documented false positives.
- I did not add or modify tests because the benchmark instructions prohibit changing test files.
