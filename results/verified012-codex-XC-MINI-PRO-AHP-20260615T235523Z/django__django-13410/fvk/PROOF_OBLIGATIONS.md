# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-FD-DOMAIN

Statement: For the formal claims, `_fd(f)` has already produced a non-negative
file descriptor modeled as `fd(FD)` with `FD >=Int 0`.

Evidence: public ledger E5.

Status: accepted domain assumption. This issue does not alter `_fd()`.

## PO-LOCK-SUCCESS

Statement: For every `FD >= 0`, `lock(fd(FD), ok)` reaches `return(true)`.

Intent trace: E1 and E2.

K claim: `lock-success` in `fvk/locks-spec.k`.

Status: satisfied by V1. Pre-V1 fails because success produced `None`, and
`None == 0` is false.

## PO-LOCK-OSERROR

Statement: For every `FD >= 0`, `lock(fd(FD), osError)` reaches
`return(false)`.

Intent trace: E1 and E2.

K claim: `lock-oserror` in `fvk/locks-spec.k`.

Status: satisfied by V1.

## PO-UNLOCK-SUCCESS

Statement: For every `FD >= 0`, `unlock(fd(FD), ok)` reaches `return(true)`.

Intent trace: E1 and E3.

K claim: `unlock-success` in `fvk/locks-spec.k`.

Status: satisfied by V1. Pre-V1 fails because success produced `None`, and
`None == 0` is false.

## PO-UNLOCK-OSERROR

Statement: For every `FD >= 0`, `unlock(fd(FD), osError)` reaches
`return(false)`.

Intent trace: E1 and E3.

K claim: `unlock-oserror` in `fvk/locks-spec.k`.

Status: satisfied by V1.

## PO-COMPAT

Statement: V1 must preserve exported names, function arity, constants, and
existing in-repo call shapes.

Intent trace: E4-E6.

Status: satisfied by source inspection. No public callsite requires a code edit.

## PO-ADEQUACY

Statement: The formal outcomes `ok` and `osError` must be adequate for the
public issue's POSIX `fcntl.flock()` behavior.

Intent trace: E1.

Status: satisfied for the reported bug. Operating-system lock-table behavior is
intentionally abstracted away.

## PO-COMMANDS

Statement: The proof must remain labeled "constructed, not machine-checked" and
must record commands instead of running K tooling.

Intent trace: task instructions and FVK honesty gate.

Status: satisfied in `fvk/PROOF.md`.
