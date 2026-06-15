# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: Username normalization

- Claim: `ModelBackend.authenticate()` must use the explicit `username` when it
  is not `None`; otherwise it must use `kwargs.get(UserModel.USERNAME_FIELD)`.
- Proven path: source lines 39-41 implement exactly this ordering before the
  incomplete-credential guard.
- Evidence: `IE-003`, `IE-005`.
- Status: discharged by V1.

## PO-002: Incomplete credentials decline without side effects

- Claim: if the normalized username is `None` or `password is None`, the method
  returns `None` and emits no `lookup`, `dummyHash`, `checkPassword`, or
  `canAuth` event.
- Proven path: source lines 42-43 return before the `try` block containing
  lookup and all password work.
- Evidence: `IE-001`, `IE-002`, `IE-003`, `IE-005`.
- Status: discharged by V1.

## PO-003: Complete credentials with missing user preserve dummy hashing

- Claim: if normalized username and password are both present and lookup raises
  `UserModel.DoesNotExist`, the method emits `lookup(username)`,
  `dummyHash(password)`, and returns `None`.
- Proven path: source lines 44-49 are unchanged for complete credentials.
- Evidence: `IE-004`.
- Status: discharged by V1.

## PO-004: Complete credentials with found user and invalid password return None

- Claim: if lookup finds a user but `user.check_password(password)` is false,
  the method emits `lookup(username)` and `checkPassword(user, password)`, does
  not need to call `user_can_authenticate(user)` due Python `and`
  short-circuiting, and returns `None`.
- Proven path: source lines 50-52 are unchanged for complete credentials.
- Evidence: `IE-005`.
- Status: discharged by V1.

## PO-005: Complete credentials with valid password but disallowed user return None

- Claim: if lookup finds a user and `check_password(password)` is true but
  `user_can_authenticate(user)` is false, the method emits lookup,
  password-check, and can-auth events, then returns `None`.
- Proven path: source lines 50-52 are unchanged for complete credentials.
- Evidence: `IE-005`, `IE-007`.
- Status: discharged by V1.

## PO-006: Complete credentials with valid authenticatable user return user

- Claim: if lookup finds a user, `check_password(password)` is true, and
  `user_can_authenticate(user)` is true, the method returns that user.
- Proven path: source lines 50-52 are unchanged for complete credentials.
- Evidence: `IE-005`, existing public docs/tests read as supporting evidence.
- Status: discharged by V1.

## PO-007: Public compatibility and subclass dispatch

- Claim: the public method signature and dispatch shape remain
  `authenticate(request, username=None, password=None, **kwargs)`, and subclasses
  that override only `user_can_authenticate()` continue to participate on the
  same complete-credential path.
- Proven path: V1 changes only the method body by adding an early return; it
  does not alter arguments, return type, or virtual method calls.
- Evidence: `IE-006`, `IE-007`.
- Status: discharged by V1.

## PO-008: Termination and proof boundary

- Claim: the method has no loop; under the partial-correctness assumption that
  called operations return or raise as modeled, each branch reaches a return.
- Proven path: branch inspection of source lines 39-52.
- Evidence: implementation control flow.
- Status: partial correctness only; full Django call termination is outside the
  event model.

