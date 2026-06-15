# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not identify a source-code defect against
the public issue intent.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` F-1 confirms that V1 combines two same-model fast-delete
querysets for the multiple-foreign-key case described in the issue. This is
justified by `fvk/PROOF_OBLIGATIONS.md` PO-1, which requires replacing a
compatible existing entry with `fast_delete | qs`, and PO-5, which ties the
combined list entry to a reduced `_raw_delete()` round-trip count.

F-2 confirms the self-referential many-to-many through-table case. It maps to
PO-1 and the second claim in `fvk/fast-delete-spec.k`, where `from_id` and
`to_id` predicates for `PersonFriends` combine into one OR predicate.

F-3 confirms the parameter-limit guard as intentional. PO-3 requires preserving
backend safety by skipping combination when known parameter counts exceed
`max_query_params` or when counts are unknown on a limited backend. This is why
I kept V1's `_fast_delete_param_counts` tracking rather than simplifying the
helper to always merge same-model querysets.

F-4 records the only plausible alternative interpretation: combining by physical
table even for distinct Django model classes. PO-2 rejects that as unsupported by
the public examples and by Django's local `QuerySet.__or__` primitive, which is
same-model. I therefore did not replace V1 with a lower-level SQL/DeleteQuery
combiner.

F-5 records the FVK honesty caveat. The K artifacts and proof are constructed
only; no `kompile`, `kast`, `kprove`, tests, Python, or Django code were run.

## Source Changes in This Iteration

No source files under `repo/` were changed during the FVK iteration. The V1
source change in `repo/django/db/models/deletion.py` remains the final code fix.

## Artifact Changes in This Iteration

Added the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added the formal core required by the FVK method:

- `fvk/mini-fast-delete.k`
- `fvk/fast-delete-spec.k`

Added this report:

- `reports/fvk_notes.md`

## Rejected Changes

I rejected broadening the fix from same-model queryset OR combination to
physical-table SQL combination across distinct model classes. That alternative
would exceed the public evidence for this issue and would require new proof
obligations for SQL aliasing, model metadata, row-count attribution, and delete
query construction. See F-4 and PO-2.

I also rejected removing the parameter-count guard. F-3 and PO-3 show it is a
safety preservation obligation derived from the existing batching behavior.
