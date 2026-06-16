# FVK Notes

## Source decision

V1 stands unchanged. `fvk/FINDINGS.md` identifies the operative defect as
unordered KMeans centers producing nonmonotonic midpoint edges (F-001, F-002),
and `fvk/PROOF_OBLIGATIONS.md` shows that sorting centers before midpoint
construction discharges the needed obligations (PO-002, PO-004). The additional
digitize check in F-004/PO-005 confirms that the suffix actually passed to
`np.digitize` remains monotonic.

No further source edit was made because F-005 and PO-007 found no public API,
learned-attribute, or unrelated-strategy compatibility issue. F-003/PO-003
records the only nontrivial side condition: successful one-dimensional KMeans
centers are within the fitted feature range. That side condition supports the
endpoint part of the monotonicity proof and does not require a change to
`KBinsDiscretizer`.

## Artifact decisions

I wrote the five requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the supporting FVK adequacy and formal-core files required by the
method documentation:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/kbins-discretizer-spec.k`

The formal model focuses on the property that caused the issue: ordered
one-dimensional centers and monotonic learned edges. It abstracts full
Python/NumPy/KMeans execution to an ordered scalar/list fragment because the
proof obligations only need to distinguish sorted edges from unsorted edges.
That abstraction is tied to F-001 through F-004 and PO-002 through PO-005.

## Rejected alternatives

Sorting final `bin_edges_` was rejected because F-002 and PO-004 require
midpoints between neighboring centers in numeric order; sorting after averaging
arbitrary returned-center pairs can hide the wrong pairing.

Sorting bins inside `transform` was rejected because F-004 and PO-005 localize
the invariant to the learned `bin_edges_` produced by `fit`. Transform should
consume already-valid learned edges, not repair estimator state on the fly.

Changing validation for KMeans-infeasible `n_bins` values was not included.
PO-001 scopes this audit to successful KMeans fits in the reported unordered-
edge path, and no finding traced the public issue to validation behavior.

## Execution policy

No tests, Python, project code, `kompile`, `kast`, or `kprove` were run. The K
commands in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` are recorded for a
future machine-checking environment only.
