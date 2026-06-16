# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO-1 | Spec adequacy: formal claims must match public intent, not the candidate implementation alone. | E1-E8, `INTENT_SPEC.md`, `SPEC_AUDIT.md`. | Discharged by the adequacy audit; all claims pass. |
| PO-2 | If `lastmod` is absent, return `None`. | Optional nature of `lastmod`; sitemap index consumes `None`. | Discharged by NO-LASTMOD. |
| PO-3 | If `lastmod` is a non-callable attribute, return the attribute value unchanged. | Docs for `Sitemap.lastmod` and `Sitemap.get_latest_lastmod()`. | Discharged by ATTRIBUTE-LASTMOD. |
| PO-4 | If `lastmod` is callable and `items()` is empty, return `None` and do not raise `ValueError`. | Problem report and `max(default=...)` hint. | Discharged by CALLABLE-EMPTY-LASTMOD and the V1 `default=None` source change. |
| PO-5 | If `lastmod` is callable and values are non-empty/comparable, return the latest value over all items. | Public docs for callable `lastmod`. | Discharged by CALLABLE-LASTMOD and CALLABLE-NONEMPTY-COMPARABLE. |
| PO-6 | Preserve existing `TypeError -> None` behavior without broadening to catch arbitrary `ValueError`. | Existing source behavior and issue patch sketch retaining `TypeError`. | Discharged by CALLABLE-TYPEERROR and by V1 not adding `except ValueError`. |
| PO-7 | Public compatibility: no method signature, caller, or override shape changes. | Source call sites and override audit. | Discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`. |
| PO-8 | Honesty gate: proof is constructed but not machine-checked; no tests or K tooling were run. | User restriction and FVK MVP status. | Recorded in `PROOF.md` and `ITERATION_GUIDANCE.md`. |
