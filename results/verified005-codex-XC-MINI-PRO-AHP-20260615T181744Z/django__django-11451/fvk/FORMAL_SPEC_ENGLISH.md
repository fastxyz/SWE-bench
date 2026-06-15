# FORMAL_SPEC_ENGLISH

Status: English paraphrase of the formal claims.

## C-001: Normalized username missing

If the explicit username is absent and the username-field keyword is absent,
`authenticate()` returns `None` and the event list remains empty.

## C-002: Password missing

If the normalized username is present but password is absent, `authenticate()`
returns `None` and the event list remains empty.

## C-003: Complete credentials, no matching user

If the normalized username and password are present and lookup misses,
`authenticate()` records a lookup event, records a dummy-hash event, and returns
`None`.

## C-004: Complete credentials, found user, bad password

If lookup finds a user but the password check fails, `authenticate()` records
lookup and password-check events, then returns `None`.

## C-005: Complete credentials, found user, valid password, disallowed user

If lookup finds a user and the password check passes but
`user_can_authenticate()` is false, `authenticate()` records lookup,
password-check, and can-auth events, then returns `None`.

## C-006: Complete credentials, found user, valid password, allowed user

If lookup finds a user, the password check passes, and
`user_can_authenticate()` is true, `authenticate()` records lookup,
password-check, and can-auth events, then returns that user.

