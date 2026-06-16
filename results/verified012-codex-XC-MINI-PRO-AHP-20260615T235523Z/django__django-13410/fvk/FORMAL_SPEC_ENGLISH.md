# Formal Spec English

Status: paraphrase of `locks-spec.k`; constructed, not machine-checked.

## Claims

`lock-success`: For every non-negative file descriptor, if the POSIX flock call
inside `lock()` completes normally, `lock()` returns `True`.

`lock-oserror`: For every non-negative file descriptor, if the POSIX flock call
inside `lock()` raises `OSError`, `lock()` returns `False`.

`unlock-success`: For every non-negative file descriptor, if the POSIX flock call
inside `unlock()` completes normally with `LOCK_UN`, `unlock()` returns `True`.

`unlock-oserror`: For every non-negative file descriptor, if the POSIX flock call
inside `unlock()` raises `OSError`, `unlock()` returns `False`.

## Frame conditions

The formal claims do not change the public function signatures, exported lock
constants, Windows locking branch, unsupported-locking branch, or `_fd()`
descriptor-extraction rule.

## Proof scope

The model abstracts `fcntl.flock()` to the two outcomes identified by the public
issue: normal completion and `OSError`. It does not prove properties of the
operating system lock table or file descriptor lifetime.
