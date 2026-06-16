# FVK Iteration Guidance

Status: V1 stands. No source edits were made in the FVK pass.

## Decision

Keep the V1 code unchanged.

The FVK audit found that the V1 patch satisfies the intent ledger and proof
obligations:

- fallback-key session hashes validate in `get_user()` (F1, O4);
- fallback-valid sessions are upgraded to current-key hashes after validation
  (F2, O4, VC4);
- password changes and invalid hashes still flush (O5);
- custom user objects without a fallback method remain compatible (F4, O6);
- `login()` uses the same fallback-validity definition for same-user session
  reuse (F3, O7-O8).

## Next Code Pass Guidance

If another code pass is needed, do not remove the fallback upgrade unless the
public contract is deliberately narrowed. It is the only mechanism in the
current patch that prevents active fallback-valid sessions from being
invalidated again after fallback removal.

Do not broaden fallback validation to users whose password field has changed.
Fallback hashes must be generated from the current password field value.

Keep fallback support optional for custom user implementations. Public code can
implement `get_session_auth_hash()` without inheriting from `AbstractBaseUser`.

## Tests to Add in a Normal Development Environment

These are recommendations only; this benchmark forbids test edits and test
execution.

- Auth middleware accepts a session whose `_auth_user_hash` was generated with
  an old key in `SECRET_KEY_FALLBACKS`.
- The accepted fallback session gets a new session key and stores the current
  hash.
- Removing `SECRET_KEY_FALLBACKS` after upgrade leaves the upgraded active
  session valid.
- A password change invalidates a session even if the old secret key remains in
  fallbacks.
- `login()` does not flush same-user session data for a fallback-valid auth
  hash, but still flushes a different user's session.

## Open Items

No blocking source issues remain from the FVK pass. The proof remains
constructed, not machine-checked, until the commands in `fvk/PROOF.md` are run
in an environment with K installed.
