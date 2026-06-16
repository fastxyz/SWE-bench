# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Audited unit: the `k_means` initialization scheduling block in
`repo/sklearn/cluster/k_means_.py`, plus the `KMeans.fit` wrapper that forwards
`random_state` and `n_jobs`.

The proof focuses on the observable affected by the issue: for fixed validated
inputs, `random_state`, `n_init`, and algorithm selection, the ordered set of
single-run KMeans initializations and the final best result must be independent
of whether execution is serial or parallel.

## Intent Spec

I1. For the same data and fixed `random_state`, `KMeans` must return the same
clustering result when `n_jobs=1` and when `n_jobs>1`.

I2. `n_jobs` is a scheduling parameter for the `n_init` runs. It may change
whether those runs execute serially or through joblib, but it must not change
which initialization seeds are evaluated or which best result is selected.

I3. `random_state` determines centroid initialization. An integer
`random_state` must make initialization deterministic.

I4. The final KMeans result is the result with the lowest inertia among the
`n_init` runs. When inertias tie, the existing code's strict comparison in the
serial branch and `np.argmin` in the parallel branch both select the first
minimal result; the fix must preserve that order-sensitive tie behavior.

I5. Validation, preprocessing, algorithm selection, sample-weight handling,
center restoration, warning behavior, and the public signatures of `k_means`
and `KMeans` are out of the reported defect and must be framed unchanged.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`.
Quote: "`cluster.KMeans` gives a slightly different result depending on if
`n_jobs=1` or `n_jobs>1`."
Obligation: identify and remove result dependence on `n_jobs`.
Status: encoded by claims `serial` and `parallel` reducing to the same
`chooseBest(mapRun(... drawSeeds ...))` result.

E2. Source: `benchmark/PROBLEM.md`.
Quote: "Should expect the the clustering result (e.g. the inertia) to be the
same regardless of how many jobs are run in parallel."
Obligation: same final observable result, not just no error.
Status: encoded as same best `Result`; inertia equality follows from result
equality.

E3. Source: public hint in `benchmark/PROBLEM.md`.
Quote: "Looks like the `n_jobs=1` case gets a different random seed for the
`n_init` runs than the `n_jobs!=1` case."
Obligation: seed-stream equality is the root repair obligation.
Status: V1 computes `seeds` once before the serial/parallel split.

E4. Source: public hint in `benchmark/PROBLEM.md`.
Quote: "sets `random_state` to be the same in both cases."
Obligation: both branches must feed equivalent `random_state` values into each
single KMeans run.
Status: V1 passes the same per-run integer `seed` in both branches.

E5. Source: `k_means` docstring.
Quote: "`n_jobs` ... works by computing each of the `n_init` runs in parallel."
Obligation: parallelism is a scheduling optimization for the same runs.
Status: modeled by `mapRun(params, seeds)` for the parallel branch and a serial
loop over the same `seeds`.

E6. Source: `k_means` and `KMeans` docstrings.
Quote: "`random_state` ... Determines random number generation for centroid
initialization. Use an int to make the randomness deterministic."
Obligation: fixed seeds produce deterministic single-run initializations.
Status: modeled by abstract deterministic function `runSingle(params, seed)`.

E7. Source: implementation.
Evidence: serial updates best only when `inertia < best_inertia`; parallel uses
`np.argmin(inertia)`.
Obligation: tie order must be first-minimum in both branches.
Status: encoded by `bestFrom`, which keeps the current best unless the next
inertia is strictly lower.

## Formal Model

The K artifact `fvk/mini-kmeans.k` abstracts the numeric KMeans inner loop as:

- `drawSeeds(rng, n_init)`: the ordered integer seed list drawn from the public
  `random_state`.
- `runSingle(params, seed)`: the deterministic result of one `_kmeans_single_*`
  call for fixed validated inputs and one seed.
- `inertia(result)`: the result's inertia.
- `chooseBest(results)`: first result with minimal inertia.

This abstraction is property-complete for the reported defect because a
passing implementation and the pre-fix failing implementation differ exactly on
the modeled axis:

- Pre-fix serial: each `n_init` run consumed one shared RNG directly; this can
  produce a different initialization sequence than the parallel seed list.
- V1: both serial and parallel run over `drawSeeds(rng, n_init)` in the same
  order, so the observable best result is the same.

The model intentionally does not prove numeric correctness of Lloyd or Elkan
KMeans iterations; that behavior is framed as `runSingle`.

## Claims

Formal claims are in `fvk/kmeans-seeding-spec.k`.

C1. Serial claim: for all `N > 0`, `kmeans(serial, rng, N)` reaches
`chooseBest(mapRun(params, drawSeeds(rng, N)))`.

C2. Parallel claim: for all `N > 0`, `kmeans(parallel, rng, N)` reaches
`chooseBest(mapRun(params, drawSeeds(rng, N)))`.

C3. Serial loop circularity: after consuming any suffix of the seed list, the
serial accumulator equals `bestFrom(current_best, mapRun(params, suffix))`.

## Adequacy Audit

A1. C1 and C2 match I1-I3 because both modes reduce to the same ordered
seed-map and best-selection expression. Pass.

A2. C3 matches I4 because `bestFrom` updates only on strict lower inertia,
which preserves first-minimum tie behavior. Pass.

A3. The model's `runSingle(params, seed)` is an abstraction of `_kmeans_single_*`.
It is adequate for this issue because the issue does not dispute inner KMeans
numeric updates, and all random centroid choices enter that call through the
single `random_state=seed` argument. Pass with trusted abstraction boundary.

A4. The spec does not include invalid-argument behavior or total termination.
Those are outside the public defect and are framed unchanged. Pass with stated
domain restriction to validated inputs and partial correctness.

## Public Compatibility Audit

No public function signature, constructor signature, return shape, virtual
dispatch protocol, or test file was changed. The affected public APIs remain
`k_means(...)` and `KMeans(...).fit(...)`.

The visible callsites in `repo/sklearn/cluster/spectral.py` and
`repo/sklearn/cluster/bicluster.py` call `k_means` through its existing
signature; V1 changes only the internal seed source used by serial
initialization runs. Compatibility status: pass.
