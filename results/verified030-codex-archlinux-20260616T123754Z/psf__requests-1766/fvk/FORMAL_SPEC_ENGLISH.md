# Formal Spec English

Status: constructed from the `.k` claims; not machine-checked.

## Claim QOP-AUTH-LIST

For every normalized qop-options list `QOPS`, if `QOPS` contains the token `"auth"`, then the qop slice of `build_digest_header` reaches a result with header fragment `qop="auth"` and response-digest qop token `"auth"`.

## Claim QOP-NO-QOP

If the challenge has no qop directive, the qop slice reaches a result with no qop header fragment and no qop token in the digest input.

## Claim QOP-UNSUPPORTED

If the challenge has a qop-options list that does not contain `"auth"`, the qop slice reaches the unsupported result. This formalizes the current branch that returns `None`; it is not a claim that `auth-int` is implemented.

## Frame Claim

The qop proof does not change the public method signature, callsites, nonce count update, cnonce generation, algorithm selection, URL path calculation, or unrelated header fields.

