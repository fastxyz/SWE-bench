# FVK Specification: SECURE_REFERRER_POLICY Default

Status: constructed, not machine-checked. K tooling was not run.

## Intent Spec

I1. The default value of `SECURE_REFERRER_POLICY` must be `"same-origin"`.

I2. When `django.middleware.security.SecurityMiddleware` is configured and a
response does not already contain `Referrer-Policy`, the default behavior must
emit `Referrer-Policy: same-origin`.

I3. Existing public behavior of the setting remains framed: applications can
still set custom valid policies, an explicit `None` disables the header, and an
existing response header is not overwritten.

I4. The backwards-incompatible default change must be documented in Django 3.1
release notes.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "change the default for this to \"same-origin\"" | Postcondition: effective default is `same-origin`. | Encoded by PO-1 and claim `defaultSECURE_REFERRER_POLICY`. |
| E2 | `benchmark/PROBLEM.md` | "Add secure default SECURE_REFERRER_POLICY / Referrer-policy header" | Postcondition: default middleware response emits a `Referrer-Policy` header. | Encoded by PO-2 through PO-4 and claim `defaultResponse`. |
| E3 | `benchmark/PROBLEM.md` | "make Django applications leak less information to third party sites" | Choose a policy value that withholds referrers from cross-origin links. | Encoded by `same-origin`; the issue names the value, so no alternative value is allowed. |
| E4 | public hint in `benchmark/PROBLEM.md` | "As long as the BC is documented in the release notes" | Documentation obligation: release notes must mention the compatibility impact. | Encoded by PO-7. |
| E5 | `repo/django/middleware/security.py` | `self.referrer_policy = settings.SECURE_REFERRER_POLICY` and `response.setdefault('Referrer-Policy', ...)` | Implementation fact: the setting controls the header and response-level headers are preserved. | Used for proof transition and frame condition, not as intent by itself. |
| E6 | `repo/django/conf/__init__.py` | `Settings` copies uppercase names from `global_settings`; `UserSettingsHolder` falls back to `default_settings`. | Implementation fact: changing `global_settings.py` changes the effective default unless a user overrides it. | Encoded by PO-2. |
| E7 | `repo/django/core/checks/security/base.py` | valid policy set includes `'same-origin'`; check returns W022 only for `None`. | Compatibility fact: the new default is valid and does not trigger the deployment warning. | Encoded by PO-6. |

## Formal Scope

The formalized observable is the default policy value and the response header
map after `SecurityMiddleware.process_response()` for policy values in scope.
There are no loops or recursion in this slice. The K files model only:

* the default setting value;
* the middleware's cached `referrer_policy`;
* response `setdefault()` behavior for `Referrer-Policy`;
* `None` as explicit opt-out and raw custom string policies as framed behavior.

The formal core is in:

* `fvk/mini-django-referrer.k`
* `fvk/referrer-policy-spec.k`

## Formal Claims in English

C1. `defaultSECURE_REFERRER_POLICY` reaches `SameOrigin`.

C2. For any response header map `H` without `Referrer-Policy`,
`defaultResponse(H)` reaches `H["Referrer-Policy" <- "same-origin"]`.

C3. For any response header map `H` that already has `Referrer-Policy`,
`defaultResponse(H)` reaches `H` unchanged.

C4. For any response header map `H`, `processResponse(NonePolicy, H)` reaches
`H` unchanged.

C5. For any custom raw policy string `P` and any header map `H` without the
header, `processResponse(RawPolicy(P), H)` reaches
`H["Referrer-Policy" <- P]`.

## Adequacy Audit

| Claim | Intent mapping | Result |
| --- | --- | --- |
| C1 | Directly matches I1 and E1. | Pass. |
| C2 | Directly matches I2 and E2, with the middleware-configured precondition from the issue and code. | Pass. |
| C3 | Matches I3 response-header frame condition from existing `setdefault()` behavior. | Pass. |
| C4 | Matches I3 opt-out compatibility and the V1 release note. | Pass. |
| C5 | Matches I3 custom-setting compatibility. | Pass. |

No claim is derived solely from legacy behavior that conflicts with the issue.
The only legacy behavior intentionally preserved is the public configurability
of `SECURE_REFERRER_POLICY` and `setdefault()` header preservation.

## Public Compatibility Audit

Changed public symbol: `django.conf.global_settings.SECURE_REFERRER_POLICY`.

Compatibility impact: projects that use `SecurityMiddleware` and do not define
`SECURE_REFERRER_POLICY` now get `Referrer-Policy: same-origin`. This is the
intended backwards-incompatible change and is documented in `docs/releases/3.1.txt`.

Preserved call signatures: no function, method, class, or virtual dispatch
signature changed.

Preserved explicit override behavior: user settings still override
`global_settings`; `None` remains an opt-out; custom valid values remain
validated and emitted by the existing middleware code.

Compatibility conclusion: no source change beyond V1 is required.
