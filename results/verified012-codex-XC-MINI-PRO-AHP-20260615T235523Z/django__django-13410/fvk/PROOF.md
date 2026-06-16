# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved Constructively

The formal claims are in `fvk/locks-spec.k`:

- `lock-success`: `lock(fd(FD), ok) => return(true)` for `FD >=Int 0`.
- `lock-oserror`: `lock(fd(FD), osError) => return(false)` for `FD >=Int 0`.
- `unlock-success`: `unlock(fd(FD), ok) => return(true)` for `FD >=Int 0`.
- `unlock-oserror`: `unlock(fd(FD), osError) => return(false)` for
  `FD >=Int 0`.

There are no loops or recursive calls in the audited functions, so there are no
loop circularities or termination measures to prove.

## Symbolic Proof Sketch

### `lock-success`

Start in `<k> lock(fd(FD), ok) </k>` with `FD >=Int 0`. By the
`MINI-PYTHON-LOCKS` rule for a normal POSIX flock outcome, the state rewrites in
one step to `<k> return(true) </k>`. This is the desired postcondition.

This corresponds to the V1 Python path:

```python
try:
    fcntl.flock(_fd(f), flags)
    return True
except OSError:
    return False
```

If `fcntl.flock()` completes normally, Python enters the next statement in the
`try` body and returns `True`.

### `lock-oserror`

Start in `<k> lock(fd(FD), osError) </k>` with `FD >=Int 0`. By the
`MINI-PYTHON-LOCKS` rule for an `OSError` POSIX flock outcome, the state rewrites
in one step to `<k> return(false) </k>`. This is the desired postcondition.

This corresponds to Python jumping to `except OSError` and returning `False`.

### `unlock-success`

Start in `<k> unlock(fd(FD), ok) </k>` with `FD >=Int 0`. The normal unlock
outcome rewrites to `<k> return(true) </k>`. This matches the V1 `return True`
after `fcntl.flock(_fd(f), fcntl.LOCK_UN)` completes normally.

### `unlock-oserror`

Start in `<k> unlock(fd(FD), osError) </k>` with `FD >=Int 0`. The `OSError`
unlock outcome rewrites to `<k> return(false) </k>`. This matches the V1
`except OSError: return False` branch.

## Why Pre-V1 Fails the Spec

On the success paths, CPython `fcntl.flock()` returns `None`. The pre-V1 code
compared the return value with `0`, so the post-state was `return(false)` for
successful `lock()` and `unlock()` calls. That violates `PO-LOCK-SUCCESS` and
`PO-UNLOCK-SUCCESS`.

On the `OSError` path, pre-V1 had no handler, so a non-blocking acquisition
failure did not produce the boolean `False` required by `PO-LOCK-OSERROR`.

## Adequacy and Compatibility

The adequacy gate passes in `fvk/SPEC_AUDIT.md`: every formal claim maps to
public evidence from the problem statement and none preserves the legacy
`ret == 0` behavior. Public compatibility passes in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: signatures and exports remain unchanged,
and inspected in-repo call sites do not rely on exception propagation from
`fcntl.flock()`.

## Commands To Machine-Check Later

These commands are recorded only. They were not executed.

```sh
cd /home/xc/.swe-fvk-runs/verified012-codex-XC-MINI-PRO-AHP-20260615T235523Z/django__django-13410
kompile fvk/mini-python-locks.k --backend haskell
kast --backend haskell fvk/locks-spec.k
kprove fvk/locks-spec.k
```

Expected result after a successful machine check: `#Top` for all four claims.

## Test Guidance

No lock-specific public tests were found by source inspection. Existing
integration-style call sites should be kept. Future unit tests for POSIX
`fcntl.flock()` success, `OSError`, and `LOCK_NB` unavailable-lock behavior
would be subsumed by this proof only after the K commands above are actually
machine-checked.

No tests were edited.

## Residual Risk

The proof is partial correctness over the mini semantics, not a proof of OS lock
table behavior, descriptor lifetime, or all Python exception mechanics. It is
constructed, not machine-checked, because the task forbids running K tooling.
