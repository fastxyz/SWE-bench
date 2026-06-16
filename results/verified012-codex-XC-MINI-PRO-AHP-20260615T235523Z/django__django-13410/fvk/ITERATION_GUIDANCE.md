# ITERATION GUIDANCE

Status: V1 stands unchanged.

## Code decision

No additional production source edit is justified by the FVK audit. V1 satisfies
`PO-LOCK-SUCCESS`, `PO-LOCK-OSERROR`, `PO-UNLOCK-SUCCESS`, and
`PO-UNLOCK-OSERROR`, and `PO-COMPAT` shows no public callsite break.

## Follow-up tests to add in a normal development environment

Do not edit tests in this benchmark. In a normal Django change, add focused tests
that mock or otherwise control the POSIX `fcntl.flock()` outcomes:

- `lock()` returns `True` when `fcntl.flock()` completes normally.
- `lock()` returns `False` when `fcntl.flock()` raises `OSError`, including a
  representative `LOCK_NB` unavailable-lock case.
- `unlock()` returns `True` on normal `LOCK_UN` completion.
- `unlock()` returns `False` on `OSError`.

## Machine-checking

Run the commands in `fvk/PROOF.md` before using the proof to remove or classify
tests as redundant. Until then, keep the result labeled "constructed, not
machine-checked."

## Clarification if the API is expanded later

The current public evidence does not require converting non-`OSError` descriptor
extraction failures to `False`. If maintainers want that broader behavior, make
it an explicit API decision and update the spec separately.
