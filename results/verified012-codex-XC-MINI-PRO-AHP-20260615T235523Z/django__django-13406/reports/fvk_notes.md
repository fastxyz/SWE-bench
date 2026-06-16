# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K tools.

## Decision

V1 stands unchanged.

The audit found that the reported `values().annotate()` crash path is covered by F1 and proof obligations PO1, PO3, and PO6: `values()` records `ValuesIterable` and fields on the `Query`, normal query cloning preserves those attributes, and the setter restores them before evaluation.

The public `values_list()` concern is covered by F2 and PO2/PO3: tuple, flat, and named modes each write their exact iterable class to the query, and assignment restores the marker.

The public hint's narrower `values_select` check was strengthened in V1. F3 and PO4 justify keeping that part: `has_select_fields` also covers annotation-only and extra-only selected queries where `values_select` can be empty.

No further source edit was justified. F5 states that all current-version in-scope obligations are discharged. The only residual limitation is F4/PO7: old or manually-created selected queries without V1 metadata cannot reveal whether they came from `values_list(flat=True)`, `values_list(named=True)`, or tuple mode. V1 safely falls back to `ValuesIterable` for those, which avoids the crash but does not promise impossible exact recovery.

## Artifacts

The requested FVK artifacts are in `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

Supporting FVK adequacy and formal-core files are also in `fvk/`: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-django-query.k`, and `django-queryset-query-spec.k`.

