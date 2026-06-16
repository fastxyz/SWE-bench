# Baseline Notes

## Root Cause

`pylint.modify_sys_path()` removed `sys.path[0]` unconditionally when `pylint`
was executed through `pylint.__main__`. That matched the usual
`python -m pylint` startup shape, where the first entry is the current working
directory, but it was not valid for programmatic execution through
`runpy.run_module(..., alter_sys=True)`. In that case, callers may have already
placed their own import location at the front of `sys.path`, and Pylint removed
that caller-owned entry before running.

The docstring already described the intended cleanup as stripping the current
working directory from the startup path. The implementation was broader than
that contract.

## Changed Files

`repo/pylint/__init__.py`

- Made the first `sys.path` removal conditional on the targeted entry being
  `""`, `"."`, or `os.getcwd()`.
- Added a small local helper so the `PYTHONPATH` leading/trailing colon cases
  also remove only current-working-directory entries instead of blindly popping
  by index.
- Adjusted the `PYTHONPATH` cleanup indices when the first entry is preserved,
  keeping the existing behavior for normal `python -m pylint` execution while
  avoiding removal of a caller-provided front entry.
- Updated the docstring bullet so it no longer claims the first entry is always
  safe to remove.

## Assumptions and Alternatives

- I treated the issue's requested valid removable entries literally:
  `""`, `"."`, and the exact value returned by `os.getcwd()`. I did not add
  broader path normalization or symlink resolution because that would widen the
  behavior beyond the described bug.
- I preserved the existing special handling for `PYTHONPATH` values that start
  or end with `":"`, including the existing exceptions for explicit `cwd` or
  `"."` entries in `PYTHONPATH`.
- I rejected removing all current-working-directory entries from `sys.path`.
  The existing docstring intentionally avoids stripping later entries, because
  editable installs can legitimately add the project path near the end.
- I rejected moving this cleanup into `pylint.__main__` or changing
  `run_pylint()` because the bug is isolated to the path cleanup contract in
  `modify_sys_path()`.
