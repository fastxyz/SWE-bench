# FVK Iteration Guidance

Status: static guidance after constructed verification.

## Verdict

Keep V1 unchanged. Findings F1-F4 and obligations OBL-1 through OBL-5 support
the conclusion that adding `"joblib"` to `_get_deps_info()`'s dependency list is
the minimal source fix for the public issue.

## Do not make these changes now

- Do not edit `repo/ISSUE_TEMPLATE.md`: F3 and OBL-4 show the template already
  invokes `show_versions()` for this version range, and V1 takes the
  `show_versions()` branch allowed by the issue text.
- Do not add special-case joblib import logic: OBL-2 shows the existing generic
  import/version-or-None path is the intended behavior for all dependencies.
- Do not edit test files: the benchmark forbids it, and F5/OBL-6 keep test
  removal conditioned on future machine-checking.

## Future work when allowed

- Run the emitted K commands and require `kprove` to return `#Top` before making
  any proof-based test-redundancy claims.
- If test edits are later allowed, add or update a unit assertion that
  `_get_deps_info()` contains `"joblib"`.
- Keep integration coverage for `show_versions()` output, because the proof
  abstracts actual printing and importlib behavior.
