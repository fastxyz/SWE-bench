# PROOF OBLIGATIONS

Status: constructed obligations, not machine-checked.

## PO-1 - Successful append-slash redirect uses the client-visible path

- Obligation: If `APPEND_SLASH` is true, `url` is missing a trailing slash, resolving `request.path_info + "/"` succeeds, and the resolved view allows append-slash, the redirect target is `request.path + "/"`.
- Public intent: I1 and I2.
- Formal claim: CLAIM-REDIRECT and CLAIM-FORCE-SCRIPT-NAME-WITNESS in `admin-catch-all-spec.k`.
- Code evidence: `repo/django/contrib/admin/sites.py:429-430`.
- Status: discharged by V1.

## PO-2 - Resolver lookup remains based on `request.path_info`

- Obligation: The candidate passed to `resolve()` is `request.path_info + "/"`, not `request.path + "/"`.
- Public/default-domain support: Django request handling separates script prefix from URLconf resolution; C1 and C2 in `SPEC.md`.
- Formal model: `RESOLVE` in the K model denotes the result of resolving `PATHINFO + "/"`.
- Code evidence: `repo/django/contrib/admin/sites.py:423-425`.
- Status: discharged by V1; no source change recommended.

## PO-3 - Non-redirect branches still raise `Http404`

- Obligation: `catch_all_view()` raises `Http404` when any redirect precondition is absent: `APPEND_SLASH` false, captured URL already slash-terminated, resolver failure, or resolved view opts out via `should_append_slash=False`.
- Public behavior support: existing admin catch-all behavior and the method's role as the final admin URL pattern.
- Formal claims: CLAIM-NO-REDIRECT-APPEND-FALSE, CLAIM-NO-REDIRECT-URL-SLASH, CLAIM-NO-REDIRECT-RESOLVER404, and CLAIM-NO-REDIRECT-SHOULD-NOT-APPEND.
- Code evidence: `repo/django/contrib/admin/sites.py:421-431`.
- Status: discharged by V1; the V1 edit does not affect these branches.

## PO-4 - Public compatibility is preserved

- Obligation: No public method signature, wrapper call shape, decorator behavior, response class family, or exception family changes.
- Compatibility audit: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: discharged by V1.

## PO-5 - Adequacy gate rejects legacy-derived redirect targets

- Obligation: The formal postcondition must not use `PATHINFO + "/"` as the redirect target, because that is exactly the reported legacy bug. It also must not strengthen the issue into query-string preservation without public evidence.
- Adequacy artifacts: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.
- Status: discharged. The postcondition is exactly `PATH + "/"`.
