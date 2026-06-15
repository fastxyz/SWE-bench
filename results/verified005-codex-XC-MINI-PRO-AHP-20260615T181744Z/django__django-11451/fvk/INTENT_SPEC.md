# INTENT_SPEC

Status: intent-only English specification from public evidence.

`ModelBackend.authenticate()` is intended to authenticate complete
username/password credentials. It may obtain the username from either the
explicit `username` argument or `kwargs[UserModel.USERNAME_FIELD]`.

If, after that fallback, either the username or password is `None`, the method
must return `None` immediately. That incomplete-credential path must not query
the user table, run dummy password hashing, check a password, or call
`user_can_authenticate()`.

For complete username/password credentials, existing behavior is preserved:
lookup by natural key, dummy hash for nonexistent users, password check for
found users, and return of the user only when the password is valid and the user
is allowed to authenticate.

