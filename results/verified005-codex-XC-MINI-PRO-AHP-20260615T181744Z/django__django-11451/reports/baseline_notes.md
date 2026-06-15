# Baseline Notes

## Root cause

`ModelBackend.authenticate()` filled `username` from `kwargs` when the explicit
argument was `None`, but it did not stop when either `username` or `password`
was still missing. That allowed calls intended for another authentication
backend to continue into `get_by_natural_key(None)`, producing a useless
database lookup for a null username, and then to run password hashing work in
the nonexistent-user path.

## Changed files

`repo/django/contrib/auth/backends.py`

- Added an early return in `ModelBackend.authenticate()` after username
  normalization when `username` or `password` is `None`.
- This keeps the existing natural-key lookup and timing-mitigation password
  hashing behavior for complete username/password attempts, while skipping all
  database and hasher work for incomplete credentials.

## Assumptions and alternatives considered

- I assumed incomplete username/password credentials should be treated as "this
  backend cannot authenticate" rather than as a failed password attempt. This
  matches the issue description and Django's existing convention of returning
  `None` from authentication backends that do not handle supplied credentials.
- I considered guarding only `username is None`, since the reported query used a
  null username. I rejected that because the issue explicitly proposed skipping
  when `password is None` too, and password checking or dummy hashing with a
  missing password is also unnecessary for a backend that requires passwords.
- I left the timing-mitigation call unchanged for the normal case where both
  credentials are present but the user does not exist, preserving the behavior
  documented by the existing comment.
