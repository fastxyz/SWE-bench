# FVK Notes

## Decision

V1 stands unchanged. The FVK audit identifies the original defect as finding
F1: the final label-producing E-step could read the last initialization's
parameters even though the estimator was restored to `best_params`. Proof
obligation PO3 is the decisive ordering obligation, and V1 satisfies it by
placing `_set_parameters(best_params)` before the final `_e_step(X)`.

## Source changes

No additional source files were changed in V2. This is justified by F2 and
proof obligations PO1-PO7: best-parameter selection is preserved (PO2), the
final E-step now uses the restored best state (PO3), and labels from that
E-step match `predict(X)` because row-wise normalization preserves argmax
(PO4). Subclass compatibility is covered by PO5 and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Alternatives reconsidered

Changing `predict` remains rejected. F1 shows the mismatch came from
`fit_predict` returning labels from the wrong parameter state; PO4 shows
`predict` is correct once the shared parameter state is restored.

Storing `log_resp` from inside the best initialization loop remains rejected.
PO4 depends on the final E-step being evaluated under the restored fitted state,
which is exactly what V1 does without adding extra state.

## Test and proof limits

F3 records the remaining public test gap: a regression test should cover
`n_init > 1`, but this benchmark forbids editing tests. F4 and PO9 record the
proof boundary: the mini-mixture proof is constructed, not machine-checked, and
does not claim full numerical EM correctness. No tests, Python, or K tooling
were run.
