# FVK Proof

Status: constructed, not machine-checked.

## Claim Summary

The formal claims are in `fvk/minimal-blocks-prune-spec.k` and run over the
mini semantics in `fvk/mini-python-list-prune.k`.

Claim 1 proves the function-level pruning contract: if `to_remove` is a
strictly increasing list of original indexes generated from an equal-length
parallel-list state, then `pruneDeletes(to_remove)` completes with all three
lists equal to their original values with exactly those indexes removed.

Claim 2 proves the deletion-loop circularity: if the deletion index list is
safe in descending order for the current list length, each loop step deletes a
valid index from all three lists and re-establishes the invariant for the
shortened lists.

## Constructed Proof

1. Before pruning, `blocks`, `num_blocks`, and `rep_blocks` have equal length:
   they are initialized together and every accepted block system appends one
   entry to each list.
2. During the comparison scan, V1 appends only the current `enumerate` index
   `i` to `to_remove`. Since `enumerate(rep_blocks)` yields original indexes in
   ascending order, `to_remove` is strictly ascending and every stored index is
   valid for the original `rep_blocks`.
3. By equal length, every stored index is also valid for the original `blocks`
   and `num_blocks`.
4. V1 executes `for i in reversed(to_remove)`, so the deletion order is
   descending.
5. Loop invariant: after deleting the first `m` descending indexes, all deleted
   indexes were larger than every remaining index. Therefore the remaining
   indexes still denote the same positions in the shortened lists as they did in
   the original lists.
6. The next deletion index is valid for `blocks`, `num_blocks`, and
   `rep_blocks`, so no `IndexError` can occur at that deletion step.
7. Deleting the same valid index from all three lists preserves equal length and
   removes the corresponding block-system record from each list.
8. By induction over the descending deletion list, loop exit yields all three
   lists equal to their original values with exactly the marked indexes removed,
   with unmarked entries in original relative order.
9. The append logic after pruning is syntactically unchanged. Because
   non-minimal existing entries have been removed before the duplicate check,
   `num_block not in num_blocks` is evaluated against the intended pruned list.
10. Therefore V1 removes the stale-index cause of the reported traceback while
    preserving the pruning semantics.

## Adequacy Gate

The English meaning of the K claims matches the intent obligations:

- The no-`IndexError` requirement traces to IE-1 and IE-2.
- Exact removal and alignment trace to IE-3 and IE-4.
- The proof precondition that `to_remove` is strictly ascending and in range
  traces to the implementation fact that it is populated only from
  `enumerate(rep_blocks)`, recorded as IE-5.
- No claim uses current candidate output as a standalone oracle.

No adequacy failure blocks accepting V1.

## Machine-Check Commands

These commands were not executed. They are the future machine-check path for an
environment with K available:

```sh
kompile fvk/mini-python-list-prune.k --backend haskell
kast --backend haskell fvk/minimal-blocks-prune-spec.k
kprove fvk/minimal-blocks-prune-spec.k --definition fvk/mini-python-list-prune-kompiled
```

Expected outcome: `kprove` returns `#Top` for both claims.

## Test Guidance

No test files were read as oracles, modified, or removed. Because the proof is
constructed but not machine-checked, no test removal is recommended in this
benchmark workspace.

After machine-checking, focused tests whose only assertion is that multiple
marked deletions in `minimal_blocks()` do not raise stale-index `IndexError`
would be subsumed by the proof. Integration tests of `sylow_subgroup()` should
remain because this local proof does not verify the entire Sylow algorithm.

## Residual Risk

This proof is partial correctness for the pruning kernel only. It does not
prove termination of the randomized stabilizer generation, mathematical
correctness of all minimal block systems, or correctness of the full Sylow
subgroup algorithm.

The trusted base is the adequacy of the mini list semantics, the stated
abstraction boundary, and future `kprove` machine-checking.
