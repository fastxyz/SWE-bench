# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## What Is Proved

For the qop-producing slice of `HTTPDigestAuth.build_digest_header`:

- If normalized qop options contain `auth`, the result uses `qop="auth"` in the header and `auth` in the response digest qop slot.
- If qop is absent, the qop header fragment remains absent.
- If qop options do not contain `auth`, the slice reaches the unsupported branch; this is not a proof of `auth-int`.

## Proof Sketch

Claim `QOP-AUTH-LIST` starts with `buildDigestQop(qopOptions(QOPS))` and side condition `containsAuth(QOPS)`. The mini semantics has exactly one enabled rule under that side condition, rewriting to `qopResult("qop=\"auth\"", "auth")`. This directly discharges PO-1 and PO-2.

Claim `QOP-NO-QOP` starts with `buildDigestQop(noQop)`. The no-qop rule rewrites to `qopResult("", "")`, so no qop header fragment or digest qop token is introduced. This discharges PO-3.

Claim `QOP-UNSUPPORTED` starts with `buildDigestQop(qopOptions(QOPS))` and side condition `notBool containsAuth(QOPS)`. The unsupported rule rewrites to `unsupportedQop`. This discharges PO-4 as a boundary claim only.

There are no loops or recursive calls in the modeled qop slice, so no circularity or termination argument is needed. The proof is partial correctness over the modeled qop behavior.

## Why V1 Was Not Enough

V1 satisfied PO-1 but not PO-2. In V1, `noncebit` was computed with the raw `qop` challenge value before selecting `auth` for the header. For a quoted multi-token challenge such as `qop="auth,auth-int"`, V1 could produce a header advertising `qop="auth"` while hashing `auth,auth-int`. The formal spec forced the qop header contributor and qop digest contributor into the same observable, producing F-2.

V2 moves `noncebit` construction into the `auth` branch and uses the selected token `'auth'`. It also strips tokens while checking membership, so comma-separated qop lists with optional spaces still select `auth`.

## Trusted Base And Residual Risk

Trusted base: the adequacy of the mini semantics for this qop slice, the public intent ledger, and any future K toolchain run. The mini semantics intentionally abstracts away hashing, randomness, URL parsing, and unrelated header fields.

Residual risk: `auth-int` remains unsupported as recorded in F-3. Termination is trivial for the modeled slice but not separately machine-checked.

## Test Recommendations

Conditioned on future machine-checking:

- Add or keep a unit-level check for a qop challenge containing `auth` that asserts the Authorization header contains `qop="auth"`.
- Add or keep a unit-level check for a multi-token qop challenge such as `auth,auth-int` or `auth-int, auth` that asserts the selected qop in the digest input is `auth`; this may require isolating or monkeypatching the hash input in a normal test environment.
- Keep integration tests for `HTTPDigestAuth`; the proof covers only the qop slice, not network retry behavior.
- Do not remove tests until `kompile` and `kprove` return `#Top`.

## Reproduce The Machine Check Later

Recorded only; not executed in this session:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell digest-auth-spec.k
kprove digest-auth-spec.k
```

