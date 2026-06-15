# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Findings From Formalization

F-001: Pre-fix default failed the public intent.

Input/state: project uses `SecurityMiddleware`, response has no existing
`Referrer-Policy`, and the project does not override `SECURE_REFERRER_POLICY`.

Observed in pre-fix code: `global_settings.SECURE_REFERRER_POLICY = None`;
`SecurityMiddleware.process_response()` skips the header because the cached
policy is falsey.

Expected from E1/E2: default policy is `same-origin`, and the response receives
`Referrer-Policy: same-origin`.

Resolution: V1 changes `repo/django/conf/global_settings.py` to
`SECURE_REFERRER_POLICY = 'same-origin'`. Covered by PO-1 through PO-4.

F-002: V1 preserves response-header override behavior.

Input/state: response already contains `Referrer-Policy`.

Observed in V1: `SecurityMiddleware.process_response()` still uses
`response.setdefault('Referrer-Policy', ...)`, so it leaves the existing header
unchanged.

Expected from public compatibility I3: existing response-level customization
should not be overwritten by a default-setting change.

Resolution: no source edit required. Covered by PO-5.

F-003: V1 preserves explicit opt-out and custom setting behavior.

Input/state: project explicitly sets `SECURE_REFERRER_POLICY = None` or a
custom valid value.

Observed in V1: `None` remains falsey and disables the header; non-None strings
and iterables flow through the existing split/join path.

Expected from I3 and the backwards-compatibility concern in E4: applications
that depend on previous behavior need an opt-out, and applications with custom
policies should keep them.

Resolution: no source edit required. Covered by PO-5 and PO-6.

F-004: Security check wording is legacy wording but not a correctness blocker.

Input/state: project explicitly sets `SECURE_REFERRER_POLICY = None` and has
`SecurityMiddleware` configured.

Observed in V1: `check_referrer_policy()` returns W022 with text saying the
setting is not set.

Expected from the issue: the default must be secure, and the compatibility
impact must be documented. The issue does not require changing warning text for
an explicit opt-out.

Resolution: no source edit required. The check still identifies the effective
disabled state and the default no longer triggers it. Covered by PO-6.

F-005: Machine verification remains pending by task constraint.

Input/state: FVK `.k` claims are written but the task forbids `kompile` and
`kprove`.

Observed: proof is constructed from source inspection and abstract K claims.

Expected: artifacts must be labeled constructed, not machine-checked.

Resolution: keep all tests and treat test-removal ideas as conditional only.
Covered by PO-8.

## Proof-Derived Findings From `/verify`

No code bug was found in V1. The proof obligations discharge by symbolic
inspection over the modeled slice. The only residual risk is F-005: the K
claims were not machine-checked, and the mini semantics abstracts Django's full
`HttpResponse` and settings machinery to the specific behavior under audit.
