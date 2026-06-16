# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level defect in the
baseline fix.

## Trace To Findings And Proof Obligations

`fvk/FINDINGS.md` F1 confirms the original reported failure is addressed:
identical non-monotonic `y` coordinates are excluded from `concat_dims` by
`_infer_concat_order_from_coords`, and V1 validates only `concat_dims`. This
traces to `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-2, and PO-3.

`fvk/FINDINGS.md` F2 confirms that V1 preserves the required error for an
impossible global order along a real concat dimension. This traces to
`fvk/PROOF_OBLIGATIONS.md` PO-4, which verifies that the `ValueError` branch is
still active for dimensions in `concat_dims`.

`fvk/FINDINGS.md` F3 confirms no compatibility repair is needed. This traces to
`fvk/PROOF_OBLIGATIONS.md` PO-5: the source diff changes only the validation
loop iterable and comment, not public signatures, return shapes, grouping,
concat, merge, or tests.

`fvk/FINDINGS.md` F4 records the honesty caveat from the FVK method and the
task's no-execution constraint. This traces to `fvk/PROOF_OBLIGATIONS.md` PO-6:
the proof is constructed, not machine-checked, and no tests should be removed.

## Alternatives Reconsidered

Removing the final monotonicity check was rejected again because F2 and PO-4
show it is still required for dimensions that actually drive concatenation.

Restoring validation over all result dimensions was rejected because F1 and
PO-1 through PO-3 show that doing so reintroduces the documented bystander
coordinate bug.

Adding a second bystander-detection pass after `_combine_nd` was rejected
because PO-2 already provides the relevant classification and PO-3 consumes it
directly. The extra pass would not satisfy any uncovered proof obligation.

No tests, Python, or K tooling were run.
