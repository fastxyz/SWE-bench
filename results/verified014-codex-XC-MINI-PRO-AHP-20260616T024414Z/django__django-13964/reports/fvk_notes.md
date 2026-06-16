# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the one-line change in
`repo/django/db/models/base.py` discharges the public issue's required behavior
and preserves the surrounding safeguards.

## Decisions Traced To Findings And Obligations

1. Kept `getattr(self, field.attname) in field.empty_values`.

   - Finding: F1.
   - Obligations: O1, O5.
   - Reason: the public issue and hint identify `product_id == ""` as the stale
     value that prevents `_prepare_related_fields_for_save()` from using the
     saved related object's primary key. The widened predicate covers the
     CharField empty-string case and is reached by both `save()` and
     `bulk_create()` through the shared preparation method.

2. Did not alter the `obj.pk is None` branch.

   - Finding: F2.
   - Obligation: O2.
   - Reason: the unsaved-related-object guard remains before the empty-value
     refresh. The audit requires this guard to keep raising `ValueError` for
     genuinely `None` primary keys, so no source edit was needed here.

3. Did not alter cache invalidation after the refresh.

   - Finding: F3.
   - Obligation: O3.
   - Reason: after any refresh opportunity, the existing comparison between
     `obj.<target_attname>` and `self.<field.attname>` still clears the cached
     relation on mismatch. This preserves the intended cache-consistency
     behavior outside the stale-empty-value fix.

4. Did not change `ForwardManyToOneDescriptor.__set__()`.

   - Findings: F1, F5.
   - Obligations: O1, O4.
   - Reason: descriptor assignment explains how the stale `""` gets copied, but
     the issue's required reconciliation happens during save preparation after
     the related object gains its primary key. Changing descriptor semantics
     would broaden the patch beyond the evidence-backed repair.

5. Accepted the per-field formal abstraction.

   - Finding: F4.
   - Obligation: O4.
   - Reason: the source loop processes concrete fields independently. The
     mini-K model captures the relation-field transition that distinguishes the
     failing state (`att == ""`) from the corrected state (`att == "foo"`), and
     O4 records the frame argument for composing that transition over the
     finite field loop.

6. Did not add, remove, or edit tests.

   - Findings: F1, F5.
   - Obligations: O1-O6.
   - Reason: the task forbids modifying tests and the proof is constructed, not
     machine-checked. `fvk/ITERATION_GUIDANCE.md` records suggested regression
     tests for future maintainers, but no test files were touched.

## Artifacts Produced

Required summary artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts required by the FVK docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-save.k`
- `fvk/django-save-spec.k`

No tests, Python, or K framework commands were run.
