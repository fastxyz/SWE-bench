# Baseline Notes

## Root cause

The POSIX implementation in `django/core/files/locks.py` treated the return value
from `fcntl.flock()` as a C-style status code and returned `ret == 0`. In CPython,
`fcntl.flock()` returns `None` on success and raises `OSError` on failure. As a
result, successful POSIX lock and unlock calls returned `False`, and non-blocking
lock failures raised instead of producing the boolean failure result expected by
callers.

## Files changed

`repo/django/core/files/locks.py`

Changed the POSIX `lock()` and `unlock()` helpers to return `True` when
`fcntl.flock()` completes without raising and `False` when it raises `OSError`.
This keeps the public boolean contract consistent with the Windows and unsupported
locking branches while matching CPython's `fcntl.flock()` behavior.

## Assumptions and alternatives considered

I assumed the intended contract for these helpers is boolean success or failure,
because every branch already returns booleans and the issue specifically calls out
non-blocking lock callers needing a valid return value.

I considered catching only specific non-blocking lock error cases such as
`EACCES` or `EAGAIN`, but rejected that narrower change because the existing helper
API does not expose exception details and the reported issue frames `OSError` as
the failure signal to convert into `False`.

No tests or project code were run, in keeping with the benchmark instructions.
