# Public Compatibility Audit

Status: source-inspection audit only; no tests or code were run.

## Changed public symbols

`django.core.files.locks.lock(f, flags)` and
`django.core.files.locks.unlock(f)` keep the same names, arity, import location,
and exported status. `LOCK_EX`, `LOCK_SH`, and `LOCK_NB` are unchanged.

## Public call sites inspected

`repo/django/core/files/storage.py` calls `locks.lock(fd, locks.LOCK_EX)` and
`locks.unlock(fd)` while saving files. It ignores return values. V1 preserves
call shape and only corrects the returned boolean.

`repo/django/core/files/move.py` calls `locks.lock(fd, locks.LOCK_EX)` and
`locks.unlock(fd)` while copying across filesystems. It ignores return values.
V1 preserves call shape.

`repo/django/core/cache/backends/filebased.py` calls `locks.lock(f,
locks.LOCK_EX)` and `locks.unlock(f)`. It ignores return values. V1 preserves
call shape.

`repo/django/test/testcases.py` calls `locks.lock(cls._lockfile,
locks.LOCK_EX)` in `SerializeMixin`. It ignores the return value. V1 preserves
call shape.

## Compatibility result

No public callsite or override requires a source edit beyond V1. External callers
that do inspect `LOCK_NB` return values now receive the boolean result required by
the issue.
