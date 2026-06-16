# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and the constructed proof obligations only.

## F1: V1 fixes the reported invalid-pair defect

Classification: code bug fixed by V1.

Evidence:

- Problem statement says `makemigrations` called `allow_migrate()` "for each
  app with all the models in the project rather than for each app with the
  app's models."
- Pre-fix code used `for app_label in consistency_check_labels` and
  `for model in apps.get_models(app_label)`.
- In this Django version, `apps.get_models()` doesn't take an app label; the
  first positional argument is `include_auto_created`.

Concrete example:

Input shape: apps `A = {A1}` and `B = {B1}`.

Observed pre-fix behavior: router may see `(A, B1)` or `(B, A1)`.

Expected behavior: router may see only `(A, A1)` and `(B, B1)`, subject to
`any()` short-circuiting.

V1 status: fixed. V1 iterates `for app_config in app_configs` and then
`for model in app_config.get_models()`.

Related proof obligations: PO1, PO2, PO3.

## F2: V1 preserves the intended consistency-check gate

Classification: proof-confirmed frame condition.

Evidence:

- The code still checks only non-dummy database connections.
- The code still checks all connection aliases only when database routers are
  configured, otherwise only `DEFAULT_DB_ALIAS`.
- The code still calls `loader.check_consistent_history(connection)` under
  `any(...)`.

Concrete example:

Input shape: alias `other` is non-dummy and at least one valid pair is allowed
by the router.

Expected behavior: history consistency is checked for `other`.

V1 status: preserved. Replacing the pair generator does not change the alias
selection, dummy-engine guard, or `any()` truth condition.

Related proof obligations: PO4, PO5.

## F3: Router call shape intentionally remains unchanged

Classification: audited non-change.

Evidence:

- The problem statement describes invalid app/model combinations, not
  `model_name` casing or missing router hints.
- Existing `makemigrations.py` behavior passed
  `model_name=model._meta.object_name`.

Decision:

V1 keeps `model_name=model._meta.object_name` and doesn't add a `model` hint.
Changing those would be a broader compatibility/API behavior change without
public issue evidence in this task.

Related proof obligations: PO6.

## F4: Proof is constructed, not machine-checked

Classification: proof process caveat.

Evidence:

- The task forbids running tests, Python, or K tooling.
- FVK's honesty gate requires labeling the proof as constructed, not
  machine-checked.

Decision:

No tests were run and no test-removal recommendation is made. Existing and
hidden tests should be kept unless a future run actually machine-checks the K
claims and separately maps tests to the checked spec.

Related proof obligations: PO7.
