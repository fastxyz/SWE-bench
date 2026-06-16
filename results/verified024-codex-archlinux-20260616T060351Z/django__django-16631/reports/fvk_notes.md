# FVK Notes

## Decisions

V1 stands unchanged. The FVK audit did not identify a blocking source defect.

The decision to keep `AbstractBaseUser.get_session_auth_fallback_hash()` is
traced to Finding F1 and proof obligations O1-O2: the public issue requires
session auth hashes to be derivable with fallback secrets, while the existing
current-key behavior remains unchanged.

The decision to keep fallback validation in `get_user()` is traced to F1 and
O3-O5. The current-key branch still authenticates, a fallback-key hash now
authenticates during rotation, and missing, invalid, or password-stale hashes
still flush.

The decision to keep the fallback-match upgrade is traced to F2 and O4. The
upgrade is guarded by a successful fallback hash comparison, cycles the session
key, and rewrites `_auth_user_hash` to the current-key hash so active sessions
do not fail again when fallbacks are later removed.

The decision to keep the `login()` change is traced to F3 and O7-O8. `login()`
uses the same valid-hash definition for a same-user existing session, while
preserving the different-user and invalid-hash flush behavior.

The decision not to add further compatibility code in the FVK pass is traced to
F4 and O6. The V1 helper uses guarded lookup and returns no fallback hashes
when a user object lacks `get_session_auth_fallback_hash()`, preserving
behavior for custom users that only implement `get_session_auth_hash()`.

## Artifacts

The FVK pass produced the required markdown artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

It also produced the constructed formal core referenced by those artifacts:

- `fvk/mini-auth-session.k`
- `fvk/auth-session-spec.k`

No tests, Python, or K tooling were run, per the task instructions.
