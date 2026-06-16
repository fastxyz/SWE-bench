# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that V1 resolves the issue's concrete
auth-loss regression, and it did not surface an intent-derived need for a second
production edit.

## Decisions Traced To FVK Artifacts

1. Kept the V1 edit in `repo/requests/utils.py`.

   `fvk/FINDINGS.md` records this as FINDING-F1. The corresponding proof
   obligations are PO-AUTH-PRESERVE and PO-ADAPTER-CONSUMER in
   `fvk/PROOF_OBLIGATIONS.md`. Together they show that reattaching
   `auth + "@" + netloc` is the source change needed for authenticated proxy
   URLs to remain consumable by `HTTPAdapter.proxy_headers`.

2. Made no further edit to unauthenticated proxy behavior or path/netloc swap
   behavior.

   PO-NO-AUTH-FRAME and PO-PATH-SWAP in `fvk/PROOF_OBLIGATIONS.md` require those
   existing behaviors to remain framed. V1's branch only runs when `auth` is
   present, and it runs after the existing effective-netloc selection, so no
   additional source change was justified.

3. Did not change `SessionRedirectMixin.rebuild_proxies`.

   FINDING-F2 explicitly audits that alternative and rejects it for this issue.
   PO-COMPAT-REDIRECT-NO-CHANGE explains the proof obligation: documented proxy
   auth URLs are schemeful, and the public issue localizes the regression to
   `prepend_scheme_if_needed`. Normalizing `new_proxies[scheme]` during redirect
   handling would broaden behavior beyond the proven issue path.

4. Added FVK artifacts without changing production code.

   `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
   `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` document the public intent,
   formal obligations, constructed proof, and next steps. I also added
   `fvk/mini-requests-proxy.k` and `fvk/requests-proxy-spec.k` because the FVK
   method says a prose-only run is unresolved.

5. Did not run or infer test results.

   FINDING-F4 records the constructed-not-machine-checked status. The emitted
   commands in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` are for a later
   environment where execution is allowed. No test files were modified.

## Residual Assumptions

- The proof abstracts `parse_url`, `urlunparse`, and `get_auth_from_url` at the
  component level. FINDING-F3 explains why that is adequate for this issue: the
  public report identifies the specific component mismatch, namely that auth is
  parsed separately from netloc.
- The proof covers the authenticated proxy normalization path. It does not prove
  real network status codes, TLS behavior, or all URL parser edge cases.
