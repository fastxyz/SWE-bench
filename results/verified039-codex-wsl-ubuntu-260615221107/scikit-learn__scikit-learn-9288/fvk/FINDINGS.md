# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations; no tests or
code were run.

## F-1 Resolved Code Bug: Serial and Parallel Used Different Seed Streams

Input: the public reproduction in `benchmark/PROBLEM.md`,
`KMeans(n_clusters=10, random_state=2, n_jobs=1)` versus `n_jobs=2`.

Observed before V1, per public issue: `n_jobs=1` reported inertia
`17815.004991244623`, while `n_jobs=2` reported `17815.060435554242`.

Expected: the same clustering result, including inertia, regardless of
`n_jobs`.

Cause: pre-fix serial execution passed the same mutable `RandomState` instance
through all `n_init` runs, while parallel execution drew an integer seed list
and passed one seed to each run.

V1 status: resolved. `k_means` now draws the seed list once before the branch
and both serial and parallel branches pass those per-run seeds to
`kmeans_single`.

Related proof obligations: PO-1, PO-2, PO-3.

## F-2 Resolved Tie Case: First Minimal Inertia Is Preserved

Input class: any fixed seed list where two or more `_kmeans_single_*` runs
return equal minimal inertia but different labels or centers.

Expected: serial and parallel choose the same result, not merely the same
inertia value.

V1 status: resolved. Serial updates the current best only when a later inertia
is strictly lower, so it keeps the first minimal result. The parallel branch
uses `np.argmin(inertia)`, which selects the first minimal index. Because V1
uses the same ordered seed list in both branches, ties resolve identically.

Related proof obligations: PO-4.

## F-3 Framed Behavior: Inner KMeans Numeric Correctness

Input class: any single `_kmeans_single_lloyd` or `_kmeans_single_elkan` run
with fixed validated inputs and a fixed seed.

Expected for this issue: the single run is deterministic with respect to its
inputs and seed; the audit does not need to re-prove the numeric correctness of
Lloyd or Elkan iterations.

Status: proof abstraction boundary, not a code bug. The proof models the single
run as `runSingle(params, seed)` and verifies that both branches call it on the
same ordered seeds.

Related proof obligations: PO-5.

## F-4 Compatibility Finding: Historical Serial RNG Sequence Changes

Input class: valid serial KMeans calls with fixed `random_state`, including the
default `n_jobs=None`/effective one-job case.

Observed before V1: serial execution consumed the caller's `RandomState` inside
each initialization run. Parallel execution consumed a seed list first.

Expected from public issue and hints: prefer consistency within a version over
preserving the historical serial-only sequence.

V1 status: accepted and documented. This is the intentional behavior change
required to make `n_jobs` a scheduling parameter rather than a result-changing
parameter. No additional production-code edit is required.

Related proof obligations: PO-1, PO-6.

## F-5 No Machine Check or Test Execution

Input: all proof claims and source changes.

Expected under this benchmark: do not run tests, Python, or K tooling.

Status: complied. The proof is constructed only. Machine checking would require
the commands listed in `fvk/PROOF.md`; test deletion is not recommended.

Related proof obligations: all obligations remain constructed, not
machine-checked.
