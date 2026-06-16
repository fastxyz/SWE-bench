# Spec Audit

Status: adequacy gate for `locks-spec.k`; constructed, not machine-checked.

| Formal claim or condition | Intent source | Adequacy result | Notes |
| --- | --- | --- | --- |
| `lock-success` returns `True` on normal `fcntl.flock()` completion. | E1, E2 | Pass | This is the central reported bug: CPython returns `None` on success, so return must not be derived from `ret == 0`. |
| `lock-oserror` returns `False` on `OSError`. | E1, E2 | Pass | Covers the non-blocking unavailable-lock case described in the issue. |
| `unlock-success` returns `True` on normal `LOCK_UN` completion. | E1, E3 | Pass | Mirrors the provided public fix for the POSIX unlock helper. |
| `unlock-oserror` returns `False` on `OSError`. | E1, E3 | Pass | Mirrors the provided public fix for unlock failure. |
| Domain is after `_fd(f)` produces a non-negative descriptor. | E5 | Pass | The issue is about `fcntl.flock()` return/exception behavior, not changing descriptor extraction. |
| Signatures and exported names are unchanged. | E4, E6 | Pass | V1 changes only function bodies, so public call shape is preserved. |

No formal-English claim is candidate-only, legacy-only, or contradicted by the
public problem statement.
