# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code change beyond
the existing guards in `related_descriptors.py`.

## Trace to Findings and Obligations

`fvk/FINDINGS.md` F1 identifies the original one-to-one bug: the outer prefetch
overwrote the inner `Profile.user` cache. `fvk/PROOF_OBLIGATIONS.md` PO1
requires preserving already-cached relations. V1 satisfies this in
`ReverseOneToOneDescriptor.get_prefetch_queryset()` by guarding
`self.related.field.set_cached_value(rel_obj, instance)` with
`if not self.related.field.is_cached(rel_obj)`.

F2 extends the same issue to the ForeignKey reverse relation named in the public
problem. PO3 requires coverage of that relation family. V1 satisfies this in
`create_reverse_many_to_one_manager().RelatedManager.get_prefetch_queryset()` by
guarding `setattr(rel_obj, self.field.name, instance)` with
`if not self.field.is_cached(rel_obj)`.

F3 protects the default behavior from the public hint: if no nested cache exists,
the origin object should still be assigned. PO2 requires seeding missing caches.
V1 satisfies this because the original writes remain in the `not is_cached`
branch.

F4 and PO4 cover public compatibility. No signatures, returned tuple shapes,
query filters, cache names, or tests changed, so no compatibility repair was
needed.

PO5 checks adequacy of the proof abstraction. The abstract `seedIfMissing`
transition distinguishes the failing pre-fix unconditional overwrite from V1's
preserve-when-cached behavior, so it is adequate for the reported cache bug.

## Alternatives Rechecked

Merging loaded fields from the inner user into the outer user was rejected again.
No finding requires object-state merging, and PO1 only requires preserving the
already-cached nested relation value.

Raising an exception for this nested graph was rejected again. F1 and F2 define
successful expected behavior, and PO1-PO3 are dischargeable without declaring the
graph unsupported.

Moving the fix into `prefetch_one_level()` was rejected after the proof
localized the overwrite to descriptor-side manual cache seeding. The existing
V1 edit covers all source locations named by PO3.

## Execution

No tests, Python, `kompile`, `kast`, or `kprove` were run. The FVK proof is
constructed, not machine-checked.

