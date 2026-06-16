# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "fcntl module returns None if successful, and raises an OSError to indicate failure" | Model POSIX `fcntl.flock()` success as normal completion, not integer `0`; model failure as `OSError`. | Encoded in `locks-spec.k` claims `lock-success`, `lock-oserror`, `unlock-success`, and `unlock-oserror`. |
| E2 | `benchmark/PROBLEM.md` | "return True to indicate success or failure acquiring a lock" and "requires a valid return value to know if they have successfully acquired the lock" | `lock()` must return a boolean where success is `True` and failure is `False`. | Encoded in `PO-LOCK-SUCCESS` and `PO-LOCK-OSERROR`. |
| E3 | `benchmark/PROBLEM.md` | The proposed fix catches `OSError` and returns `False` in both `lock()` and `unlock()`. | The same boolean convention applies to POSIX `unlock()`. | Encoded in `PO-UNLOCK-SUCCESS` and `PO-UNLOCK-OSERROR`. |
| E4 | `repo/django/core/files/locks.py` | `__all__ = ('LOCK_EX', 'LOCK_SH', 'LOCK_NB', 'lock', 'unlock')` | The public names and function arities must remain stable. | Confirmed by compatibility audit; V1 changes only function bodies. |
| E5 | `repo/django/core/files/locks.py` | `_fd(f)` returns `f.fileno()` when available, otherwise `f`. | The formal model reasons after descriptor extraction; descriptor extraction itself is a frame condition for this issue. | Domain assumption in `INTENT_SPEC.md`. |
| E6 | Source callsite search | In-repo call sites ignore the return value and use `LOCK_EX`, not `LOCK_NB`. | V1 must not break public callers; the issue still requires return correctness for external non-blocking callers. | Confirmed by `PUBLIC_COMPATIBILITY_AUDIT.md`. |
