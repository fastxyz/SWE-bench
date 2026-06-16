# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Quoted selected qop in the header

For any normalized qop-options list containing `auth`, `build_digest_header` must emit an Authorization header fragment containing `qop="auth"` and must not emit `qop=auth`.

Evidence: E-1, E-3, E-4. Finding: F-1. K claim: `QOP-AUTH-LIST`.

## PO-2: Selected-token consistency

For any normalized qop-options list containing `auth`, the qop token used in the response digest input must be `auth`, matching the token serialized in the header.

Evidence: E-2 and the implementation's existing selection of `auth` when available. Finding: F-2. K claim: `QOP-AUTH-LIST`.

## PO-3: No-qop frame condition

If qop is absent, the qop-producing slice must emit no qop header fragment and must use the legacy no-qop digest path.

Evidence: existing no-qop branch and absence of issue evidence requiring a change. Finding: none. K claim: `QOP-NO-QOP`.

## PO-4: Unsupported qop boundary

If qop options do not contain `auth`, the existing unsupported result is outside the proven success domain. The proof must not present this as `auth-int` support.

Evidence: E-6. Finding: F-3. K claim: `QOP-UNSUPPORTED`.

## PO-5: Public compatibility

The repair must preserve the `HTTPDigestAuth` public construction pattern, the `build_digest_header(self, method, url)` signature, and existing internal callsites.

Evidence: E-7 and repository callsite search. Finding: F-4. Audit: `PUBLIC_COMPATIBILITY_AUDIT.md`.

## Recorded Commands

These commands are the commands to run later; they were not executed in this session.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell digest-auth-spec.k
kprove digest-auth-spec.k
```

Expected machine-check result after a future run: `#Top` for all three claims, assuming the mini semantics parses as written.

