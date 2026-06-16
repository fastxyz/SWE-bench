# SPEC

Status: FVK audit for V1; constructed, not machine-checked.

## Target

`repo/django/core/files/locks.py`, POSIX branch when `import fcntl` succeeds.
The audited public behavior is the return value of `lock(f, flags)` and
`unlock(f)` around `fcntl.flock()`.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical
entries are:

- E1: CPython `fcntl.flock()` returns `None` on success and raises `OSError` on
  failure.
- E2: Non-blocking callers need a valid boolean return value to know whether
  they acquired the lock.
- E3: The issue's proposed POSIX fix applies the same `try`/`except OSError`
  structure to `unlock()`.
- E4-E6: Public names, signatures, constants, and existing in-repo call shapes
  must be preserved.

## Intent-Only Contract

For the POSIX fcntl implementation:

- `lock(f, flags)` returns `True` when `fcntl.flock(_fd(f), flags)` completes
  without raising `OSError`.
- `lock(f, flags)` returns `False` when that `fcntl.flock()` call raises
  `OSError`.
- `unlock(f)` returns `True` when `fcntl.flock(_fd(f), fcntl.LOCK_UN)` completes
  without raising `OSError`.
- `unlock(f)` returns `False` when that unlock call raises `OSError`.

## Domain and Frame Conditions

The formal model starts after `_fd(f)` has produced a non-negative file
descriptor. This matches the issue boundary: the bug is the interpretation of
`fcntl.flock()`'s result, not descriptor extraction.

The Windows branch, unsupported-locking branch, exported constants, exported
names, and function signatures are frame conditions and remain unchanged.

## Formal Core

The K core is in:

- `fvk/mini-python-locks.k`: a minimal semantics that abstracts the POSIX
  `fcntl.flock()` call to two outcomes, `ok` and `osError`.
- `fvk/locks-spec.k`: four reachability claims over the public outcomes:
  `lock-success`, `lock-oserror`, `unlock-success`, and `unlock-oserror`.

The exact commands to machine-check later are recorded in `fvk/PROOF.md`; they
were not run.

## Adequacy Gate

The adequacy artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All required formal claims pass the intent audit. No claim relies on preserving
the legacy `ret == 0` behavior.

## V1 Audit Result

V1 satisfies the four public obligations by treating normal `fcntl.flock()`
completion as success and `OSError` as failure. The pre-V1 implementation fails
`lock-success` and `unlock-success` because `None == 0` is `False`.
