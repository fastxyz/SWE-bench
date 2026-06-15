# PUBLIC_EVIDENCE_LEDGER

This file mirrors the public evidence ledger in `SPEC.md`.

- `IE-001`: Prompt says `ModelBackend.authenticate()` should not make a
  database query when `username is None`; obligation is no lookup for normalized
  username `None`.
- `IE-002`: Prompt says username and password can both be `None` when
  credentials are for another backend; obligation is to decline incomplete
  username/password credentials.
- `IE-003`: Prompt proposes `if username is None or password is None: return`;
  obligation is that this check runs after username fallback and before lookup.
- `IE-004`: Prompt and code comment preserve dummy hashing for nonexistent users
  in complete credential attempts; obligation is not to remove that path.
- `IE-005`: Public docs describe `ModelBackend` as using a user identifier and
  password; obligation is that both are required for this backend to act.
- `IE-006`: Public docs and source show `None` lets auth dispatch continue to
  other backends; obligation is compatibility with multi-backend auth.
- `IE-007`: Public docs/source show the method signature and subclass pattern;
  obligation is no signature or dispatch-shape change.

