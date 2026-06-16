# FVK Spec

Status: constructed, not machine-checked.

## Scope

The verified unit is the qop-producing slice of `HTTPDigestAuth.build_digest_header` in `repo/requests/auth.py`. The model abstracts away MD5/SHA internals, nonce randomness, URL parsing, and unrelated header fields because the issue and proof obligations are about the qop contributor to the Authorization header. Those other fields are frame conditions: the V2 edit does not change their formatting or control flow.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries mirrored into the K claims:

- E-1/E-3/E-4 require the outgoing qop directive to be serialized as `qop="auth"`, not `qop=auth`.
- E-2 requires treating qop as an options list. A compliant challenge can contain more than one token, so the selected token must be separated from the raw options string.
- E-6 records that `auth-int` is not implemented; the proof does not certify auth-int-only challenges.
- E-7 requires public API compatibility for `HTTPDigestAuth`.

## Domain And Preconditions

The in-domain qop inputs are:

- `qop is None`, representing an RFC 2069-compatible challenge with no qop directive.
- A comma-separated qop-options string that, after splitting on commas and stripping whitespace from each token, contains `auth`.
- A qop-options string that does not contain `auth`, which remains an explicitly unsupported branch and returns `None`.

The broader `build_digest_header` preconditions from existing code are unchanged: `self.chal` must contain `realm` and `nonce`; the algorithm must be one of the implementations this version already handles (`MD5`, `MD5-SESS`, or `SHA`) for a non-`None` header result.

## Postconditions

P-1. If qop options contain `auth`, the emitted Authorization header contains the fragment `qop="auth"`.

P-2. If qop options contain `auth`, the response digest input uses `auth` as the qop-value in `nonce:nc:cnonce:qop:HA2`, not the raw options string such as `auth,auth-int`.

P-3. If qop is absent, the qop header fragment is absent and the no-qop digest input remains `nonce:HA2`.

P-4. If qop is present but contains no `auth` token, `build_digest_header` returns `None`; this is recorded as unsupported behavior, not proof of RFC2617 `auth-int` completeness.

P-5. The method signature, `HTTPDigestAuth` constructor behavior, and internal callsites that install the Authorization header are unchanged.

## Formal Artifacts

The K fragment is in `fvk/mini-python.k`; the qop claims are in `fvk/digest-auth-spec.k`. The model normalizes qop options to a K `List` of stripped string tokens. This abstraction is property-complete for the qop issue because it distinguishes the failing V1 behavior from the passing V2 behavior:

- failing behavior: a raw options string such as `auth,auth-int` is used as the digest qop-value while the header advertises selected qop `auth`;
- passing behavior: `qopOptions(ListItem("auth") ListItem("auth-int"))` reaches selected qop-value `"auth"` and header fragment `qop="auth"`.

The proof is partial correctness only and is constructed, not machine-checked.
