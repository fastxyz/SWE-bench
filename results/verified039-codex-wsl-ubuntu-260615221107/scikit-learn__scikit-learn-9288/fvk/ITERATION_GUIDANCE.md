# FVK Iteration Guidance

Status: V1 stands. No additional production-code edit is required by the FVK
audit.

## Decision Trace

Keep V1 unchanged because:

- F-1 and PO-1 show the reported defect was the branch-dependent seed stream,
  and V1 makes the seed stream common.
- F-2 and PO-4 show the order-sensitive tie case is also covered, so equality
  is over the selected result, not just over a best inertia scalar.
- F-3 and PO-5 identify the intentional abstraction boundary: numeric KMeans
  correctness is not the defect under audit.
- F-4 and PO-6 acknowledge the historical serial RNG sequence change and trace
  it to the public intent preference for consistency across `n_jobs`.

## Future Code Constraints

Maintain these constraints in later edits:

1. Generate per-run seeds before choosing serial versus parallel execution.
2. Pass one per-run seed into every `_kmeans_single_*` call in both branches.
3. Preserve seed order through result selection.
4. Keep strict-lower-inertia update semantics in serial unless the parallel tie
   rule changes at the same time.
5. Do not change public signatures or test files as part of this fix.

## Recommended Future Tests

Tests were not modified in this benchmark. In a normal development workflow,
add a regression test that compares `n_jobs=1` with at least one parallel value
for:

- `init="k-means++"`
- `init="random"`
- both Lloyd/full and Elkan paths where applicable
- a callable initializer that uses the provided `random_state`

Keep broader KMeans tests for numeric quality, convergence, invalid inputs, and
integration behavior.

## Machine-Check Next Step

When a K environment exists, run the commands in `fvk/PROOF.md`. Until those
return `#Top`, treat the proof as constructed evidence, not a basis for
deleting tests.
