# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent Domain

For a transitive permutation group where `sylow_subgroup()` reaches
`minimal_blocks()`, the pruning block inside `minimal_blocks()` must complete
without `IndexError` and return internal lists that still describe block
systems consistently.

Evidence: IE-1 through IE-4 in `fvk/SPEC.md`.

## PO-2: Stored Removal Indexes Are Original In-Range Indexes

Every value appended to `to_remove` is the `i` yielded by
`enumerate(rep_blocks)`. Therefore, before any deletion:

- `0 <= i < len(rep_blocks)`;
- because `blocks`, `num_blocks`, and `rep_blocks` are maintained in parallel,
  `0 <= i < len(blocks)` and `0 <= i < len(num_blocks)`;
- the sequence of appended indexes is strictly increasing.

This obligation rules out invalid indexes entering `to_remove`.

## PO-3: Descending Deletion Preserves Index Validity

Let `T = [t0, t1, ..., tk]` be the strictly increasing list of original indexes
to remove. V1 deletes indexes in `reverse(T)`.

For each deletion of original index `tj`, all previously deleted indexes are
larger than `tj`. Removing larger positions does not change the position of
`tj`, so `tj` remains a valid index in each shortened list.

This obligation rules out the stale-index failure that produced the reported
`IndexError`.

## PO-4: Exact Parallel Removal

After the deletion loop finishes, `blocks`, `num_blocks`, and `rep_blocks` are
exactly their original values with the indexes in `to_remove` removed. All
unremoved entries retain their original relative order, and all three lists have
the same length.

This obligation preserves the meaning of each parallel entry.

## PO-5: Candidate Append Logic Is Framed

The V1 change does not alter:

- the predicates used to mark existing systems as non-minimal;
- the predicate that marks the candidate as non-minimal;
- the duplicate check `num_block not in num_blocks`;
- the append order for the candidate block system.

Therefore V1 changes only deletion timing, not the selection rule.

## PO-6: Public Compatibility

No public signature, return type, or caller protocol changes for
`minimal_blocks()` or `sylow_subgroup()`.

## PO-7: Formal Abstraction Adequacy

The mini-K model must preserve the properties that distinguish the bug from the
fix: list length, index validity, deletion order, exact removal, and parallel
alignment. It may abstract away the mathematical content of each block system
because the traceback occurred before any group-theoretic postcondition could
be observed.
