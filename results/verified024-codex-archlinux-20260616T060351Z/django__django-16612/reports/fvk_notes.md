# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional source edit justified by
the public issue intent.

## Trace to Findings and Proof Obligations

F-001 identifies the original code bug: the legacy redirect target used
`request.path`, which excludes `QUERY_STRING`. PO-001, PO-002, and PO-003 state
the required redirect behavior: when the existing admin APPEND_SLASH gates pass,
the redirect location must append the slash to the path component and preserve
every non-empty query string after it. V1 discharges these obligations by using
`request.get_full_path(force_append_slash=True)`.

F-002 checks that the fix did not broaden the redirect behavior. PO-005 requires
the non-redirect branches to keep raising `Http404` when `APPEND_SLASH` is
false, the captured URL already ends in `/`, the slash-appended path does not
resolve, or `should_append_slash` is false. V1 leaves those gates unchanged, so
no code edit was made there.

F-003 records the formal model boundary: URL resolving and URI encoding are
abstracted because the issue concerns query preservation in the redirect
location. PO-006 and PO-007 keep that abstraction honest by requiring public
compatibility and an adequacy check against the issue intent. The audit found
no signature, URL registration, or `should_append_slash` protocol change.

## Artifacts Produced

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

To satisfy the FVK artifact contract, I also wrote the intent/adequacy and K
core files under `fvk/`: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
`FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`,
`mini-django-admin.k`, and `admin-catch-all-spec.k`.

## Execution

No tests, Python, `kompile`, `kast`, or `kprove` were run. The proof is
constructed, not machine-checked, and the commands to run later are recorded in
`fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
