# Intent Spec

Status: constructed from public evidence only. This file does not use hidden
tests, evaluator data, internet access, or upstream fixes.

## Target

`pylint.modify_sys_path()` in `repo/pylint/__init__.py`.

## Required Behavior

I1. When Pylint is executed as a module, current-working-directory entries at
the interpreter startup positions should be stripped so local files do not
shadow stdlib or Pylint modules.

I2. The first `sys.path` entry may be removed only if it is a current-directory
marker: `""`, `"."`, or the exact string returned by `os.getcwd()`.

I3. If the first `sys.path` entry is not one of those current-directory markers,
it is caller-owned and must be preserved. This includes the reported
`runpy.run_module(..., alter_sys=True)` scenario where the caller first inserts
`"something"` at index `0`.

I4. Existing `PYTHONPATH` leading-colon and trailing-colon behavior remains in
scope: implicit current-directory entries near the front of `sys.path` should be
removed, but explicit `.` or `cwd` entries in `PYTHONPATH` should not trigger an
extra removal.

I5. Later current-directory entries must not be stripped wholesale, because the
existing docstring identifies editable installs as a legitimate reason for a
current-directory-like entry later in `sys.path`.

I6. Public API compatibility must be preserved: `modify_sys_path()` keeps the
same name, signature, return behavior, and call sites.

## Domain and Assumptions

- `sys.path` is modeled as a finite list of path strings.
- `cwd` is modeled as the exact value returned by `os.getcwd()`, not as a
  normalized or symlink-resolved equivalent.
- `PYTHONPATH` parsing is abstracted into the branch classes used by the code:
  no relevant edge colon, leading implicit current directory, trailing implicit
  current directory, and the explicit `cwd` or `.` exception cases.
- Partial correctness is sufficient. The function has no loops or recursion, so
  no loop termination obligation is present.
