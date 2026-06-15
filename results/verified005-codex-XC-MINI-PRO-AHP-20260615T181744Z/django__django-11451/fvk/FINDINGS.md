# FINDINGS

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the branch proof obligations; no tests or code
were run.

## F-001: Pre-fix null-username lookup is the reported bug

- Classification: code bug, resolved by V1.
- Evidence: `IE-001`, `IE-002`, `PO-001`, `PO-002`.
- Input class: `username is None`, `kwargs.get(UserModel.USERNAME_FIELD) is
  None`, any `password`.
- Observed before V1: `get_by_natural_key(None)` was reachable, producing the
  reported `WHERE username IS NULL` query. If no user was found, the dummy
  password hasher also ran.
- Expected: return `None` without lookup, dummy hash, password check, or
  `user_can_authenticate()`.
- V1 status: satisfied by the guard at
  `repo/django/contrib/auth/backends.py:42`.

## F-002: Missing password is also an incomplete credential set

- Classification: code bug, resolved by V1.
- Evidence: `IE-002`, `IE-003`, `IE-005`, `PO-002`.
- Input class: normalized username is present, `password is None`.
- Observed before V1: the method could still query the database and either run
  dummy hashing or password checking with a missing password.
- Expected: return `None` without lookup or password work, because
  `ModelBackend` authenticates an identifier plus password and the prompt
  explicitly requires the same shortcut when `password is None`.
- V1 status: satisfied by the same guard at
  `repo/django/contrib/auth/backends.py:42`.

## F-003: Complete credential timing mitigation remains in scope

- Classification: compatibility preservation, no code issue found.
- Evidence: `IE-004`, `PO-003`.
- Input class: normalized username and password are both present, lookup misses.
- Expected: perform lookup, then run `UserModel().set_password(password)`, then
  return `None`.
- V1 status: unchanged. The new guard does not fire for complete credentials.

## F-004: Complete credential authentication behavior remains in scope

- Classification: compatibility preservation, no code issue found.
- Evidence: `IE-005`, `IE-007`, `PO-004`, `PO-005`, `PO-006`, `PO-007`.
- Input class: normalized username and password are both present, lookup finds a
  user.
- Expected: return the user exactly when `check_password(password)` and
  `user_can_authenticate(user)` both hold; otherwise return `None`.
- V1 status: unchanged. The guard does not fire for complete credentials.

## F-005: Formal model is event-abstract, not full Django

- Classification: proof capability gap, not a code bug.
- Evidence: `PO-008`.
- Scope: the constructed K model abstracts the database, password hasher, and
  user object into branch parameters and events.
- Impact: the proof is adequate for the reported no-query/no-hash property, but
  it is not a full proof of Django ORM semantics, password hasher correctness,
  or database behavior.
- Required honesty label: constructed, not machine-checked.

## F-006: Tests are recommended but were not edited or run

- Classification: test gap.
- Evidence: `PO-001`, `PO-002`, `PO-003`.
- Recommended tests: public tests should assert zero queries and no dummy hash
  when credentials lack a normalized username or lack a password, and should
  keep existing complete-credential authentication and nonexistent-user timing
  tests.
- V1 status: no test files were modified, per task constraints.

## Summary Verdict

No FVK finding requires a production-code change beyond V1. The V1 guard
discharges the intent-derived obligations for incomplete credentials while
preserving the complete-credential paths.

