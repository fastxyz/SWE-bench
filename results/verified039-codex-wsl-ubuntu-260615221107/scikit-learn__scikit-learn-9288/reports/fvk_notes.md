# FVK Notes

The FVK audit confirms V1 and makes no further production-code changes.

Decision: keep the V1 seed-list fix in `repo/sklearn/cluster/k_means_.py`
unchanged. `fvk/FINDINGS.md` F-1 identifies the original bug as different seed
streams between serial and parallel `n_init` execution, and
`fvk/PROOF_OBLIGATIONS.md` PO-1 through PO-3 show V1 discharges that by drawing
one seed list before the branch and using it in both branches.

Decision: do not add an extra tie-handling change. F-2 and PO-4 show the
existing strict serial comparison and parallel `np.argmin` already agree on the
first minimal-inertia result once both branches share the same ordered seed
list.

Decision: do not change `_kmeans_single_lloyd`, `_kmeans_single_elkan`, or
`_init_centroids`. F-3 and PO-5 show those functions are only needed as a
deterministic `runSingle(params, seed)` abstraction for this issue; all relevant
randomness already enters through the per-run `random_state` argument.

Decision: accept the historical serial RNG sequence change. F-4 and PO-6 trace
that compatibility tradeoff to the public issue's preference for consistency
across `n_jobs`, while confirming the diff frames unrelated validation,
preprocessing, postprocessing, signatures, and return shapes.

Decision: do not run tests, Python, or K tooling. F-5 records the benchmark
constraint, and all proof obligations remain constructed rather than
machine-checked.
