# Intent Spec

Status: constructed from public evidence; not machine-checked.

## Scope

The audited unit is the POSIX `fcntl` branch of
`repo/django/core/files/locks.py`, specifically `lock()` and `unlock()` after
`import fcntl` succeeds. The Windows branch and unsupported-locking branch are
compatibility frame conditions: their behavior is not changed by V1.

## Required behavior

1. When POSIX `fcntl.flock(_fd(f), flags)` completes without raising `OSError`,
   `lock(f, flags)` returns `True`.
2. When POSIX `fcntl.flock(_fd(f), flags)` raises `OSError`, including the
   non-blocking unavailable-lock case, `lock(f, flags)` returns `False`.
3. When POSIX `fcntl.flock(_fd(f), fcntl.LOCK_UN)` completes without raising
   `OSError`, `unlock(f)` returns `True`.
4. When POSIX `fcntl.flock(_fd(f), fcntl.LOCK_UN)` raises `OSError`, `unlock(f)`
   returns `False`.
5. Public API compatibility is preserved: names, arity, and imports remain
   unchanged for `LOCK_EX`, `LOCK_SH`, `LOCK_NB`, `lock`, and `unlock`.

## Domain assumptions

The proof models the path after `_fd(f)` produces a non-negative file descriptor.
Exceptions unrelated to POSIX `fcntl.flock()` raising `OSError` are outside the
issue's public intent and are not used to justify V1.
