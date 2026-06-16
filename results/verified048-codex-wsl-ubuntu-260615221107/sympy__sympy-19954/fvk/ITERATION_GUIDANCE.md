# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source fix in `repo/sympy/combinatorics/perm_groups.py` unchanged.

## Justification

- FVK-F1 identifies the concrete pre-V1 bug: deleting from `blocks` and
  `num_blocks` while still iterating over original `rep_blocks` indexes.
- PO-2 proves the collected indexes are valid original indexes because they
  come from `enumerate(rep_blocks)`.
- PO-3 proves V1's reverse deletion order prevents those original indexes from
  becoming stale.
- PO-4 proves the fix removes exactly the marked entries from all three
  parallel lists.
- PO-5 proves V1 does not change the candidate-minimality or duplicate logic.
- FVK-F3 and PO-6 show there is no public API or caller compatibility issue.

Therefore the FVK audit found no justified source edit beyond V1.

## Recommended Next Checks

These are recommendations for a future environment; they were not executed here.

1. Run the recorded K commands in `fvk/PROOF.md` and require `kprove` to return
   `#Top` before treating the proof as machine-checked.
2. Add or keep integration coverage for `DihedralGroup(18).sylow_subgroup(p=2)`
   and `DihedralGroup(2*25).sylow_subgroup(p=2)` in the normal project test
   suite.
3. Keep broader Sylow subgroup tests, because the local proof only covers the
   pruning mutation kernel.
4. If future maintenance touches this block again, consider extracting the
   three-list pruning into a private helper so the exact-removal invariant is
   easier to test and review.
