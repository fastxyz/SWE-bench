# Baseline Notes

## Root Cause

When `--recursive=y` is enabled, `PyLinter.check()` first calls
`PyLinter._discover_files()` to turn input directories into a flat list of
packages and Python files. That recursive discovery path did not consult the
configured `ignore`, `ignore-patterns`, or `ignore-paths` values. As a result,
ignored directories and files could be yielded before the normal
`expand_modules()` filtering ran, especially for non-package directories walked
with `os.walk()`.

## Changed Files

`repo/pylint/lint/pylinter.py`

- Imported `_is_in_ignore_list_re` from `pylint.lint.expand_modules` so
  recursive discovery uses the same regex matching semantics as normal module
  expansion.
- Added `PyLinter._is_ignored_file()` to centralize basename, basename-regex,
  and path-regex ignore checks for recursive discovery.
- Updated `PyLinter._discover_files()` to accept an optional ignore predicate,
  skip ignored starting arguments, prune ignored directories during `os.walk()`,
  skip ignored directory roots, and avoid yielding ignored `.py` files. The
  default predicate preserves the previous behavior for callers that do not pass
  ignore handling.
- Checked both the original path and `os.path.normpath(path)` for
  `ignore-paths` so paths discovered as `./.a` can still match patterns intended
  for `.a`, while preserving matching against the path spelling produced by the
  walker.

## Assumptions and Alternatives

- I treated the issue as a recursive-discovery bug, not as a request to change
  option defaults. In this checkout, the default `ignore-patterns` value is
  `^\.#`, matching the help text for Emacs lock files; changing it to ignore all
  dot directories would be a separate behavior change.
- I applied ignore checks while walking directories rather than only filtering
  the final yielded file list. Filtering only yielded files would still allow
  nested files under an ignored directory to be discovered if their own basename
  did not match `--ignore`.
- I kept the change in `pylinter.py` instead of changing `expand_modules()`
  because the missed filtering happens before `expand_modules()` receives the
  recursive file list.
- I did not modify tests or run tests/code, per the benchmark instructions.
