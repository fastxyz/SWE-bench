# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edits are recommended. V1 satisfies the intent-derived
obligations in `fvk/PROOF_OBLIGATIONS.md`:

* PO-1 through PO-4 prove the effective default and default response header.
* PO-5 preserves explicit opt-out, custom settings, and existing response
  headers.
* PO-6 confirms the new default is a valid policy and does not trigger W022.
* PO-7 confirms the backwards-incompatible default change is documented.

## Rejected Follow-up Edits

Changing `SecurityMiddleware.process_response()` was rejected. The existing
middleware already emits the header for any truthy setting, and changing the
default is sufficient to satisfy E1/E2.

Changing the deployment warning text for W022 was considered and rejected as
out of scope for this issue. F-004 records the wording mismatch, but the check
still correctly identifies the effective disabled state when a project
explicitly sets `SECURE_REFERRER_POLICY = None`.

Changing project templates was rejected. The template already includes
`django.middleware.security.SecurityMiddleware`, and the issue requests a
setting default, not a middleware-list change.

## Next Verification Step

When an execution environment is available, the next step is to machine-check
the abstract FVK claims:

```sh
kompile fvk/mini-django-referrer.k --backend haskell
kast --backend haskell fvk/referrer-policy-spec.k
kprove fvk/referrer-policy-spec.k
```

The expected result is `#Top`. Until that is actually obtained, keep all tests.
