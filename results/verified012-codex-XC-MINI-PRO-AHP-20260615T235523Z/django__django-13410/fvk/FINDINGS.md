# FINDINGS

Status: constructed, not machine-checked. Findings are from public intent,
source inspection, and proof-obligation construction only.

## F-001: POSIX success was returned as failure before V1

Classification: code bug fixed by V1.

Input/class: POSIX `lock(f, flags)` where `fcntl.flock(_fd(f), flags)` completes
successfully.

Observed pre-V1: `fcntl.flock()` returns `None`; `ret == 0` evaluates to
`False`, so `lock()` reports failure.

Expected: `lock()` returns `True` when the lock is acquired.

Evidence: public ledger E1 and E2. Proof obligation: `PO-LOCK-SUCCESS`.

V1 result: satisfied. The V1 `try` body returns `True` after normal completion.

## F-002: POSIX non-blocking failure needed a boolean result

Classification: code bug fixed by V1.

Input/class: POSIX `lock(f, locks.LOCK_NB | ...)` where the lock cannot be
acquired and `fcntl.flock()` raises `OSError`.

Observed pre-V1: the exception escapes instead of producing the boolean failure
result needed by non-blocking callers.

Expected: `lock()` returns `False`.

Evidence: public ledger E1 and E2. Proof obligation: `PO-LOCK-OSERROR`.

V1 result: satisfied. The V1 `except OSError` branch returns `False`.

## F-003: POSIX unlock must follow the same fcntl result convention

Classification: code bug fixed by V1.

Input/class: POSIX `unlock(f)` where `fcntl.flock(_fd(f), fcntl.LOCK_UN)`
completes successfully or raises `OSError`.

Observed pre-V1: success returned `False` because `None == 0`; failure raised
instead of returning `False`.

Expected: success returns `True`; `OSError` returns `False`.

Evidence: public ledger E1 and E3. Proof obligations:
`PO-UNLOCK-SUCCESS` and `PO-UNLOCK-OSERROR`.

V1 result: satisfied.

## F-004: Public compatibility remains intact

Classification: compatibility check; no source defect.

Input/class: Existing imports and call sites for `lock()` and `unlock()`.

Observed V1: function names, arity, constants, and import paths are unchanged.
In-repo call sites ignore return values, so correcting the boolean result is
compatible.

Expected: no public call shape breaks while external `LOCK_NB` users can rely on
the return value.

Evidence: public ledger E4-E6. Proof obligation: `PO-COMPAT`.

V1 result: satisfied.

## F-005: Proof is constructed, not machine-checked

Classification: proof capability and process limitation; not a code bug.

The FVK proof abstracts `fcntl.flock()` into the two public outcomes named by
the issue and records `kompile`/`kprove` commands without running them. This is
required by the task and by the FVK honesty gate.

Expected next step outside this environment: run the commands in `fvk/PROOF.md`
and keep any tests until `kprove` reports `#Top`.

Evidence: proof obligations `PO-ADEQUACY` and `PO-COMMANDS`.

V1 result: code stands unchanged; proof confidence remains "constructed, not
machine-checked."

## Open ambiguity

The issue does not specify whether non-`OSError` failures during descriptor
extraction should be converted to `False`. V1 does not change that behavior, and
the FVK spec does not use it to justify correctness. If maintainers want all
descriptor errors converted to booleans, that is a separate public contract
change.
