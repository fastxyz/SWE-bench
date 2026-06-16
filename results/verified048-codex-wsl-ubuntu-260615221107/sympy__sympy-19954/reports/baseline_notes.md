# Baseline Notes

## Root Cause

`PermutationGroup.minimal_blocks()` keeps three parallel lists while it searches
for minimal block systems: `blocks`, `num_blocks`, and `rep_blocks`. When a new
representative block was found to be smaller than existing representative
blocks, the function deleted entries from `blocks` and `num_blocks` immediately
inside `enumerate(rep_blocks)`.

That made the indexes from the `rep_blocks` iteration stale after the first
deletion. If the same pass found more than one existing non-minimal block
system, a later deletion could address an index that no longer existed in the
already-shortened `blocks` or `num_blocks` lists. This matches the reported
`IndexError` raised from `del num_blocks[i], blocks[i]` during
`sylow_subgroup(p=2)`, which calls `minimal_blocks()` for transitive groups.

## Changed Files

`repo/sympy/combinatorics/perm_groups.py`

- Changed `minimal_blocks()` so it records indexes of existing non-minimal block
  systems during the comparison loop.
- After the loop, it removes those indexes in reverse order from all three
  parallel lists: `num_blocks`, `blocks`, and `rep_blocks`.
- This preserves the intended pruning behavior while avoiding index shifts
  during iteration.

## Assumptions and Alternatives

- I assumed the block-system comparison logic itself is correct: an existing
  representative block that strictly contains the new representative block is no
  longer minimal, while a smaller existing representative block means the new
  block system should not be added.
- I rejected changing `sylow_subgroup()` because its failure is downstream of
  `minimal_blocks()` returning via an unsafe internal mutation pattern.
- I rejected replacing the parallel lists with a larger structural refactor
  because the issue can be fixed locally by preserving index alignment during
  removal.
- I did not add or modify tests, and I did not run tests or reproducer code, per
  the benchmark instructions.
