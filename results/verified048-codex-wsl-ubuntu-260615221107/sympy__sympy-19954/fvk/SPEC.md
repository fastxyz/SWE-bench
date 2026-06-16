# FVK Spec: sympy__sympy-19954

Status: constructed, not machine-checked.

## Scope

The audited unit is the pruning block in
`repo/sympy/combinatorics/perm_groups.py::PermutationGroup.minimal_blocks()`,
lines 2196-2215 in the current workspace. The public symptom is an
`IndexError` in this pruning block when `sylow_subgroup(p=2)` calls
`minimal_blocks()`.

The proof abstracts away the group-theoretic generation of candidate block
systems and focuses on the mutation kernel that produced the traceback:
collecting non-minimal existing block-system indexes and deleting those entries
from the three parallel lists `blocks`, `num_blocks`, and `rep_blocks`.

## Intent Spec

1. For in-domain calls where `sylow_subgroup()` reaches
   `minimal_blocks()`, pruning candidate block systems must not raise
   `IndexError` from stale list indexes.
2. `minimal_blocks()` must preserve its documented result shape: for a
   transitive group, return block systems; for an intransitive group, return
   `False`.
3. The pruning step must remove exactly the existing block systems found to be
   non-minimal relative to the candidate representative block.
4. The three internal lists `blocks`, `num_blocks`, and `rep_blocks` must remain
   aligned: entry `k` in each list describes the same block system.
5. The public API of `minimal_blocks()` and `sylow_subgroup()` must remain
   unchanged.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| IE-1 | `benchmark/PROBLEM.md` | "`sylow_subgroup() IndexError`" and traceback ending at `del num_blocks[i], blocks[i]` | The fix must eliminate stale-index deletion in `minimal_blocks()` for the reported call path. | Encoded in K pruning claims and PO-2 through PO-4. |
| IE-2 | `benchmark/PROBLEM.md` | `G = DihedralGroup(18); S2 = G.sylow_subgroup(p=2)` and `G = DihedralGroup(2*25); S2 = G.sylow_subgroup(p=2)` | The reported families are in-domain examples for `sylow_subgroup(p=2)` and must not fail with this `IndexError`. | Covered by the local no-IndexError obligation at the failing site. |
| IE-3 | `perm_groups.py` docstring | "`For a transitive group, return the list of all minimal block systems. If a group is intransitive, return `False`.`" | Pruning must preserve minimal-block-system semantics rather than only suppressing the exception. | Encoded as exact-removal and alignment obligations. |
| IE-4 | `sylow_subgroup()` docstring | "`Return a p-Sylow subgroup of the group.`" | The caller depends on `minimal_blocks()` returning usable block-system lists. | Compatibility/frame obligation; no caller-side signature or return-shape change. |
| IE-5 | implementation evidence | V1 collects `to_remove` from `enumerate(rep_blocks)` and deletes in `reversed(to_remove)`. | The formal model may assume `to_remove` is strictly ascending and in range before deletion, because that follows from enumeration, not from the candidate output. | Encoded in `minimal-blocks-prune-spec.k` preconditions and PO-2. |

## Formal Model

Formal files:

- `fvk/mini-python-list-prune.k`
- `fvk/minimal-blocks-prune-spec.k`

The mini semantics models only the Python fragment relevant to the fix:
finite lists, list size, index validity, `deleteAt`, reversing an index list,
and a loop that deletes one index from each of three parallel lists.

The central contract is:

Given three equal-length lists `BS`, `NS`, and `RS`, and a strictly ascending
list `IS` of indexes generated from the original `rep_blocks` enumeration,
running `pruneDeletes(IS)` reaches `done()` with:

- `blocks == deleteManyDescending(BS, reverse(IS))`
- `numBlocks == deleteManyDescending(NS, reverse(IS))`
- `repBlocks == deleteManyDescending(RS, reverse(IS))`

The loop circularity for `deleteLoop(DS)` requires `DS` to be safe in descending
order relative to the current list length. This is the formal expression of
the V1 repair: deleting larger original indexes first cannot invalidate smaller
remaining original indexes.

## Formal Spec English

1. If `to_remove` is produced by enumerating the original `rep_blocks`, then
   every stored index is valid for all three original parallel lists.
2. Reversing that strictly ascending index list makes the deletion order
   descending.
3. During descending deletion, after each deletion the remaining indexes are
   smaller than every deleted index, so their numeric positions are unchanged by
   the removed suffix entries.
4. Therefore each deletion is in range for `blocks`, `num_blocks`, and
   `rep_blocks`.
5. When the deletion loop finishes, all three lists have the same length and
   are exactly the original lists with the marked indexes removed.
6. The candidate append logic after pruning is unchanged by V1.

## Spec Audit

| Formal obligation | Intent match | Audit |
|---|---|---|
| No stale deletion index can be used by the pruning loop. | IE-1 and IE-2 require removing the reported `IndexError`. | Pass. |
| Deletion removes exactly the marked non-minimal entries. | IE-3 requires preserving `minimal_blocks()` semantics. | Pass. |
| Parallel lists remain aligned. | IE-3 and the caller behavior in IE-4 require usable block systems. | Pass. |
| Candidate append condition is unchanged. | No public evidence requires a different duplicate or minimality rule. | Pass. |
| Group-theoretic correctness of `minimal_block()` and Sylow construction. | Outside the failing mutation kernel; no V1 edit changed this behavior. | Explicit proof boundary, not used to justify a broader claim. |

## Public Compatibility Audit

No public signature, return type, virtual dispatch protocol, or storage format
is changed. The only source behavior change is internal deletion order within
`minimal_blocks()`. Public call sites that consume `minimal_blocks()` receive
the same kind of return value as before: `False` for intransitive groups or a
list of block-system lists for transitive groups.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They
were not executed in this workspace.

```sh
kompile fvk/mini-python-list-prune.k --backend haskell
kast --backend haskell fvk/minimal-blocks-prune-spec.k
kprove fvk/minimal-blocks-prune-spec.k --definition fvk/mini-python-list-prune-kompiled
```

Expected outcome: `kprove` discharges both claims to `#Top`.
