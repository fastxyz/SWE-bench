# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the source edit already satisfies
the public intent captured in `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`.

## Trace to findings and obligations

`F-001` maps to `PO-LOCK-SUCCESS` and `PO-UNLOCK-SUCCESS`: CPython
`fcntl.flock()` returns `None` on success, so pre-V1 returned `False`. V1 fixes
that by returning `True` after the call completes normally.

`F-002` maps to `PO-LOCK-OSERROR`: non-blocking callers need `False` when
`fcntl.flock()` raises `OSError`. V1 fixes that with `except OSError:
return False`.

`F-003` maps to `PO-UNLOCK-SUCCESS` and `PO-UNLOCK-OSERROR`: the issue's
proposed POSIX fix applies the same boolean convention to `unlock()`. V1 already
does this.

`F-004` maps to `PO-COMPAT`: V1 does not change exported names, constants,
function arity, or in-repo call shapes. No compatibility edit is needed.

`F-005` maps to `PO-ADEQUACY` and `PO-COMMANDS`: the proof abstracts
`fcntl.flock()` to the two public outcomes named by the issue and records K
commands without running them. This is a process limitation, not a source-code
problem.

## Alternatives considered

I rechecked whether V1 should catch only narrower non-blocking errno values, but
the public issue describes `OSError` as the failure signal and provides the same
`except OSError` shape for both helpers. Narrowing the catch would not better
satisfy any public obligation in the ledger.

I also considered broadening V1 to catch non-`OSError` failures from descriptor
extraction. The FVK spec rejects that as unsupported by the issue: `_fd()` is a
domain/frame condition here, and changing its error policy would be a separate
API decision.

No tests, Python, or K tooling were run, per the task instructions.
