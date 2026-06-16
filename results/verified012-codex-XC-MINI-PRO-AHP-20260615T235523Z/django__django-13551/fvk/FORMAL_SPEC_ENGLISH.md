# Formal Spec English

Status: paraphrase of the K claims in
`fvk/password-reset-token-spec.k`.

K1. `HASH-USES-CONFIGURED-EMAIL`

When the configured email field exists and contains a concrete email string,
`makeHashValue(user, timestamp)` reduces to a hash input whose final component
is that concrete configured email string.

K2. `MISSING-EMAIL-DEFINED`

When the configured email field is absent, `makeHashValue(user, timestamp)`
reduces to a hash input with an empty email component rather than becoming
undefined.

K3. `NULL-EMAIL-DEFINED`

When the configured email field exists but is null-like, `makeHashValue(user,
timestamp)` reduces to a hash input with an empty email component rather than
becoming undefined.

K4. `SAME-STATE-VALIDATES`

For an unexpired token whose digest was generated from the same modeled user
state and timestamp, `checkToken(user, token, now, timeout)` reduces to `true`.

K5. `EMAIL-CHANGE-REJECTED`

For an unexpired token generated from an old user state, checking against a new
user state with the same primary key, password, login timestamp, configured
field name, and timestamp but a different concrete configured email string
reduces to `false`.

K6. `PASSWORD-CHANGE-REJECTED`

For an unexpired token generated from an old user state, checking against a new
user state with a different password hash reduces to `false`.

K7. `EXPIRED-TOKEN-REJECTED`

For a token whose timestamp is older than the timeout window,
`checkToken(user, token, now, timeout)` reduces to `false`.
