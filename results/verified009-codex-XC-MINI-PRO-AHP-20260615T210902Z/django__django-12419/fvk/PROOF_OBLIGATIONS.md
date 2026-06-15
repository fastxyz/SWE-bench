# FVK Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Discharge |
| --- | --- | --- | --- |
| PO-1 | The default value of `SECURE_REFERRER_POLICY` is `same-origin`. | E1, `repo/django/conf/global_settings.py`. | Discharged by V1 line `SECURE_REFERRER_POLICY = 'same-origin'` and K claim C1. |
| PO-2 | The global default is the effective value for projects that do not override it. | E6, `repo/django/conf/__init__.py`. | Discharged by `Settings` copying uppercase names from `global_settings` and `UserSettingsHolder` falling back to defaults. |
| PO-3 | `SecurityMiddleware` reads the effective setting value used for responses. | E5, `repo/django/middleware/security.py`. | Discharged by `self.referrer_policy = settings.SECURE_REFERRER_POLICY` in `__init__`. |
| PO-4 | With the V1 default and no existing header, `process_response()` emits `Referrer-Policy: same-origin`. | E2, E5. | Discharged by truthy `'same-origin'`, string split/join preserving the single value, and `response.setdefault()`. Modeled by K claim C2. |
| PO-5 | Existing response headers, explicit `None`, and custom policies are preserved. | I3, E5. | Discharged by unchanged `setdefault()` and falsey/nonnull branches. Modeled by K claims C3, C4, and C5. |
| PO-6 | The new default is accepted by the security check and does not trigger W022. | E7, `repo/django/core/checks/security/base.py`. | Discharged because `'same-origin'` is in `REFERRER_POLICY_VALUES` and W022 is returned only when the setting is `None`. |
| PO-7 | The compatibility impact is documented in release notes. | E4. | Discharged by V1 addition to `repo/docs/releases/3.1.txt`, including the `None` opt-out. |
| PO-8 | The FVK result must not claim machine verification or delete tests. | FVK `verify.md` honesty gate and task no-exec rule. | Discharged by labeling artifacts constructed, not machine-checked, and recommending no test deletion. |

## Obligation Coverage Notes

The proof is partial correctness over the response-processing slice: if the
middleware is invoked with the default policy and a response object supporting
`setdefault()`, the header map reaches the specified state. There is no loop or
recursive termination obligation in this slice.

The issue does not require changing `MIDDLEWARE` defaults because the generated
project template already includes `SecurityMiddleware`. The spec therefore
states the middleware-configured precondition explicitly.
