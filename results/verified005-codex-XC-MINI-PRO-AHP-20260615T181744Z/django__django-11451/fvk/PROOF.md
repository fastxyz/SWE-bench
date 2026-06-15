# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Formal Claims

The formal core is recorded in:

- `fvk/mini-auth.k`
- `fvk/modelbackend-authenticate-spec.k`

The claims model `ModelBackend.authenticate()` as a deterministic branch program
over normalized credentials and an abstract database result. The observable
state is the return value plus an event list containing `lookup`, `dummyHash`,
`checkPassword`, and `canAuth`.

## Branch Proof

### Username normalization (`PO-001`)

Source line 40 checks `if username is None`, and source line 41 substitutes
`kwargs.get(UserModel.USERNAME_FIELD)` only on that branch. Therefore all later
branches operate on the normalized username required by `IE-003` and `IE-005`.

### Incomplete credentials (`PO-002`)

After normalization, source lines 42-43 perform:

```python
if username is None or password is None:
    return
```

This return precedes the `try` block at source line 44. The lookup call, dummy
hash, password check, and `user_can_authenticate()` call are all syntactically
inside later branches. By symbolic execution of the event model, every state
with normalized username `None` or password `None` reaches `retNone` with the
event list unchanged. This discharges `F-001` and `F-002`.

### Complete credentials, missing user (`PO-003`)

When normalized username and password are both present, the guard at line 42 is
false. Execution reaches the lookup at line 45. On the `DoesNotExist` branch,
line 49 runs `UserModel().set_password(password)` and there is no return value,
so Python returns `None`. The event model records `lookup(username)` followed by
`dummyHash(password)`. This preserves the timing-mitigation behavior named by
`IE-004`.

### Complete credentials, found user (`PO-004` through `PO-006`)

When lookup succeeds, line 51 evaluates:

```python
user.check_password(password) and self.user_can_authenticate(user)
```

If `check_password()` is false, Python short-circuits the `and`, the `if` body
does not execute, and the method returns `None`. If `check_password()` is true
but `user_can_authenticate()` is false, the `if` body still does not execute and
the method returns `None`. If both are true, line 52 returns the user. These
paths are unchanged from V1's base code for complete credentials.

## Adequacy Check

The formal claims match the intent specification:

- `IE-001` and `IE-002` require no lookup/hash work for incomplete credentials;
  the incomplete-credential claims state an unchanged event list.
- `IE-003` requires the shortcut after username fallback; the proof models
  normalization before the incomplete-credential guard.
- `IE-004` requires the complete-credential nonexistent-user dummy hash to
  remain; the missing-user claims retain it.
- `IE-005` and `IE-007` require complete identifier/password authentication and
  public compatibility; the found-user claims preserve the prior return
  behavior and signature.

No formal claim depends solely on the candidate implementation for its expected
observable. The no-event obligations come from the public issue text; the
complete-credential preservation obligations come from public docs and the
issue's timing discussion.

## Commands Not Run

The following commands are the machine-checking commands to run later in an
environment with K installed:

```sh
kompile fvk/mini-auth.k --backend haskell
kast --backend haskell fvk/modelbackend-authenticate-spec.k
kprove fvk/modelbackend-authenticate-spec.k
```

Expected machine-check result in an environment with compatible K tooling:
`#Top` for the listed claims. Until then, this proof remains constructed, not
machine-checked.

## Test Recommendation

No tests were run or modified. If this proof is machine-checked, unit tests that
only assert the no-query/no-hash behavior for incomplete credentials would be
subsumed by `PO-002`, but they should still be kept unless and until the K
claims discharge in the target environment. Integration tests for Django's auth
dispatcher, database behavior, password hashers, and backend ordering remain
outside this event proof and should be kept.
