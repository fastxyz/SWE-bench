# FINDINGS

Status: constructed FVK findings, not machine-checked.

## F1 - Resolved code bug: script prefix was lost in the append-slash redirect

- Classification: code bug, fixed by V1.
- Public evidence: issue entries I1 and I2 in `SPEC.md`.
- Concrete input class: `APPEND_SLASH=True`, captured `url` does not end with `/`, `request.path_info="/admin/auth/user"`, `request.path="/script/admin/auth/user"`, and resolving `"/admin/auth/user/"` succeeds with `should_append_slash=True`.
- Pre-V1 observed behavior: redirect target `"/admin/auth/user/"`, because the same `request.path_info + "/"` value was used for resolving and redirecting.
- Expected behavior: redirect target `"/script/admin/auth/user/"`, because public intent says the redirect should use `request.path + "/"`.
- V1 behavior: `HttpResponsePermanentRedirect("%s/" % request.path)`, satisfying the expected target.
- Proof obligation trace: PO-1 and PO-2.

## F2 - No open code finding: resolver input should remain script-stripped

- Classification: confirmed non-bug in V1.
- Evidence: source code and Django request model entries C1 and C2 in `SPEC.md`.
- Concrete input class: same as F1, with a non-empty script prefix.
- Rejected alternative: resolving `request.path + "/"`.
- Reason: URLconf resolution operates on the script-stripped path. Including `SCRIPT_NAME` in the resolver candidate would make mounted deployments fail to resolve otherwise valid admin URLs.
- Proof obligation trace: PO-2.

## F3 - No open code finding: query-string preservation is not part of this fix

- Classification: underspecified behavior intentionally left unchanged.
- Evidence: issue entry I2 names `request.path`, not `request.get_full_path()` or `request.get_full_path(force_append_slash=True)`.
- Concrete input class: the same missing-slash redirect branch with a query string.
- V1 behavior: the redirect target is path-only, matching the pre-existing path-only shape while preserving the script prefix.
- Expected behavior under this spec: path-only redirect to `request.path + "/"`.
- Proof obligation trace: PO-5.

## F4 - Compatibility finding: no public API or test-suite shape changed

- Classification: compatibility confirmed.
- Evidence: V1 changes only the redirect target expression inside an existing branch.
- Public surface: `AdminSite.catch_all_view(self, request, url)` signature, wrapper dispatch, decorators, exception behavior, and return type family are unchanged.
- Proof obligation trace: PO-4.

## Proof-derived findings from `/verify`

The proof construction did not surface a new code defect. The only proof side condition is adequacy: CLAIM-REDIRECT must refer to `PATH`, not `PATHINFO`, because a claim over `PATHINFO + "/"` would reproduce the reported bug. This is discharged by PO-1 and by the adequacy audit in `SPEC_AUDIT.md`.
