# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Formal Core

K semantics: `fvk/mini-django-referrer.k`

K claims: `fvk/referrer-policy-spec.k`

Commands to machine-check later:

```sh
kompile fvk/mini-django-referrer.k --backend haskell
kast --backend haskell fvk/referrer-policy-spec.k
kprove fvk/referrer-policy-spec.k
```

Expected machine-check result if the abstract semantics and claims are accepted:
`#Top`.

## Constructed Proof Sketch

Claim C1: default value.

The semantics rule for `defaultSECURE_REFERRER_POLICY` rewrites directly to
`SameOrigin`. This corresponds to V1's `SECURE_REFERRER_POLICY = 'same-origin'`
in `global_settings.py`. By one axiom step, the claim reaches its post-state.

Claim C2: default response without existing header.

Start with `defaultResponse(H)` and side condition
`notBool hasHeader(H, "Referrer-Policy")`. The semantics first rewrites
`defaultResponse(H)` to `processResponse(SameOrigin, H)`. Since `SameOrigin` is
not `NonePolicy`, the response rule rewrites to
`setDefaultHeader(H, "Referrer-Policy", render(SameOrigin))`. The render
function rewrites `SameOrigin` to `"same-origin"`. Under the side condition that
the header is absent, `setDefaultHeader()` rewrites to
`H["Referrer-Policy" <- "same-origin"]`. This is the desired post-state.

Claim C3: default response with existing header.

The same first two steps apply, but the side condition is
`hasHeader(H, "Referrer-Policy")`. The `setDefaultHeader()` abstraction then
rewrites to `H`, matching `HttpResponse.setdefault()` preserving an existing
header.

Claim C4: explicit opt-out.

`processResponse(NonePolicy, H)` matches the disabled-policy rule and rewrites
directly to `H`. This models the unchanged `if self.referrer_policy:` branch in
the middleware.

Claim C5: custom policy.

For `RawPolicy(P)`, the non-None response rule applies. `render(RawPolicy(P))`
rewrites to `P`, and when the header is absent `setDefaultHeader()` rewrites to
`H["Referrer-Policy" <- P]`. This proves custom values remain framed by the
default change.

## Adequacy and Completeness Check

The public intent requires the default value and resulting default header, not a
new middleware algorithm. C1 and C2 cover that changed behavior. C3 through C5
cover the compatibility frame around existing header preservation, explicit
opt-out, and custom settings. PO-7 covers the release-note obligation. No
public-intent requirement remains outside these claims.

## Residual Risk

The proof is not machine-checked. The mini semantics abstracts Django's full
settings system and `HttpResponse` implementation, but it preserves the
property axis under audit: policy value, header key, header value, absence or
presence of an existing header, and opt-out behavior.

The proof is partial correctness. There is no loop or recursion in the audited
slice, so no termination measure is needed.

## Test Guidance

Do not delete tests. Existing and hidden tests should be kept because the K
claims were not machine-checked in this task. Useful test coverage, if tests
were editable, would include the default header, explicit `None` opt-out,
existing header preservation, and no W022 warning for the default.
