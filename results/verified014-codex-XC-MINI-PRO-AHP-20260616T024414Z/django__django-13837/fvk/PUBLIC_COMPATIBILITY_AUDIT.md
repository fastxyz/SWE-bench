# Public Compatibility Audit

Status: source-inspection audit only; no commands executed.

## Changed Symbol

`django.utils.autoreload.get_child_arguments()`

Compatibility result: signature unchanged, return shape unchanged, exception
shape unchanged for the preserved missing-script branch.

## Public Callers

`django.utils.autoreload.restart_with_reloader()` calls
`get_child_arguments()` without arguments and passes the returned list directly
to `subprocess.run()`.

Compatibility result: unchanged. The caller benefits from the new package
`-m` branch and needs no signature or protocol update.

## Overrides / Subclasses

No public override or subclass dispatch is involved; `get_child_arguments()` is
a module-level function.

Compatibility result: no override compatibility risk found.

## Tests as Public Evidence

The existing tests for warning options and fallback branches remain aligned
with the frame conditions. The old path-only `test_run_as_module` mechanism is
suspect relative to the issue text, but the intended real behavior for
`python -m django` remains satisfied by the same `PACKAGE_MAIN` rule used for
other packages.
