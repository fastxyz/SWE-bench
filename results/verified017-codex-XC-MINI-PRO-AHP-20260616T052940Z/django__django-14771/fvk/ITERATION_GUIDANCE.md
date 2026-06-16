# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No further source edit is justified by the FVK audit. V1 discharges all open
proof obligations in `PROOF_OBLIGATIONS.md`; the only non-code caveats are the
attached `-X<key>` spelling assumption (F-003) and the constructed-not-machine-
checked proof status (F-005).

## Recommended Tests When Test Editing Is Allowed

- Add a `get_child_arguments()` unit test with `_xoptions = {'utf8': True}` on
  the ordinary script path, expecting an equivalent `-X utf8` replay before the
  script argument.
- Add a value-style xoption test, for example `_xoptions = {'pycache_prefix':
  '/tmp/cache'}`, expecting `-Xpycache_prefix=/tmp/cache`.
- Add a module relaunch test that combines `sys.warnoptions` and `_xoptions` to
  confirm warning and xoption args are both preserved before `-m`.
- Keep existing tests for `.exe` fallback behavior because that branch remains a
  deliberate non-`sys.executable` path.

## Follow-Up Verification

Run the commands in `PROOF.md` in an environment with K installed. Until
`kprove` returns `#Top`, treat the proof as constructed evidence and keep the
test suite intact.
