# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1 Shared Seed Stream

Claim: after validation and `n_init` normalization, `k_means` computes one
ordered seed list:

```python
seeds = random_state.randint(np.iinfo(np.int32).max, size=n_init)
```

and both serial and parallel branches iterate over exactly that `seeds` object.

Evidence: V1 places seed generation immediately before the
`effective_n_jobs(n_jobs)` branch and removes the parallel-only seed draw.

Status: discharged by source inspection and K claim C1/C2 using the same
`drawSeeds(RNG, N)`.

## PO-2 Serial Loop Invariant

Claim: after the serial branch has consumed the first `k` seeds, its stored
best result is the first minimal-inertia result among
`mapRun(params, seeds[0:k])`.

Initialization: before the first run, no best result exists.

Preservation: for the next result `R`, if `inertia(R)` is strictly lower than
the current best, replace the best with `R`; otherwise keep the current best.

Exit: after all `n_init` seeds are consumed, the serial best is
`chooseBest(mapRun(params, seeds))`.

Status: discharged by the serial loop circularity C3.

## PO-3 Parallel Result List

Claim: the parallel branch evaluates `kmeans_single` once per seed in the same
ordered seed list and obtains `mapRun(params, seeds)`.

Evidence: the generator passed to `Parallel` is `for seed in seeds`, and
`results` is unpacked in returned order before `np.argmin` is applied.

Status: discharged under the implementation/library assumption already relied
on by this code: `Parallel(...)` returns results corresponding to the input
task order.

## PO-4 First-Minimum Tie Rule

Claim: serial and parallel choose the same result when multiple runs have equal
minimal inertia.

Evidence: serial uses `inertia < best_inertia`, so equal inertia does not
replace the current best. Parallel uses `np.argmin(inertia)`, which returns the
first minimal index. The common ordered seed list therefore gives the same
first minimal result.

Status: discharged by `bestFrom`, which updates only on strict lower inertia.

## PO-5 Single-Run Determinism for Fixed Seed

Claim: for fixed validated inputs, algorithm choice, and per-run seed,
`kmeans_single` returns a deterministic result.

Evidence: `_kmeans_single_lloyd` and `_kmeans_single_elkan` both call
`check_random_state(random_state)` and pass that object into `_init_centroids`;
the randomized init modes and callable init receive randomness through that
single argument.

Status: accepted abstraction boundary for this issue. The FVK proof verifies
branch equivalence over `runSingle(params, seed)` rather than re-proving
numeric KMeans convergence.

## PO-6 Frame Conditions

Claim: V1 does not alter validation, data centering, squared-norm
precomputation, algorithm dispatch, sample-weight normalization,
postprocessing, warnings, or return shape.

Evidence: the diff is confined to seed generation and the `random_state`
argument passed by the serial branch.

Status: discharged by diff inspection.

## PO-7 Public Wrapper Forwarding

Claim: `KMeans.fit` continues to pass its existing public parameters into
`k_means`, so the fixed behavior is exposed through the estimator API without a
signature or protocol change.

Evidence: `KMeans.fit` remains unchanged and forwards `random_state`,
`n_jobs`, `n_init`, and `return_n_iter=True` as before.

Status: discharged by source inspection.
