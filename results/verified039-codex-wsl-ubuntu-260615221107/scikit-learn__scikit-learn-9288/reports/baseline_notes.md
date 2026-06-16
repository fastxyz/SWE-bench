# Baseline Notes

## Root Cause

`k_means` used different random-state handling depending on `n_jobs`.
When `effective_n_jobs(n_jobs) == 1`, each `n_init` run received the same
`RandomState` instance and consumed it sequentially. When `n_jobs` was greater
than one, the function first drew one integer seed per initialization and gave
each run its own seed. As a result, the set of centroid initializations differed
between serial and parallel execution even when the public `random_state`
parameter was fixed, which could produce different best inertia values.

## Changed Files

`repo/sklearn/cluster/k_means_.py`

Moved the per-initialization seed generation above the serial/parallel branch
and made the serial branch pass each derived seed to `kmeans_single`, matching
the parallel branch. This keeps the lower-memory serial result-selection logic
unchanged while ensuring both execution modes evaluate the same initializations
in the same order.

`reports/baseline_notes.md`

Added this report to document the issue analysis and the implemented fix.

## Assumptions and Alternatives

I assumed the intended behavior is consistency within a version: the same input
data, `random_state`, and `n_init` should produce the same `KMeans` result
regardless of `n_jobs`. This follows the issue description and public hints,
even though it changes the historical serial RNG sequence.

I considered changing the parallel path to mimic the old serial `RandomState`
consumption, but that is not generally feasible because parallel jobs cannot
share and advance one mutable RNG in the same way, especially for callable
initializers. I also considered a documentation-only note, but the issue and
hints lean toward fixing the inconsistent behavior rather than preserving it.

No tests or project code were run, per the task instructions.
