# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 change to
`repo/django/contrib/auth/backends.py::ModelBackend.authenticate()`. The audited
observable is whether the method returns a user/`None` and whether it performs
the expensive side-effecting operations relevant to the issue:

- `lookup(username)`: `UserModel._default_manager.get_by_natural_key(username)`
- `dummyHash(password)`: `UserModel().set_password(password)`
- `checkPassword(user, password)`: `user.check_password(password)`
- `canAuth(user)`: `self.user_can_authenticate(user)`

The method has no loop. The proof is a branch-by-branch partial-correctness
argument over an event abstraction of those calls.

## Intent Specification

`ModelBackend.authenticate(request, username=None, password=None, **kwargs)`
normalizes the user identifier as:

- if the explicit `username` argument is not `None`, use it;
- otherwise use `kwargs.get(UserModel.USERNAME_FIELD)`.

Let the normalized identifier be `U` and the password argument be `P`.

Required behavior:

- If `U is None` or `P is None`, return `None` and perform no lookup, dummy hash,
  password check, or user-can-authenticate call.
- If both `U` and `P` are present and no user exists for `U`, perform exactly the
  natural-key lookup and then the existing dummy password hash, returning `None`.
- If both `U` and `P` are present and a user exists for `U`, perform the
  natural-key lookup and the password check. Return the user only when
  `check_password(P)` is true and `user_can_authenticate(user)` is true.
- Preserve the public method signature and the behavior of complete
  username/password authentication attempts except for avoiding work on
  incomplete credentials.

## Public Evidence Ledger

### IE-001: No query for missing username

- Source: prompt.
- Evidence: "ModelBackend.authenticate() shouldn't make a database query when
  username is None".
- Semantic obligation: after username normalization, a `None` user identifier is
  outside this backend's actionable credentials; the method must return `None`
  without `lookup`.
- Status: encoded by `PO-001` and `PO-002`; V1 satisfies it.

### IE-002: Missing credentials for other backends

- Source: prompt.
- Evidence: "At this point, username and password can be None, typically if
  credentials are provided for another backend."
- Semantic obligation: `ModelBackend` must decline incomplete
  username/password credentials rather than treating them as failed
  ModelBackend credentials.
- Status: encoded by `PO-002`; V1 satisfies it.

### IE-003: Exact proposed guard

- Source: prompt.
- Evidence: "My suggestion is to shortcut with: if username is None or password
  is None: return".
- Semantic obligation: the guard belongs after the `kwargs` username fallback
  and before lookup/hash/check operations.
- Status: encoded by `PO-001` and `PO-002`; V1 implements that placement.

### IE-004: Timing mitigation is retained for complete credentials

- Source: prompt and code comment.
- Evidence: the prompt acknowledges timing mitigation for existing vs.
  nonexistent users; the code comment says the dummy hash reduces timing
  differences for nonexistent users.
- Semantic obligation: do not remove dummy hashing for complete
  username/password attempts where the user does not exist.
- Status: encoded by `PO-003`; V1 preserves it.

### IE-005: ModelBackend authenticates identifier plus password

- Source: docs.
- Evidence: `ModelBackend` "authenticates using credentials consisting of a
  user identifier and password" and `authenticate()` "tries to authenticate
  username with password".
- Semantic obligation: a missing identifier or missing password is not a
  complete credential set for this backend.
- Status: supports `PO-002`.

### IE-006: Backend dispatcher continues after `None`

- Source: docs and implementation.
- Evidence: custom backends return `None` for invalid credentials; the
  dispatcher continues to later backends when a backend returns `None`.
- Semantic obligation: returning `None` for credentials meant for another
  backend is compatible with multi-backend authentication.
- Status: supports `PO-007`.

### IE-007: Public signature compatibility

- Source: docs and source search.
- Evidence: the documented signature is
  `authenticate(request, username=None, password=None, **kwargs)`;
  `AllowAllUsersModelBackend` inherits this method and overrides only
  `user_can_authenticate()`.
- Semantic obligation: do not change the public signature or virtual dispatch
  shape.
- Status: encoded by `PO-007`; V1 does not change the signature.

## Formal Model

The K files are:

- `fvk/mini-auth.k`: a minimal event semantics for this method.
- `fvk/modelbackend-authenticate-spec.k`: reachability claims for the branch
  classes named in `PROOF_OBLIGATIONS.md`.

The model represents:

- explicit username as `noneCred` or `cred(U)`;
- `kwargs[USERNAME_FIELD]` as `noneCred` or `cred(U)`;
- password as `nonePass` or `pass(P)`;
- database lookup result as `missing` or `found(User, PasswordOk, CanAuth)`;
- the side-effect trace as a list of events.

This is intentionally not a full Python or Django semantics. It is
property-complete for the audited issue because the defect and the fix are
distinguished by the presence or absence of `lookup` and `dummyHash` events.

## Frame Conditions

- No permission methods, `get_user()`, remote-user backends, or backend-loading
  behavior are changed.
- Complete username/password attempts retain the existing lookup, dummy-hash,
  password-check, and `user_can_authenticate()` paths.
- `AllowAllUsersModelBackend` continues to inherit the method and only changes
  the `user_can_authenticate()` predicate result.

