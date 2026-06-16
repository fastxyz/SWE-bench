# FVK Notes

## Source Decision

V1 stands unchanged. The FVK audit found the operative bug in F-001 and PO-4: callable `lastmod` with an empty `items()` result must return `None` instead of raising `ValueError`. The existing V1 edit adds `default=None` to `max()`, which directly discharges that obligation.

## Why No Additional Source Edit Was Made

- F-002 and PO-6 reject the alternative of catching `ValueError`; it would mask user-raised `ValueError`s unrelated to empty `max()`.
- F-003 and PO-5 show that non-empty comparable callable values still return the documented latest value.
- F-004 and PO-7 show that the patch changes no public signature, call shape, or override contract.
- F-005 and PO-8 require honesty about the proof status, but they are not source-code findings.

## Artifacts Produced

The required artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`. To satisfy the FVK method's formal-core and adequacy gates, I also added `fvk/mini-python.k`, `fvk/sitemap-lastmod-spec.k`, `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

No tests, Python, or K tooling were run.
